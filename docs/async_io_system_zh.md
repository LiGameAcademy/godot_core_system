# 异步IO系统

异步IO系统为您的Godot游戏提供了强大的非阻塞文件操作解决方案，让您能够读写文件而不影响游戏性能。

## 特性

- 🔄 **非阻塞IO**：执行文件操作而不会冻结主线程
- 🧵 **单线程设计**：高效的单线程架构以获得最佳性能
- 🔐 **内置安全性**：为敏感数据提供可选的压缩和加密
- 💼 **进度跟踪**：通过回调支持监控正在进行的操作
- 🛡️ **错误处理**：强大的错误报告和恢复机制
- 🔌 **简单API**：易于使用的常见文件操作接口

## 核心功能

### AsyncIOManager（异步IO管理器）

处理异步文件操作的主要组件：

- 管理专用的IO线程
- 提供异步读写文件的方法
- 支持可选的压缩和加密
- 发出操作完成和错误信号

```gdscript
# 使用示例
func _ready() -> void:
    # 通过CoreSystem访问
    var task_id = CoreSystem.async_io_manager.read_file_async(
        "user://save.dat",                  # 文件路径
        false,                              # 使用压缩
        "",                                 # 加密密钥(空表示不加密)
        func(success, data):                # 回调
            if success:
                print("文件已加载: ", data)
            else:
                print("加载文件失败")
    )
```

## 文件操作

### 读取文件

异步读取文件，可选择性处理：

```gdscript
# 基本异步读取
var task_id = CoreSystem.async_io_manager.read_file_async(
    "user://config.json",
    func(success, data):
        if success:
            var json = JSON.parse_string(data)
            apply_config(json)
)

# 带压缩和加密的读取
var task_id = CoreSystem.async_io_manager.read_file_async(
    "user://player_data.sav",
    true,                              # 使用压缩
    "my_secret_key",                   # 加密密钥
    func(success, data):
        if success:
            var player_data = JSON.parse_string(data)
            load_player(player_data)
)
```

### 写入文件

异步写入数据，可选安全功能：

```gdscript
# 基本异步写入
var data = JSON.stringify(game_state)
var task_id = CoreSystem.async_io_manager.write_file_async(
    "user://save.json",
    data,
    func(success, _result):
        if success:
            print("游戏成功保存！")
)

# 带压缩和加密的写入
var sensitive_data = JSON.stringify(player_credentials)
var task_id = CoreSystem.async_io_manager.write_file_async(
    "user://credentials.dat",
    sensitive_data,
    true,                              # 使用压缩
    "secure_encryption_key",           # 加密密钥
    func(success, _result):
        if success:
            print("凭证已安全保存")
)
```

### 目录操作

异步执行与目录相关的操作：

```gdscript
# 异步删除文件
var task_id = CoreSystem.async_io_manager.delete_file_async(
    "user://temp.dat",
    func(success, _result):
        if success:
            print("临时文件已删除")
)
```

## 错误处理

通过信号连接处理IO错误：

```gdscript
func _ready() -> void:
    # 连接到错误信号
    CoreSystem.async_io_manager.io_error.connect(_on_io_error)

func _on_io_error(task_id: String, error: String) -> void:
    push_error("IO操作失败 - 任务ID: %s, 错误: %s" % [task_id, error])
    # 在此实现恢复策略
```

## 自定义加密

系统支持自定义加密提供者：

```gdscript
# 创建自定义加密提供者
class MyEncryptionProvider extends EncryptionProvider:
    func encrypt(data: PackedByteArray, key: String) -> PackedByteArray:
        # 实现自定义加密
        return data
        
    func decrypt(data: PackedByteArray, key: String) -> PackedByteArray:
        # 实现自定义解密
        return data

# 设置自定义提供者
CoreSystem.async_io_manager.encryption_provider = MyEncryptionProvider.new()
```

## 性能考虑

- 系统使用单个专用线程进行IO操作，以避免系统过载
- 操作被队列化并按顺序处理，以防止磁盘抖动
- 对于大型数据集，考虑将数据拆分为更小的块
- 始终正确处理错误以防止数据损坏

## API参考

### 信号

- `io_completed(task_id: String, success: bool, result: Variant)`：当IO操作完成时发出
- `io_error(task_id: String, error: String)`：当IO操作遇到错误时发出

### 方法

- `read_file_async(path: String, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String`：异步读取文件
- `write_file_async(path: String, data: Variant, use_compression: bool = false, encryption_key: String = "", callback: Callable = func(_s, _r): pass) -> String`：异步写入文件
- `delete_file_async(path: String, callback: Callable = func(_s, _r): pass) -> String`：异步删除文件
- `encrypt_data(data: PackedByteArray, encryption_key: String) -> PackedByteArray`：使用当前提供者加密数据
- `decrypt_data(data: PackedByteArray, encryption_key: String) -> PackedByteArray`：使用当前提供者解密数据
- `compress_data(data: PackedByteArray) -> PackedByteArray`：压缩数据
- `decompress_data(data: PackedByteArray) -> PackedByteArray`：解压数据
