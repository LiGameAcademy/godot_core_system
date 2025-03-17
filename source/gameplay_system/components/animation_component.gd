extends AnimationPlayer
class_name AnimationComponent

## 动画组件
## 继承自AnimationPlayer，添加游戏相关的动画功能

# 动画状态
var current_state: StringName = &""

# 状态动画映射
var _state_animations: Dictionary = {}

## 注册状态动画
## [param state_name] 状态名称
## [param animation_name] 动画名称
func register_state_animation(state_name: StringName, animation_name: StringName) -> void:
	_state_animations[state_name] = animation_name

## 移除状态动画
## [param state_name] 状态名称
func unregister_state_animation(state_name: StringName) -> void:
	_state_animations.erase(state_name)

## 播放状态动画
## [param state_name] 状态名称
## [param custom_blend] 混合时间
## [param custom_speed] 播放速度
## [param from_end] 是否从结尾开始播放
func play_state(state_name: StringName, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if _state_animations.has(state_name):
		current_state = state_name
		play(_state_animations[state_name], custom_blend, custom_speed, from_end)

## 获取当前状态
## [return] 当前状态名称
func get_current_state() -> StringName:
	return current_state

## 检查是否处于指定状态
## [param state_name] 状态名称
## [return] 是否处于该状态
func is_in_state(state_name: StringName) -> bool:
	return current_state == state_name

## 获取状态动画名称
## [param state_name] 状态名称
## [return] 动画名称，如果状态不存在则返回空字符串
func get_state_animation(state_name: StringName) -> StringName:
	return _state_animations.get(state_name, &"")
