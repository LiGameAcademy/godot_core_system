extends CanvasLayer

## 输入记录器演示
## 展示输入记录器的功能，包括：
## 1. 输入序列记录
## 2. 回放功能
## 3. 存档和加载

@onready var input_manager: CoreSystem.InputManager = CoreSystem.input_manager
@onready var status_label = $UI/StatusPanel/StatusLabel
@onready var playback_display = $UI/PlaybackPanel/PlaybackDisplay
@onready var character = $Character
@onready var ghost = $Ghost
@onready var record_indicator = $UI/Title/RecordIndicator

# 常量定义
const MOVE_SPEED = 300.0
const SCREEN_MARGIN = 32.0

# 输入动作映射
const INPUT_ACTIONS = {
	"move_left": "ui_left",
	"move_right": "ui_right",
	"move_up": "ui_up",
	"move_down": "ui_down",
	"jump": "ui_accept"
}

# 成员变量
var initial_position: Vector2
var current_movement: Vector2
var is_moving: bool
var is_jumping: bool
var is_recording: bool
var is_playing: bool
var has_recorded_data: bool

func _ready() -> void:
	# 保存初始位置
	initial_position = character.position
	
	# 初始化状态
	_reset_state()
	
	# 初始化UI
	_update_button_states()
	_update_character_label(character)
	_update_character_label(ghost)
	ghost.hide()
	record_indicator.hide()
	
	# 设置初始提示
	_update_status_display()

func _exit_tree() -> void:
	# 确保停止所有活动
	if is_recording:
		_on_stop_record_pressed()
	elif is_playing:
		_on_stop_playback_pressed()

func _update_button_states() -> void:
	$UI/Controls/RecordButtons/StartRecord.disabled = is_recording or is_playing
	$UI/Controls/RecordButtons/StopRecord.disabled = not is_recording
	$UI/Controls/PlaybackButtons/StartPlayback.disabled = is_recording or is_playing or not has_recorded_data
	$UI/Controls/PlaybackButtons/StopPlayback.disabled = not is_playing
	$UI/Controls/SaveLoadButtons/SaveRecording.disabled = is_recording or is_playing or not has_recorded_data
	$UI/Controls/SaveLoadButtons/LoadRecording.disabled = is_recording or is_playing
	$UI/Controls/ResetButton.disabled = is_recording or is_playing

func _get_movement_input() -> Vector2:
	var movement = Vector2.ZERO
	
	# 使用 Input.get_action_strength 来获取输入强度
	if Input.is_action_pressed(INPUT_ACTIONS.move_left):
		movement.x -= Input.get_action_strength(INPUT_ACTIONS.move_left)
	if Input.is_action_pressed(INPUT_ACTIONS.move_right):
		movement.x += Input.get_action_strength(INPUT_ACTIONS.move_right)
	if Input.is_action_pressed(INPUT_ACTIONS.move_up):
		movement.y -= Input.get_action_strength(INPUT_ACTIONS.move_up)
	if Input.is_action_pressed(INPUT_ACTIONS.move_down):
		movement.y += Input.get_action_strength(INPUT_ACTIONS.move_down)
	
	# 归一化移动向量，保持对角线移动速度一致
	return movement.normalized() if movement.length() > 0 else movement

func _move_character(target: Node2D, movement: Vector2, delta: float) -> void:
	if movement != Vector2.ZERO:
		# 计算新位置
		var new_position = target.position + movement * MOVE_SPEED * delta
		
		# 获取视口大小
		var viewport_size = $Character.get_viewport_rect().size
		
		# 限制在屏幕范围内
		new_position.x = clamp(new_position.x, SCREEN_MARGIN, viewport_size.x - SCREEN_MARGIN)
		new_position.y = clamp(new_position.y, SCREEN_MARGIN, viewport_size.y - SCREEN_MARGIN)
		
		# 更新位置
		target.position = new_position

func _update_character_color(target: Node2D, is_jumping: bool) -> void:
	var color_rect = target.get_node("ColorRect")
	color_rect.color = Color(0, 1, 0, 1) if is_jumping else Color(0, 0.6, 1, 1)

func _update_character_label(target: Node2D) -> void:
	var label = target.get_node("Label")
	if target == character:
		label.text = "玩家" + (" (记录中)" if is_recording else "")
	else:
		label.text = "回放" + (" (播放中)" if is_playing else "")

func _process(delta: float) -> void:
	if not _validate_state():
		return
	
	if is_recording:
		_handle_recording(delta)
		# 闪烁录制指示器
		record_indicator.visible = int(Time.get_ticks_msec() / 500) % 2 == 0
		record_indicator.color = Color(1, 0, 0, 1)  # 红色
	elif is_playing:
		_handle_playback(delta)
		# 显示回放指示器
		record_indicator.visible = true
		record_indicator.color = Color(0, 1, 0, 1)  # 绿色
		
		# 检查回放是否结束
		if input_manager.input_recorder.is_playback_finished():
			_on_stop_playback_pressed()
			playback_display.text = "回放已完成\n可以重新开始回放"
	else:
		record_indicator.hide()
	
	# 更新状态显示
	_update_status_display()
	_update_button_states()

