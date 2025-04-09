# 标签系统

标签系统是一个轻量级的、灵活的标签管理系统，用于为游戏对象添加和管理标签。它支持层级标签结构，可以用于实现各种游戏功能，如状态标记、分类系统等。

## 特性

- 🏷️ **层级标签**: 支持通过点号分隔的多层级标签（如 "character.player.state.idle"）
- 🔍 **灵活查询**: 支持精确和模糊匹配标签
- 📦 **标签容器**: 为游戏对象提供独立的标签管理
- 🎯 **事件通知**: 标签变化时发送信号
- 💾 **持久化**: 支持标签的序列化和反序列化

## 快速开始

### 1. 访问标签管理器

```gdscript
var tag_manager = CoreSystem.tag_manager
```

### 2. 创建标签容器

```gdscript
# 在场景中添加标签容器节点
var tag_container = GameplayTagContainer.new()
add_child(tag_container)

# 或者通过场景树引用已有的标签容器
@onready var tag_container = $TagContainer
```

### 3. 基本使用

```gdscript
# 添加标签
tag_container.add_tag("character.player")
tag_container.add_tag("state.idle")

# 检查标签
if tag_container.has_tag("character.player"):
    print("This is a player!")

# 移除标签
tag_container.remove_tag("state.idle")

# 获取所有标签
var all_tags = tag_container.get_tags()
print("Current tags:", all_tags)
```

### 4. 高级功能

```gdscript
# 检查多个标签
var required_tags = ["character.player", "state.idle"]
if tag_container.has_all_tags(required_tags):
    print("Player is idle!")

# 模糊匹配
if tag_container.has_tag("character", false):
    print("This is any character!")

# 监听标签变化
tag_container.tag_added.connect(_on_tag_added)
tag_container.tag_removed.connect(_on_tag_removed)
```

## 示例

查看 [tag_demo](../examples/tag_demo/) 目录获取完整的示例项目。

### 玩家状态示例

```gdscript
# 给玩家添加初始标签
player_tags.add_tag("character.player")
player_tags.add_tag("state.idle")

# 切换玩家状态
func _on_player_move():
    player_tags.remove_tag("state.idle")
    player_tags.add_tag("state.moving")

# 添加buff
func _on_buff_acquired(buff_name: String):
    player_tags.add_tag("buff." + buff_name)
```

## API 参考

### GameplayTagManager

全局标签管理器，负责标签的注册和管理。

- `register_tag(tag_name: String) -> void`: 注册新标签
- `get_tag(tag_name: String) -> GameplayTag`: 获取标签对象
- `has_tag(tag_name: String) -> bool`: 检查标签是否已注册

### GameplayTagContainer

标签容器节点，用于管理单个对象的标签集合。

- `add_tag(tag) -> void`: 添加标签
- `remove_tag(tag) -> void`: 移除标签
- `has_tag(tag, exact: bool = true) -> bool`: 检查是否有指定标签
- `has_all_tags(required_tags: Array, exact: bool = true) -> bool`: 检查是否有所有指定标签
- `has_any_tags(required_tags: Array, exact: bool = true) -> bool`: 检查是否有任意指定标签
- `get_tags() -> Array`: 获取所有标签名称
- `get_all_tags() -> Array[GameplayTag]`: 获取所有标签对象（包括子标签）

### GameplayTag

标签对象，表示单个标签。

- `name: StringName`: 标签名称
- `parent: GameplayTag`: 父标签
- `children: Array[GameplayTag]`: 子标签列表
- `matches(other: GameplayTag, exact: bool) -> bool`: 检查是否匹配另一个标签

## 最佳实践

1. **使用层级结构**
   - 使用点号分隔不同层级
   - 例如：`character.player.state.idle`

2. **标签命名规范**
   - 使用小写字母
   - 使用点号分隔层级
   - 避免特殊字符
   - 使用描述性名称

3. **性能考虑**
   - 避免过度使用标签
   - 及时移除不需要的标签
   - 使用精确匹配而不是模糊匹配

4. **组织标签**
   - 按功能分类（如 state、buff、character）
   - 保持层级结构清晰
   - 记录标签的用途和含义

## 常见问题

1. **标签不存在**
   - 确保在使用前已注册标签
   - 检查标签名称拼写是否正确
   - 查看日志输出的错误信息

2. **标签匹配失败**
   - 检查是否使用了正确的匹配模式（精确/模糊）
   - 确认标签的层级结构是否正确
   - 检查标签名称的大小写

3. **性能问题**
   - 减少不必要的标签
   - 使用精确匹配代替模糊匹配
   - 避免频繁添加/移除标签
