extends Node

## 事件优先级枚举
enum Priority {
	LOW = 0,			## 低优先级
	NORMAL = 1,		## 普通优先级
	HIGH = 2,		## 高优先级
}

## 事件历史记录
var _event_history: Array[Dictionary] = []
## 事件优先级表 {事件名: {object_id: {priority, once, filter}}}
var _event_metadata: Dictionary = {}
## 是否记录事件历史
@export var enable_history: bool = false
## 历史记录最大长度
@export var max_history_length: int = 100
## 调试模式
@export var debug_mode: bool = false

## 信号：事件被推送时触发
signal event_pushed(event_name: String, payload: Array)
## 信号：事件处理完成时触发
signal event_handled(event_name: String, payload: Array)

## 推送事件
## [param event_name] 事件名
## [param payload] 事件负载
## [param immediate] 是否立即触发事件
func push_event(event_name: String, payload : Variant = [], immediate: bool = true) -> void:
	if not payload is Array:
		payload = [payload]
	
	if debug_mode:
		print("[EventBus] Pushing event: %s with payload: %s" % [event_name, payload])
	
	if enable_history:
		_record_event(event_name, payload)
	
	event_pushed.emit(event_name, payload)
	
	# 如果事件没有被订阅，直接返回
	if not has_signal(event_name) or get_signal_connection_list(event_name).is_empty():
		if debug_mode:
			print("[EventBus] No subscribers for event: %s" % event_name)
		return
	
	# 获取所有订阅者
	var connections = get_signal_connection_list(event_name)
	if connections.is_empty():
		return
		
	# 按优先级排序订阅者
	var ordered_connections = _sort_connections_by_priority(event_name, connections)
	
	# 筛选满足过滤条件的连接
	var filtered_connections = []
	var to_disconnect = []
	
	for conn in ordered_connections:
		var object = conn["callable"].get_object()
		var method = conn["callable"].get_method()
		
		# 如果对象已被释放，将其标记为需要断开连接
		if not is_instance_valid(object):
			to_disconnect.append(conn)
			continue
			
		# 检查过滤器
		var obj_id = _get_object_id(object, method)
		if _event_metadata.has(event_name) and _event_metadata[event_name].has(obj_id):
			var metadata = _event_metadata[event_name][obj_id]
			var filter_callable = metadata["filter"]
			
			# 应用过滤器
			if filter_callable.is_valid() and not filter_callable.call(payload):
				continue
				
			# 如果是一次性订阅，标记为需要断开连接
			if metadata["once"]:
				to_disconnect.append(conn)
				
		filtered_connections.append(conn)
	
	# 发送事件
	for conn in filtered_connections:
		if immediate:
			conn["callable"].callv(payload)
		else:
			_schedule_deferred_call(conn["callable"], payload)
	
	# 断开一次性连接
	for conn in to_disconnect:
		var object = conn["callable"].get_object()
		var method = conn["callable"].get_method()
		if is_instance_valid(object):
			disconnect(event_name, conn["callable"])
			
			# 移除元数据
			var obj_id = _get_object_id(object, method)
			if _event_metadata.has(event_name) and _event_metadata[event_name].has(obj_id):
				_event_metadata[event_name].erase(obj_id)
				if _event_metadata[event_name].is_empty():
					_event_metadata.erase(event_name)
	
	event_handled.emit(event_name, payload)

## 订阅事件
## [param event_name] 事件名
## [param callback] 回调函数
## [param priority] 优先级
## [param once] 是否只执行一次
## [param filter] 过滤器
func subscribe(
	event_name: String, 
	callback: Callable, 
	priority: Priority = Priority.NORMAL,
	once: bool = false,
	filter: Callable = func(_p): return true
) -> void:
	# 动态添加信号（如果不存在）
	if not has_signal(event_name):
		add_user_signal(event_name)
	
	# 检查是否已存在相同的回调
	for conn in get_signal_connection_list(event_name):
		if conn["callable"] == callback:
			if debug_mode:
				print("[EventBus] Callback already subscribed to event: %s" % event_name)
			else:
				push_warning("Callback already subscribed to event: %s" % event_name)
			return
	
	# 连接信号
	connect(event_name, callback)
	
	# 保存优先级和其他元数据
	var object = callback.get_object()
	var method = callback.get_method()
	var obj_id = _get_object_id(object, method)
	
	if not _event_metadata.has(event_name):
		_event_metadata[event_name] = {}
		
	_event_metadata[event_name][obj_id] = {
		"priority": priority,
		"once": once,
		"filter": filter
	}
	
	if debug_mode:
		print("[EventBus] Subscribed to event: %s with priority: %s" % [event_name, priority])

