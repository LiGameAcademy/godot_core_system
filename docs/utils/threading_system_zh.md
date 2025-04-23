# 线程系统

线程系统为您的Godot游戏提供了强大的并发任务管理解决方案，通过利用多线程能力来优化性能。

## 特性

- 🚀 **高性能**：优化的并发任务处理
- 🛡️ **线程安全**：稳健的同步机制
- 🏷️ **命名线程**：按用途或系统组织线程
- 📊 **任务优先级**：优先执行重要任务
- 📈 **监控功能**：跟踪线程状态和性能
- 🔧 **灵活API**：适用于不同场景的多层次抽象

## 核心组件

### ModuleThread（模块线程管理器）

主要的线程管理器，用于组织和访问命名线程：

- 创建和管理命名线程工作器
- 允许向特定线程提交任务
- 提供线程查询和统计功能

```gdscript
# 使用示例
func _ready() -> void:
    # 创建模块线程管理器
    var module_thread = ModuleThread.new()
    
    # 创建一个用于特定目的的命名线程
    var io_thread = module_thread.create_thread(&"io_thread")
    
    # 向该线程提交任务
    io_thread.submit_task(
        func(): return load_file("user://save.dat"),
        func(result): print("文件已加载: ", result)
    )
```

### SingleThread（单线程）

用于顺序异步操作的轻量级线程包装器：

- 管理单个工作线程
- 按顺序执行任务
- 提供手动任务推进控制

```gdscript
# 使用示例
func _ready() -> void:
    var thread = SingleThread.new()
    
    # 连接信号以处理结果
    thread.task_completed.connect(_on_task_completed)
    thread.task_error.connect(_on_task_error)
    thread.thread_finished.connect(_on_thread_finished)
    
    # 添加多个要按顺序执行的任务
    thread.add_task(
        func():
            # 第一个任务
            return load_data()
        ,
        func(result):
            # 处理第一个任务的结果
            process_data(result)
    )
    
    thread.add_task(
        func():
            # 第二个任务（在第一个任务之后执行）
            return process_more_data()
        ,
        func(result):
            # 处理第二个任务的结果
            finalize_data(result)
    )

# 处理信号回调
func _on_task_completed(result, task_id):
    print("任务完成，ID: ", task_id, " 结果: ", result)
    
func _on_task_error(error, task_id):
    print("任务错误，ID: ", task_id, " 错误: ", error)
    
func _on_thread_finished():
    print("所有任务已完成")
```

### ThreadPool（线程池）

用于通用并行处理的线程池实现：

- 管理多个工作线程
- 在可用线程之间分配任务
- 提供基于优先级的任务调度
- 提供监控和统计功能

```gdscript
# 使用示例
func _ready() -> void:
    # 创建一个有4个工作线程的线程池
    var pool = ThreadPool.new(4)
    
    # 提交一个带回调的任务
    pool.submit_task(
        func():
            # 执行一些重量级工作
            var result = perform_calculation()
            return result
        ,
        func(result):
            # 在主线程中处理结果
            display_result(result)
    )
    
    # 使用完毕后清理
    pool.stop()
```

## 使用示例

### 基本任务执行

```gdscript
# 创建一个指定线程数的线程池
var thread_pool = ThreadPool.new(4)

# 异步执行任务
thread_pool.submit_task(
    func():
        # 执行重型计算
        var sum = 0
        for i in range(1000000):
            sum += i
        return sum
    ,
    func(result):
        # 处理结果
        print("计算的总和: ", result)
)
```

### 基于优先级的任务调度

```gdscript
# 创建线程池
var thread_pool = ThreadPool.new(2)

# 提交低优先级任务
thread_pool.submit_task(
    func(): 
        print("低优先级任务执行")
        return "低优先级完成"
    ,
    func(result): print(result),
    0  # 低优先级
)

# 提交高优先级任务
thread_pool.submit_task(
    func(): 
        print("高优先级任务执行")
        return "高优先级完成"
    ,
    func(result): print(result),
    10  # 高优先级
)
```

