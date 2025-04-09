# Async I/O System

The Async I/O System provides a robust solution for non-blocking file operations in your Godot game, allowing you to read and write files without impacting gameplay performance.

## Features

- 🔄 **Non-Blocking I/O**: Perform file operations without freezing the main thread
- 🧵 **Single-Thread Design**: Efficient single-thread architecture for optimal performance
- 🔐 **Built-in Security**: Optional compression and encryption for sensitive data
- 💼 **Progress Tracking**: Monitor ongoing operations with callback support
- 🛡️ **Error Handling**: Robust error reporting and recovery mechanisms
- 🔌 **Simple API**: Easy-to-use interface for common file operations

## Core Functionality

### AsyncIOManager

The main component that handles asynchronous file operations:

- Manages a dedicated IO thread
- Provides methods for reading and writing files asynchronously
- Supports optional compression and encryption
- Emits signals for operation completion and errors

```gdscript
# Usage example
func _ready() -> void:
    # Access through CoreSystem
    var task_id = CoreSystem.async_io_manager.read_file_async(
        "user://save.dat",                  # File path
        false,                              # Use compression
        "",                                 # Encryption key (empty for none)
        func(success, data):                # Callback
            if success:
                print("File loaded: ", data)
            else:
                print("Failed to load file")
    )
```

## File Operations

### Reading Files

Read files asynchronously with optional processing:

```gdscript
# Basic async read
var task_id = CoreSystem.async_io_manager.read_file_async(
    "user://config.json",
    func(success, data):
        if success:
            var json = JSON.parse_string(data)
            apply_config(json)
)

# Read with compression and encryption
var task_id = CoreSystem.async_io_manager.read_file_async(
    "user://player_data.sav",
    true,                              # Use compression
    "my_secret_key",                   # Encryption key
    func(success, data):
        if success:
            var player_data = JSON.parse_string(data)
            load_player(player_data)
)
```

### Writing Files

Write data asynchronously with optional security features:

```gdscript
# Basic async write
var data = JSON.stringify(game_state)
var task_id = CoreSystem.async_io_manager.write_file_async(
    "user://save.json",
    data,
    func(success, _result):
        if success:
            print("Game saved successfully!")
)

# Write with compression and encryption
var sensitive_data = JSON.stringify(player_credentials)
var task_id = CoreSystem.async_io_manager.write_file_async(
    "user://credentials.dat",
    sensitive_data,
    true,                              # Use compression
    "secure_encryption_key",           # Encryption key
    func(success, _result):
        if success:
            print("Credentials saved securely")
)
```

### Directory Operations

Perform directory-related operations asynchronously:

```gdscript
# Delete a file asynchronously
var task_id = CoreSystem.async_io_manager.delete_file_async(
    "user://temp.dat",
    func(success, _result):
        if success:
            print("Temporary file deleted")
)
```

## Error Handling

Handle IO errors through signal connections:

```gdscript
func _ready() -> void:
    # Connect to error signal
    CoreSystem.async_io_manager.io_error.connect(_on_io_error)

func _on_io_error(task_id: String, error: String) -> void:
    push_error("IO operation failed - Task ID: %s, Error: %s" % [task_id, error])
    # Implement recovery strategies here
```

## Custom Encryption

The system supports custom encryption providers:

```gdscript
# Create a custom encryption provider
class MyEncryptionProvider extends EncryptionProvider:
    func encrypt(data: PackedByteArray, key: String) -> PackedByteArray:
        # Implement custom encryption
        return data
        
    func decrypt(data: PackedByteArray, key: String) -> PackedByteArray:
        # Implement custom decryption
        return data

# Set the custom provider
CoreSystem.async_io_manager.encryption_provider = MyEncryptionProvider.new()
```

## Performance Considerations

- The system uses a single dedicated thread for IO operations to avoid overloading the system
- Operations are queued and processed sequentially to prevent disk thrashing
- For large data sets, consider splitting data into smaller chunks
- Always handle errors properly to prevent data corruption

## API Reference

### Signals

- `io_completed(task_id: String, success: bool, result: Variant)`: Emitted when an IO operation completes
- `io_error(task_id: String, error: String)`: Emitted when an IO operation encounters an error

### Methods

- `read_file_async(path: String, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String`: Read a file asynchronously
- `write_file_async(path: String, data: Variant, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String`: Write to a file asynchronously
- `delete_file_async(path: String, callback: Callable = func(_s, _r): pass) -> String`: Delete a file asynchronously
- `encrypt_data(data: PackedByteArray, encryption_key: String) -> PackedByteArray`: Encrypt data using the current provider
- `decrypt_data(data: PackedByteArray, encryption_key: String) -> PackedByteArray`: Decrypt data using the current provider
- `compress_data(data: PackedByteArray) -> PackedByteArray`: Compress data
- `decompress_data(data: PackedByteArray) -> PackedByteArray`: Decompress data
