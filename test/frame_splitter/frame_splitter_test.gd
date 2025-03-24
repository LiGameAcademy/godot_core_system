extends Node2D

@onready var progress_bar = $ProgressBar
@onready var fps_label = $FPSLabel
@onready var time_label = $TimeLabel

var frame_counter = 0
var fps_update_time = 0.0
var current_fps = 0
var test_start_time = 0

func _ready():
	$NormalBtn.pressed.connect(_on_normal_test_pressed)
	$FrameSplitBtn.pressed.connect(_on_frame_split_test_pressed)

func _process(delta):
	# 更新FPS显示
	frame_counter += 1
	fps_update_time += delta
	if fps_update_time >= 1.0:
		current_fps = frame_counter
		fps_label.text = "FPS: %d" % current_fps
		frame_counter = 0
		fps_update_time = 0.0

## 创建测试数据
func _create_test_data() -> Array:
	var items = []
	for i in range(1000000):  # 100万个测试项
		items.append({
			"id": i,
			"value": randf(),
			"name": "Item_%d" % i
		})
	return items

## 处理单个测试项
func _process_test_item(item: Dictionary) -> void:
	# 模拟复杂的处理逻辑
	var result = 0.0
	for j in range(5):  # 增加每项的处理复杂度
		result += pow(sin(item.value * j), 2) + pow(cos(item.value * j), 2)
		result *= pow(2.0, sin(j)) + log(max(1, j))
	
	# 字符串操作
	var str_result = "%s_%f" % [item.name, result]
	str_result = str_result.pad_zeros(20)

## 普通执行测试（不使用分帧）
func _on_normal_test_pressed() -> void:
	progress_bar.value = 0
	time_label.text = "Time: 0ms"
	test_start_time = Time.get_ticks_msec()
	
	var items = _create_test_data()
	
	# 直接在一帧内处理所有数据
	for i in range(items.size()):
		_process_test_item(items[i])
		if i % 1000 == 0:  # 更新进度
			progress_bar.value = (float(i) / items.size()) * 100
	
	progress_bar.value = 100
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "Time: %dms" % total_time

## 分帧执行测试
func _on_frame_split_test_pressed() -> void:
	progress_bar.value = 0
	time_label.text = "Time: 0ms"
	test_start_time = Time.get_ticks_msec()
	
	var items = _create_test_data()
	
	# 创建分帧执行器（每帧最多执行10ms）
	var splitter = CoreSystem.FrameSplitter.new(100, 10.0)
	
	# 连接进度信号
	splitter.progress_changed.connect(func(p): progress_bar.value = p * 100)
	
	# 使用分帧执行器处理数据
	await splitter.process_array(items, _process_test_item)
	
	var total_time = Time.get_ticks_msec() - test_start_time
	time_label.text = "Time: %dms" % total_time