### 顺序任务执行

```gdscript
# 创建单线程工作器
var single_thread = SingleThread.new()

# 连接信号
single_thread.task_completed.connect(func(result, task_id): print("任务完成: ", task_id, " 结果: ", result))
single_thread.thread_finished.connect(func(): print("所有任务已完成"))

# 添加任务到队列
single_thread.add_task(
    func():
        print("任务1开始")
        # 注意：SingleThread不支持await，若需要延迟可使用OS.delay_msec
        OS.delay_msec(1000)  # 延迟1秒
        print("任务1完成")
        return "任务1结果"
    ,
    func(result):
        print("处理任务1结果: ", result)
)

single_thread.add_task(
    func():
        print("任务2开始")
        OS.delay_msec(1000)  # 延迟1秒
        print("任务2完成")
        return "任务2结果"
    ,
    func(result):
        print("处理任务2结果: ", result)
)
```

### 结合IO操作使用

```gdscript
# 用于文件操作的线程池
var io_thread_pool = ThreadPool.new(2)

# 异步读取文件
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

# 异步写入文件
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

## 最佳实践

1. **线程安全**
   - 始终使用互斥锁保护共享资源
   - 访问共享数据时避免竞态条件
   - 尽可能使用线程安全的数据结构

2. **错误处理**
   - 在任务中实现适当的错误处理
   - 使用task_error信号捕获和处理错误
   - 考虑为关键任务实现重试机制

3. **资源管理**
   - 仅在需要时保持线程池活动
   - 使用完线程池后始终调用stop()
   - 注意长时间运行的线程中的内存使用

4. **性能考虑**
   - 使用适当数量的线程（通常为CPU核心数）
   - 平衡任务粒度（不要太小也不要太大）
   - 在生产环境中监控线程池性能

## API参考

### ModuleThread（模块线程管理器）

- `add_task(name: StringName, function: Callable, callback: Callable, call_deferred: bool = true) -> void`：向命名线程添加任务
- `next_step(name: StringName) -> void`：在命名线程中推进到下一个任务
- `create_thread(name: StringName) -> SingleThread`：创建新的命名线程
- `has_thread(name: StringName) -> bool`：检查线程是否存在
- `get_thread(name: StringName) -> SingleThread`：按名称获取线程
- `get_thread_names() -> Array[StringName]`：获取所有线程名称
- `get_thread_count() -> int`：获取线程数量
- `clear_threads() -> void`：清空所有线程
- `unload_thread(name: StringName) -> void`：卸载特定线程

### SingleThread（单线程）

- `_init() -> void`：构造函数
- `add_task(task_function: Callable, task_callback: Callable = func(_result: Variant): pass, call_deferred: bool = true) -> void`：添加任务
- `next_step() -> void`：进入下一个任务
- `get_index() -> int`：获取当前任务索引
- `get_pending_task_count() -> int`：获取待处理任务数量
- `get_running_task_count() -> int`：获取运行中任务数量
- `clear_pending_tasks() -> void`：清空任务队列
- `stop() -> void`：停止线程工作

信号：
- `thread_finished`：所有任务完成时触发
- `task_completed(result, task_id)`：任务成功完成时触发
- `task_error(error, task_id)`：任务出错时触发

### ThreadPool（线程池）

- `_init(pool_size: int = 4) -> void`：带线程数的构造函数
- `submit_task(work_func: Callable, callback: Callable, priority: int = 0) -> String`：提交任务到池
- `stop(wait_for_completion: bool = false) -> void`：停止所有线程
- `get_pending_tasks() -> int`：获取待处理任务数量
- `clear_queue() -> int`：清空任务队列
- `get_thread_info() -> Array[Dictionary]`：获取线程状态信息
- `get_stats() -> Dictionary`：获取池统计信息
- `resize_pool(new_size: int) -> int`：更改池大小（只能增加）
