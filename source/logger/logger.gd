extends Node

## 日志工具（与引擎内置 Logger 区分）

## 日志级别枚举
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	FATAL = 4
}

## 日志颜色配置
const LOG_COLORS = {
	LogLevel.DEBUG: Color.DARK_GRAY,
	LogLevel.INFO: Color.WHITE,
	LogLevel.WARNING: Color.YELLOW,
	LogLevel.ERROR: Color.RED,
	LogLevel.FATAL: Color.DARK_RED
}

## 当前日志级别
var _current_level: LogLevel = LogLevel.DEBUG
## 是否启用文件日志
var _enable_file_logging: bool = false
## 日志文件路径
var _log_file_path: String = "user://logs/game.log"
## 日志文件对象
var _log_file: FileAccess = null

func _init(data: Dictionary = {}) -> void:
	_setup_file_logging()

## 设置日志级别
## [param level] 日志级别
func set_level(level: LogLevel) -> void:
	_current_level = level

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

## 记录错误日志
## [param message] 消息
## [param context] 上下文
func error(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.ERROR, message, context)
	print_stack()

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
	print(stack_message)

## 设置文件日志
func _setup_file_logging() -> void:
	if not _enable_file_logging:
		return
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
	
	_log_file = FileAccess.open(_log_file_path, FileAccess.WRITE)