func _handle_recording(delta: float) -> void:
	# 处理移动输入
	var movement = _get_movement_input()
	if movement != Vector2.ZERO:
		if not is_moving:
			is_moving = true
			input_manager.input_recorder.record_input("ui_move", true)
		
		# 获取并记录每个方向的输入强度
		var directions = {
			"ui_left": INPUT_ACTIONS.move_left,
			"ui_right": INPUT_ACTIONS.move_right,
			"ui_up": INPUT_ACTIONS.move_up,
			"ui_down": INPUT_ACTIONS.move_down
		}
		
		for action_name in directions:
			var strength = Input.get_action_strength(directions[action_name])
			if strength > 0:
				input_manager.input_recorder.record_input(action_name, true, strength)
		
		current_movement = movement
	else:
		if is_moving:
			is_moving = false
			input_manager.input_recorder.record_input("ui_move", false)
			
			# 记录释放所有活动的方向键
			var directions = {
				"ui_left": INPUT_ACTIONS.move_left,
				"ui_right": INPUT_ACTIONS.move_right,
				"ui_up": INPUT_ACTIONS.move_up,
				"ui_down": INPUT_ACTIONS.move_down
			}
			
			for action_name in directions:
				if Input.is_action_pressed(directions[action_name]):
					input_manager.input_recorder.record_input(action_name, false)
		
		current_movement = Vector2.ZERO
	
	# 处理跳跃输入
	if Input.is_action_just_pressed(INPUT_ACTIONS.jump):
		is_jumping = true
		input_manager.input_recorder.record_input("ui_accept", true)
		_update_character_color(character, true)
	elif Input.is_action_just_released(INPUT_ACTIONS.jump):
		is_jumping = false
		input_manager.input_recorder.record_input("ui_accept", false)
		_update_character_color(character, false)
	
	# 更新角色位置
	if is_moving and current_movement != Vector2.ZERO:
		_move_character(character, current_movement, delta)

