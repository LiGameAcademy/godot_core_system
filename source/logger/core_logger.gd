extends Node

## Standalone engine logger with optional project colors and explicit file ownership.
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	FATAL = 4,
}

## Optional project colors have local defaults; no plugin setting script is required.
var default_log_colors: Dictionary = {
	LogLevel.DEBUG: ProjectSettings.get_setting("godot_core_system/logger/color_debug", Color.GRAY),
	LogLevel.INFO: ProjectSettings.get_setting("godot_core_system/logger/color_info", Color.WHITE),
	LogLevel.WARNING: ProjectSettings.get_setting("godot_core_system/logger/color_warning", Color.YELLOW),
	LogLevel.ERROR: ProjectSettings.get_setting("godot_core_system/logger/color_error", Color.RED),
	LogLevel.FATAL: ProjectSettings.get_setting("godot_core_system/logger/color_fatal", Color.DARK_RED),
}
var last_file_error: Error = OK

var _current_level: LogLevel = LogLevel.DEBUG
var _enable_file_logging: bool = false
var _log_file_path: String = "user://logs/game.log"
var _log_file: FileAccess = null
var _log_colors: Dictionary = default_log_colors.duplicate()

func _init() -> void:
	_setup_file_logging()

func set_level(level: LogLevel) -> void:
	_current_level = level

func set_color(level: LogLevel, color: Color) -> void:
	_log_colors[level] = color

func set_colors(colors: Dictionary) -> void:
	for level: Variant in colors:
		if level is LogLevel and colors[level] is Color:
			_log_colors[level] = colors[level]

func reset_colors() -> void:
	_log_colors = default_log_colors.duplicate()

func get_colors() -> Dictionary:
	return _log_colors.duplicate()

func enable_file_logging(enable: bool) -> void:
	_enable_file_logging = enable
	_setup_file_logging()

func debug(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, context)

func info(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, context)

func warning(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.WARNING, message, context)
	push_warning(message)

func error(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.ERROR, message, context)
	print_stack()
	push_error(message)

func fatal(message: String, context: Dictionary = {}) -> void:
	_log(LogLevel.FATAL, message, context)
	print_stack()
	push_error(message)

func _log(level: LogLevel, message: String, context: Dictionary) -> void:
	if level < _current_level:
		return

	var timestamp: String = Time.get_datetime_string_from_system()
	var level_name: String = LogLevel.keys()[level]
	var formatted_message: String = "[%s] [%s] %s" % [timestamp, level_name, message]

	if not context.is_empty():
		formatted_message += " | Context: " + str(context)

	if level in _log_colors:
		var color: Color = _log_colors[level]
		print_rich("[color=%s]%s[/color]" % [color.to_html(), formatted_message])
	else:
		print(formatted_message)

	if _enable_file_logging and _log_file:
		_log_file.store_line(formatted_message)

func print_stack() -> void:
	var stack: Array = get_stack()
	var stack_message: String = "\nCall Stack:"
	for frame: Dictionary in stack:
		stack_message += "\n  at %s:%d - %s()" % [frame["source"], frame["line"], frame["function"]]
	print_rich("[color=%s]%s[/color]" % [_log_colors[LogLevel.ERROR].to_html(), stack_message])

func _setup_file_logging() -> void:
	close_file()
	if not _enable_file_logging:
		return
	last_file_error = DirAccess.make_dir_recursive_absolute(_log_file_path.get_base_dir())
	if last_file_error == OK:
		_log_file = FileAccess.open(_log_file_path, FileAccess.WRITE)
		last_file_error = FileAccess.get_open_error()
	if last_file_error != OK:
		push_error("Log file open failed (%s): %s" % [error_string(last_file_error), _log_file_path])

## One writer owns a path. Changing the path closes the previous handle.
func set_file_path(path: String) -> Error:
	_log_file_path = path
	_setup_file_logging()
	return last_file_error

func close_file() -> void:
	if _log_file != null:
		_log_file.close()
		_log_file = null

func _exit_tree() -> void:
	close_file()
