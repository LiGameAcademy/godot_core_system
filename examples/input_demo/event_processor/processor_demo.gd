extends CanvasLayer

## 事件处理器演示
## 展示事件处理器的功能，包括：
## 1. 事件过滤
## 2. 优先级处理
## 3. 事件队列管理

@onready var input_manager = CoreSystem.input_manager
@onready var status_label = $UI/StatusLabel
@onready var event_log = $UI/EventLog
@onready var priority_display = $UI/PriorityDisplay

# 事件优先级
enum Priority {
	SYSTEM = 0,  # 系统级事件（如退出、暂停）
	UI = 1,      # UI事件（如按钮点击）
	GAMEPLAY = 2, # 游戏输入（如角色移动）
	DEBUG = 3     # 调试事件（最低优先级）
}

# 事件过滤设置
var filter_settings := {
	"system_events": true,
	"ui_events": true,
	"gameplay_events": true,
	"debug_events": true
}

func _ready() -> void:
	# 初始化显示
	status_label.text = "事件处理器就绪"
	event_log.text = ""
	_update_priority_display()

func _input(event: InputEvent) -> void:
	# 根据事件类型确定优先级
	var priority = _get_event_priority(event)
	
	# 检查是否应该过滤此事件
	if _should_filter_event(event, priority):
		return
	
	# 处理事件
	_process_event(event, priority)

func _get_event_priority(event: InputEvent) -> int:
	if event.is_action_pressed("ui_cancel"):  # ESC键
		return Priority.SYSTEM
	elif event is InputEventMouseButton:
		return Priority.UI
	elif event.is_action("ui_debug"):  # F12键
		return Priority.DEBUG
	else:
		return Priority.GAMEPLAY

func _should_filter_event(event: InputEvent, priority: int) -> bool:
	match priority:
		Priority.SYSTEM:
			return not filter_settings.system_events
		Priority.UI:
			return not filter_settings.ui_events
		Priority.GAMEPLAY:
			return not filter_settings.gameplay_events
		Priority.DEBUG:
			return not filter_settings.debug_events
	return false

func _process_event(event: InputEvent, priority: int) -> void:
	# 记录事件
	_log_event(event, priority)
	
	# 根据优先级处理事件
	match priority:
		Priority.SYSTEM:
			_handle_system_event(event)
		Priority.UI:
			_handle_ui_event(event)
		Priority.GAMEPLAY:
			_handle_gameplay_event(event)
		Priority.DEBUG:
			_handle_debug_event(event)

func _handle_system_event(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_log_message("系统事件：ESC键被按下")

func _handle_ui_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pos = event.position
		_log_message("UI事件：鼠标点击在 (%d, %d)" % [pos.x, pos.y])

func _handle_gameplay_event(event: InputEvent) -> void:
	if event.is_action_type():
		_log_message("游戏事件：" + event.as_text())

func _handle_debug_event(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug"):
		_log_message("调试事件：F12键被按下")

func _log_event(event: InputEvent, priority: int) -> void:
	var priority_text = ["系统", "UI", "游戏", "调试"][priority]
	var time = Time.get_ticks_msec() / 1000.0
	var log_text = "[%.2f] [%s] %s\n" % [time, priority_text, event.as_text()]
	event_log.text = log_text + event_log.text
	
	# 限制日志长度
	if event_log.text.length() > 500:
		event_log.text = event_log.text.substr(0, 500)

func _log_message(message: String) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	var log_text = "[%.2f] %s\n" % [time, message]
	event_log.text = log_text + event_log.text

func _update_priority_display() -> void:
	var display_text = "事件优先级：\n"
	display_text += "0 - 系统事件：%s\n" % ["启用" if filter_settings.system_events else "禁用"]
	display_text += "1 - UI事件：%s\n" % ["启用" if filter_settings.ui_events else "禁用"]
	display_text += "2 - 游戏事件：%s\n" % ["启用" if filter_settings.gameplay_events else "禁用"]
	display_text += "3 - 调试事件：%s\n" % ["启用" if filter_settings.debug_events else "禁用"]
	priority_display.text = display_text

func _on_clear_log_pressed() -> void:
	event_log.text = ""

func _on_system_events_toggled(button_pressed: bool) -> void:
	filter_settings.system_events = button_pressed
	_update_priority_display()

func _on_ui_events_toggled(button_pressed: bool) -> void:
	filter_settings.ui_events = button_pressed
	_update_priority_display()

func _on_gameplay_events_toggled(button_pressed: bool) -> void:
	filter_settings.gameplay_events = button_pressed
	_update_priority_display()

func _on_debug_events_toggled(button_pressed: bool) -> void:
	filter_settings.debug_events = button_pressed
	_update_priority_display()
