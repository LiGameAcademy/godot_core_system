# 分帧执行器

分帧执行器 (FrameSplitter) 是一个用于优化性能的工具类，它可以将耗时的操作分散到多个帧中执行，避免因为大量计算导致的游戏卡顿。

## 主要特性

- **自动分帧**：将大量计算任务分散到多个帧中执行
- **动态调整**：根据实际执行时间动态调整每帧处理量
- **进度反馈**：提供进度信号，方便显示进度条
- **多种处理模式**：支持数组、范围、迭代器和自定义处理

## 快速开始

### 创建分帧执行器

```gdscript
# 基本用法
var splitter = CoreSystem.FrameSplitter.new()

# 自定义参数
var splitter = CoreSystem.FrameSplitter.new(
    100,  # 每帧处理数量
    10.0  # 每帧最大执行时间（毫秒）
)
```

### 连接信号

```gdscript
# 监听进度
splitter.progress_changed.connect(func(progress): 
    progress_bar.value = progress * 100
)

# 监听完成
splitter.completed.connect(func(): 
    print("处理完成")
)
```

## 处理模式

### 1. 数组处理
适用于处理已有的数组数据。

```gdscript
# 处理数组
await splitter.process_array(items, func(item): 
    process_item(item)
)
```

### 2. 范围处理
适用于处理连续的数字范围。

```gdscript
# 处理0到999的数字
await splitter.process_range(0, 1000, func(i): 
    generate_something(i)
)
```

### 3. 迭代器处理
适用于处理自定义数据结构。

```gdscript
class MyIterator:
    var current = 0
    var max_value = 100
    
    func has_next() -> bool:
        return current < max_value
    
    func next():
        current += 1
        return current - 1

var iterator = MyIterator.new()
await splitter.process_iterator(iterator, func(value):
    print("处理值: ", value)
, iterator.max_value)
```

### 4. 自定义处理
适用于需要批量处理的场景。

```gdscript
await splitter.process_custom(1000, func(start, end):
    print("处理范围: %d 到 %d" % [start, end])
)
```

## 使用场景

### 1. 资源加载
分批加载大量资源，避免加载时卡顿。

```gdscript
await splitter.process_array(resource_paths, func(path):
    var resource = load(path)
    resources.append(resource)
)
```

### 2. 地图生成
分帧生成大型地图，保持游戏流畅。

```gdscript
await splitter.process_range(0, map_size, func(i):
    generate_map_tile(i)
)
```

### 3. 批量数据处理
处理大量数据时避免卡顿。

```gdscript
await splitter.process_custom(total_items, func(start, end):
    # 批量处理数据
    for i in range(start, end):
        process_data(data[i])
)
```

### 4. AI行为更新
分批更新多个实体的AI。

```gdscript
await splitter.process_array(entities, func(entity):
    entity.update_ai()
)
```

## 性能优化

### 参数调整

1. **每帧处理数量 (items_per_frame)**
   - 增加：提高处理速度，但可能影响性能
   - 减少：降低性能影响，但处理时间更长
   - 建议：根据处理项的复杂度调整

2. **每帧最大执行时间 (max_ms_per_frame)**
   - 增加：允许更多处理，但可能影响流畅度
   - 减少：保证流畅，但总处理时间更长
   - 建议：在目标帧时间（16.67ms@60FPS）的50%以内

### 动态调整

分帧执行器会根据实际执行时间动态调整每帧处理量：
- 如果执行时间超过限制，减少处理量
- 如果执行时间充裕（小于限制的80%），增加处理量
- 始终保持至少1个处理量，最大不超过初始设置

## 最佳实践

### 1. 错误处理
添加错误处理确保稳定性。

```gdscript
await splitter.process_array(items, func(item): 
    try:
        process_item(item)
    except:
        push_error("处理失败: " + str(item))
)
```

### 2. 进度显示
提供进度反馈提升用户体验。

```gdscript
# 进度条显示
splitter.progress_changed.connect(func(p): 
    progress_bar.value = p * 100
    progress_label.text = "%d%%" % (p * 100)
)

# 完成回调
splitter.completed.connect(func():
    print("处理完成")
    show_complete_message()
)
```

### 3. 可中断处理
添加中断机制以支持取消操作。

```gdscript
var should_continue = true

# 中断处理
cancel_button.pressed.connect(func():
    should_continue = false
)

# 处理数据
await splitter.process_array(items, func(item): 
    if not should_continue:
        return
    process_item(item)
)
```

## 常见问题

### Q: 为什么使用分帧执行器后总处理时间变长了？
A: 分帧执行会增加一些额外开销，并且通过延长总时间来换取更好的实时性能。这是为了保持游戏流畅运行的必要代价。

### Q: 如何选择合适的参数？
A: 建议从默认值开始，然后根据实际性能表现逐步调整：
1. 监控FPS保持在目标帧率
2. 观察处理时间是否合理
3. 权衡流畅度和总处理时间

### Q: 处理过程中能暂停或取消吗？
A: 可以通过在处理函数中添加控制逻辑来实现：
1. 使用标志变量控制处理流程
2. 在处理函数中检查标志
3. 根据标志决定是否继续处理

### Q: 如何处理异步操作？
A: 在处理函数中可以使用await，但需要注意：
1. 异步操作会影响性能监控的准确性
2. 可能需要调整时间限制参数
3. 考虑使用其他方式处理耗时的异步操作
