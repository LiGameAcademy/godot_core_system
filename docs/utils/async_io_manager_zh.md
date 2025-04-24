# 异步 I/O 管理器 (`AsyncIOManager`)

`AsyncIOManager` 为您的 Godot 项目提供了一个健壮且灵活的解决方案，用于执行非阻塞的文件输入/输出操作。它利用一个专用的后台线程和一个策略模式来处理序列化、压缩和加密，允许在不影响主线程性能的情况下访问文件。

## 功能特性

- 🔄 **非阻塞 I/O**: 在单独的线程中执行文件读取、写入、删除和列出操作。
- 🧩 **策略模式**: 将核心 I/O 逻辑与数据处理解耦：
    - **序列化 (Serialization)**: 定义数据如何与字节相互转换（例如，JSON、自定义二进制）。
    - **压缩 (Compression)**: 定义可选的数据压缩（例如，Gzip、无压缩）。
    - **加密 (Encryption)**: 定义可选的数据加密（例如，XOR、无加密）。
- 🧵 **单个专用线程**: 在一个后台线程中高效地顺序管理 I/O 任务。
- ✨ **基于信号的完成通知**: 使用 Godot 的信号系统 (`io_completed`) 来通知任务完成。
- 🆔 **任务跟踪**: 为每个异步操作返回一个唯一的字符串任务 ID。
- 🛡️ **错误处理**: 通过 `io_completed` 信号报告成功或失败。使用 `CoreSystem.logger` 在内部记录详细错误。

## 核心概念：策略 (Strategies)

`AsyncIOManager` 的强大之处在于其策略的使用。您可以配置或替换这些策略来自定义在读取和写入期间如何处理数据。

-   **序列化策略 (Serialization Strategy)**: 处理将您的 Godot `Variant` 数据（如字典、数组等）转换为 `PackedByteArray` 以便写入，以及在读取时反向转换。
    -   默认: `JSONSerializationStrategy`
-   **压缩策略 (Compression Strategy)**: 可选地在序列化后压缩字节数组，并在反序列化前解压缩。
    -   默认: `NoCompressionStrategy` (无压缩)
    -   可用: `GzipCompressionStrategy`
-   **加密策略 (Encryption Strategy)**: 可选地加密字节数组（压缩后），并在解压缩前解密。需要一个加密密钥。
    -   默认: `NoEncryptionStrategy` (无加密)
    -   可用: `XOREncryptionStrategy`

策略在写入时按此顺序应用：`序列化 -> 压缩 -> 加密`
在读取时按相反顺序应用：`解密 -> 解压缩 -> 反序列化`

## 入门 / 基本用法

1.  **实例化 `AsyncIOManager`**: 通常您不直接访问它，而是通过特定的格式策略（如 `JsonSaveStrategy`, `BinarySaveStrategy`）访问，这些策略会在内部实例化并配置 `AsyncIOManager`。如果直接使用，您可以提供策略：

    ```gdscript
    # 示例：使用 JSON、Gzip 和 XOR 加密
    var io_manager = CoreSystem.AsyncIOManager.new(
        CoreSystem.AsyncIOManager.JSONSerializationStrategy.new(),
        CoreSystem.AsyncIOManager.GzipCompressionStrategy.new(),
        CoreSystem.AsyncIOManager.XOREncryptionStrategy.new()
    )
    ```

2.  **调用异步方法**: 启动一个操作，如 `read_file_async`。

    ```gdscript
    var my_data = {"player_name": "Hero", "score": 100}
    var encryption_key = "your-secret-key" # 您的密钥
    var task_id = io_manager.write_file_async("user://savegame.dat", my_data, encryption_key)
    print("写入任务已启动，ID: ", task_id)
    ```

3.  **等待完成信号**: 使用 `await` 等待 `io_completed` 信号以获取结果。

    ```gdscript
    # 等待特定的任务完成
    var result = await io_manager.io_completed # 注意：这将等待 *任何* 任务完成。
    # 理想情况下，您应该存储 task_id 并在结果中检查它：
    # var result_task_id = result[0]
    # var success = result[1]
    # var data = result[2]
    # if result_task_id == task_id:
    #     if success:
    #         print("写入操作成功！")
    #     else:
    #         print("写入操作失败。")

    # 一个更健壮的等待特定任务 ID 的方法
    var task_id_to_wait_for = io_manager.write_file_async(...)
    while true:
        var result = await io_manager.io_completed
        if result[0] == task_id_to_wait_for: # 检查是否是我们的任务
            var success = result[1]
            var data = result[2]
            if success:
                 print("写入成功！")
            else:
                 print("写入失败。")
            break # 退出循环
    ```

## 文件操作

所有操作都是异步的，并返回一个唯一的字符串 `task_id`。完成通过 `io_completed` 信号通知。

