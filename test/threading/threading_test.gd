extends Control

## 线程系统性能测试
## 比较三种数据处理方式：
## 1. 同步处理 - 在主线程上直接处理所有数据
## 2. 单线程异步 - 使用SingleThread处理数据
## 3. 模块线程多任务 - 使用ModuleThread将任务分配到多个命名线程

@onready var progress_bar = $MarginContainer/VBoxContainer/ProgressContainer/ProgressBar
@onready var fps_label = $MarginContainer/VBoxContainer/StatusContainer/FPSLabel
@onready var time_label = $MarginContainer/VBoxContainer/StatusContainer/TimeLabel
@onready var status_label = $MarginContainer/VBoxContainer/StatusContainer/StatusLabel
@onready var results_container = $MarginContainer/VBoxContainer/ScrollContainer/ResultsContainer

# 测试配置
const TEST_ITEMS_COUNT = 100000  # 测试数据量
const TASK_SPLITS = 4            # 多线程测试的任务分割数
const WORKERS = ["计算任务", "字符串处理", "矩阵运算", "文件模拟"]  # 多线程工作器名称

# 性能指标
var frame_counter = 0
var fps_update_time = 0.0
var current_fps = 0
var lowest_fps = 999
var test_start_time = 0
var test_running = false
var module_thread = null

func _ready():
	# 连接按钮信号
	$MarginContainer/VBoxContainer/ButtonsContainer/SyncBtn.pressed.connect(_on_sync_test_pressed)
	$MarginContainer/VBoxContainer/ButtonsContainer/SingleThreadBtn.pressed.connect(_on_single_thread_test_pressed)
	$MarginContainer/VBoxContainer/ButtonsContainer/ModuleThreadBtn.pressed.connect(_on_module_thread_test_pressed)
	
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
	
	# 清空结果容器
	for child in results_container.get_children():
		child.queue_free()

## 创建测试数据
func _create_test_data() -> Array:
	var items = []
	for i in range(TEST_ITEMS_COUNT):
		items.append({
			"id": i,
			"value": randf(),
			"vector": Vector3(randf(), randf(), randf()),
			"name": "Item_%d" % i,
			"matrix": [
				[randf(), randf(), randf()],
				[randf(), randf(), randf()],
				[randf(), randf(), randf()]
			]
		})
	return items

## 处理单个测试项（CPU密集型操作）
func _process_test_item(item: Dictionary) -> Dictionary:
	# 模拟复杂的计算处理
	var result = 0.0
	for j in range(10):
		result += pow(sin(item.value * j), 2) + pow(cos(item.value * j), 2)
		result *= pow(2.0, sin(j)) + log(max(1, j))
	
	# 字符串处理
	var str_result = ""
	for j in range(5):
		str_result += "%s_%f_" % [item.name, result + j]
	
	# 矩阵运算
	var matrix_result = []
	for row in item.matrix:
		var new_row = []
		for val in row:
			new_row.append(val * result / (1.0 + randf()))
		matrix_result.append(new_row)
	
	# 模拟文件操作延迟
	OS.delay_msec(1)
	
	return {
		"id": item.id,
		"computed_value": result,
		"processed_string": str_result,
		"transformed_matrix": matrix_result
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
	
	var items = _create_test_data()
	var results = []
	
	# 直接在主线程处理所有数据
	for i in range(items.size()):
		var result = _process_test_item(items[i])
		results.append(result)
		
		# 更新进度条
		if i % 100 == 0:
			progress_bar.value = (float(i) / items.size()) * 100
			# 让界面有机会更新
			await get_tree().process_frame
	
	# 完成处理
	progress_bar.value = 100
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "时间: %dms" % total_time
	status_label.text = "状态: 同步测试完成 (%d个结果)" % results.size()
	
	_add_result("同步测试", total_time, lowest_fps)
	test_running = false

## 2. 单线程异步测试（使用SingleThread在后台处理）
func _on_single_thread_test_pressed() -> void:
	_reset_ui()
	status_label.text = "状态: 执行单线程测试..."
	test_running = true
	test_start_time = Time.get_ticks_msec()
	
	var items = _create_test_data()
	var progress_count = 0
	var results = []
	
	# 创建单线程工作器
	var single_thread = CoreSystem.SingleThread.new()
	
	# 批量添加任务到单线程
	for item in items:
		single_thread.add_task(
			func():
				return _process_test_item(item),
			func(result):
				results.append(result)
				progress_count += 1
				progress_bar.value = (float(progress_count) / items.size()) * 100
		)
	
	# 等待所有任务完成
	while progress_count < items.size():
		status_label.text = "状态: 单线程测试中 (%d/%d)" % [progress_count, items.size()]
		await get_tree().process_frame
	
	# 停止线程
	single_thread.stop()
	
	# 完成处理
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "时间: %dms" % total_time
	status_label.text = "状态: 单线程测试完成 (%d个结果)" % results.size()
	
	_add_result("单线程异步测试", total_time, lowest_fps)
	test_running = false

## 3. 模块线程多任务测试（使用ModuleThread将任务分配到多个命名线程）
func _on_module_thread_test_pressed() -> void:
	_reset_ui()
	status_label.text = "状态: 执行模块线程测试..."
	test_running = true
	test_start_time = Time.get_ticks_msec()
	
	var items = _create_test_data()
	var chunk_size = items.size() / TASK_SPLITS
	var progress_count = 0
	var results = []
	
	# 创建模块线程管理器
	module_thread = CoreSystem.ModuleThread.new()
	
	# 为每个工作类型创建专用线程
	for worker_name in WORKERS:
		var thread = module_thread.create_thread(worker_name)
		
		# 连接完成信号
		thread.task_completed.connect(
			func(result, _task_id):
				results.append_array(result)
				progress_count += 1
				progress_bar.value = (float(progress_count) / TASK_SPLITS) * 100
		)
	
	# 分割任务并分配给不同的命名线程
	for i in range(TASK_SPLITS):
		var start_idx = i * chunk_size
		var end_idx = start_idx + chunk_size if i < TASK_SPLITS - 1 else items.size()
		var chunk = items.slice(start_idx, end_idx)
		
		# 分配任务到对应工作线程
		var worker_name = WORKERS[i % WORKERS.size()]
		
		module_thread.submit_task(
			worker_name,
			func():
				var chunk_results = []
				for item in chunk:
					chunk_results.append(_process_test_item(item))
				return chunk_results,
			func(_result):
				# 回调在task_completed信号中处理
				pass
		)
	
	# 等待所有任务完成
	while progress_count < TASK_SPLITS:
		status_label.text = "状态: 模块线程测试中 (%d/%d)" % [progress_count, TASK_SPLITS]
		await get_tree().process_frame
	
	# 清理线程
	module_thread.clear_threads()
	module_thread = null
	
	# 完成处理
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "时间: %dms" % total_time
	status_label.text = "状态: 模块线程测试完成 (%d个结果)" % results.size()
	
	_add_result("模块线程多任务测试", total_time, lowest_fps)
	test_running = false