func _handle_playback(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 获取回放数据
	var playback_data = input_manager.input_recorder.get_playback_data(current_time)
	if playback_data:
		# 处理移动
		if playback_data.action == "ui_move":
			is_moving = playback_data.pressed
			if not is_moving:
				current_movement = Vector2.ZERO
		
		# 更新移动向量
		if playback_data.pressed:
			match playback_data.action:
				"ui_left":
					current_movement.x = -playback_data.strength
				"ui_right":
					current_movement.x = playback_data.strength
				"ui_up":
					current_movement.y = -playback_data.strength
				"ui_down":
					current_movement.y = playback_data.strength
		else:
			# 释放按键时，重置对应方向
			match playback_data.action:
				"ui_left":
					if current_movement.x < 0: current_movement.x = 0
				"ui_right":
					if current_movement.x > 0: current_movement.x = 0
				"ui_up":
					if current_movement.y < 0: current_movement.y = 0
				"ui_down":
					if current_movement.y > 0: current_movement.y = 0
		
		# 如果有移动输入，确保向量被归一化
		if current_movement.length() > 0:
			current_movement = current_movement.normalized()
		
		# 处理跳跃
		if playback_data.action == "ui_accept":
			is_jumping = playback_data.pressed
			_update_character_color(ghost, is_jumping)
		
		# 更新位置
		if is_moving and current_movement != Vector2.ZERO:
			_move_character(ghost, current_movement, delta)

func _reset_state() -> void:
	# 重置状态变量
	is_moving = false
	is_jumping = false
	current_movement = Vector2.ZERO
	
	# 重置角色状态
	character.position = initial_position
	if ghost.visible:
		ghost.position = initial_position
	
	# 重置角色外观
	_update_character_color(character, false)
	_update_character_color(ghost, false)
	
	# 重置标签
	_update_character_label(character)
	_update_character_label(ghost)
	
	# 重置录制指示器
	record_indicator.hide()

func _handle_error(error_message: String) -> void:
	# 显示错误信息
	playback_display.text = "错误：%s" % error_message
	
	# 重置相关状态
	if is_recording:
		_on_stop_record_pressed()
	elif is_playing:
		_on_stop_playback_pressed()
	
	# 更新UI状态
	_update_button_states()
	_update_status_display()

func _on_error_dialog_confirmed() -> void:
	# 关闭错误对话框后的处理
	_reset_state()
	_update_status_display()

func _validate_state() -> bool:
	# 检查输入管理器
	if not input_manager:
		_handle_error("输入管理器未初始化")
		return false
	
	# 检查角色引用
	if not character or not ghost:
		_handle_error("角色引用无效")
		return false
	
	# 检查UI引用
	if not playback_display or not record_indicator:
		_handle_error("UI引用无效")
		return false
	
	return true

func _on_start_record_pressed() -> void:
	if not _validate_state():
		return
	
	if not is_recording and not is_playing:
		# 重置并开始记录
		is_recording = true
		input_manager.input_recorder.start_recording()
		
		# 重置状态
		_reset_state()
		
		# 更新UI
		_update_character_label(character)
		_update_button_states()
		_update_status_display()

func _on_stop_record_pressed() -> void:
	if not _validate_state():
		return
	
	if is_recording:
		# 停止记录
		is_recording = false
		input_manager.input_recorder.stop_recording()
		has_recorded_data = input_manager.input_recorder.has_records()
		
		# 重置状态
		_reset_state()
		
		# 更新UI
		_update_character_label(character)
		_update_button_states()
		_update_status_display()

func _on_start_playback_pressed() -> void:
	if not _validate_state():
		return
	
	if not is_recording and not is_playing and has_recorded_data:
		# 重置并开始回放
		is_playing = true
		_reset_state()
		
		# 设置幽灵角色
		ghost.position = initial_position
		ghost.show()
		_update_character_label(ghost)
		
		# 开始回放
		input_manager.input_recorder.start_playback()
		
		# 更新UI
		_update_button_states()
		_update_status_display()

func _on_stop_playback_pressed() -> void:
	if not _validate_state():
		return
	
	if is_playing:
		# 停止回放
		is_playing = false
		input_manager.input_recorder.stop_playback()
		
		# 隐藏幽灵角色
		ghost.hide()
		_update_character_label(ghost)
		
		# 重置状态
		_reset_state()
		
		# 更新UI
		_update_button_states()
		_update_status_display()

func _on_save_recording_pressed() -> void:
	if not _validate_state():
		return
	
	if not is_recording and not is_playing:
		if has_recorded_data:
			var file_path = "user://demo_recording.rec"
			var success = input_manager.input_recorder.save_records_to_file(file_path)
			if not success:
				_handle_error("保存记录失败，请检查文件权限和磁盘空间")
		else:
			_handle_error("没有可保存的记录，请先进行记录")
		
		# 更新UI
		_update_button_states()
		_update_status_display()

func _on_load_recording_pressed() -> void:
	if not _validate_state():
		return
	
	if not is_recording and not is_playing:
		var file_path = "user://demo_recording.rec"
		var success = input_manager.input_recorder.load_records_from_file(file_path)
		if success:
			has_recorded_data = true
			_reset_state()
		else:
			has_recorded_data = false
			_handle_error("加载记录失败，文件可能不存在或已损坏")
		
		# 更新UI
		_update_button_states()
		_update_status_display()

func _on_reset_positions_pressed() -> void:
	if not _validate_state():
		return
	
	if not is_recording and not is_playing:
		_reset_state()
		_update_button_states()
		_update_status_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC键
		if is_recording:
			_on_stop_record_pressed()
		elif is_playing:
			_on_stop_playback_pressed()
		else:
			_on_reset_positions_pressed()

func _update_status_display() -> void:
	if is_recording:
		var elapsed_time = Time.get_ticks_msec() / 1000.0 - input_manager.input_recorder.record_start_time
		var record_count = input_manager.input_recorder.get_record_count()
		playback_display.text = (
			"正在记录中...\n"
			+ "已记录 %.2f 秒\n" % elapsed_time
			+ "已记录 %d 个输入\n\n" % record_count
			+ "方向键：移动\n"
			+ "空格键：跳跃\n\n"
			+ "当前状态：\n"
			+ "%s\n" % ("移动中" if is_moving else "静止")
			+ "%s\n" % ("跳跃中" if is_jumping else "地面")
			+ "ESC：停止记录"
		)
	elif is_playing:
		var progress = input_manager.input_recorder.get_playback_progress()
		var elapsed_time = Time.get_ticks_msec() / 1000.0 - input_manager.input_recorder.playback_start_time
		var total_time = input_manager.input_recorder.get_total_duration()
		var current_index = input_manager.input_recorder.get_current_playback_index()
		var total_records = input_manager.input_recorder.get_record_count()
		
		playback_display.text = (
			"正在回放中...\n"
			+ "已回放 %.2f / %.2f 秒\n" % [elapsed_time, total_time]
			+ "进度 %.1f%%\n" % (progress * 100)
			+ "已播放 %d / %d 个输入\n\n" % [current_index, total_records]
			+ "观察白色幽灵角色\n"
			+ "重现你的操作\n\n"
			+ "当前状态：\n"
			+ "%s\n" % ("移动中" if is_moving else "静止")
			+ "%s\n" % ("跳跃中" if is_jumping else "地面")
			+ "ESC：停止回放"
		)
	else:
		if has_recorded_data:
			var total_time = input_manager.input_recorder.get_total_duration()
			var record_count = input_manager.input_recorder.get_record_count()
			playback_display.text = (
				"已有记录数据\n"
				+ "总时长：%.2f 秒\n" % total_time
				+ "输入数量：%d\n\n" % record_count
				+ "可以开始回放\n"
				+ "或开始新的记录\n\n"
				+ "方向键：移动\n"
				+ "空格键：跳跃\n"
				+ "ESC：重置位置"
			)
		else:
			playback_display.text = (
				"准备就绪\n"
				+ "点击开始记录\n"
				+ "开始操作演示\n\n"
				+ "方向键：移动\n"
				+ "空格键：跳跃\n"
				+ "ESC：重置位置"
			)
