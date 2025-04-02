extends RefCounted
class_name InputRecorder

## 输入记录数据结构
class InputRecord:
	## 动作名称
	var action: String
	## 是否按下
	var pressed: bool
	## 输入强度
	var strength: float
	## 记录时间
	var timestamp: float
	
	func _init(p_action: String, p_pressed: bool, p_strength: float) -> void:
		action = p_action
		pressed = p_pressed
		strength = p_strength
		timestamp = Time.get_ticks_msec() / 1000.0
	
	## 转换为字典
	func to_dict() -> Dictionary:
		return {
			"action": action,
			"pressed": pressed,
			"strength": strength,
			"timestamp": timestamp
		}

## 是否正在记录
var is_recording: bool = false
## 是否正在回放
var is_playing: bool = false
## 记录开始时间
var record_start_time: float = 0.0
## 回放开始时间
var playback_start_time: float = 0.0
## 当前回放索引
var _current_playback_index: int = 0
## 输入记录列表
var _records: Array[InputRecord] = []
## 最大记录数量
var _max_records: int = 1000

## 开始记录
func start_recording() -> void:
	is_recording = true
	record_start_time = Time.get_ticks_msec() / 1000.0
	_records.clear()

## 停止记录
func stop_recording() -> void:
	is_recording = false

## 开始回放
func start_playback() -> void:
	if _records.is_empty():
		return
	
	is_playing = true
	playback_start_time = Time.get_ticks_msec() / 1000.0
	_current_playback_index = 0
	
	# 计算时间偏移，使第一个记录立即播放
	var time_offset = playback_start_time - _records[0].timestamp
	
	# 调整所有记录的时间戳
	for record in _records:
		record.timestamp += time_offset

## 停止回放
func stop_playback() -> void:
	is_playing = false
	_current_playback_index = 0

## 记录输入
func record_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not is_recording:
		return
	
	var record = InputRecord.new(action, pressed, strength)
	_records.append(record)
	
	# 限制记录数量
	if _records.size() > _max_records:
		_records.pop_front()

## 清除记录
func clear_records() -> void:
	_records.clear()
	is_recording = false
	is_playing = false
	_current_playback_index = 0
	record_start_time = 0.0

## 设置最大记录数量
## [param max_count] 最大记录数量
func set_max_records(max_count: int) -> void:
	_max_records = max_count
	
	# 如果当前记录数量超过新的最大值，移除多余的记录
	while _records.size() > _max_records:
		_records.pop_front()

## 获取记录数量
## [return] 记录数量
func get_record_count() -> int:
	return _records.size()

## 获取记录时长
## [return] 记录时长（秒）
func get_record_duration() -> float:
	if _records.is_empty():
		return 0.0
	return _records[-1].timestamp - record_start_time

## 获取指定时间范围内的记录
## [param start_time] 开始时间（相对于记录开始时间）
## [param end_time] 结束时间（相对于记录开始时间）
## [return] 记录列表
func get_records_in_timeframe(start_time: float, end_time: float) -> Array:
	var result = []
	for record in _records:
		var relative_time = record.timestamp - record_start_time
		if relative_time >= start_time and relative_time <= end_time:
			result.append(record.to_dict())
	return result

## 获取所有记录
## [return] 所有记录列表
func get_all_records() -> Array:
	var records = []
	for record in _records:
		records.append(record.to_dict())
	return records

## 获取最后一条记录
## [return] 最后一条记录字典，如果没有记录则返回空字典
func get_last_record() -> Dictionary:
	if _records.is_empty():
		return {}
	return _records[-1].to_dict()

## 获取回放数据
func get_playback_data(current_time: float) -> Dictionary:
	if not is_playing or _records.is_empty() or _current_playback_index >= _records.size():
		return {}
	
	var record = _records[_current_playback_index]
	if record.timestamp <= current_time:
		_current_playback_index += 1
		return record.to_dict()
	
	return {}

## 检查回放是否结束
func is_playback_finished() -> bool:
	return is_playing and _current_playback_index >= _records.size()

## 获取记录的总时长
func get_total_duration() -> float:
	if _records.is_empty():
		return 0.0
	return _records[-1].timestamp - _records[0].timestamp

## 获取当前回放进度（0.0 到 1.0）
func get_playback_progress() -> float:
	if _records.is_empty() or not is_playing:
		return 0.0
	
	var total_duration = get_total_duration()
	if total_duration <= 0:
		return 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed_time = current_time - playback_start_time
	return clamp(elapsed_time / total_duration, 0.0, 1.0)

## 检查是否有记录数据
func has_records() -> bool:
	return not _records.is_empty()

## 获取最后一条记录的时间戳
func get_last_record_timestamp() -> float:
	if _records.is_empty():
		return 0.0
	return _records[-1].timestamp

## 获取当前回放的记录索引
func get_current_playback_index() -> int:
	return _current_playback_index

## 重置回放状态
func reset_playback() -> void:
	is_playing = false
	_current_playback_index = 0
	playback_start_time = 0.0

## 重置所有状态
func reset() -> void:
	clear_records()
	reset_playback()
	record_start_time = 0.0

## 保存记录到文件
## [param filepath] 文件路径
## [return] 是否保存成功
func save_records_to_file(filepath: String) -> bool:
	if _records.is_empty():
		return false
	
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		return false
	
	# 保存记录数据
	var save_data = {
		"version": "1.0",
		"record_start_time": record_start_time,
		"records": []
	}
	
	for record in _records:
		save_data.records.append({
			"action": record.action,
			"pressed": record.pressed,
			"strength": record.strength,
			"timestamp": record.timestamp
		})
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	return true

## 从文件加载记录
## [param filepath] 文件路径
## [return] 是否加载成功
func load_records_from_file(filepath: String) -> bool:
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var save_data = json.get_data()
	if not save_data is Dictionary or not save_data.has("records"):
		return false
	
	# 清除现有记录
	_records.clear()
	record_start_time = save_data.get("record_start_time", 0.0)
	
	# 加载记录
	for record_data in save_data.records:
		if record_data is Dictionary:
			var record = InputRecord.new(
				record_data.get("action", ""),
				record_data.get("pressed", false),
				record_data.get("strength", 1.0)
			)
			record.timestamp = record_data.get("timestamp", 0.0)
			_records.append(record)
	
	return not _records.is_empty()
