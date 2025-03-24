# Frame Splitter

Frame Splitter is a performance optimization tool that distributes time-consuming operations across multiple frames to prevent game stuttering caused by heavy computations.

## Key Features

- **Automatic Frame Distribution**: Splits large computational tasks across multiple frames
- **Dynamic Adjustment**: Automatically adjusts per-frame workload based on actual execution time
- **Progress Feedback**: Provides progress signals for easy progress bar implementation
- **Multiple Processing Modes**: Supports arrays, ranges, iterators, and custom processing

## Quick Start

### Creating a Frame Splitter

```gdscript
# Basic usage
var splitter = CoreSystem.FrameSplitter.new()

# Custom parameters
var splitter = CoreSystem.FrameSplitter.new(
    100,  # Items per frame
    10.0  # Maximum milliseconds per frame
)
```

### Connecting Signals

```gdscript
# Progress monitoring
splitter.progress_changed.connect(func(progress): 
    progress_bar.value = progress * 100
)

# Completion callback
splitter.completed.connect(func(): 
    print("Processing completed")
)
```

## Processing Modes

### 1. Array Processing
Suitable for processing existing array data.

```gdscript
# Process array items
await splitter.process_array(items, func(item): 
    process_item(item)
)
```

### 2. Range Processing
Ideal for processing numerical ranges.

```gdscript
# Process numbers from 0 to 999
await splitter.process_range(0, 1000, func(i): 
    generate_something(i)
)
```

### 3. Iterator Processing
For processing custom data structures.

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
    print("Processing value: ", value)
, iterator.max_value)
```

### 4. Custom Processing
For batch processing scenarios.

```gdscript
await splitter.process_custom(1000, func(start, end):
    print("Processing range: %d to %d" % [start, end])
)
```

## Use Cases

### 1. Resource Loading
Load multiple resources without freezing the game.

```gdscript
await splitter.process_array(resource_paths, func(path):
    var resource = load(path)
    resources.append(resource)
)
```

### 2. Map Generation
Generate large maps while maintaining game smoothness.

```gdscript
await splitter.process_range(0, map_size, func(i):
    generate_map_tile(i)
)
```

### 3. Batch Data Processing
Process large datasets without stuttering.

```gdscript
await splitter.process_custom(total_items, func(start, end):
    # Process data in batches
    for i in range(start, end):
        process_data(data[i])
)
```

### 4. AI Behavior Updates
Update multiple entity AI behaviors.

```gdscript
await splitter.process_array(entities, func(entity):
    entity.update_ai()
)
```

## Performance Optimization

### Parameter Tuning

1. **Items Per Frame (items_per_frame)**
   - Increase: Higher processing speed but may impact performance
   - Decrease: Better performance but longer total processing time
   - Recommendation: Adjust based on processing complexity

2. **Maximum Time Per Frame (max_ms_per_frame)**
   - Increase: More processing but may affect smoothness
   - Decrease: Better smoothness but longer total time
   - Recommendation: Stay within 50% of target frame time (16.67ms@60FPS)

### Dynamic Adjustment

The Frame Splitter automatically adjusts per-frame workload:
- Reduces workload if execution time exceeds limit
- Increases workload if execution time is comfortable (below 80% of limit)
- Always maintains at least 1 item per frame, never exceeds initial setting

## Best Practices

### 1. Error Handling
Add error handling for stability.

```gdscript
await splitter.process_array(items, func(item): 
    try:
        process_item(item)
    except:
        push_error("Processing failed: " + str(item))
)
```

### 2. Progress Display
Provide feedback for better user experience.

```gdscript
# Progress bar display
splitter.progress_changed.connect(func(p): 
    progress_bar.value = p * 100
    progress_label.text = "%d%%" % (p * 100)
)

# Completion callback
splitter.completed.connect(func():
    print("Processing completed")
    show_complete_message()
)
```

### 3. Interruptible Processing
Add interruption mechanism for cancellation support.

```gdscript
var should_continue = true

# Interrupt handler
cancel_button.pressed.connect(func():
    should_continue = false
)

# Process data
await splitter.process_array(items, func(item): 
    if not should_continue:
        return
    process_item(item)
)
```

## Common Questions

### Q: Why does processing take longer with Frame Splitter?
A: Frame splitting adds some overhead and extends total processing time to maintain real-time performance. This trade-off is necessary for smooth gameplay.

### Q: How do I choose appropriate parameters?
A: Start with default values and adjust based on actual performance:
1. Monitor FPS to maintain target frame rate
2. Observe if processing time is reasonable
3. Balance smoothness and total processing time

### Q: Can I pause or cancel processing?
A: Yes, by adding control logic in the processing function:
1. Use a flag variable to control flow
2. Check the flag in processing function
3. Decide whether to continue based on flag

### Q: How do I handle async operations?
A: You can use await in processing functions, but note:
1. Async operations affect performance monitoring accuracy
2. May need to adjust time limit parameters
3. Consider alternative approaches for time-consuming async operations
