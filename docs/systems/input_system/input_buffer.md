# 输入缓冲系统 (Input Buffer System)

## 简介
输入缓冲系统为游戏提供了一个灵活的输入缓冲机制，可以在一定时间窗口内记住玩家的输入，提高游戏的操作手感，特别适用于格斗游戏、动作游戏等需要精确输入的场景。

## 功能特性
- 可配置的缓冲时间窗口
- 支持多个动作的并行缓冲
- 自动清理过期缓冲
- 优先级队列管理

## 核心类
### InputBuffer
主要的缓冲管理类，负责处理输入缓冲的添加、检查和清理。

#### 主要属性
```gdscript
var _buffer_window: float = 0.1  # 默认缓冲窗口为100ms
var _input_buffers: Dictionary   # 存储各个动作的缓冲
```

#### 主要方法
- `add_buffer(action_name, strength)`: 添加一个输入缓冲
- `has_buffer(action_name)`: 检查是否存在有效的缓冲
- `get_buffer_strength(action_name)`: 获取缓冲的输入强度
- `clean_expired_buffers()`: 清理过期的缓冲
- `set_buffer_window(window)`: 设置缓冲时间窗口
- `clear_buffers()`: 清除所有缓冲

## 使用示例
```gdscript
# 设置缓冲窗口
input_buffer.set_buffer_window(0.15)  # 150ms的缓冲窗口

# 添加输入缓冲
input_buffer.add_buffer("attack", 1.0)

# 检查是否有有效缓冲
if input_buffer.has_buffer("attack"):
    character.perform_attack()
```

## 高级用法
### 连招系统集成
```gdscript
# 在连招系统中使用输入缓冲
func check_combo():
    if input_buffer.has_buffer("punch"):
        if _last_move == "kick":
            perform_special_move()
        else:
            perform_normal_punch()
```

### 优先级处理
当多个输入在缓冲窗口内时，系统会：
1. 优先处理最新的输入
2. 考虑输入强度
3. 根据游戏逻辑决定最终行为

## 实现细节
### 缓冲数据结构
```gdscript
class BufferData:
    var timestamp: float    # 输入时间戳
    var strength: float     # 输入强度
    var consumed: bool      # 是否已消费
```

### 缓冲清理
- 自动清理过期缓冲
- 手动清理已消费的缓冲
- 场景切换时清理所有缓冲

## 最佳实践
1. 根据游戏类型调整缓冲窗口
   - 格斗游戏：较短窗口（50-100ms）
   - 动作游戏：中等窗口（100-200ms）
   - 休闲游戏：较长窗口（200-300ms）

2. 合理使用缓冲检查
   ```gdscript
   # 好的做法：在合适的时机检查缓冲
   func _physics_process(delta):
       update_movement()
       check_action_buffers()
   ```

3. 及时清理缓冲
   ```gdscript
   # 在状态切换时清理相关缓冲
   func change_state(new_state):
       clear_related_buffers()
       current_state = new_state
   ```

## 注意事项
- 定期调用 clean_expired_buffers() 以防止内存泄漏
- 避免过长的缓冲窗口，可能导致不期望的行为
- 在状态切换或场景转换时适当清理缓冲
