extends Node

## 事件优先级枚举
enum Priority {
	LOW = 0,			## 低优先级
	NORMAL = 1,		## 普通优先级
	HIGH = 2,		## 高优先级
}

## 事件订阅字典 {事件名: [Subscription]}
var _subscriptions: Dictionary = {}
## 事件历史记录
var _event_history: Array[Dictionary] = []
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
	
	if not _subscriptions.has(event_name):
		if debug_mode:
			print("[EventBus] No subscribers for event: %s" % event_name)
		return
	
	# 按优先级排序订阅者
	var subscribers = _subscriptions[event_name].duplicate()
	subscribers.sort_custom(func(a, b): return a.priority > b.priority)
	
	# 收集需要移除的一次性订阅
	var to_remove: Array[WeakSubscription] = []
	
	# 处理事件
	var valid_subscriptions := []
	for sub : WeakSubscription in subscribers:
		if not sub.is_valid():
			continue
		valid_subscriptions.append(sub)
		if sub.filter.is_valid() and sub.filter.call(payload):
			if immediate:
				sub.call_subscribed(payload)
			else:
				call_deferred("_deferred_call", sub, payload)
			if sub.once:
				to_remove.append(sub)

	# 更新订阅列表，移除无效订阅
	if valid_subscriptions.size() != _subscriptions[event_name].size():
		_subscriptions[event_name] = valid_subscriptions
		if valid_subscriptions.is_empty():
			_subscriptions.erase(event_name)
	
	# 移除一次性订阅
	for sub in to_remove:
		_subscriptions[event_name].erase(sub)

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
	if not _subscriptions.has(event_name):
		_subscriptions[event_name] = []
	
	# 检查是否已存在相同的回调
	for sub in _subscriptions[event_name]:
		if (sub.is_anonymous and sub.callback == callback) or (not sub.is_anonymous and sub.callback_method == callback.get_method()):
			if debug_mode:
				print("[EventBus] Callback already subscribed to event: %s" % event_name)
			else:
				push_warning("Callback already subscribed to event: %s" % event_name)
			return
	
	var subscription = WeakSubscription.new(callback, priority, once, filter)
	_subscriptions[event_name].append(subscription)
	
	if debug_mode:
		print("[EventBus] Subscribed to event: %s with priority: %s" % [event_name, priority])

## 取消订阅事件
## [param event_name] 事件名
## [param callback] 回调函数
func unsubscribe(event_name: String, callback: Callable) -> void:
	if not _subscriptions.has(event_name):
		return
	
	var index = -1
	for i in range(_subscriptions[event_name].size()):
		if _subscriptions[event_name][i].is_anonymous:
			if _subscriptions[event_name][i].callback == callback:
				index = i
				break
		else:
			if _subscriptions[event_name][i].callback_method == callback.get_method():
				index = i
				break
	
	if index != -1:
		_subscriptions[event_name].remove_at(index)
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
	for event_name in _subscriptions:
		unsubscribe(event_name, callback)

## 清除所有订阅
func clear_subscriptions() -> void:
	_subscriptions.clear()
	if debug_mode:
		print("[EventBus] All subscriptions cleared")

## 获取事件订阅者数量
## [param event_name] 事件名
func get_subscriber_count(event_name: String) -> int:
	if not _subscriptions.has(event_name):
		return 0
	return _subscriptions[event_name].size()

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

## 延迟调用回调
## [param subscription] 订阅对象
## [param payload] 事件负载
func _deferred_call(subscription: WeakSubscription, payload: Array) -> void:
	if subscription.is_valid():
		subscription.call_subscribed(payload)

## 事件订阅信息
class Subscription:
	## 回调函数
	var callback: Callable
	## 优先级
	var priority: Priority
	## 是否只触发一次
	var once: bool
	## 过滤器
	var filter: Callable
	
	func _init(cb: Callable, p: Priority, o: bool, f: Callable = func(_p): return true) -> void:
		callback = cb
		priority = p
		once = o
		filter = f

	func call_subscribed(args: Array) -> void:
		callback.callv(args)

## 使用弱引用避免内存移除情况
class WeakSubscription:
	extends Subscription

	var callback_object: WeakRef
	var callback_method: StringName
	var is_anonymous: bool

	func _init(cb: Callable, p: Priority, o: bool, f: Callable = func(_p): return true) -> void:
		callback_object = weakref(cb.get_object())
		is_anonymous = cb.get_method() == "<anonymous lambda>"  # 检查是否是匿名方法
		
		if is_anonymous:
			callback = cb  # 匿名方法保存完整的 Callable
		else:
			callback_method = cb.get_method()  # 普通方法只保存方法名
			
		priority = p
		once = o
		filter = f
	
	func is_valid() -> bool:
		var obj = callback_object.get_ref()
		if not obj:
			return false
		if is_anonymous:
			return callback.is_valid()
		return true
	
	func call_subscribed(args: Array) -> void:
		var obj = callback_object.get_ref()
		if obj:
			if is_anonymous:
				if not callback.is_valid():
					CoreSystem.logger.error("callback is not valid, cant call subscribed!")
					return
				callback.callv(args)  # 匿名方法使用完整的 Callable
			else:
				obj.callv(callback_method, args)  # 普通方法使用 call
