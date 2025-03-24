# 输入系统

输入系统提供了一种灵活而强大的方式来处理游戏中的用户输入，支持虚拟动作和轴映射。

## 功能特性

- 🎮 **虚拟动作**: 定义和管理自定义输入动作
- 🕹️ **轴映射**: 从动作组合创建虚拟轴
- 📊 **输入状态**: 跟踪按下、刚按下和刚释放状态
- 🎯 **事件处理**: 全面的输入事件处理
- 🔄 **动态注册**: 在运行时注册和清除输入映射

## 核心组件

### 输入管理器 (InputManager)

所有输入操作的中央管理器：
- 虚拟动作管理
- 轴映射
- 输入状态跟踪

```gdscript
# 注册虚拟动作
input_manager.register_virtual_action(
    "jump",                 # 动作名称
    [jump_event]           # 按键组合
)

# 注册轴
input_manager.register_axis(
    "movement",            # 轴名称
    "move_right",         # 正向 X
    "move_left",          # 负向 X
    "move_down",          # 正向 Y
    "move_up"             # 负向 Y
)
```

## API 参考

### 输入管理器 (InputManager)

#### 信号

```gdscript
# 当动作被触发时发出
signal action_triggered(action_name: String, event: InputEvent)

# 当轴值改变时发出
signal axis_changed(axis_name: String, value: Vector2)
```

#### 方法

##### 虚拟动作

```gdscript
# 注册虚拟动作
func register_virtual_action(
    action_name: String,       # 动作名称
    key_combination: Array     # 按键组合
) -> void

# 检查动作是否被按下
func is_action_pressed(action_name: String) -> bool

# 检查动作是否刚刚被按下
func is_action_just_pressed(action_name: String) -> bool

# 检查动作是否刚刚被释放
func is_action_just_released(action_name: String) -> bool
```

##### 轴映射

```gdscript
# 注册虚拟轴
func register_axis(
    axis_name: String,        # 轴名称
    positive_x: String = "",  # 正向 X 动作
    negative_x: String = "",  # 负向 X 动作
    positive_y: String = "",  # 正向 Y 动作
    negative_y: String = ""   # 负向 Y 动作
) -> void

# 获取轴的值
func get_axis_value(axis_name: String) -> Vector2
```

##### 系统管理

```gdscript
# 清除所有虚拟输入
func clear_virtual_inputs() -> void
```

## 最佳实践

1. 在游戏启动或场景初始化时注册虚拟动作
2. 为动作和轴使用有意义的名称
3. 在改变游戏状态时清除虚拟输入
4. 通过输入管理器而不是直接处理输入事件
5. 对移动和类似的连续输入使用轴映射

## 示例

```gdscript
# 设置玩家输入
func _ready():
    # 注册移动轴
    input_manager.register_axis(
        "movement",
        "move_right",
        "move_left",
        "move_down",
        "move_up"
    )
    
    # 注册跳跃动作
    var jump_event = InputEventKey.new()
    jump_event.keycode = KEY_SPACE
    input_manager.register_virtual_action("jump", [jump_event])

# 在处理中处理输入
func _process(delta):
    # 获取移动输入
    var movement = input_manager.get_axis_value("movement")
    position += movement * speed * delta
    
    # 检查跳跃输入
    if input_manager.is_action_just_pressed("jump"):
        jump()
