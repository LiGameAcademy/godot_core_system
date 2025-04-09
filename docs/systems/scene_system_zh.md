# 场景系统

场景系统提供了一个完整的场景管理解决方案，包括场景转场效果、场景状态管理和异步加载等功能。

## 功能特性

- 🔄 **转场效果**: 内置和自定义场景转场效果
- 📚 **场景栈**: 保存和恢复场景状态
- ⚡ **异步加载**: 非阻塞的场景加载操作
- 🔍 **场景预加载**: 预加载场景以加快切换速度
- 🎯 **子场景管理**: 添加和管理子场景

## 核心组件

### 场景管理器 (SceneManager)

所有场景操作的中央管理器：

- 场景转场管理
- 场景状态处理
- 场景栈操作

```gdscript
# 基本场景切换
scene_manager.change_scene_async(
    "res://scenes/game.tscn",    # 场景路径
    {"level": 1},               # 场景数据
    true,                       # 保存到栈
    SceneManager.TransitionEffect.FADE  # 转场效果
)

# 返回上一个场景
scene_manager.pop_scene_async(
    SceneManager.TransitionEffect.FADE
)
```

### 转场基类 (BaseTransition)

创建自定义转场效果的基类：

```gdscript
extends BaseTransition
class_name CustomTransition

func _do_start(duration: float) -> void:
    # 实现开始转场效果
    pass

func _do_end(duration: float) -> void:
    # 实现结束转场效果
    pass
```

## API 参考

### 场景管理器

#### 属性

```gdscript
enum TransitionEffect {
    NONE,       # 无转场效果
    FADE,       # 淡入淡出
    SLIDE,      # 滑动
    DISSOLVE,   # 溶解
    CUSTOM      # 自定义
}
```

#### 方法

##### 场景管理

```gdscript
# 异步切换场景
func change_scene_async(
    scene_path: String,              # 场景路径
    scene_data: Dictionary = {},     # 场景数据
    push_to_stack: bool = false,     # 保存当前场景
    effect: TransitionEffect = NONE, # 效果类型
    duration: float = 0.5,          # 持续时间
    callback: Callable = Callable(), # 回调函数
    custom_transition: BaseTransition = null  # 自定义效果
) -> void

# 返回上一个场景
func pop_scene_async(
    effect: TransitionEffect = NONE,
    duration: float = 0.5,
    callback: Callable = Callable(),
    custom_transition: BaseTransition = null
) -> void

# 添加子场景
func add_sub_scene(
    parent_node: Node,
    scene_path: String,
    scene_data: Dictionary = {}
) -> Node

# 获取当前场景
func get_current_scene() -> Node
```

##### 场景预加载

```gdscript
# 预加载场景
func preload_scene(scene_path: String) -> void

# 清除预加载的场景
func clear_preloaded_scenes() -> void
```

##### 转场效果

```gdscript
# 注册自定义转场效果
func register_transition(
    effect: TransitionEffect,
    transition: BaseTransition
) -> void
```

#### 信号

```gdscript
signal scene_loading_started(scene_path: String)  # 场景开始加载
signal scene_changed(old_scene: Node, new_scene: Node)  # 场景已切换
signal scene_loading_finished()  # 场景加载完成
signal scene_preloaded(scene_path: String)  # 场景预加载完成
```

### 转场基类 (BaseTransition)

#### 方法

```gdscript
# 初始化转场效果
func init(transition_rect: ColorRect) -> void

# 开始转场
func start(duration: float) -> void

# 结束转场
func end(duration: float) -> void
```

#### 保护方法

```gdscript
# 重写以实现自定义开始效果
func _do_start(duration: float) -> void

# 重写以实现自定义结束效果
func _do_end(duration: float) -> void
```

## 最佳实践

1. 始终使用 `change_scene_async()` 进行场景切换
2. 为需要保持状态的场景实现状态管理
3. 预加载常用场景
4. 使用适当的转场效果
5. 优雅地处理场景加载错误

## 示例

查看 `examples/scene_demo` 目录获取完整示例：

- 基本场景切换
- 自定义转场效果
- 场景状态管理
- 场景预加载
