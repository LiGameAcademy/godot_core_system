extends Node
class_name SceneBase

## 场景基类，提供状态保存和恢复功能
## 注意：core_system使用has_method确认场景是否有对应方法
## 注意：因此继承SceneBase并不是必须的

## 初始化场景状态
func init_state(_data: Dictionary) -> void:
	pass

## 保存场景状态
func save_state() -> Dictionary:
	return {}

## 恢复场景状态
func restore_state(_data: Dictionary) -> void:
	pass
