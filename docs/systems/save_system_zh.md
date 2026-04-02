# 存档系统

存档系统为 Godot 提供了一个灵活且异步的解决方案来管理游戏存档。它利用不同的存档格式策略（Resource、JSON、Binary）和节点注册机制来保存和加载游戏状态。

## 功能特性

- 💾 **多种存档格式**: 支持将存档保存为 Godot 资源 (`.tres`)、JSON (`.json`) 或压缩/加密的二进制 (`.save`)，通过可配置的策略实现。
- ✨ **策略模式**: 轻松切换或添加新的存档格式。
- ⚡ **异步操作**: 所有核心文件操作（保存、加载、删除、列出）都是非阻塞的，使用 `async`/`await`。
- 🌳 **基于节点的存档**: 注册特定节点以自动保存和加载其状态。
- 📄 **元数据支持**: 在游戏数据旁边自动保存元数据，如时间戳、游戏版本和游戏时长。
- 🔄 **自动存档支持**: 内建功能，用于创建和管理可配置数量的自动存档。
- 🔐 **可选的加密/压缩**: 二进制格式策略支持可选的 Gzip 压缩和 XOR 加密。
- ⚙️ **项目设置集成**: 通过项目设置配置存档目录、默认格式和自动存档行为。

## 快速开始

### 1. 访问存档管理器

```gdscript
# 假设 CoreSystem 单例已设置
var save_manager: SaveManager = CoreSystem.save_manager
```

### 2. 在节点中实现保存/加载

需要保存状态的节点必须实现 `save() -> Dictionary` 和 `load_data(data: Dictionary) -> void` 方法。

```gdscript
# 示例：玩家节点
extends CharacterBody2D

func save() -> Dictionary:
    # 返回一个包含要保存状态的字典
    return {
        "position_x": global_position.x,
        "position_y": global_position.y,
        "current_health": health,
        "collected_items": inventory.get_items() # 假设 inventory 有此方法
    }

func load_data(data: Dictionary) -> void:
    # 从字典恢复状态
    global_position.x = data.get("position_x", 0.0)
    global_position.y = data.get("position_y", 0.0)
    health = data.get("current_health", max_health)
    # inventory.load_items(data.get("collected_items", []))
```

### 3. 注册可存档节点

注册您想要保存其状态的节点，通常在它们的 `_ready` 函数中或实例化时进行。

```gdscript
func _ready() -> void:
    # 向存档管理器注册此节点
    CoreSystem.save_manager.register_saveable_node(self)
```

### 4. 基本的异步存/读档操作

使用 `await` 来处理存档操作的异步性。

```gdscript
# --- 保存 --- 
# 使用给定的 ID (例如 "slot_1") 创建一个存档文件。
# 它会通过已注册节点的 save() 方法收集数据。
async func perform_save(save_id: String):
    var success: bool = await save_manager.create_save(save_id)
    if success:
        print("存档 '" + save_id + "' 创建成功！")
    else:
        print("创建存档 '" + save_id + "' 失败。")

# --- 加载 --- 
# 从指定的存档 ID 加载完整的游戏状态。
async func perform_load(save_id: String):
    # load_game() 返回 *整个* 存档数据字典，包括
    # 元数据和包含每个已保存节点状态的 'nodes' 数组。
    var save_data: Dictionary = await save_manager.load_game(save_id)

    if save_data.is_empty():
        print("加载存档 '" + save_id + "' 失败或存档为空。")
        return

    print("存档 '" + save_id + "' 已加载。时间戳: ", save_data.get("metadata", {}).get("timestamp"))

    # 重要提示：应用加载的数据通常涉及更多步骤：
    # 1. 恢复全局状态（例如，GameInstance 中的当前关卡、总分）。
    # 2. 加载正确的游戏场景（例如，基于 save_data.metadata.level_index）。
    # 3. 场景加载 *之后*，找到对应的节点，并使用 save_data["nodes"] 中的数据
    #    调用它们的 load_data(node_specific_data) 方法。
    #    这种协调通常发生在 SaveManager *外部*，例如在您的 GameInstance 或 LevelManager 中。
    #    (save_manager 中被注释掉的 _apply_node_states 逻辑展示了先前的一种方法)。

# --- 删除 --- 
async func perform_delete(save_id: String):
    var success: bool = await save_manager.delete_save(save_id)
    if success:
        print("存档 '" + save_id + "' 删除成功！")
    else:
        print("删除存档 '" + save_id + "' 失败。")

# --- 列出存档 --- 
async func list_saves():
    # 获取目录中所有有效存档文件的元数据
    var saves: Array[Dictionary] = await save_manager.get_save_list()
    if saves.is_empty():
        print("未找到存档。")
    else:
        print("可用存档:")
        for save_meta in saves:
            print("- ID: %s, 日期: %s" % [save_meta.save_id, save_meta.save_date])
```

