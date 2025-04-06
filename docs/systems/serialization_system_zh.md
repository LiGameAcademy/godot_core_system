# 序列化系统

序列化系统为您的 Godot 游戏提供了一个全面的解决方案，用于保存游戏状态、管理配置和处理 I/O 操作。

## 特性

- 💾 **存档系统**：易用的存档/读档功能，支持自动保存
- ⚙️ **配置系统**：灵活的配置管理，支持自动保存
- 🔄 **异步 I/O**：非阻塞 I/O 操作，提供更好的性能
- 🔐 **数据安全**：可选的压缩和加密功能
- 📱 **项目设置**：通过 Godot 的项目设置配置所有选项

## 核心组件

### SaveManager（存档管理器）

处理游戏状态持久化：
- 存档/读档游戏状态
- 自动保存功能
- 存档文件管理

```gdscript
# 通过项目设置配置
core_system/save_system/save_directory = "user://saves"
core_system/save_system/save_extension = "save"
core_system/save_system/auto_save_interval = 300
core_system/save_system/max_auto_saves = 3
core_system/save_system/auto_save_enabled = true

# 使用示例
func _ready() -> void:
    # 通过 CoreSystem 访问
    CoreSystem.save_manager.save("my_save")
    CoreSystem.save_manager.load("my_save")
    
    # 如果启用，自动保存会自动处理
```

### ConfigManager（配置管理器）

管理游戏配置：
- 加载/保存设置
- 基于分节的组织
- 自动保存支持

```gdscript
# 通过项目设置配置
core_system/config_system/config_path = "user://config.cfg"
core_system/config_system/auto_save = true

# 使用示例
func _ready() -> void:
    var config = CoreSystem.config_manager
    
    # 设置值
    config.set_value("audio", "volume", 0.8)
    config.set_value("graphics", "fullscreen", true)
    
    # 获取值
    var volume = config.get_value("audio", "volume", 1.0)  # 默认值：1.0
    var fullscreen = config.get_value("graphics", "fullscreen", false)
```

### SerializableComponent（可序列化组件）

需要保存的对象的基类：
- 属性的自动序列化
- 自定义序列化支持
- 状态恢复

```gdscript
class_name MySerializableObject extends SerializableComponent

var health: int = 100
var position: Vector2 = Vector2.ZERO

func _get_state() -> Dictionary:
    return {
        "health": health,
        "position": position,
    }

func _set_state(state: Dictionary) -> void:
    health = state.get("health", 100)
    position = state.get("position", Vector2.ZERO)
```

## 使用示例

### 基本存档/读档

```gdscript
# 保存游戏状态
func save_game() -> void:
    CoreSystem.save_manager.save("save_slot_1")

# 加载游戏状态
func load_game() -> void:
    CoreSystem.save_manager.load("save_slot_1")

# 删除存档
func delete_save() -> void:
    CoreSystem.save_manager.delete_save("save_slot_1")

# 获取存档列表
func get_saves() -> Array:
    return CoreSystem.save_manager.get_save_list()
```

### 配置管理

```gdscript
# 保存设置
func save_settings(volume: float, fullscreen: bool) -> void:
    var config = CoreSystem.config_manager
    config.set_value("audio", "volume", volume)
    config.set_value("graphics", "fullscreen", fullscreen)
    # 如果启用则自动保存

# 加载设置
func load_settings() -> void:
    var config = CoreSystem.config_manager
    var volume = config.get_value("audio", "volume", 1.0)
    var fullscreen = config.get_value("graphics", "fullscreen", false)
```

## 最佳实践

1. **存档数据组织**
   - 在配置文件中使用清晰的分节名称
   - 使用有意义的名称保持存档文件的组织
   - 实现存档文件版本控制

2. **错误处理**
   - 加载时始终检查错误
   - 提供后备值
   - 处理损坏的存档文件

3. **性能**
   - 对大型存档使用异步操作
   - 为大型状态实现存档数据压缩
   - 优化序列化数据大小

## API 参考

### SaveManager（存档管理器）
- `save(save_name: String) -> void`: 保存游戏状态
- `load(save_name: String) -> void`: 加载游戏状态
- `delete_save(save_name: String) -> void`: 删除存档文件
- `get_save_list() -> Array`: 获取可用存档列表
- `auto_save() -> void`: 触发自动保存

### ConfigManager（配置管理器）
- `set_value(section: String, key: String, value: Variant) -> void`: 设置配置值
- `get_value(section: String, key: String, default: Variant = null) -> Variant`: 获取配置值
- `save_config() -> void`: 保存配置到文件
- `load_config() -> void`: 从文件加载配置
- `clear_config() -> void`: 清除所有配置数据

### SerializableComponent（可序列化组件）
- `_get_state() -> Dictionary`: 获取对象状态
- `_set_state(state: Dictionary) -> void`: 设置对象状态
- `save() -> Dictionary`: 保存组件状态
- `load(state: Dictionary) -> void`: 加载组件状态
