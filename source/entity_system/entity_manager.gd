extends Node

## 实体管理器
## 负责管理实体的生命周期和资源加载

## 实体加载完成信号
signal entity_loaded(entity_id: StringName, entity: PackedScene)
signal entity_unloaded(entity_id: StringName)
## 实体销毁信号
signal entity_created(entity_id: StringName, entity: Node)
signal entity_destroyed(entity_id: StringName, entity: Node)

## 实体资源缓存
var _entity_resource_cache: Dictionary[StringName, PackedScene] = {}
## 实体ID路径映射
var _entity_path_map: Dictionary[StringName, String] = {}

var _resource_manager : CoreSystem.ResourceManager:
	get:
		return CoreSystem.resource_manager

func _ready() -> void:
	_resource_manager.resource_loaded.connect(
		func(resource_path: String, resource: Resource):
			if resource is PackedScene:
				var entity_id := _entity_path_map.find_key(resource_path)
				if not entity_id:
					return
				if _entity_resource_cache.has(entity_id):
					return
				_entity_resource_cache[entity_id] = resource
				var scene := resource
				entity_loaded.emit(entity_id, scene)
	)
	_resource_manager.resource_unloaded.connect(
		func(resource_path: String):
			var entity_id: StringName = _entity_path_map.find_key(resource_path)
			if not entity_id:
				return
			_entity_resource_cache.erase(entity_id)
			entity_unloaded.emit(entity_id)
	)

## 获取实体场景
func get_entity_scene(entity_id: StringName) -> PackedScene:
	return _entity_resource_cache.get(entity_id)

## 加载实体
## [param entity_id] 实体ID
## [param scene_path] 场景路径
## [param load_mode] 加载模式
## [return] 加载的实体
func load_entity(entity_id: StringName, scene_path: String, 
		load_mode: CoreSystem.ResourceManager.LOAD_MODE = CoreSystem.ResourceManager.LOAD_MODE.IMMEDIATE) -> PackedScene:
	if _entity_resource_cache.has(entity_id):
		push_warning("实体已存在: %s" % entity_id)
		return _entity_resource_cache[entity_id]

	_entity_path_map[entity_id] = scene_path
	var scene: PackedScene = _resource_manager.load_resource(scene_path, load_mode)
	if not scene:
		# push_error("无法加载实体场景: %s" % scene_path)
		return null
		
	_entity_resource_cache[entity_id] = scene
	entity_loaded.emit(entity_id, scene)
	return scene

## 卸载实体
## [param entity_id] 实体ID
func unload_entity(entity_id: StringName) -> void:
	if not _entity_resource_cache.has(entity_id):
		push_warning("实体不存在: %s" % entity_id)
		return

## 创建实体
## [param entity_id] 实体ID
## [param parent] 父节点
func create_entity(entity_id: StringName, entity_config: Resource, parent : Node = null) -> Node:
	var instance : Node =  _resource_manager.get_instance(_entity_path_map[entity_id])
	if not instance:
		instance = get_entity_scene(entity_id).instantiate()
	
	if not instance or not instance is Node:
		push_error("实体实例不是 Node 类型: %s" % entity_id)
		return

	if parent:
		parent.add_child(instance)
	
	## 初始化实体
	if not instance.has_method("initialize"):
		return
	instance.initialize(entity_config)

	entity_created.emit(entity_id, instance)
	return instance

## 更新实体
## [param entity_id] 实体ID
## [param instance] 要更新的实体
func update_entity(instance : Node, entity_config: Resource) -> void:
	if instance.has_method("update"):
		instance.update(entity_config)

## 销毁实体
## [param entity_id] 实体ID
## [param instance] 要销毁的实体
func destroy_entity(entity_id: StringName, instance : Node) -> void:
	if instance.has_method("destroy"):
		instance.destroy()
	_resource_manager.recycle_instance(_entity_path_map[entity_id], instance)
	entity_destroyed.emit(entity_id, instance)

## 清理所有实体
func clear_entities() -> void:
	for entity_id in _entity_resource_cache.keys():
		_resource_manager.clear_instance_pool(_entity_path_map[entity_id])
