# Asynchronous I/O Manager (`AsyncIOManager`)

The `AsyncIOManager` provides a robust and flexible solution for performing non-blocking file input/output operations within your Godot project. It leverages a dedicated background thread and a strategy pattern to handle serialization, compression, and encryption, allowing file access without impacting main thread performance.

## Features

- 🔄 **Non-Blocking I/O**: Executes file reads, writes, deletes, and listing operations in a separate thread.
- 🧩 **Strategy Pattern**: Decouples core I/O logic from data processing:
    - **Serialization**: Defines how data is converted to/from bytes (e.g., JSON, custom binary).
    - **Compression**: Defines optional data compression (e.g., Gzip, none).
    - **Encryption**: Defines optional data encryption (e.g., XOR, none).
- 🧵 **Single Dedicated Thread**: Efficiently manages I/O tasks sequentially in one background thread.
- ✨ **Signal-Based Completion**: Uses Godot's signal system (`io_completed`) to notify when tasks are finished.
- 🆔 **Task Tracking**: Returns a unique string Task ID for each asynchronous operation.
- 🛡️ **Error Handling**: Reports success or failure via the `io_completed` signal. Logs detailed errors internally using `CoreSystem.logger`.

## Core Concept: Strategies

The power of `AsyncIOManager` lies in its use of Strategies. You can configure or replace these strategies to customize how data is processed during reads and writes.

-   **Serialization Strategy**: Handles converting your Godot `Variant` data (like Dictionaries, Arrays, etc.) into `PackedByteArray` for writing, and vice-versa for reading.
    -   Default: `JSONSerializationStrategy`
-   **Compression Strategy**: Optionally compresses the byte array after serialization and decompresses before deserialization.
    -   Default: `NoCompressionStrategy` (No compression)
    -   Available: `GzipCompressionStrategy`
-   **Encryption Strategy**: Optionally encrypts the byte array (after compression) and decrypts (before decompression). Requires an encryption key.
    -   Default: `NoEncryptionStrategy` (No encryption)
    -   Available: `XOREncryptionStrategy`

Strategies are applied in this order for writing: `Serialize -> Compress -> Encrypt`
And in reverse order for reading: `Decrypt -> Decompress -> Deserialize`

## Getting Started / Basic Usage

1.  **Instantiate `AsyncIOManager`**: You typically don't access this directly but through specific format strategies (like `JsonSaveStrategy`, `BinarySaveStrategy`) which instantiate and configure `AsyncIOManager` internally. If used directly, you can provide strategies:

    ```gdscript
    # Example: Using JSON, Gzip, and XOR encryption
    var io_manager = CoreSystem.AsyncIOManager.new(
        CoreSystem.AsyncIOManager.JSONSerializationStrategy.new(),
        CoreSystem.AsyncIOManager.GzipCompressionStrategy.new(),
        CoreSystem.AsyncIOManager.XOREncryptionStrategy.new()
    )
    ```

2.  **Call an Async Method**: Initiate an operation like `read_file_async`.

    ```gdscript
    var my_data = {"player_name": "Hero", "score": 100}
    var encryption_key = "your-secret-key"
    var task_id = io_manager.write_file_async("user://savegame.dat", my_data, encryption_key)
    print("Write task started with ID: ", task_id)
    ```

3.  **Await Completion Signal**: Use `await` on the `io_completed` signal to get the result.

    ```gdscript
    # Wait for the specific task to complete
    var result = await io_manager.io_completed # Note: This waits for ANY task.
    # Ideally, you'd store the task_id and check it in the result:
    # var result_task_id = result[0]
    # var success = result[1]
    # var data = result[2]
    # if result_task_id == task_id:
    #     if success:
    #         print("Write operation successful!")
    #     else:
    #         print("Write operation failed.")

    # A more robust way to wait for a specific task ID
    var task_id_to_wait_for = io_manager.write_file_async(...)
    while true:
        var result = await io_manager.io_completed
        if result[0] == task_id_to_wait_for: # Check if it's our task
            var success = result[1]
            var data = result[2]
            if success:
                 print("Write successful!")
            else:
                 print("Write failed.")
            break # Exit the loop
    ```

## File Operations

All operations are asynchronous and return a unique string `task_id`. Completion is signaled via `io_completed`.

### Reading Files (`read_file_async`)

Reads a file, applies Decryption -> Decompression -> Deserialization strategies, and returns the resulting `Variant`.

