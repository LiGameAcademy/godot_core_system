extends RefCounted

## 分帧执行器
## 用于将耗时操作分散到多帧执行，避免卡顿。
## 主要功能：
## 1. 自动分帧：将大量计算任务分散到多个帧中执行
## 2. 动态调整：根据实际执行时间动态调整每帧处理量
## 3. 进度反馈：提供进度信号，方便显示进度条
## 4. 多种处理模式：支持数组、范围、迭代器和自定义处理
##
## 使用示例:
## ```gdscript
## # 创建分帧执行器（可选择自定义每帧处理量和时间限制）
## var splitter = FrameSplitter.new(100, 10.0)
##
## # 处理数组
## await splitter.process_array(items, func(item): 
##     process_item(item)
## )
##
## # 处理数字范围
## await splitter.process_range(0, 1000, func(i): 
##     process_number(i)
## )
##
## # 使用迭代器
## await splitter.process_iterator(my_iterator, func(item):
##     process_item(item)
## , total_items)
##
## # 自定义批量处理
## await splitter.process_custom(total_work, func(start, end):
##     process_batch(start, end)
## )
## ```
##
## @tutorial(分帧执行器使用指南):
##     title: 分帧执行器使用指南
##     description: 学习如何使用分帧执行器来优化性能
##     link: docs/frame_splitter.md

## 进度变化信号，返回 0-1 之间的浮点数
signal progress_changed(progress: float)
## 处理完成信号
signal completed

## 每帧处理的默认数量
var items_pre_frame = 100
## 每帧默认最大执行时间（毫秒）
## 默认为 8ms，假设目标 60FPS (16.67ms)，留出足够余量给其他操作
var max_ms_pre_frame = 8.0

## 当前帧开始时间
var _frame_start_time: int = 0
## 当前帧已处理数量
var _frame_items: int = 0
## 当前每帧处理数量
var _current_items_per_frame: int = 0

## 构造函数
## [param p_items_per_frame] 每帧初始处理数量，默认100
## [param p_max_ms_per_frame] 每帧最大执行时间（毫秒），默认8ms
func _init(p_items_per_frame: int = items_pre_frame, p_max_ms_per_frame: float = max_ms_pre_frame) -> void:
	items_pre_frame = p_items_per_frame
	max_ms_pre_frame = p_max_ms_per_frame
	_current_items_per_frame = items_pre_frame

## 开始新的一帧，重置计数器
func _begin_frame() -> void:
	_frame_start_time = Time.get_ticks_msec()
	_frame_items = 0

## 检查是否应该结束当前帧
## 当达到以下条件之一时返回true：
## 1. 当前帧处理数量达到限制
## 2. 当前帧执行时间超过限制
func _should_end_frame() -> bool:
	return _frame_items >= _current_items_per_frame or \
		   (Time.get_ticks_msec() - _frame_start_time) >= max_ms_pre_frame

## 更新每帧处理数量
## 根据实际执行时间动态调整：
## 1. 如果执行时间过长，减少处理数量
## 2. 如果执行时间充裕，适当增加处理数量
func _update_items_per_frame() -> void:
	var frame_time = Time.get_ticks_msec() - _frame_start_time
	if frame_time > 0:
		if frame_time > max_ms_pre_frame:
			_current_items_per_frame = max(1, int(float(_frame_items) * max_ms_pre_frame / frame_time))
		elif frame_time < max_ms_pre_frame * 0.8:  # 留出20%余量
			_current_items_per_frame = min(_current_items_per_frame * 2, items_pre_frame)

## 等待下一帧
func _wait_next_frame() -> void:
	await CoreSystem.get_tree().process_frame

## 处理数组
## [param items] 要处理的数组
## [param process_func] 处理单个元素的函数，接收一个参数 (item)
## 示例：
## ```gdscript
## await process_array(items, func(item): print(item))
## ```
func process_array(items: Array, process_func: Callable) -> void:
	var total_items = items.size()
	var processed_items = 0
	
	while processed_items < total_items:
		_begin_frame()
		
		while processed_items < total_items and not _should_end_frame():
			process_func.call(items[processed_items])
			processed_items += 1
			_frame_items += 1
		
		_update_items_per_frame()
		progress_changed.emit(float(processed_items) / total_items)
		await _wait_next_frame()
	
	completed.emit()

## 处理数字范围
## [param start] 起始数字（包含）
## [param end] 结束数字（不包含）
## [param process_func] 处理单个数字的函数，接收一个参数 (i)
## 示例：
## ```gdscript
## await process_range(0, 1000, func(i): print(i))
## ```
func process_range(start: int, end: int, process_func: Callable) -> void:
	var total_items = end - start
	var processed_items = 0
	
	while processed_items < total_items:
		_begin_frame()
		
		while processed_items < total_items and not _should_end_frame():
			process_func.call(start + processed_items)
			processed_items += 1
			_frame_items += 1
		
		_update_items_per_frame()
		progress_changed.emit(float(processed_items) / total_items)
		await _wait_next_frame()
	
	completed.emit()

## 处理自定义迭代器
## [param iterator] 自定义迭代器对象，必须实现has_next()和next()方法
## [param process_func] 处理单个元素的函数，接收一个参数 (item)
## [param total_items] 总项目数（用于进度计算）
## 示例：
## ```gdscript
## await process_iterator(my_iterator, func(item): print(item), total_items)
## ```
func process_iterator(iterator, process_func: Callable, total_items: int) -> void:
	var processed_items = 0
	
	while iterator.has_next() and processed_items < total_items:
		_begin_frame()
		
		while iterator.has_next() and processed_items < total_items and not _should_end_frame():
			process_func.call(iterator.next())
			processed_items += 1
			_frame_items += 1
		
		_update_items_per_frame()
		progress_changed.emit(float(processed_items) / total_items)
		await _wait_next_frame()
	
	completed.emit()

## 自定义执行
## [param total_work] 总工作量
## [param work_func] 执行工作的函数，接收起始索引和结束索引两个参数
## 示例：
## ```gdscript
## await process_custom(total_work, func(start, end): print("Processing from %d to %d" % [start, end]))
## ```
func process_custom(total_work: int, work_func: Callable) -> void:
	var processed_work = 0
	
	while processed_work < total_work:
		_begin_frame()
		
		var frame_work = min(_current_items_per_frame, total_work - processed_work)
		work_func.call(processed_work, processed_work + frame_work)
		_frame_items = frame_work
		
		_update_items_per_frame()
		processed_work += frame_work
		progress_changed.emit(float(processed_work) / total_work)
		await _wait_next_frame()
	
	completed.emit()
