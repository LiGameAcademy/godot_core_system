extends Control

## 线程系统性能测试
## 比较同步处理与异步处理的性能

@onready var progress_bar = $MarginContainer/VBoxContainer/ProgressContainer/ProgressBar
@onready var fps_label = $MarginContainer/VBoxContainer/StatusContainer/FPSLabel
@onready var time_label = $MarginContainer/VBoxContainer/StatusContainer/TimeLabel
@onready var status_label = $MarginContainer/VBoxContainer/StatusContainer/StatusLabel
@onready var results_container = $MarginContainer/VBoxContainer/ScrollContainer/ResultsContainer

# 测试配置
const TEST_ITEMS_COUNT = 10000  # 测试数据量
const TASK_SPLITS = 4            # 多线程测试的任务分割数 (保留，供未来使用)

# 性能指标
var frame_counter = 0
var fps_update_time = 0.0
var current_fps = 0
var lowest_fps = 999
var test_start_time = 0
var test_running = false

var items = []

var completed_count : int = 0

func _ready():
	# 连接按钮信号 (暂时只保留同步测试)
	$MarginContainer/VBoxContainer/ButtonsContainer/SyncBtn.pressed.connect(_on_sync_test_pressed)
	# 可以在这里添加新的按钮和连接来触发 _run_async_test

	# 设置初始状态
	_reset_ui()

func _process(delta):
	# 更新FPS显示
	frame_counter += 1
	fps_update_time += delta

	if fps_update_time >= 0.5:  # 每0.5秒更新一次
		current_fps = frame_counter / fps_update_time
		fps_label.text = "FPS: %d" % current_fps

		# 记录测试期间的最低FPS
		if test_running and current_fps < lowest_fps:
			lowest_fps = current_fps

		frame_counter = 0
		fps_update_time = 0.0

## 重置UI状态
func _reset_ui() -> void:
	progress_bar.value = 0
	time_label.text = "时间: 0ms"
	status_label.text = "状态: 空闲"
	lowest_fps = 999
	items.clear() # 清空上次测试的数据

	# 清空结果容器
	for child in results_container.get_children():
		child.queue_free()

## 创建测试数据
func _create_test_data() -> void:
	items.clear() # 确保每次创建前清空
	for i in range(TEST_ITEMS_COUNT):
		items.append({
			"id": i,
			# "value": randf(), # 简化，移除不必要的数据
			# "vector": Vector3(randf(), randf(), randf()),
			# "name": "Item_%d" % i,
			# "matrix": [],
			"completed": false # 添加 completed 标志
		})

## 处理单个测试项（模拟耗时操作）
func _process_test_item(item: Dictionary) -> Dictionary:
	# 模拟文件操作延迟或其他耗时操作
	OS.delay_msec(1)

	# 注意：这里不修改 item["completed"]

	# 返回处理结果，只包含 ID
	return {
		"id": item.id
		# "computed_value": result, # 简化，移除不必要的数据
		# "processed_string": str_result,
		# "transformed_matrix": matrix_result
	}

## 添加结果到UI
func _add_result(label: String, time_ms: int, min_fps: float) -> void:
	var result_label = Label.new()
	result_label.text = "%s - 耗时: %dms, 最低FPS: %.1f" % [label, time_ms, min_fps]
	results_container.add_child(result_label)

## 1. 同步执行测试（在主线程上直接处理所有数据）
func _on_sync_test_pressed() -> void:
	_reset_ui()
	status_label.text = "状态: 执行同步测试..."
	test_running = true
	test_start_time = Time.get_ticks_msec()

	# 强制界面更新
	await get_tree().process_frame

	_create_test_data() # 创建数据
	var results = []

	# 直接在主线程处理所有数据
	for i in range(items.size()):
		var item = items[i]
		var result = _process_test_item(item)
		item["completed"] = true # 同步测试直接标记完成
		results.append(result)

		# 更新进度条 (简化，每处理100个更新一次)
		if i % 100 == 0:
			progress_bar.value = (float(i + 1) / items.size()) * 100
			status_label.text = "状态: 同步测试中 (%d/%d)" % [i + 1, items.size()]
			# 让界面有机会更新
			await get_tree().process_frame

	# 完成处理
	progress_bar.value = 100
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "时间: %dms" % total_time
	status_label.text = "状态: 同步测试完成 (%d个结果)" % results.size()

	_add_result("同步测试", total_time, lowest_fps)
	test_running = false


