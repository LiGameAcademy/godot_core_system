# 日志系统

日志系统通过结构化日志提供了一种灵活而强大的方式来跟踪和调试游戏行为。

## 特性

- 📝 **日志级别**：不同严重程度的消息
- 📊 **多个通道**：输出到控制台、文件和自定义通道
- 🔍 **过滤**：按级别和类别过滤日志
- 📱 **项目设置**：通过 Godot 的项目设置进行配置
- 🔄 **日志轮转**：自动日志文件管理
- 🎯 **上下文跟踪**：为日志消息添加上下文

## 核心组件

### Logger（日志记录器）

中央日志设施：

- 日志级别管理
- 通道配置
- 消息格式化

```gdscript
# 通过项目设置配置
core_system/logger/log_level = "info"
core_system/logger/file_logging = true
core_system/logger/log_directory = "user://logs"
core_system/logger/max_log_files = 5

# 使用示例
func _ready() -> void:
    var logger = CoreSystem.logger

    # 记录日志
    logger.debug("正在初始化游戏...")
    logger.info("游戏已启动")
    logger.warning("内存不足警告")
    logger.error("加载资源失败")
```

## 使用示例

### 基本日志记录

```gdscript
# 不同日志级别
func example_logging() -> void:
    var logger = CoreSystem.logger

    logger.debug("调试消息")     # 用于调试的详细信息
    logger.info("信息消息")      # 一般信息
    logger.warning("警告消息")   # 不会停止执行的警告
    logger.error("错误消息")     # 影响功能的错误
    logger.fatal("致命消息")     # 导致停止执行的严重错误
```

### 上下文日志记录

```gdscript
# 为日志添加上下文
func player_action() -> void:
    var logger = CoreSystem.logger

    logger.with_context({
        "player_id": "player_1",
        "position": Vector2(100, 100),
        "health": 100
    }).info("玩家执行动作")

    # 带类别的日志
    logger.category("combat").info("玩家攻击敌人")
```

### 日志配置

```gdscript
# 配置日志记录器
func setup_logger() -> void:
    var logger = CoreSystem.logger

    # 设置日志级别
    logger.set_level(Logger.LEVEL.DEBUG)

    # 添加自定义通道
    logger.add_channel("analytics", func(message):
        send_to_analytics_service(message)
    )

    # 配置文件日志
    logger.configure_file_logging("user://logs", 5)
```

## 最佳实践

1. **日志组织**

   - 使用适当的日志级别
   - 添加相关上下文
   - 使用类别进行过滤

2. **性能**

   - 在生产环境中避免过多的调试日志
   - 对复杂的日志消息使用延迟求值
   - 配置适当的日志轮转

3. **调试信息**
   - 为错误包含堆栈跟踪
   - 记录状态变化
   - 为消息添加时间戳

## API 参考

### Logger（日志记录器）（中文名称：日志记录器 Logger）

- `debug(message: String) -> void`: 记录调试消息
- `info(message: String) -> void`: 记录信息消息
- `warning(message: String) -> void`: 记录警告消息
- `error(message: String) -> void`: 记录错误消息
- `fatal(message: String) -> void`: 记录致命消息
- `with_context(context: Dictionary) -> Logger`: 为下一条日志添加上下文
- `category(name: String) -> Logger`: 为下一条日志设置类别
- `set_level(level: int) -> void`: 设置最小日志级别
- `add_channel(name: String, callback: Callable) -> void`: 添加自定义日志通道
- `remove_channel(name: String) -> void`: 移除日志通道
- `configure_file_logging(directory: String, max_files: int) -> void`: 配置文件日志
- `flush() -> void`: 刷新日志缓冲区

### 日志级别

```gdscript
enum LEVEL {
    DEBUG = 0,  # 调试
    INFO = 1,   # 信息
    WARNING = 2, # 警告
    ERROR = 3,   # 错误
    FATAL = 4    # 致命
}
```
