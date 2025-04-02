# 输入系统 (Input System)

## 简介
输入系统是一个全面的输入处理框架，提供了高级的输入管理、状态跟踪、缓冲处理和事件记录功能。它由多个专门的子系统组成，每个子系统都专注于特定的输入处理方面。

## 系统架构
输入系统由以下核心组件组成：

### 输入管理器 (InputManager)
中央控制器，协调各个子系统的工作。主要职责包括：
- 初始化和管理所有子系统
- 处理原始输入事件
- 更新输入状态
- 分发处理后的事件

### 子系统
1. [虚拟轴系统](input_system/virtual_axis.md)
   - 处理基于轴的输入（如角色移动）
   - 支持死区和灵敏度调节
   - 提供实时轴值更新

2. [输入状态系统](input_system/input_state.md)
   - 跟踪所有输入动作的状态
   - 提供精确的时间戳记录
   - 支持输入强度检测

3. [输入缓冲系统](input_system/input_buffer.md)
   - 实现输入缓冲机制
   - 支持可配置的缓冲窗口
   - 自动管理缓冲优先级

4. [输入记录器](input_system/input_recorder.md)
   - 记录输入序列
   - 支持回放功能
   - 提供存档和加载功能

5. [事件处理器](input_system/input_event_processor.md)
   - 处理和过滤输入事件
   - 管理事件优先级
   - 提供事件转换功能

## 使用示例
### 基本设置
```gdscript
# 获取输入管理器实例
@onready var input_manager = CoreSystem.input_manager

# 设置虚拟轴
input_manager.virtual_axis.register_axis(
    "movement",
    "ui_right",
    "ui_left",
    "ui_up",
    "ui_down"
)

# 检查输入状态
if input_manager.input_state.is_just_pressed("jump"):
    character.jump()
```

### 高级功能
```gdscript
# 使用输入缓冲
input_manager.input_buffer.add_buffer("attack", 1.0)

# 记录输入序列
input_manager.input_recorder.start_recording()

# 处理自定义事件
input_manager.event_processor.process_event(event)
```

## 配置和自定义
### 系统配置
```gdscript
# 配置虚拟轴
virtual_axis.set_sensitivity(1.0)
virtual_axis.set_deadzone(0.2)

# 设置缓冲窗口
input_buffer.set_buffer_window(0.15)
```

### 信号连接
```gdscript
# 监听动作触发
input_manager.action_triggered.connect(_on_action_triggered)

# 监听轴值变化
input_manager.axis_changed.connect(_on_axis_changed)
```

## 最佳实践
1. 状态管理
   - 使用输入状态系统而不是直接检查输入
   - 在适当的时机更新和重置状态

2. 事件处理
   - 使用事件处理器过滤无关事件
   - 遵循事件优先级规则

3. 性能优化
   - 合理使用缓冲机制
   - 及时清理过期数据
   - 避免过度记录

## 调试支持
- 详细的状态日志
- 输入序列记录和回放
- 性能监控工具

## 扩展性
系统支持通过以下方式进行扩展：
1. 添加新的子系统
2. 自定义事件处理规则
3. 实现特定游戏类型的输入处理

## 注意事项
1. 初始化顺序
   - 确保在使用前正确初始化所有子系统
   - 遵循依赖关系

2. 资源管理
   - 及时清理不需要的记录
   - 控制缓冲区大小

3. 线程安全
   - 在主线程处理输入
   - 注意异步操作的影响

## API 参考
请参考各个子系统的详细文档：
- [虚拟轴系统](input_system/virtual_axis.md)
- [输入状态系统](input_system/input_state.md)
- [输入缓冲系统](input_system/input_buffer.md)
- [输入记录器](input_system/input_recorder.md)
- [事件处理器](input_system/input_event_processor.md)