```gdscript
var read_task_id = io_manager.read_file_async("user://savegame.dat", "your-secret-key")
# ... await io_completed and check task_id ...
# result[2] will contain the deserialized data (e.g., a Dictionary) if successful
```

### Writing Files (`write_file_async`)

Applies Serialization -> Compression -> Encryption strategies to the input `data` (`Variant`) and writes the resulting bytes to a file.

```gdscript
var player_stats = {"level": 5, "hp": 85}
var write_task_id = io_manager.write_file_async("user://stats.json", player_stats) # No encryption
# ... await io_completed and check task_id ...
# result[1] (success) indicates if writing was successful. result[2] is typically null for writes.
```

### Deleting Files (`delete_file_async`)

Deletes a file asynchronously.

```gdscript
var delete_task_id = io_manager.delete_file_async("user://old_log.txt")
# ... await io_completed and check task_id ...
# result[1] indicates success.
```

### Listing Files (`list_files_async`)

Lists all *files* (not directories) within a specified directory asynchronously. Strategies are not applied here.

```gdscript
var list_task_id = io_manager.list_files_async("user://saves/")
# ... await io_completed and check task_id ...
# result[2] will be an Array of filenames (Strings) if successful.
```

## Strategies In-Depth

You can change the default strategies after initialization:

```gdscript
var io_manager = CoreSystem.AsyncIOManager.new() # Starts with defaults

# Change to Gzip compression
io_manager.set_compression_strategy(CoreSystem.AsyncIOManager.GzipCompressionStrategy.new())

# Change to XOR encryption
io_manager.set_encryption_strategy(CoreSystem.AsyncIOManager.XOREncryptionStrategy.new())

# You can also create and set custom strategies inheriting from the base strategy classes
# class CustomSerializer extends CoreSystem.AsyncIOManager.SerializationStrategy:
#     # ... implement serialize() and deserialize() ...
# io_manager.set_serialization_strategy(CustomSerializer.new())
```

## Error Handling

-   Operation success/failure is indicated by the `success: bool` parameter in the `io_completed` signal.
-   Detailed error messages (e.g., file not found, permission denied, decompression failed) are logged internally using `CoreSystem.logger`. Check the Godot output/logs for specifics when an operation fails.

## API Reference

### Signals

-   `io_completed(task_id: String, success: bool, result: Variant)`
    -   Emitted when any asynchronous I/O task finishes.
    -   `task_id`: The unique string ID returned when the task was started.
    -   `success`: `true` if the operation completed successfully, `false` otherwise.
    -   `result`: The data returned by the operation (e.g., deserialized data for reads, file list for listing) or potentially error information if `success` is `false`. Often `null` for write/delete operations upon success.

### Methods

-   `_init(p_serializer: SerializationStrategy = null, p_compressor: CompressionStrategy = null, p_encryptor: EncryptionStrategy = null)`
    -   Constructor. Allows injecting specific strategies on creation. Defaults to `JSONSerializationStrategy`, `NoCompressionStrategy`, `NoEncryptionStrategy`.
-   `set_serialization_strategy(strategy: SerializationStrategy) -> void`
    -   Sets the serialization strategy instance to use.
-   `set_compression_strategy(strategy: CompressionStrategy) -> void`
    -   Sets the compression strategy instance to use.
-   `set_encryption_strategy(strategy: EncryptionStrategy) -> void`
    -   Sets the encryption strategy instance to use.
-   `read_file_async(path: String, encryption_key: String = "") -> String`
    -   Starts an asynchronous read operation.
    -   Returns a unique task ID string.
-   `write_file_async(path: String, data: Variant, encryption_key: String = "") -> String`
    -   Starts an asynchronous write operation.
    -   Returns a unique task ID string.
-   `delete_file_async(path: String) -> String`
    -   Starts an asynchronous delete operation.
    -   Returns a unique task ID string.
-   `list_files_async(path: String) -> String`
    -   Starts an asynchronous directory listing operation (files only).
    -   Returns a unique task ID string.

## Performance Considerations

-   Uses a single dedicated thread to avoid excessive context switching and manage disk access sequentially.
-   Operations are queued and processed one after another by the thread.
-   For very large files, consider if reading/writing the entire file at once is necessary or if streaming/chunking would be more appropriate (though this manager doesn't directly support streaming).
-   Compression and encryption add computational overhead. Choose strategies based on your needs for security and file size vs. performance. 