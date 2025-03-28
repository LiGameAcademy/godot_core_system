extends RefCounted
class_name InputBuffer

## 缓冲数据结构
class BufferData:
	## 动作名称
	var action: String
	## 输入强度
	var strength: float
	## 创建时间
	var creation_time: float
	## 缓冲持续时间
	var duration: float
	
	func _init(p_action: String, p_strength: float, p_duration: float) -> void:
		action = p_action
		strength = p_strength
		creation_time = Time.get_ticks_msec() / 1000.0
		duration = p_duration

## 缓冲列表
var _buffers: Array[BufferData] = []
## 默认缓冲时间（秒）
var _default_buffer_duration: float = 0.1

## 设置默认缓冲时间
## [param duration] 缓冲时间（秒）
func set_buffer_duration(duration: float) -> void:
	_default_buffer_duration = duration

## 获取默认缓冲时间
## [return] 缓冲时间（秒）
func get_buffer_duration() -> float:
	return _default_buffer_duration

## 添加输入缓冲
## [param action] 动作名称
## [param strength] 输入强度
## [param duration] 缓冲时间（可选，默认使用默认缓冲时间）
func add_buffer(action: String, strength: float = 1.0, duration: float = -1.0) -> void:
	if duration < 0:
		duration = _default_buffer_duration
	_buffers.append(BufferData.new(action, strength, duration))

## 检查动作是否在缓冲中
## [param action] 动作名称
## [return] 是否在缓冲中
func has_buffer(action: String) -> bool:
	clean_expired_buffers()
	for buffer in _buffers:
		if buffer.action == action:
			return true
	return false

## 获取缓冲的输入强度
## [param action] 动作名称
## [return] 输入强度，如果不在缓冲中则返回0
func get_buffer_strength(action: String) -> float:
	clean_expired_buffers()
	for buffer in _buffers:
		if buffer.action == action:
			return buffer.strength
	return 0.0

## 清除指定动作的缓冲
## [param action] 动作名称
func clear_buffer(action: String) -> void:
	for i in range(_buffers.size() - 1, -1, -1):
		if _buffers[i].action == action:
			_buffers.remove_at(i)

## 清除所有缓冲
func clear_all_buffers() -> void:
	_buffers.clear()

## 清理过期的缓冲
func clean_expired_buffers() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	for i in range(_buffers.size() - 1, -1, -1):
		var buffer = _buffers[i]
		if current_time - buffer.creation_time > buffer.duration:
			_buffers.remove_at(i)

## 获取所有缓冲数据
## [return] 缓冲数据字典
func get_all_buffers() -> Dictionary:
	clean_expired_buffers()
	var buffers = {}
	for buffer in _buffers:
		buffers[buffer.action] = {
			"strength": buffer.strength,
			"creation_time": buffer.creation_time,
			"duration": buffer.duration,
			"remaining_time": buffer.duration - (Time.get_ticks_msec() / 1000.0 - buffer.creation_time)
		}
	return buffers
