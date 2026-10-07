extends Control

const Inputs = preload("../../source/input_system/core_inputs.gd")
const Binding = preload("../../source/input_system/core_input_binding.gd")
const Manager = preload("../../source/input_system/input_manager.gd")
const Adapter = preload("../../source/input_system/config/input_config_adapter.gd")

@export var preferences_path: String = "user://input_extensions.cfg"
var bindings: Inputs = Inputs.new()
var observer: Manager = Manager.new()
var preferences: Adapter
var _file: ConfigFile = ConfigFile.new()
var _actions: Array[StringName] = [&"extension_jump", &"extension_right"]
var _created: Array[StringName] = []
var _ready_for_input: bool = false
@onready var _status: Label = $Layout/Status

func _ready() -> void:
	for action: StringName in _actions:
		if InputMap.has_action(action):
			_status.text = "示例动作已存在，请先关闭另一个示例。"
			return
	for index: int in range(_actions.size()):
		InputMap.add_action(_actions[index])
		_created.append(_actions[index])
		InputMap.action_add_event(_actions[index], Binding.new(Binding.Kind.KEY, KEY_SPACE if index == 0 else KEY_D).to_event())
	if bindings.register_actions(_actions) != OK:
		_status.text = "动作组注册失败。"
		return
	observer.use_bindings(bindings)
	observer.name = "InputObserver"
	add_child(observer)
	observer.action_triggered.connect(_on_action)
	observer.remap_completed.connect(_on_remapped)
	observer.virtual_axis.register_axis("move", "extension_right")
	preferences = Adapter.new(null, _read_preferences, _write_preferences, _save_preferences)
	$Layout/Rebind.pressed.connect(_rebind)
	$Layout/Cancel.pressed.connect(observer.cancel_remap)
	$Layout/Record.pressed.connect(_record)
	$Layout/Playback.pressed.connect(_playback)
	$Layout/Save.pressed.connect(_save)
	$Layout/Load.pressed.connect(_load)
	_ready_for_input = true
	_status.text = "空格：跳跃；D：向右。可以改键、录制，再读取回放记录。"

func _process(_delta: float) -> void:
	if not _ready_for_input or not observer.input_recorder.is_playing:
		return
	var record: Dictionary = observer.input_recorder.get_playback_data(Time.get_ticks_msec() / 1000.0)
	if not record.is_empty():
		_status.text = "回放：%s %s" % [record.action, "按下" if record.pressed else "释放"]
	if observer.input_recorder.is_playback_finished():
		observer.input_recorder.stop_playback()

func _exit_tree() -> void:
	observer.close()
	bindings.close()
	if preferences != null:
		preferences.close()
	for action: StringName in _created:
		InputMap.erase_action(action)
	if observer.get_parent() == null:
		observer.free()

func _rebind() -> void:
	_status.text = "请按新按键；取消按钮可以结束捕获。" if observer.start_remap(_actions[0]) == OK else "无法开始改键。"

func _record() -> void:
	observer.input_recorder.start_recording()
	_status.text = "正在录制跳跃与向右动作。"

func _playback() -> void:
	observer.input_recorder.stop_recording()
	observer.input_recorder.start_playback()
	_status.text = "读取已录制动作；回放不会替你移动游戏对象。"

func _save() -> void:
	for action: StringName in _actions:
		preferences.set_action_mapping(String(action), bindings.to_data().Actions[String(action)])
	_status.text = "改键偏好已保存。" if preferences.save_config() == OK else "偏好保存失败。"

func _load() -> void:
	var result: Error = _file.load(preferences_path)
	if result != OK:
		_status.text = "尚无偏好文件。" if result == ERR_FILE_NOT_FOUND else "偏好读取失败。"
		return
	if preferences.reload_config() == OK and bindings.apply_data({"Actions": preferences.get_action_mappings()}) == OK:
		_status.text = "已恢复保存的按键。"
	else:
		_status.text = "偏好无效，当前按键保持不变。"

func _read_preferences() -> Variant:
	return _file.get_value("input", "data", {})

func _write_preferences(data: Dictionary) -> void:
	_file.set_value("input", "data", data)

func _save_preferences() -> Error:
	return _file.save(preferences_path)

func _on_action(action: String, event: InputEvent) -> void:
	_status.text = "%s：%s" % [action, "按下" if event.is_pressed() else "释放"]

func _on_remapped(_action: String, _event: InputEvent) -> void:
	_status.text = "跳跃按键已修改；保存按钮可保留此次偏好。"
