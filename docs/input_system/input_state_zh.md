# 输入状态系统 (Input State System)

## 简介
输入状态系统提供了一个强大的输入状态管理机制，用于跟踪和管理所有输入动作的状态。它不仅记录基本的按下/释放状态，还包括时间戳和输入强度等高级特性。

## 功能特性
- 完整的输入状态跟踪
- 精确的时间戳记录
- 输入强度支持
- 状态持久化和重置功能

## 核心类
### InputState
主要的状态管理类，负责跟踪所有注册动作的状态。

#### ActionState 数据结构
```gdscript
class ActionState:
    var pressed: bool        # 当前是否按下
    var just_pressed: bool   # 是否刚刚按下
    var just_released: bool  # 是否刚刚释放
    var strength: float      # 输入强度
    var press_time: float    # 当前按下时间
    var last_press_time: float    # 上次按下时间
    var last_release_time: float  # 上次释放时间
```

#### 主要方法
- `update_action(action_name, is_pressed, strength)`: 更新动作状态
- `is_pressed(action_name)`: 检查动作是否按下
- `is_just_pressed(action_name)`: 检查动作是否刚按下
- `is_just_released(action_name)`: 检查动作是否刚释放
- `get_strength(action_name)`: 获取动作强度
- `get_press_time(action_name)`: 获取按下时间
- `reset_action(action_name)`: 重置动作状态

## 使用示例
```gdscript
# 更新动作状态
input_state.update_action("jump", true, 1.0)

# 检查动作状态
if input_state.is_just_pressed("jump"):
    character.jump()

# 获取按下持续时间
var hold_time = input_state.get_press_time("crouch")
```

## 高级特性
### 时间戳跟踪
系统自动记录以下时间戳：
- 当前按下时间
- 上次按下时间
- 上次释放时间

这些时间戳可用于实现：
- 连击检测
- 长按判定
- 输入缓冲

### 输入强度
支持模拟输入的强度值，范围从0到1：
- 对于键盘输入，通常是0或1
- 对于游戏手柄扳机键，可以是0到1之间的任意值
- 对于触摸输入，可以基于压力感应

## 高级用法
### 连击检测示例
```gdscript
func check_double_tap(action_name: String) -> bool:
    var state = input_state.get_action_state(action_name)
    if not state.just_pressed:
        return false
        
    var time_since_last = state.press_time - state.last_press_time
    return time_since_last < 0.3  # 300ms内的两次按下视为连击
```

### 长按检测示例
```gdscript
func check_long_press(action_name: String) -> bool:
    var state = input_state.get_action_state(action_name)
    if not state.pressed:
        return false
        
    var hold_duration = Time.get_ticks_msec() / 1000.0 - state.press_time
    return hold_duration >= 1.0  # 按住1秒以上视为长按
```

## 注意事项
- 状态更新应该在每帧进行
- 使用 just_pressed 和 just_released 进行精确的输入检测
- 合理使用时间戳来实现高级输入功能
- 注意及时重置不再使用的动作状态

## 性能优化
- 只跟踪必要的动作状态
- 定期清理未使用的状态
- 避免在每帧重复获取状态信息
