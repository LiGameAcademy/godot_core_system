# Logger System

The Logger System provides a flexible and powerful way to track and debug your game's behavior through structured logging.

## Features

- 📝 **Log Levels**: Different severity levels for messages
- 📊 **Multiple Channels**: Output to console, file, and custom channels
- 🔍 **Filtering**: Filter logs by level and category
- 📱 **Project Settings**: Configure through Godot's project settings
- 🔄 **Log Rotation**: Automatic log file management
- 🎯 **Context Tracking**: Add context to log messages

## Core Components

### Logger

Central logging facility:
- Log level management
- Channel configuration
- Message formatting

```gdscript
# Configure through project settings
core_system/logger/log_level = "info"
core_system/logger/file_logging = true
core_system/logger/log_directory = "user://logs"
core_system/logger/max_log_files = 5

# Usage example
func _ready() -> void:
    var logger = CoreSystem.logger
    
    # Log messages
    logger.debug("Initializing game...")
    logger.info("Game started")
    logger.warning("Low memory warning")
    logger.error("Failed to load resource")
```

## Usage Examples

### Basic Logging

```gdscript
# Different log levels
func example_logging() -> void:
    var logger = CoreSystem.logger
    
    logger.debug("Debug message")     # Detailed information for debugging
    logger.info("Info message")       # General information
    logger.warning("Warning message") # Warnings that don't stop execution
    logger.error("Error message")     # Errors that affect functionality
    logger.fatal("Fatal message")     # Critical errors that stop execution
```

### Contextual Logging

```gdscript
# Add context to logs
func player_action() -> void:
    var logger = CoreSystem.logger
    
    logger.with_context({
        "player_id": "player_1",
        "position": Vector2(100, 100),
        "health": 100
    }).info("Player performed action")
    
    # Log with category
    logger.category("combat").info("Player attacked enemy")
```

### Log Configuration

```gdscript
# Configure logger
func setup_logger() -> void:
    var logger = CoreSystem.logger
    
    # Set log level
    logger.set_level(Logger.LEVEL.DEBUG)
    
    # Add custom channel
    logger.add_channel("analytics", func(message):
        send_to_analytics_service(message)
    )
    
    # Configure file logging
    logger.configure_file_logging("user://logs", 5)
```

## Best Practices

1. **Log Organization**
   - Use appropriate log levels
   - Add relevant context
   - Use categories for filtering

2. **Performance**
   - Avoid excessive debug logging in production
   - Use lazy evaluation for complex log messages
   - Configure appropriate log rotation

3. **Debug Information**
   - Include stack traces for errors
   - Log state changes
   - Add timestamps to messages

## API Reference

### Logger
- `debug(message: String) -> void`: Log debug message
- `info(message: String) -> void`: Log info message
- `warning(message: String) -> void`: Log warning message
- `error(message: String) -> void`: Log error message
- `fatal(message: String) -> void`: Log fatal message
- `with_context(context: Dictionary) -> Logger`: Add context to next log
- `category(name: String) -> Logger`: Set category for next log
- `set_level(level: int) -> void`: Set minimum log level
- `add_channel(name: String, callback: Callable) -> void`: Add custom log channel
- `remove_channel(name: String) -> void`: Remove log channel
- `configure_file_logging(directory: String, max_files: int) -> void`: Configure file logging
- `flush() -> void`: Flush log buffers

### Log Levels
```gdscript
enum LEVEL {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    FATAL = 4
}
```
