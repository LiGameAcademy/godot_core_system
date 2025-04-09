# 配置系统

配置系统提供了一个强大的游戏配置管理解决方案，支持运行时设置和持久化存储。

## 特性

- ⚙️ **灵活的配置**: 易用的键值存储
- 💾 **持久化存储**: 自动保存和加载设置
- 🔄 **默认值**: 内置默认配置支持
- 🔌 **项目设置集成**: 通过 Godot 的项目设置进行配置
- 🛡️ **异步操作**: 非阻塞的保存/加载操作
- 📦 **分段管理**: 在逻辑分段中组织设置

## 快速开始

### 1. 访问配置管理器

```gdscript
var config_manager = CoreSystem.config_manager
```

### 2. 基本操作

```gdscript
# 加载配置
config_manager.load_config(func(success: bool):
    if success:
        print("配置加载成功！")
)

# 获取配置值
var sound_volume = config_manager.get_value("audio", "sound_volume", 1.0)

# 设置配置值
config_manager.set_value("audio", "sound_volume", 0.8)

# 保存配置
config_manager.save_config(func(success: bool):
    if success:
        print("配置保存成功！")
)

# 重置为默认值
config_manager.reset_config(func(success: bool):
    if success:
        print("配置已重置为默认值！")
)
```

### 3. 默认配置

```gdscript
# 在 default_config.gd 中定义默认配置
static func get_default_config() -> Dictionary:
    return {
        "audio": {
            "master_volume": 1.0,
            "music_volume": 0.8,
            "sound_volume": 1.0,
            "voice_volume": 1.0
        },
        "graphics": {
            "fullscreen": false,
            "vsync": true,
            "resolution": "1920x1080"
        },
        "gameplay": {
            "difficulty": "normal",
            "language": "zh"
        }
    }
```

## 项目设置

| 设置 | 描述 | 默认值 |
|---------|-------------|---------|
| config_path | 配置文件路径 | "user://config.cfg" |
| auto_save | 更改时自动保存 | true |

## API 参考

### ConfigManager

配置管理的核心类。

#### 属性
- `config_path: String`: 配置文件路径
- `auto_save: bool`: 是否自动保存更改

#### 方法
- `load_config(callback: Callable) -> void`: 从文件加载配置
- `save_config(callback: Callable) -> void`: 保存配置到文件
- `reset_config(callback: Callable) -> void`: 重置为默认配置
- `get_value(section: String, key: String, default: Variant) -> Variant`: 获取配置值
- `set_value(section: String, key: String, value: Variant) -> void`: 设置配置值
- `has_section(section: String) -> bool`: 检查分段是否存在
- `has_key(section: String, key: String) -> bool`: 检查键是否存在于分段中
- `get_section(section: String) -> Dictionary`: 获取整个分段
- `set_section(section: String, data: Dictionary) -> void`: 设置整个分段

#### 信号
- `config_loaded`: 配置加载时发出
- `config_saved`: 配置保存时发出
- `config_reset`: 配置重置时发出

## 最佳实践

1. **配置组织**
   - 使用逻辑分段名称
   - 将相关设置放在一起
   - 使用一致的命名规范

2. **默认值**
   - 始终提供合理的默认值
   - 记录默认值
   - 考虑平台差异

3. **错误处理**
   - 检查回调成功状态
   - 提供备用值
   - 优雅处理缺失的分段/键

4. **性能优化**
   - 谨慎使用自动保存
   - 缓存频繁访问的值
   - 批量处理多个更改

## 常见问题

1. **配置不保存**
   - 检查写入权限
   - 验证配置路径是否有效
   - 确保需要时启用自动保存

2. **默认值不加载**
   - 检查默认配置格式
   - 验证分段和键名
   - 调试与已保存数据的合并冲突

3. **设置缺失**
   - 始终使用带默认值的 get_value
   - 检查分段存在性
   - 验证配置结构

## 示例

### 音频配置

```gdscript
# 加载音频设置
func load_audio_settings():
    var master = config_manager.get_value("audio", "master_volume", 1.0)
    var music = config_manager.get_value("audio", "music_volume", 0.8)
    var sound = config_manager.get_value("audio", "sound_volume", 1.0)
    
    AudioServer.set_bus_volume_db(0, linear_to_db(master))
    AudioServer.set_bus_volume_db(1, linear_to_db(music))
    AudioServer.set_bus_volume_db(2, linear_to_db(sound))

# 保存音频设置
func save_audio_settings():
    var master = db_to_linear(AudioServer.get_bus_volume_db(0))
    var music = db_to_linear(AudioServer.get_bus_volume_db(1))
    var sound = db_to_linear(AudioServer.get_bus_volume_db(2))
    
    config_manager.set_value("audio", "master_volume", master)
    config_manager.set_value("audio", "music_volume", music)
    config_manager.set_value("audio", "sound_volume", sound)
```

### 图形配置

```gdscript
# 应用图形设置
func apply_graphics_settings():
    var fullscreen = config_manager.get_value("graphics", "fullscreen", false)
    var vsync = config_manager.get_value("graphics", "vsync", true)
    var resolution = config_manager.get_value("graphics", "resolution", "1920x1080")
    
    if fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    
    DisplayServer.window_set_vsync_mode(vsync)
    var res = resolution.split("x")
    DisplayServer.window_set_size(Vector2i(int(res[0]), int(res[1])))
```