## --------------------------------------------------
##  异步测试
## --------------------------------------------------

## 通用的异步测试执行函数
func _run_async_test(thread_tool, test_name: String) -> void:
	_reset_ui()
	status_label.text = "状态: 执行 %s 测试..." % test_name
	test_running = true
	test_start_time = Time.get_ticks_msec()

	_create_test_data()
	var results = []

	# 1. 连接任务完成信号
	# 使用 bind() 传递 results 数组引用，避免闭包捕获
	thread_tool.task_completed.connect(_on_async_task_completed.bind(results))

	# 2. 批量添加任务
	for item in items:
		# 捕获 item 的副本以传递给 lambda
		var captured_item = item.duplicate() # 使用 duplicate 确保线程拿到的是独立副本
		thread_tool.add_task(func():
			# 线程内调用处理函数
			var result_data = _process_test_item(captured_item)
			# 返回包含 ID 的结果字典
			return { "id": captured_item.id, "data": result_data }
		)
	
	var items_size = items.size()
	# 3. 等待所有任务完成 (基于回调更新的 completed_count)
	while completed_count < items_size:
		status_label.text = "状态: %s 测试中 (%d/%d)" % [test_name, completed_count, items.size()]
		# 可以在这里添加基于 items 数组 completed 状态的检查作为备用或调试
		# var actual_completed = _count_actual_completed()
		progress_bar.value = float(completed_count) / float(items_size) * 100
		await get_tree().process_frame

	# 4. 停止线程/清理资源
	if thread_tool.has_method("stop"):
		thread_tool.stop()
	# elif thread_tool.has_method("clear_threads"): # 如果是 ModuleThread
	# 	thread_tool.clear_threads()

	# 5. 完成处理
	progress_bar.value = 100 # 确保进度条满
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "时间: %dms" % total_time
	status_label.text = "状态: %s 测试完成 (%d个结果)" % [test_name, results.size()]

	_add_result(test_name, total_time, lowest_fps)
	test_running = false

## 异步任务完成回调 (实例方法避免闭包问题)
func _on_async_task_completed(result_dict, task_id, results_array: Array) -> void:
	if not result_dict is Dictionary or not result_dict.has("id"):
		printerr("任务返回结果格式错误: ", result_dict)
		return

	var item_id = result_dict["id"]
	var item_data = result_dict.get("data") # 获取实际处理数据

	# 查找对应的 item 并标记完成
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			items[i]["completed"] = true
			break # 找到后退出循环

	results_array.append(item_data) # 将实际数据添加到结果数组
	
	completed_count += 1

## 示例：触发单线程测试
func _on_single_thread_btn_pressed() -> void:
	# 确保 simple_thread.gd 存在且路径正确
	# var simple_thread_script = load("res://addons/godot_core_system/test/threading/simple_thread.gd")
	var single_thread = CoreSystem.SingleThread.new()
	if single_thread:
		_run_async_test(single_thread, "单线程(简化)测试")
	else:
		printerr("无法加载 simple_thread.gd")

## 示例：如何使用框架测试 ModuleThread (需要更复杂的设置)
# func _on_module_thread_test_pressed():
#    # ... 创建 ModuleThread 实例 ...
#    # ... 创建 Worker 线程 ...
#    # ... 分配任务到不同 Worker ...
#    # ... 可能需要调整 _run_async_test 或创建专用函数 ...
#    pass
