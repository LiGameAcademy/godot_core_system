extends Node

## 日志工具

## 日志级别枚举
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	FATAL = 4,
}

## 默认日志颜色配置
const SETTING_SCRIPT: Script = preload("res://addons/godot_core_system/setting.gd")

var default_log_colors: Dictionary = {
	LogLevel.DEBUG:
		SETTING_SCRIPT.get_setting_value("logger/color_debug"),
	LogLevel.INFO:
		SETTING_SCRIPT.get_setting_value("logger/color_info"),
	LogLevel.WARNING:
		SETTING_SCRIPT.get_setting_value("logger/color_warning"),
	LogLevel.ERROR:
		SETTING_SCRIPT.get_setting_value("logger/color_error"),
	LogLevel.FATAL:
		SETTING_SCRIPT.get_setting_value("logger/color_fatal"),
}

## 当前日志级别
var _current_level: LogLevel = LogLevel.DEBUG
## 是否启用文件日志
var _enable_file_logging: bool = false
## 日志文件路径
var _log_file_path: String = "user://logs/game.log"
## 日志文件对象
var _log_file: FileAccess = null
## 当前日志颜色配置
var _log_colors: Dictionary = default_log_colors.duplicate()

func _init() -> void:
	_setup_file_logging()

## 设置日志级别
## [param level] 日志级别
func set_level(level: LogLevel) -> void:
	_current_level = level

## 设置指定级别的日志颜色
## [param level] 日志级别
## [param color] 颜色
func set_color(level: LogLevel, color: Color) -> void:
	_log_colors[level] = color

## 设置多个日志级别的颜色
## [param colors] 颜色配置字典
func set_colors(colors: Dictionary) -> void:
	for level in colors:
		if level is LogLevel and colors[level] is Color:
			_log_colors[level] = colors[level]

## 重置所有日志颜色为默认值
func reset_colors() -> void:
	_log_colors = default_log_colors.duplicate()

## 获取当前日志颜色配置
func get_colors() -> Dictionary:
	return _log_colors.duplicate()

## 设置是否启用文件日志
## [param enable] 是否启用
func enable_file_logging(enable: bool) -> void:
	_enable_file_logging = enable
	if enable:
		_setup_file_logging()

## 记录调试日志
## [param message] 消息
## [param context] 上下文
func debug(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, context)

## 记录信息日志
## [param message] 消息
## [param context] 上下文
func info(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, context)

## 记录警告日志
## [param message] 消息
## [param context] 上下文
func warning(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.WARNING, message, context)
	push_warning(message)

## 记录错误日志
## [param message] 消息
## [param context] 上下文
func error(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.ERROR, message, context)
	print_stack()
	push_error(message)

## 记录致命错误日志
## [param message] 消息
## [param context] 上下文
func fatal(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.FATAL, message, context)
	print_stack()
	push_error(message)

## 内部日志记录方法
## [param level] 日志级别
## [param message] 消息
## [param context] 上下文
func _log(level: LogLevel, message: String, context: Dictionary) -> void:
	if level < _current_level:
		return

	var timestamp = Time.get_datetime_string_from_system()
	var level_name = LogLevel.keys()[level]
	var formatted_message = "[%s] [%s] %s" % [timestamp, level_name, message]

	if not context.is_empty():
		formatted_message += " | Context: " + str(context)

	# 控制台输出（带颜色）
	if level in _log_colors:
		var color = _log_colors[level]
		print_rich("[color=%s]%s[/color]" % [color.to_html(), formatted_message])
	else:
		print(formatted_message)

	# 文件日志
	if _enable_file_logging and _log_file:
		_log_file.store_line(formatted_message)

## 获取调用堆栈
func print_stack() -> void:
	var stack = get_stack()
	var stack_message = "\nCall Stack:"
	for frame in stack:
		stack_message += "\n  at %s:%d - %s()" % [frame["source"], frame["line"], frame["function"]]
	print_rich("[color=%s]%s[/color]" % [_log_colors[LogLevel.ERROR].to_html(), stack_message])

## 设置文件日志
func _setup_file_logging() -> void:
	if not _enable_file_logging:
		return

	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")

	_log_file = FileAccess.open(_log_file_path, FileAccess.WRITE)