### 5. 自动存档使用

```gdscript
# 创建一个自动存档（使用配置的前缀并管理历史记录）
async func perform_auto_save():
    var auto_save_id: String = await save_manager.create_auto_save()
    if not auto_save_id.is_empty():
        print("自动存档 '" + auto_save_id + "' 已创建。")
    else:
        print("自动存档创建失败。")
```

## 存档格式策略 (Save Format Strategies)

`SaveManager` 使用 `SaveFormatStrategy` 来处理读/写不同文件格式的具体细节。

-   **`ResourceSaveStrategy`**: 将数据保存为自定义的 `GameStateData` 资源 (`.tres`)。简单，与 Godot 编辑器集成良好，但可移植性和灵活性较差。
-   **`JsonSaveStrategy`**: 将数据保存为人类可读的 JSON (`.json`)。使用 `AsyncIOManager` 进行非阻塞 I/O。利于调试，广泛兼容，但可能文件较大，且不能直接保存所有 Godot 类型（需要转换，由 `AsyncIOStrategy` 处理）。
-   **`BinarySaveStrategy`**: 将数据保存为 JSON，然后可选地压缩 (Gzip) 和加密 (XOR)，最后保存为 `.save` 文件。使用 `AsyncIOManager`。提供更小的文件大小和基本的安全性，但不可人工阅读。

当前活动的策略由 `default_format` 设置决定，或者可能通过编程方式更改（尽管当前的 `SaveManager` 主要使用默认设置）。策略定义了文件扩展名并处理特定格式的保存/加载逻辑。

## 项目设置 (通过 `setting.gd`)

| 设置名称 (在 ProjectSettings 中)                    | 描述                                | `setting.gd` 示例中的默认值 |
| ---------------------------------------------------- | ----------------------------------- | --------------------------- |
| `godot_core_system/save_system/defaults/save_directory` | 存档文件存储的目录。                | `"user://saves/"`         |
| `godot_core_system/save_system/defaults/serialization_format` | 默认存档格式 (`resource`, `json`, `binary`)。 | `"binary"`                |
| `godot_core_system/save_system/auto_save/prefix`      | 用于自动存档文件名的前缀。          | `"auto_save_"`            |
| `godot_core_system/save_system/auto_save/max_saves`     | 保留的最大自动存档文件数量。        | `3`                         |

## API 参考

### SaveManager (`save_manager.gd`)

管理存档操作的核心类。

#### 属性 (可通过项目设置配置)

-   `save_directory: String`
-   `default_format: String`
-   `auto_save_prefix: String`
-   `max_auto_saves: int`

#### 方法 (异步)

-   `create_save(save_id: String) -> bool`: 使用给定的 ID 创建一个新的存档文件，收集来自已注册节点的数据。成功时返回 `true`。
-   `load_game(save_id: String) -> Dictionary`: 从指定的存档文件加载完整的数据字典（元数据 + 节点状态）。失败时返回空字典。
-   `load_save_metadata(save_id: String) -> Dictionary`: 仅从指定的存档文件加载元数据字典。失败时返回空字典。
-   `delete_save(save_id: String) -> bool`: 删除指定的存档文件。成功时返回 `true`。
-   `get_save_list() -> Array[Dictionary]`: 返回一个数组，包含在存档目录中找到的所有有效存档文件的元数据字典。
-   `create_auto_save() -> String`: 创建一个自动存档，根据 `max_auto_saves` 管理历史记录，并返回生成的存档 ID 字符串（例如 `auto_save_3`）。失败时返回空字符串。
-   `has_any_save() -> bool`: 检查存档目录中是否存在任何有效的存档文件。