## 取消订阅事件
## [param event_name] 事件名
## [param callback] 回调函数
func unsubscribe(event_name: String, callback: Callable) -> void:
	if not has_signal(event_name):
		return
		
	# 断开连接
	if is_connected(event_name, callback):
		disconnect(event_name, callback)
		
		# 移除元数据
		var object = callback.get_object()
		var method = callback.get_method()
		var obj_id = _get_object_id(object, method)
		
		if _event_metadata.has(event_name) and _event_metadata[event_name].has(obj_id):
			_event_metadata[event_name].erase(obj_id)
			if _event_metadata[event_name].is_empty():
				_event_metadata.erase(event_name)
				
		if debug_mode:
			print("[EventBus] Unsubscribed from event: %s" % event_name)

## 订阅一次性事件
## [param event_name] 事件名
## [param callback] 回调函数
## [param priority] 优先级
## [param filter] 过滤器
func subscribe_once(
	event_name: String, 
	callback: Callable, 
	priority: Priority = Priority.NORMAL,
	filter: Callable = func(_p): return true
) -> void:
	subscribe(event_name, callback, priority, true, filter)

## 取消订阅所有事件
## [param callback] 回调函数
func unsubscribe_all(callback: Callable) -> void:
	for event_name in _get_all_signals():
		if is_connected(event_name, callback):
			unsubscribe(event_name, callback)

## 清除所有订阅
func clear_subscriptions() -> void:
	for event_name in _get_all_signals():
		for conn in get_signal_connection_list(event_name):
			disconnect(event_name, conn["callable"])
			
	_event_metadata.clear()
	
	if debug_mode:
		print("[EventBus] All subscriptions cleared")

## 获取事件订阅者数量
## [param event_name] 事件名
func get_subscriber_count(event_name: String) -> int:
	if not has_signal(event_name):
		return 0
	return get_signal_connection_list(event_name).size()

## 获取事件历史记录
## [return] 事件历史记录
func get_event_history() -> Array[Dictionary]:
	return _event_history.duplicate()

## 清除事件历史记录
func clear_event_history() -> void:
	_event_history.clear()

## 记录事件
## [param event_name] 事件名
## [param payload] 事件负载
func _record_event(event_name: String, payload: Array) -> void:
	var event = {
		"timestamp": Time.get_unix_time_from_system(),
		"event_name": event_name,
		"payload": payload
	}
	_event_history.push_front(event)
	
	if _event_history.size() > max_history_length:
		_event_history.pop_back()

## 获取所有可用信号
func _get_all_signals() -> Array[String]:
	var signal_list: Array[String] = []
	for signal_dict in get_signal_list():
		if signal_dict["name"] != "event_pushed" and signal_dict["name"] != "event_handled":
			signal_list.append(signal_dict["name"])
	return signal_list

## 为对象和方法生成唯一ID
func _get_object_id(object: Object, method: StringName) -> String:
	return str(object.get_instance_id()) + "_" + method

## 按优先级排序连接
func _sort_connections_by_priority(event_name: String, connections: Array) -> Array:
	if not _event_metadata.has(event_name):
		return connections
		
	var result = connections.duplicate()
	result.sort_custom(func(a, b):
		var a_obj = a["callable"].get_object()
		var a_method = a["callable"].get_method()
		var b_obj = b["callable"].get_object()
		var b_method = b["callable"].get_method()
		
		var a_id = _get_object_id(a_obj, a_method)
		var b_id = _get_object_id(b_obj, b_method)
		
		# 默认优先级
		var a_priority = Priority.NORMAL
		var b_priority = Priority.NORMAL
		
		if _event_metadata[event_name].has(a_id):
			a_priority = _event_metadata[event_name][a_id]["priority"]
			
		if _event_metadata[event_name].has(b_id):
			b_priority = _event_metadata[event_name][b_id]["priority"]
			
		# 高优先级在前
		return a_priority > b_priority
	)
	return result

## 延迟调用
func _schedule_deferred_call(callable: Callable, payload: Array) -> void:
	call_deferred("_do_deferred_call", callable, payload)

## 执行延迟调用
func _do_deferred_call(callable: Callable, payload: Array) -> void:
	if callable.is_valid() and is_instance_valid(callable.get_object()):
		callable.callv(payload)
		
## 获取订阅数量（测试用）
func get_subscription_counts() -> Dictionary:
	var result = {}
	for event_name in _get_all_signals():
		result[event_name] = get_signal_connection_list(event_name).size()
	return result
