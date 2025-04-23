# 存档系统

存档系统是一个全面的游戏存档管理解决方案，提供创建、加载和管理存档文件的功能，并支持自动存档。

## 特性

- 💾 **灵活的存档管理**: 创建、加载和删除存档文件
- 🔄 **自动存档支持**: 可配置的自动存档功能
- 📁 **自定义存档位置**: 可配置的存档目录和文件扩展名
- 🔌 **基于组件的序列化**: 易于与游戏对象集成
- 🛡️ **异步操作**: 非阻塞的存档/读档操作
- ⚙️ **项目设置集成**: 通过 Godot 的项目设置进行配置

## 快速开始

### 1. 访问存档管理器

```gdscript
var save_manager = CoreSystem.save_manager
```

### 2. 注册可序列化组件

```gdscript
# 创建可序列化组件
class_name PlayerData
extends SerializableComponent

func serialize() -> Dictionary:
    return {
        "position": owner.position,
        "health": owner.health,
        "inventory": owner.inventory
    }

func deserialize(data: Dictionary) -> void:
    owner.position = data.position
    owner.health = data.health
    owner.inventory = data.inventory

# 注册组件
save_manager.register_serializable_component($PlayerData)
```

### 3. 基本存档操作

```gdscript
# 创建存档
save_manager.create_save("save_001", func(success: bool):
    if success:
        print("存档创建成功！")
)

# 加载存档
save_manager.load_save("save_001", func(success: bool):
    if success:
        print("存档加载成功！")
)

# 删除存档
save_manager.delete_save("save_001", func(success: bool):
    if success:
        print("存档删除成功！")
)
```

### 4. 自动存档使用

```gdscript
# 启用自动存档
ProjectSettings.set_setting("save_system/auto_save_enabled", true)
ProjectSettings.set_setting("save_system/auto_save_interval", 300)  # 5分钟
ProjectSettings.set_setting("save_system/max_auto_saves", 3)

# 手动创建自动存档
save_manager.create_auto_save()
```

## 项目设置

| 设置 | 描述 | 默认值 |
|---------|-------------|---------|
| save_directory | 存档文件目录 | "user://saves" |
| save_extension | 存档文件扩展名 | "save" |
| auto_save_enabled | 启用自动存档 | true |
| auto_save_interval | 自动存档间隔（秒） | 300 |
| max_auto_saves | 最大自动存档数量 | 3 |

## API 参考

### SaveManager

存档操作的核心类。

#### 属性
- `save_directory: String`: 存档存储目录
- `save_extension: String`: 存档文件扩展名
- `auto_save_interval: float`: 自动存档间隔
- `max_auto_saves: int`: 最大自动存档数量
- `auto_save_enabled: bool`: 是否启用自动存档

#### 方法
- `create_save(save_name: String, callback: Callable) -> void`: 创建新存档
- `load_save(save_name: String, callback: Callable) -> void`: 加载已有存档
- `delete_save(save_name: String, callback: Callable) -> void`: 删除存档
- `create_auto_save() -> void`: 创建自动存档
- `register_serializable_component(component: SerializableComponent) -> void`: 注册可序列化组件
- `unregister_serializable_component(component: SerializableComponent) -> void`: 注销可序列化组件

#### 信号
- `save_created(save_name: String)`: 存档创建时发出
- `save_loaded(save_name: String)`: 存档加载时发出
- `save_deleted(save_name: String)`: 存档删除时发出
- `auto_save_created`: 自动存档创建时发出
- `auto_save_cleaned`: 清理旧自动存档时发出

### SerializableComponent

可保存组件的基类。

#### 方法
- `serialize() -> Dictionary`: 将组件状态转换为字典
- `deserialize(data: Dictionary) -> void`: 从字典恢复组件状态

## 最佳实践

1. **组件组织**
   - 保持可序列化组件功能单一明确
   - 使用清晰的存档文件命名规范
   - 定期清理旧存档

2. **错误处理**
   - 始终检查回调成功状态
   - 为加载失败提供备用行为
   - 优雅处理损坏的存档文件

3. **自动存档使用**
   - 根据游戏类型设置适当的间隔
   - 考虑玩家进度和检查点频率
   - 定期清理旧的自动存档

4. **性能优化**
   - 大型存档使用异步操作
   - 优化序列化数据大小
   - 可能时批量处理多个存档

## 常见问题

1. **存档创建失败**
   - 检查写入权限
   - 验证存档目录是否存在
   - 确保存档名称格式有效

2. **加载操作失败**
   - 验证存档文件是否存在
   - 检查文件权限
   - 验证存档数据格式

3. **自动存档问题**
   - 检查自动存档设置
   - 验证可用磁盘空间
   - 监控自动存档性能影响