### 读取文件 (`read_file_async`)

读取文件，应用 解密 -> 解压缩 -> 反序列化 策略，并返回结果 `Variant`。

```gdscript
var read_task_id = io_manager.read_file_async("user://savegame.dat", "your-secret-key")
# ... await io_completed 并检查 task_id ...
# 如果成功，result[2] 将包含反序列化后的数据（例如，一个字典）
```

### 写入文件 (`write_file_async`)

将 序列化 -> 压缩 -> 加密 策略应用于输入的 `data` (`Variant`)，并将结果字节写入文件。

```gdscript
var player_stats = {"level": 5, "hp": 85}
var write_task_id = io_manager.write_file_async("user://stats.json", player_stats) # 无加密
# ... await io_completed 并检查 task_id ...
# result[1] (success) 指示写入是否成功。对于写入操作，成功时 result[2] 通常为 null。
```

### 删除文件 (`delete_file_async`)

异步删除文件。

```gdscript
var delete_task_id = io_manager.delete_file_async("user://old_log.txt")
# ... await io_completed 并检查 task_id ...
# result[1] 指示是否成功。
```

### 列出文件 (`list_files_async`)

异步列出指定目录中的所有*文件*（不包括目录）。此操作不应用策略。

```gdscript
var list_task_id = io_manager.list_files_async("user://saves/")
# ... await io_completed 并检查 task_id ...
# 如果成功，result[2] 将是一个包含文件名（字符串）的数组。
```

## 策略详解

您可以在初始化后更改默认策略：

```gdscript
var io_manager = CoreSystem.AsyncIOManager.new() # 使用默认策略启动

# 更改为 Gzip 压缩
io_manager.set_compression_strategy(CoreSystem.AsyncIOManager.GzipCompressionStrategy.new())

# 更改为 XOR 加密
io_manager.set_encryption_strategy(CoreSystem.AsyncIOManager.XOREncryptionStrategy.new())

# 您也可以创建并设置继承自基础策略类的自定义策略
# class CustomSerializer extends CoreSystem.AsyncIOManager.SerializationStrategy:
#     # ... 实现 serialize() 和 deserialize() ...
# io_manager.set_serialization_strategy(CustomSerializer.new())
```

## 错误处理

-   操作的成功/失败由 `io_completed` 信号中的 `success: bool` 参数指示。
-   详细的错误消息（例如，文件未找到、权限被拒绝、解压缩失败）会使用 `CoreSystem.logger` 在内部记录。当操作失败时，请检查 Godot 的输出/日志以获取具体信息。

## API 参考

### 信号

-   `io_completed(task_id: String, success: bool, result: Variant)`
    -   当任何异步 I/O 任务完成时发出。
    -   `task_id`: 启动任务时返回的唯一字符串 ID。
    -   `success`: 如果操作成功完成则为 `true`，否则为 `false`。
    -   `result`: 操作返回的数据（例如，读取时的反序列化数据，列出文件时的文件列表）或在 `success` 为 `false` 时可能包含错误信息。对于写入/删除操作，成功时通常为 `null`。

### 方法

-   `_init(p_serializer: SerializationStrategy = null, p_compressor: CompressionStrategy = null, p_encryptor: EncryptionStrategy = null)`
    -   构造函数。允许在创建时注入特定的策略。默认为 `JSONSerializationStrategy`, `NoCompressionStrategy`, `NoEncryptionStrategy`。
-   `set_serialization_strategy(strategy: SerializationStrategy) -> void`
    -   设置要使用的序列化策略实例。
-   `set_compression_strategy(strategy: CompressionStrategy) -> void`
    -   设置要使用的压缩策略实例。
-   `set_encryption_strategy(strategy: EncryptionStrategy) -> void`
    -   设置要使用的加密策略实例。
-   `read_file_async(path: String, encryption_key: String = "") -> String`
    -   启动一个异步读取操作。
    -   返回一个唯一的任务 ID 字符串。
-   `write_file_async(path: String, data: Variant, encryption_key: String = "") -> String`
    -   启动一个异步写入操作。
    -   返回一个唯一的任务 ID 字符串。
-   `delete_file_async(path: String) -> String`
    -   启动一个异步删除操作。
    -   返回一个唯一的任务 ID 字符串。
-   `list_files_async(path: String) -> String`
    -   启动一个异步目录列出操作（仅文件）。
    -   返回一个唯一的任务 ID 字符串。

## 性能考量

-   使用单个专用线程以避免过多的上下文切换并按顺序管理磁盘访问。
-   操作被排队并由该线程逐一处理。
-   对于非常大的文件，请考虑一次性读取/写入整个文件是否必要，或者流式传输/分块是否更合适（尽管此管理器不直接支持流式传输）。
-   压缩和加密会增加计算开销。根据您对安全性、文件大小与性能的需求来选择策略。 