# 输入事件处理器 (Input Event Processor)

## 简介
输入事件处理器提供了一个统一的接口来处理和过滤各种输入事件，支持自定义事件处理规则和优先级管理。它是输入系统的核心组件之一，负责对原始输入事件进行预处理和分发。

## 功能特性
- 输入事件过滤
- 事件优先级管理
- 自定义处理规则
- 事件转换和规范化
- 事件队列管理

## 核心类
### InputEventProcessor
主要的事件处理器类，负责处理和分发输入事件。

#### 主要方法
```gdscript
class_name InputEventProcessor

func process_event(event: InputEvent) -> bool:
    # 处理输入事件，返回是否应该继续处理
    if _should_ignore_event(event):
        return false
    
    # 处理事件并返回结果
    return _process_event_internal(event)
```

## 事件处理流程
1. 事件接收
2. 事件验证
3. 事件过滤
4. 事件转换
5. 事件分发

### 使用示例
```gdscript
# 在输入管理器中使用事件处理器
func _input(event: InputEvent) -> void:
    if not event_processor.process_event(event):
        return
    _process_action_input(event)
```

## 事件过滤
### 内置过滤规则
- 重复事件过滤
- 无效事件过滤
- 优先级过滤

### 自定义过滤规则
```gdscript
func _should_ignore_event(event: InputEvent) -> bool:
    # 忽略未知类型的事件
    if not (event is InputEventKey or 
            event is InputEventMouseButton or 
            event is InputEventJoypadButton):
        return true
    return false
```

## 事件转换
### 输入规范化
```gdscript
func _normalize_event(event: InputEvent) -> Dictionary:
    return {
        "type": _get_event_type(event),
        "action": _get_event_action(event),
        "strength": event.get_action_strength(),
        "timestamp": Time.get_ticks_msec()
    }
```

### 事件合并
```gdscript
func _merge_events(event1: Dictionary, event2: Dictionary) -> Dictionary:
    # 根据规则合并事件
    return {
        "type": event1.type,
        "action": event1.action,
        "strength": max(event1.strength, event2.strength),
        "timestamp": event1.timestamp
    }
```

## 优先级管理
### 优先级规则
1. 系统级事件 (最高优先级)
2. UI事件
3. 游戏输入事件
4. 调试事件 (最低优先级)

### 优先级实现
```gdscript
enum Priority {
    SYSTEM = 0,
    UI = 1,
    GAMEPLAY = 2,
    DEBUG = 3
}

func _get_event_priority(event: InputEvent) -> int:
    if event.is_action("ui_cancel"):
        return Priority.SYSTEM
    elif event is InputEventMouseButton:
        return Priority.UI
    return Priority.GAMEPLAY
```

## 事件队列
### 队列管理
```gdscript
var _event_queue: Array = []
var _max_queue_size: int = 32

func queue_event(event: InputEvent) -> void:
    if _event_queue.size() >= _max_queue_size:
        _event_queue.pop_front()
    _event_queue.push_back(event)
```

### 队列处理
```gdscript
func process_queued_events() -> void:
    while not _event_queue.is_empty():
        var event = _event_queue.pop_front()
        process_event(event)
```

## 调试支持
### 事件日志
```gdscript
func _log_event(event: InputEvent) -> void:
    if _debug_mode:
        print("处理事件: ", _get_event_description(event))
```

### 性能监控
```gdscript
var _processing_times: Array = []

func _monitor_performance(event: InputEvent) -> void:
    var start_time = Time.get_ticks_usec()
    process_event(event)
    var end_time = Time.get_ticks_usec()
    _processing_times.append(end_time - start_time)
```

## 最佳实践
1. 事件处理要快速高效
2. 避免在事件处理中进行耗时操作
3. 合理使用事件过滤减少不必要的处理
4. 保持处理逻辑的模块化和可测试性

## 注意事项
- 确保事件处理的线程安全
- 避免事件处理循环
- 合理设置队列大小限制
- 注意事件处理的性能开销
- 正确处理事件的优先级关系
- 避免在事件处理中修改事件队列
