extends Node

const RandomPicker = CoreSystem.RandomPicker

var _logger: CoreSystem.Logger = CoreSystem.logger
var _picker : RandomPicker

func _ready() -> void:
	run_all_tests()

## 运行所有测试
func run_all_tests() -> void:
	test_constructor()
	test_basic_operations()
	test_array_format_items()
	test_arr_format_items()
	test_dict_format_items()
	test_invalid_items()
	test_weight_distribution()
	test_remove_and_clear()
	_logger.info("所有测试完成")

## 测试构造函数
func test_constructor() -> void:
	# 测试空构造
	_picker = RandomPicker.new()
	assert(_picker.is_empty())
	
	# 测试数组格式初始化
	var array_items := [
		["test1", 12.0],
		["test2", 22.0],
		["test3", 22.0],
		["test4", 22.0]
	]
	_picker = RandomPicker.new(array_items)
	assert(_picker.get_remaining_count() == 4)
	
	# 测试字典格式初始化
	var dict_items := [
		{"data": "test1", "weight": 12.0},
		{"data": "test2", "weight": 22.0}
	]
	_picker = RandomPicker.new(dict_items)
	assert(_picker.get_remaining_count() == 2)
	
	_logger.info("构造函数测试通过")

## 测试基本操作
func test_basic_operations() -> void:
	_picker = RandomPicker.new()
	
	# 测试添加单个物品
	assert(_picker.add_item("测试物品1", 1.0))
	assert(_picker.get_remaining_count() == 1)
	assert(_picker.has_item("测试物品1"))
	
	# 测试非法权重
	assert(not _picker.add_item("测试物品2", -1.0))
	assert(not _picker.add_item("测试物品3", 0.0))
	
	_logger.info("基本操作测试通过")

## 测试数组格式批量添加
func test_array_format_items() -> void:
	_picker = RandomPicker.new()
	
	var items := [
		["物品1", 1.0],
		["物品2", 2.0],
		["物品3", 3.0]
	]
	_picker.add_items(items)
	assert(_picker.get_remaining_count() == 3)
	
	# 测试格式错误的数组
	var invalid_items := [
		["物品4"],  # 缺少权重
		["物品5", "非数字权重"],  # 错误的权重类型
		[]  # 空数组
	]
	_picker.add_items(invalid_items)
	assert(_picker.get_remaining_count() == 3)  # 不应该增加
	
	_logger.info("数组格式批量添加测试通过")

## 测试数组批量添加
func test_arr_format_items() -> void:
	_picker = RandomPicker.new([
		["数组物品1", 1.0],
		["数组物品2", 2]
	])
	assert(_picker.get_remaining_count() == 2)
	
	_picker.add_items([
		["数组物品3", 3],
		["数组物品4", 2]
	])
	assert(_picker.get_remaining_count() == 4)
	
	# 测试格式错误的字典
	var invalid_items := [
		["数组物品5"],
		["数组物品6", "2"]
	]
	_picker.add_items(invalid_items)
	assert(_picker.get_remaining_count() == 4)  # 不应该增加
	
	_logger.info("数组格式批量添加测试通过")

## 测试字典格式批量添加
func test_dict_format_items() -> void:
	_picker = RandomPicker.new()
	
	var items := [
		{"data": "字典物品1", "weight": 1.0},
		{"data": "字典物品2", "weight": 2.0}
	]
	_picker.add_items(items)
	assert(_picker.get_remaining_count() == 2)
	
	# 测试格式错误的字典
	var invalid_items := [
		{"data": "物品3"},  # 缺少weight字段
		{"weight": 1.0},  # 缺少data字段
		{}  # 空字典
	]
	_picker.add_items(invalid_items)
	assert(_picker.get_remaining_count() == 2)  # 不应该增加
	
	_logger.info("字典格式批量添加测试通过")

## 测试无效数据处理
func test_invalid_items() -> void:
	_picker = RandomPicker.new()
	
	# 测试混合格式
	var mixed_items := [
		["数组物品", 1.0],
		{"data": "字典物品", "weight": 2.0},
		"无效物品",  # 无效格式
		42  # 无效格式
	]
	_picker.add_items(mixed_items)
	assert(_picker.get_remaining_count() == 2)  # 只有两个有效项
	
	_logger.info("无效数据处理测试通过")

## 测试权重分布
func test_weight_distribution() -> void:
	_picker = RandomPicker.new()
	
	# 添加测试物品
	_picker.add_items([
		["高权重", 100.0],
		["低权重", 1.0]
	])
	
	var high_count := 0
	var low_count := 0
	var total_tests := 1000
	
	# 进行多次随机测试
	for i in range(total_tests):
		var item = _picker.get_random_item(false)
		if item == "高权重":
			high_count += 1
		elif item == "低权重":
			low_count += 1
	
	# 验证权重比例（允许10%的误差）
	var expected_ratio := 100.0 / 101.0
	var actual_ratio := float(high_count) / total_tests
	assert(abs(actual_ratio - expected_ratio) < 0.1)
	
	_logger.info("权重分布测试通过")

## 测试移除和清空
func test_remove_and_clear() -> void:
	_picker = RandomPicker.new()
	
	# 添加测试物品
	_picker.add_items([
		["物品1", 1.0],
		["物品2", 2.0],
		["物品3", 3.0]
	])
	
	# 测试移除
	assert(_picker.remove_item("物品2"))
	assert(_picker.get_remaining_count() == 2)
	assert(not _picker.has_item("物品2"))
	
	# 测试移除不存在的物品
	assert(not _picker.remove_item("不存在"))
	
	# 测试清空
	_picker.clear()
	assert(_picker.is_empty())
	assert(_picker.get_remaining_count() == 0)
	
	_logger.info("移除和清空测试通过")
