# Threading System

The Threading System provides a robust solution for managing concurrent tasks in your Godot game, optimizing performance by leveraging multi-threading capabilities.

## Features

- 🚀 **High Performance**: Optimized for handling concurrent tasks
- 🛡️ **Thread Safety**: Robust synchronization mechanisms
- 🏷️ **Named Threads**: Organize threads by purpose or system
- 📊 **Task Prioritization**: Execute important tasks first
- 📈 **Monitoring**: Track thread status and performance
- 🔧 **Flexible API**: Multiple abstraction levels for different use cases

## Core Components

### ModuleThread

The main thread manager for organizing and accessing named threads:

- Creates and manages named thread workers
- Allows task submission to specific threads
- Provides thread lookup and statistics

```gdscript
# Usage example
func _ready() -> void:
    # Create a module thread manager
    var module_thread = ModuleThread.new()
    
    # Create a named thread for a specific purpose
    var io_thread = module_thread.create_thread(&"io_thread")
    
    # Submit a task to this thread
    io_thread.submit_task(
        func(): return load_file("user://save.dat"),
        func(result): print("File loaded: ", result)
    )
```

### SingleThread

A lightweight thread wrapper for sequential async operations:

- Manages a single worker thread
- Executes tasks in sequence
- Provides manual task progression control

```gdscript
# Usage example
func _ready() -> void:
    var thread = SingleThread.new()
    
    # Add multiple tasks to be executed sequentially
    thread.add_task(
        func():
            # First task
            return load_data()
        ,
        func(result):
            # Handle first task result
            process_data(result)
    )
    
    thread.add_task(
        func():
            # Second task (executed after the first one)
            return process_more_data()
        ,
        func(result):
            # Handle second task result
            finalize_data(result)
    )
```

### ThreadPool

A thread pool implementation for general-purpose parallel processing:

- Manages multiple worker threads
- Distributes tasks among available threads
- Provides priority-based task scheduling
- Offers monitoring and statistics

```gdscript
# Usage example
func _ready() -> void:
    # Create a thread pool with 4 worker threads
    var pool = ThreadPool.new(4)
    
    # Submit a task with a callback
    pool.submit_task(
        func():
            # Do some heavy work
            var result = perform_calculation()
            return result
        ,
        func(result):
            # Handle the result in the main thread
            display_result(result)
    )
    
    # Clean up when done
    pool.stop()
```

## Usage Examples

### Basic Task Execution

```gdscript
# Create a module thread manager
var module_thread = ModuleThread.new()

# Create a named thread for a specific purpose
var io_thread = module_thread.create_thread(&"io_thread")

# Execute a task asynchronously
io_thread.submit_task(
    func():
        # Perform heavy calculation
        var sum = 0
        for i in range(1000000):
            sum += i
        return sum
    ,
    func(result):
        # Process the result
        print("Sum calculated: ", result)
)
```

### Priority-Based Task Scheduling

```gdscript
# Create a thread pool
var thread_pool = ThreadPool.new(2)

# Submit low-priority task
thread_pool.submit_task(
    func(): 
        print("Low priority task executed")
        return "low priority completed"
    ,
    func(result): print(result),
    0  # Low priority
)

# Submit high-priority task
thread_pool.submit_task(
    func(): 
        print("High priority task executed")
        return "high priority completed"
    ,
    func(result): print(result),
    10  # High priority
)
```

### Sequential Task Execution

```gdscript
# Create a single thread worker
var single_thread = SingleThread.new()

# Queue multiple tasks that will execute in sequence
single_thread.add_task(
    func():
        print("Task 1 started")
        await get_tree().create_timer(1.0).timeout
        print("Task 1 completed")
        return "Task 1 result"
    ,
    func(result):
        print("Processing task 1 result: ", result)
)

single_thread.add_task(
    func():
        print("Task 2 started")
        await get_tree().create_timer(1.0).timeout
        print("Task 2 completed")
        return "Task 2 result"
    ,
    func(result):
        print("Processing task 2 result: ", result)
)
```

### Using With IO Operations

```gdscript
# Thread pool for file operations
var io_thread_pool = ThreadPool.new(2)

# Read file asynchronously
func read_file_async(path: String, callback: Callable) -> void:
    io_thread_pool.submit_task(
        func():
            var file = FileAccess.open(path, FileAccess.READ)
            if not file:
                return null
            var content = file.get_as_text()
            file.close()
            return content
        ,
        callback
    )

# Write file asynchronously
func write_file_async(path: String, content: String, callback: Callable) -> void:
    io_thread_pool.submit_task(
        func():
            var file = FileAccess.open(path, FileAccess.WRITE)
            if not file:
                return false
            file.store_string(content)
            file.close()
            return true
        ,
        callback
    )
```

## Best Practices

1. **Thread Safety**
   - Always use mutexes to protect shared resources
   - Avoid race conditions when accessing shared data
   - Use thread-safe data structures when possible

2. **Error Handling**
   - Implement proper error handling in tasks
   - Use the task_error signal to catch and handle errors
   - Consider implementing retry mechanisms for critical tasks

3. **Resource Management**
   - Keep thread pools alive only as long as needed
   - Always call stop() when done with a thread pool
   - Be mindful of memory usage in long-running threads

4. **Performance Considerations**
   - Use an appropriate number of threads (typically number of CPU cores)
   - Balance task granularity (not too small, not too large)
   - Monitor thread pool performance in production

## API Reference

### ModuleThread

- `add_task(name: StringName, function: Callable, callback: Callable, call_deferred: bool = true) -> void`: Add task to named thread
- `next_step(name: StringName) -> void`: Advance to next task in named thread
- `create_thread(name: StringName) -> SingleThread`: Create a new named thread
- `has_thread(name: StringName) -> bool`: Check if thread exists
- `get_thread(name: StringName) -> SingleThread`: Get thread by name
- `get_thread_names() -> Array[StringName]`: Get all thread names
- `get_thread_count() -> int`: Get thread count
- `clear_threads() -> void`: Clear all threads
- `unload_thread(name: StringName) -> void`: Unload a specific thread

### SingleThread

- `_init() -> void`: Constructor
- `add_task(task_function: Callable, task_callback: Callable, call_deferred: bool = true) -> void`: Add a task
- `next_step() -> void`: Advance to the next task
- `get_pending_task_count() -> int`: Get number of pending tasks
- `get_running_task_count() -> int`: Get number of running tasks
- `clear_pending_tasks() -> void`: Clear the task queue

### ThreadPool

- `_init(pool_size: int = 4) -> void`: Constructor with thread count
- `submit_task(work_func: Callable, callback: Callable, priority: int = 0) -> String`: Submit a task to the pool
- `stop(wait_for_completion: bool = false) -> void`: Stop all threads
- `get_pending_tasks() -> int`: Get number of pending tasks
- `clear_queue() -> int`: Clear the task queue
- `get_thread_info() -> Array[Dictionary]`: Get thread status information
- `get_stats() -> Dictionary`: Get pool statistics
- `resize_pool(new_size: int) -> int`: Change pool size (can only increase)
