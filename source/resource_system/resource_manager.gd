extends Node

## 资源管理器
## 负责管理资源的加载，缓存和对象池

## 资源加载模式
enum LOAD_MODE {
	## 立即加载a
	IMMEDIATE,
	## 懒加载
	LAZY
}

## 资源加载信号
signal resource_loaded(path: String, resource: Resource)
## 资源卸载信号
signal resource_unloaded(path: String)

## 资源缓存
var _resource_cache: Dictionary = {}
## 对象池
var _instance_pools: Dictionary = {}
## 懒加载时间间隔
var _lazy_load_interval: float = 1.0
## 当前懒加载时间
var _lazy_load_time: float = 0.0
## 待加载资源数量
var _loading_count: int = 0

var _logger: CoreSystem.Logger:
	get:
		return CoreSystem.logger

## 处理懒加载
func _process(delta: float) -> void:
	_lazy_load(delta)

## 加载资源
## [param path] 资源路径
## [param mode] 加载模式
## [return] 加载的资源
func load_resource(path: String, mode: LOAD_MODE = LOAD_MODE.IMMEDIATE) -> Resource:
	if _resource_cache.has(path) and _resource_cache[path] != null:
		# 如果资源已经加载过了
		return _resource_cache[path]
	var resource: Resource = null
	if not ResourceLoader.exists(path):
		push_error("资源地址无效: " + path)
		return null
	match mode:
		LOAD_MODE.IMMEDIATE:
			resource = ResourceLoader.load(path)
		LOAD_MODE.LAZY:
			ResourceLoader.load_threaded_request(path)
			_loading_count += 1
	_resource_cache[path] = resource
	if resource:
		resource_loaded.emit(path, resource)
	return resource

## 获取缓存资源
## [param path] 资源路径
## [return] 缓存中的资源
func get_cached_resource(path: String) -> Resource:
	if _resource_cache.has(path) and _resource_cache[path] == null:
		# 如果资源正在加载，则这里调用直接加载
		_loading_count -= 1
	if _resource_cache.get(path, null) == null:
		_logger.warning("[ResourceManager]cannot get cached resource on {0}, reload it!".format([path]))
		return load_resource(path)
	return _resource_cache.get(path)

## 清空资源缓存
## [param path] 资源路径，如果为空，则清空所有资源
func clear_resource_cache(path: String = "") -> void:
	if path.is_empty():
		_resource_cache.clear()
		resource_unloaded.emit("")
	elif _resource_cache.has(path):
		_resource_cache.erase(path)
		resource_unloaded.emit(path)

## 从对象池获取实例，如果不存在则返回空
## [param id] 实例ID
## [return] 池中的实例
func get_instance(id: StringName) -> Node:
	if _instance_pools.has(id):
		return _instance_pools[id].pop_back()
	return null

## 回收实例到对象池
## [param id] 实例ID
## [param instance] 要回收的实例
func recycle_instance(id: StringName, instance: Node) -> void:
	if not _instance_pools.has(id):
		_instance_pools[id] = []
	if instance.get_parent():
		instance.get_parent().remove_child(instance)
	_instance_pools[id].append(instance)

## 获取对象池中实例的数量，如果为空，计算所有对象池中的实例数量
## [param id] 实例ID
## [return] 池中的实例数量
func get_instance_count(id: StringName = "") -> int:
	if id.is_empty():
		var count: int = 0
		for pool in _instance_pools.values():
			count += pool.size()
		return count
	if not _instance_pools.has(id):
		return 0
	return _instance_pools[id].size()

## 清空对象池，如果为空，清空所有对象池
## [param id] 实例ID
func clear_instance_pool(id: StringName = "") -> void:
	if id.is_empty():
		_instance_pools.clear()
	elif _instance_pools.has(id):
		_instance_pools[id].clear()
		_instance_pools[id].resize(0)
	else:
		push_error("Instance pool for id " + id + " does not exist.")

## 设置懒加载时间间隔
## [param interval] 时间间隔
func set_lazy_load_interval(interval: float) -> void:
	_lazy_load_interval = interval

## 处理懒加载
## [param delta] 时间间隔
func _lazy_load(delta: float) -> void:
	#判断是否需要处理懒加载
	if _loading_count <= 0: return
	_lazy_load_time += delta
	if _lazy_load_time < _lazy_load_interval:
		return
	_lazy_load_time -= _lazy_load_interval
	var loading_paths = []
	for path in _resource_cache:
		if _resource_cache[path] == null:
			loading_paths.append(path)
	
	for path in loading_paths:
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			_resource_cache[path] = resource
			_loading_count -= 1
			resource_loaded.emit(path, resource)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load resource: " + path)
			_resource_cache.erase(path)
			_loading_count -= 1
		elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Invalid resource: " + path)
			_resource_cache.erase(path)
			_loading_count -= 1
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
