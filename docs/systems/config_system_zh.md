# 配置系统

配置系统使用 Godot 内建的 `ConfigFile` 格式提供了一个直接的解决方案，用于管理游戏配置，支持持久化存储和默认值。

## 特性

- ⚙️ **简单的键值存储**: 利用 Godot 的 `ConfigFile` 实现轻松的分段/键/值管理。
- 💾 **持久化存储**: 从指定文件加载并保存到该文件（默认: `user://config.cfg`）。
- 🔄 **默认值处理**: `get_value` 通过返回提供的默认值来优雅地处理缺失的键。
- 🔌 **项目设置集成**: 关键设置如 `config_path` 和 `auto_save` 可通过项目设置进行配置（尽管是在内部访问，并未在提供的脚本中直接暴露为可设置属性）。
- 📂 **分段管理**: 在配置文件中将设置组织到逻辑分段中。
- ⚙️ **同步操作**: 核心的加载、保存、获取和设置操作是同步的。

## 快速开始

### 1. 访问配置管理器

```gdscript
# 假设 CoreSystem 单例已设置
var config_manager = CoreSystem.config_manager
```

### 2. 基本操作

```gdscript
# ConfigManager 通常在 init/ready 时自动加载。手动加载示例：
# var success = config_manager.load_config()
# if success:
#     print("配置已加载/重新加载。")

# 获取配置值（如果键可能不存在，请提供默认值）
var sound_volume = config_manager.get_value("audio", "sound_volume", 1.0)
print("声音音量: ", sound_volume)

# 设置配置值
# 如果 auto_save 为 true（默认），这可能会触发自动保存。
config_manager.set_value("audio", "sound_volume", 0.8)

# 检查值是否被修改，如果 auto_save 关闭，可能需要手动保存
# (如果 auto_save 开启，内部的 _modified 标志会处理此问题)
# if config_manager._modified: # 注意：_modified 是内部变量，不建议直接访问
#    var save_success = config_manager.save_config()
#    if save_success:
#        print("手动保存配置。")

# 重置内存中的配置（如果 auto_save 开启，则保存一个空文件）
# config_manager.reset_config()
```

### 3. 默认值

该系统依赖于在调用 `get_value` 时提供默认值。脚本中未显示明确的"默认配置文件"机制，而是在访问点处理默认值。

```gdscript
# 如果 [gameplay] 分段中不存在 "difficulty"，则返回 "normal"
var difficulty = config_manager.get_value("gameplay", "difficulty", "normal")
```

## 项目设置 (通过 `setting.gd`)

这些设置控制 ConfigManager 的行为，通常在插件的 `setting.gd` 或类似的设置脚本中定义：

| 设置名称 (在 ProjectSettings 中)           | 描述                     | `setting.gd` 示例中的默认值 |
| ------------------------------------------ | ------------------------ | --------------------------- |
| `godot_core_system/config_system/config_path` | 配置文件的路径。         | `"user://config.cfg"`     |
| `godot_core_system/config_system/auto_save`   | 当 `set_value` 更改值时自动保存。 | `true`                      |

*注意: `config_manager.gd` 中的 `@export` 变量仅使用 `get:` 来读取这些项目设置。*

## API 参考

### ConfigManager (`config_manager.gd`)

通过 `ConfigFile` 管理配置的核心类。

#### 属性 (通过项目设置访问)

-   `config_path: String` (通过 `ProjectSettings.get_setting(SETTING_CONFIG_PATH, ...)` 读取): 配置文件的路径。
-   `auto_save: bool` (通过 `ProjectSettings.get_setting(SETTING_AUTO_SAVE, ...)` 读取): 当通过 `set_value` 修改值时是否自动保存。

#### 方法

-   `load_config(p_path: String = "") -> bool`: 从指定路径加载配置（如果为空则使用默认 `config_path`）。如果加载成功（或文件未找到，这被视为空配置加载成功）则返回 `true`，其他错误返回 `false`。通常在初始化时自动调用。
-   `save_config(p_path: String = "") -> bool`: 将当前配置保存到指定路径（或默认 `config_path`）。确保目录存在。成功时返回 `true`，失败时返回 `false`。如果 `auto_save` 为 true 且值已更改，则由 `set_value` 自动调用。
-   `reset_config() -> void`: 清空内存中配置的所有分段和键。如果 `auto_save` 为 true，则会保存一个空的配置文件。
-   `set_value(section: String, key: String, value: Variant) -> void`: 设置配置值。如果新值与当前值不同，则标记配置为已修改。如果 `auto_save` 为 true 且值已更改，则触发 `save_config`。
-   `get_value(section: String, key: String, p_default_value: Variant) -> Variant`: 获取配置值。如果分段或键不存在，则返回 `p_default_value`。
-   `get_section(section: String) -> Dictionary`: 返回包含给定分段*当前已加载*的所有键值对的字典。如果分段不存在，则返回空字典。
-   `set_section(section: String, value: Dictionary) -> void`: 通过基于输入字典 `value` 设置或覆盖键来更新配置分段。*注意：此实现会添加或覆盖键，它不会通过先删除旧键来严格替换整个分段。* 如果 `auto_save` 为 true 且任何值已更改，则触发 `save_config`。
-   `get_sections() -> PackedStringArray`: 返回当前配置中加载的所有分段名称的数组。
-   `has_section(section: String) -> bool`: 检查当前加载的配置中是否存在某个分段。
-   `has_key(section: String, key: String) -> bool`: 检查当前加载的配置中给定分段内是否存在某个键。

#### 信号

-   `config_loaded`: 当通过 `load_config` 完成配置加载（即使是空配置/文件未找到）时发出。
-   `config_saved`: 当通过 `save_config` 成功保存配置时发出。
-   `config_reset`: 当通过 `reset_config` 清空内存中的配置时发出。

## 最佳实践

1.  **配置组织**: 使用清晰的分段和键名 (例如 `[audio] music_volume = 0.8`)。
2.  **默认值**: 在 `get_value` 调用中始终提供默认值，以防止设置丢失时出错。
3.  **错误处理**: 如果手动调用 `load_config` 和 `save_config`（尤其是在 `auto_save` 关闭时），请检查它们的返回值。
4.  **性能**: `ConfigFile` 操作涉及磁盘 I/O，相对较慢。避免在性能关键的循环中重复调用 `load_config` 或 `save_config`。依赖 `auto_save` 或在逻辑点（例如，关闭设置菜单、退出游戏）保存更改。将频繁访问的值缓存在变量中，而不是在同一作用域或帧内重复调用 `get_value`。

## 常见问题

1.  **配置未保存**:
    *   检查 `user://` 目录的文件系统权限。
    *   验证 `config_path` 设置指向正确的位置。
    *   确保 `auto_save` 为 `true` 或者您在 `set_value` 之后手动调用了 `save_config()`。
    *   检查 `save_config` 记录的任何错误日志。
2.  **设置未加载 / 返回默认值**:
    *   验证 `config_path` 是否正确以及文件是否存在。
    *   检查文件系统权限。
    *   确保在尝试访问值*之前*调用了 `load_config()`（将 `load_config` 移至 `_init` 有助于解决此问题）。
    *   检查 `load_config` 记录的任何错误日志。
    *   确保 `get_value` 中的分段和键名与 `.cfg` 文件中的完全匹配（区分大小写）。

## 示例

### 音频配置

```