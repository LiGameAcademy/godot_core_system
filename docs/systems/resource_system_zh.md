# 资源系统

资源系统提供了一种高效的方式来管理和加载游戏资源，具有异步加载和资源缓存等功能。

## 特性

- 🔄 **异步加载**：非阻塞资源加载
- 📦 **资源缓存**：智能缓存以提高性能
- 🎯 **资源引用**：管理资源依赖关系
- 🔍 **资源验证**：验证资源完整性
- 📱 **项目设置**：通过 Godot 的项目设置进行配置
- 🗑️ **自动清理**：智能资源卸载

## 核心组件

### ResourceManager（资源管理器）

所有资源操作的中央管理器：

- 资源加载和缓存
- 引用计数
- 内存管理

```gdscript
# 通过项目设置配置
core_system/resource_system/cache_size = 100
core_system/resource_system/preload_resources = true
core_system/resource_system/cleanup_interval = 300

# 使用示例
func _ready() -> void:
    var resource_manager = CoreSystem.resource_manager

    # 加载资源
    var texture = resource_manager.load("res://assets/textures/player.png")

    # 异步加载
    resource_manager.load_async("res://assets/models/enemy.tscn",
        func(resource): setup_enemy(resource)
    )
```

## 使用示例

### 基本资源加载

```gdscript
# 同步加载
func load_player_resources() -> void:
    var resource_manager = CoreSystem.resource_manager

    var texture = resource_manager.load("res://assets/textures/player.png")
    var animation = resource_manager.load("res://assets/animations/player.tres")
    var sound = resource_manager.load("res://assets/sounds/footstep.wav")

    setup_player(texture, animation, sound)
```

### 异步加载

```gdscript
# 带回调的异步加载
func load_level_async() -> void:
    var resource_manager = CoreSystem.resource_manager

    # 加载多个资源
    resource_manager.load_multiple_async([
        "res://assets/levels/level1.tscn",
        "res://assets/textures/background.png",
        "res://assets/music/level1_theme.ogg"
    ], func(resources): setup_level(resources))

    # 加载单个资源
    resource_manager.load_async("res://assets/models/enemy.tscn",
        func(resource): spawn_enemy(resource)
    )
```

### 资源管理

```gdscript
# 资源引用管理
func manage_resources() -> void:
    var resource_manager = CoreSystem.resource_manager

    # 添加引用
    resource_manager.add_reference("res://assets/textures/player.png")

    # 移除引用
    resource_manager.remove_reference("res://assets/textures/player.png")

    # 清理未使用的资源
    resource_manager.cleanup_unused()
```

## 最佳实践

1. **资源组织**

   - 使用清晰的文件夹结构
   - 遵循一致的命名约定
   - 对相关资源进行分组

2. **性能**

   - 预加载常用资源
   - 对大型资源使用异步加载
   - 实现适当的引用计数

3. **内存管理**
   - 清理未使用的资源
   - 监控内存使用
   - 对频繁实例化的对象使用资源池

## API 参考

### 资源管理器 ResourceManager

- `load(path: String) -> Resource`: 同步加载资源
- `load_async(path: String, callback: Callable) -> void`: 异步加载资源
- `load_multiple_async(paths: Array, callback: Callable) -> void`: 加载多个资源
- `add_reference(path: String) -> void`: 添加资源引用
- `remove_reference(path: String) -> void`: 移除资源引用
- `cleanup_unused() -> void`: 清理未引用的资源
- `preload_resources(paths: Array) -> void`: 预加载资源
- `unload_resource(path: String) -> void`: 卸载特定资源
- `get_resource(path: String) -> Resource`: 获取缓存的资源
- `has_resource(path: String) -> bool`: 检查资源是否已缓存
- `clear_cache() -> void`: 清理资源缓存
