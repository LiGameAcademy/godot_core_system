# 触发器系统

触发器系统是一个灵活而强大的系统，用于管理游戏中的触发器和事件。它支持多种触发类型、条件和动作，非常适合创建交互式游戏机制。

## 特性

- 🎯 **多种触发类型**: 支持即时触发、事件触发和周期触发
- 🔄 **条件执行**: 灵活的条件系统控制触发器激活
- 📊 **概率控制**: 内置触发概率控制
- ⏱️ **周期触发**: 支持基于时间的周期性触发
- 🔌 **事件总线集成**: 可选的事件总线系统集成
- 💾 **持久化**: 支持触发器状态序列化

## 快速开始

### 1. 访问触发器管理器

```gdscript
var trigger_manager = CoreSystem.trigger_manager
```

### 2. 创建简单触发器

```gdscript
# 创建事件触发器
var trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
    "trigger_event": "player_entered",
    "conditions": [
        {
            "type": "state_trigger_condition",
            "state_name": "player_in_area",
            "required_state": "true"
        }
    ]
})

# 连接触发器信号
trigger.triggered.connect(_on_trigger_activated)

# 激活触发器
trigger.activate()
```

### 3. 创建周期触发器

```gdscript
# 创建周期触发器
var periodic_trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.PERIODIC,
    "period": 2.0,  # 每2秒触发一次
    "trigger_chance": 0.5  # 50%触发概率
})

periodic_trigger.triggered.connect(_on_periodic_trigger)
periodic_trigger.activate()
```

### 4. 处理事件

```gdscript
# 发送事件到触发器系统
trigger_manager.handle_event("player_entered", {
    "state_name": "player_in_area",
    "state_value": "true"
})
```

## 示例

查看 [trigger_demo](../examples/trigger_demo/) 目录获取完整的示例项目。

### 区域触发器示例

```gdscript
# 创建区域触发器
var area_trigger = GameplayTrigger.new({
    "trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
    "trigger_event": "enter_area",
    "conditions": [
        {
            "type": "state_trigger_condition",
            "state_name": "player_in_area",
            "required_state": "true"
        }
    ]
})

# 处理区域事件
func _on_area_entered(body: Node) -> void:
    trigger_manager.handle_event("enter_area", {
        "state_name": "player_in_area",
        "state_value": "true"
    })
```

## API 参考

### TriggerManager

全局触发器管理器，负责触发器注册和事件处理。

- `handle_event(trigger_type: StringName, context: Dictionary) -> void`: 处理触发事件
- `register_event_trigger(trigger_type: StringName, trigger: GameplayTrigger) -> void`: 注册事件触发器
- `register_periodic_trigger(trigger: GameplayTrigger) -> void`: 注册周期触发器
- `create_condition(config: Dictionary) -> TriggerCondition`: 创建触发条件

### GameplayTrigger

核心触发器类，处理触发逻辑和条件。

#### 属性
- `trigger_type: TRIGGER_TYPE`: 触发器类型（IMMEDIATE、ON_EVENT、PERIODIC）
- `conditions: Array[TriggerCondition]`: 条件列表
- `persistent: bool`: 是否持久化
- `max_triggers: int`: 最大触发次数
- `trigger_count: int`: 当前触发次数
- `trigger_event: StringName`: 事件触发器的事件名称
- `period: float`: 周期触发器的触发间隔
- `trigger_chance: float`: 触发概率

#### 方法
- `activate(initial_context: Dictionary = {}) -> void`: 激活触发器
- `deactivate() -> void`: 停用触发器
- `execute(context: Dictionary) -> void`: 执行触发器
- `should_trigger(context: Dictionary) -> bool`: 检查是否应该触发
- `reset() -> void`: 重置触发器状态

### TriggerCondition

触发条件的基类。

- `evaluate(context: Dictionary) -> bool`: 评估条件

## 最佳实践

1. **选择合适的触发器类型**
   - 使用 ON_EVENT 处理事件驱动的触发
   - 使用 PERIODIC 处理基于时间的触发
   - 使用 IMMEDIATE 处理一次性触发

2. **管理触发器生命周期**
   - 在需要时激活触发器
   - 在不需要时停用触发器
   - 重用时重置触发器

3. **有效使用条件**
   - 保持条件简单明确
   - 组合条件实现复杂逻辑
   - 使用适当的条件类型

4. **性能考虑**
   - 限制活动触发器数量
   - 使用适当的周期更新间隔
   - 清理未使用的触发器

## 常见问题

1. **触发器不触发**
   - 检查触发器是否已激活
   - 验证事件名称是否完全匹配
   - 检查条件逻辑
   - 确保触发概率合适

2. **性能问题**
   - 活动触发器过多
   - 周期更新过于频繁
   - 条件评估过于复杂

3. **事件集成问题**
   - 检查事件总线订阅设置
   - 验证事件名称和参数
   - 检查事件处理器连接