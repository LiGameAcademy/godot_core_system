extends Node
class_name GameplayObject

## 游戏对象基类
## 所有游戏对象的基类，提供基础功能和组件系统

# 信号
signal component_added(component_name: StringName, component: Node)
signal component_removed(component_name: StringName, component: Node)
signal controller_changed(old_controller: GameplayController, new_controller: GameplayController)

# 控制器引用
var controller: GameplayController:
    set(value):
        var old_controller = controller
        controller = value
        emit_signal("controller_changed", old_controller, value)

# 组件系统
var _components: Dictionary = {}

func _init() -> void:
    pass

## 添加组件
## [param component] 要添加的组件
## [param name] 组件名称，如果为空则使用组件的类名
func add_gameplay_component(component: Node, name: StringName = &"") -> void:
    if not name:
        name = component.get_class()
    
    _components[name] = component
    add_child(component)
    component_added.emit(name, component)

## 移除组件
## [param name] 要移除的组件名称
func remove_gameplay_component(name: StringName) -> void:
    if _components.has(name):
        var component = _components[name]
        _components.erase(name)
        remove_child(component)
        component.queue_free()
        component_removed.emit(name, component)

## 获取组件
## [param name] 组件名称
## [return] 组件实例，如果不存在则返回null
func get_gameplay_component(name: StringName) -> Node:
    return _components.get(name)

## 检查是否有组件
## [param name] 组件名称
## [return] 是否存在该组件
func has_gameplay_component(name: StringName) -> bool:
    return _components.has(name)

## 获取所有组件
## [return] 组件字典的副本
func get_all_components() -> Dictionary:
    return _components.duplicate()

## 受到伤害
## [param amount] 伤害值
func take_damage(amount: float) -> void:
    var health = get_gameplay_component(&"health") as HealthComponent
    if health:
        health.take_damage(amount)

## 治疗
## [param amount] 治疗值
func heal(amount: float) -> void:
    var health = get_gameplay_component(&"health") as HealthComponent
    if health:
        health.heal(amount)

## 销毁对象
func destroy() -> void:
    # 移除所有组件
    for component_name in _components.keys():
        remove_gameplay_component(component_name)
    queue_free()