#### 方法 (同步)

-   `register_saveable_node(node: Node) -> void`: 注册一个节点以包含在存档操作中。期望该节点具有 `save() -> Dictionary` 和 `load_data(data: Dictionary) -> void` 方法。
-   `unregister_saveable_node(node: Node) -> void`: 注销一个节点。
-   `set_encryption_key(key: String) -> void`: 设置要被支持加密的策略（如通过 `AsyncIOManager` 的 `BinarySaveStrategy`）使用的加密密钥。如果需要密钥，在保存/加载加密文件*之前必须*调用此方法。

#### 信号

-   `save_created(save_id: String)`: 存档文件成功创建后发出。
-   `save_loaded(save_id: String)`: `load_game` 成功读取数据后发出（但在数据应用于游戏状态*之前*）。
-   `save_deleted(save_id: String)`: 存档文件成功删除后发出。
-   `auto_save_created(save_id: String)`: 自动存档成功创建后发出。
-   `save_list_updated(saves: Array[Dictionary])`: `get_save_list` 完成后发出。

### 可存档节点约定 (Saveable Node Convention)

通过 `register_saveable_node` 注册的节点必须实现：

-   `save() -> Dictionary`: 在 `create_save` 期间由 `SaveManager` 调用。应返回包含此节点所有必要状态的字典。
-   `load_data(data: Dictionary) -> void`: 在加载存档且节点/场景存在后，*由您的游戏逻辑*调用。应从提供的字典（对应于之前 `save()` 返回的内容）恢复节点的状态。

## 最佳实践

1.  **加载顺序**: 请记住 `load_game` 仅返回数据。您的游戏逻辑（例如 `GameInstance`）必须处理这个顺序：加载数据 -> 恢复全局状态 -> 加载场景 -> 从加载的数据应用节点状态。
2.  **仔细实现 `save`/`load_data`**: 确保 `save` 捕获所有必要状态，并且 `load_data` 正确恢复它，使用默认值处理潜在的缺失键 (`data.get("key", default_value)`)。
3.  **注册/注销**: 在节点与存档相关时注册它们（例如 `_ready`），如果它们在游戏过程中被永久移除，考虑注销它们 (`unregister_saveable_node`)。
4.  **加密密钥管理**: 如果使用加密（例如 `BinarySaveStrategy`），确保在保存和加载*之前*都通过 `set_encryption_key` 提供了*完全相同*的加密密钥。安全地存储和检索此密钥（例如，使用 `ConfigManager`）至关重要。
5.  **错误处理**: 检查 `async` 函数的返回值（`bool` 表示成功，空字典/数组/字符串表示失败），并适当地使用 `try/catch` 或检查结果。
6.  **明智选择策略**: 考虑权衡：Resource（简单，编辑器友好），JSON（可读，可调试），Binary（紧凑，基本安全）。

## 常见问题

1.  **存档/读档失败**: 检查文件权限、存档目录是否存在、`save_id` 是否正确，以及所选格式策略是否与文件扩展名匹配。对于二进制存档，确保在加载*之前*已正确设置加密密钥。
2.  **节点状态未保存/加载**: 验证节点是否已注册，是否正确实现了 `save()` 和 `load_data()`，以及您的游戏逻辑是否在场景加载后调用了 `load_data`。
3.  **二进制存档重启后加载失败**: 几乎总是因为在尝试加载之前没有正确设置加密密钥。确保密钥在游戏启动早期从 `ConfigManager`（或其他来源）加载，并传递给 `SaveManager.set_encryption_key()`。
4.  **数据类型问题 (JSON/Binary)**: `Vector2`, `Color` 等可能被保存为字典。`AsyncIOStrategy` 会处理基本的类型转换，但如果需要，请确保您的 `load_data` 逻辑能正确地重构这些类型（尽管该策略旨在透明地处理此问题）。
