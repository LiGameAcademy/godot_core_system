# 输入记录器 (Input Recorder)

## 简介
输入记录器系统提供了一种记录和回放玩家输入序列的机制。这对于游戏回放、调试、录制演示和创建游戏教程特别有用。

## 功能特性
- 实时输入记录
- 输入序列回放
- 时间戳精确记录
- 支持保存和加载记录数据
- 可配置的记录缓冲区大小

## 核心类
### InputRecorder
主要的记录器类，负责记录和管理输入序列。

#### 主要属性
```gdscript
class InputRecord:
    var timestamp: float      # 记录时间戳
    var action: String        # 动作名称
    var pressed: bool         # 是否按下
    var strength: float       # 输入强度
```

#### 主要方法
- `start_recording()`: 开始记录输入
- `stop_recording()`: 停止记录
- `record_input(action, pressed, strength)`: 记录一个输入事件
- `start_playback()`: 开始回放
- `stop_playback()`: 停止回放
- `save_recording(path)`: 保存记录到文件
- `load_recording(path)`: 从文件加载记录

## 使用示例
### 基本记录和回放
```gdscript
# 开始记录
input_recorder.start_recording()

# 记录输入
func _on_input_event(action: String, pressed: bool, strength: float):
    input_recorder.record_input(action, pressed, strength)

# 停止记录并保存
input_recorder.stop_recording()
input_recorder.save_recording("user://demo.rec")

# 加载和回放
input_recorder.load_recording("user://demo.rec")
input_recorder.start_playback()
```

### 游戏回放系统集成
```gdscript
# 回放管理器示例
class ReplayManager:
    var recorder: InputRecorder
    var game_state: Dictionary
    
    func start_replay():
        game_state = save_game_state()
        recorder.start_playback()
        
    func on_replay_input(action: String, pressed: bool):
        process_input(action, pressed)
```

## 高级特性
### 时间同步
系统使用精确的时间戳来确保回放的时序准确：
```gdscript
func _process(delta: float):
    if _is_playing:
        _playback_time += delta
        _process_pending_inputs()
```

### 压缩存储
记录数据使用高效的存储格式：
```gdscript
func _serialize_record(record: InputRecord) -> Dictionary:
    return {
        "t": record.timestamp,
        "a": record.action,
        "p": record.pressed,
        "s": record.strength
    }
```

### 回放控制
提供详细的回放控制选项：
- 暂停/继续
- 速度调节
- 跳转到特定时间点
- 循环回放

## 应用场景
1. 游戏回放系统
   - 比赛回放
   - 精彩时刻回放
   - 死亡回放

2. 调试工具
   - 问题复现
   - 输入序列测试
   - 性能分析

3. 教程系统
   - 操作示范
   - 引导教学
   - 动作展示

## 最佳实践
1. 记录管理
   ```gdscript
   # 定期清理旧记录
   func manage_recordings():
       var max_recordings = 10
       clean_old_recordings(max_recordings)
   ```

2. 性能优化
   ```gdscript
   # 使用缓冲区限制记录大小
   var _record_buffer: Array
   var _max_buffer_size = 1000
   
   func add_record(record: InputRecord):
       if _record_buffer.size() >= _max_buffer_size:
           _record_buffer.pop_front()
       _record_buffer.append(record)
   ```

3. 错误处理
   ```gdscript
   # 处理回放过程中的异常
   func safe_playback():
       try:
           start_playback()
       catch:
           handle_playback_error()
   ```

## 注意事项
- 确保记录数据的版本兼容性
- 考虑记录文件的大小限制
- 在状态切换时正确处理记录器状态
- 注意回放时的游戏状态同步
