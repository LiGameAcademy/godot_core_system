extends Node

# 测试配置
const STRESS_TEST_SIZES := [100, 500, 1000, 5000, 10000, 100000]
const STRESS_TEST_COUNT := 1000

var _random_pool : RefCounted

var default_items: Array = [
	["sword", 10],
	["shield", 8],
	["potion", 15],
	["key", 1],
	{"data": "gem", "weight": 5}
]

func _ready() -> void:
	_test_edge_cases()
	await get_tree().create_timer(0.5).timeout
	_test_basic_functionality()
	await get_tree().create_timer(0.5).timeout
	_test_dynamic_changes()
	await get_tree().create_timer(0.5).timeout
	_test_stress_performance()

# 边界条件测试
func _test_edge_cases() -> void:
	print("\n=== 开始边界条件测试 ===")
	
	# 测试空池
	var empty_pool = _create_test_pool([])
	assert(empty_pool.get_random_item() == null, "空池应返回null")
	print("✓ 空池处理正常")
	
	# 测试无效权重
	var invalid_pool = _create_test_pool([["broken_sword", -5]])
	assert(invalid_pool.get_remaining_count() == 0, "负权重项不应被添加")
	print("✓ 负权重处理正常")
	
	# 测试零权重
	var zero_pool = _create_test_pool([["phantom_item", 0]])
	assert(zero_pool.get_remaining_count() == 0, "零权重项不应被添加")
	print("✓ 零权重处理正常")
	
	# 测试重复项处理
	var dup_pool = _create_test_pool([["apple", 1], ["apple", 1]])
	assert(dup_pool.get_remaining_count() == 1, "重复项未正确合并")
	print("✓ 重复项处理正常")
	
	print("=== 边界测试通过 ===")

# 基础功能测试
func _test_basic_functionality() -> void:
	print("\n=== 开始基础功能测试 ===")
	_random_pool = _create_test_pool(default_items)
	
	# 初始状态验证
	assert(_random_pool.get_remaining_count() == 5, "初始数量错误")
	assert(_random_pool.get_item_weight("key") == 1.0, "权重查询错误")
	print("✓ 初始状态正常")
	
	# 随机性验证
	var items := []
	for _i in 50:
		items.append(_random_pool.get_random_item())
	assert(items.any(func(x): return x != items[0]), "随机性不足")
	print("✓ 随机性基础验证")
	
	# 权重分布验证
	var distribution := {}
	for _i in 10000:
		var item = _random_pool.get_random_item()
		distribution[item] = distribution.get(item, 0) + 1
	
	var expected_ratio := {
		"sword": 10.0/39,
		"shield": 8.0/39,
		"potion": 15.0/39,
		"key": 1.0/39,
		"gem": 5.0/39
	}
	
	for item in distribution:
		var actual = distribution[item]/10000.0
		var expected = expected_ratio[item]
		assert(abs(actual - expected) < 0.02, "权重分布异常: %s" % item)
	print("✓ 权重分布合理")

	_random_pool.update_item_weight("potion", 20.0)
	assert(_random_pool.get_item_weight("potion") == 20.0, "权重更新失败")
	print("✓ 权重更新功能正常")

	# 新增批量更新测试（混合格式）
	print("-- 批量权重更新测试 --")
	var update_data := [
		["sword", 20.0],          # 数组格式
		{"data": "potion", "weight": 25.0},  # 字典格式
		["invalid_item", 5.0]     # 不存在项
	]
	var updated_count = _random_pool.update_items_weights(update_data)
	assert(updated_count == 2, "批量更新计数错误（预期2，实际%d）" % updated_count)
	assert(_random_pool.get_item_weight("sword") == 20.0, "sword权重更新失败")
	assert(_random_pool.get_item_weight("potion") == 25.0, "potion权重更新失败")
	print("✓ 批量权重更新格式兼容性验证通过")

	print("=== 基础测试通过 ===")

var picked_count := 0
# 动态变动测试
func _test_dynamic_changes() -> void:
	print("\n=== 开始动态变动测试 ===")
	_random_pool = _create_test_pool(default_items)
	
	# 信号测试
	picked_count = 0
	_random_pool.item_picked.connect(func(_x:Variant): 
		picked_count += 1
		)
	_random_pool.pool_emptied.connect(func(): print("★ 池子清空信号触发"))
	
	# 动态操作序列
	_random_pool.add_item("dragon_sword", 5.0)
	_random_pool.remove_item("shield")
	_random_pool.add_items([["scroll", 3], {"data": "ring", "weight": 2}])
	
	# 混合操作验证
	assert(_random_pool.get_remaining_count() == 7, "动态操作后数量异常")
	assert(picked_count == 0, "未预期信号触发")
	
	# 清空测试
	while not _random_pool.is_empty():
		_random_pool.get_random_item(true)
	assert(picked_count == 7, "信号触发次数错误")
	print("✓ 动态操作与信号正常")
	
	print("=== 动态测试通过 ===")

# 压力性能测试
func _test_stress_performance() -> void:
	print("\n=== 开始压力性能测试 ===")
	
	for size in STRESS_TEST_SIZES:
		# 数据生成
		var test_data := []
		for i in size:
			test_data.append({"data": "item_%d" % i, "weight": randf_range(0.1, 10.0)})
		# 从池创建前开始计时
		var start_time := Time.get_ticks_usec()
		# 池创建
		var pool = _create_test_pool(test_data)
		var create_time := float(Time.get_ticks_usec() - start_time) / 1000.0
		print("\n▶ 数据规模: %d" % size)
		print("创建耗时: %.2f ms" % create_time)
		
		# 随机访问测试
		start_time = Time.get_ticks_usec()
		for _i in STRESS_TEST_COUNT:
			pool.get_random_item()
		var access_time := float(Time.get_ticks_usec() - start_time) / 1000.0
		print("抽取 %d 次耗时: %.2f ms (平均 %.4f ms/次)" % [
			STRESS_TEST_COUNT,
			access_time,
			access_time / STRESS_TEST_COUNT
		])
		
		# 内存清理
		pool.clear()
	
	print("=== 压力测试完成 ===")

# 创建测试池
func _create_test_pool(items: Array) -> RefCounted:
	return CoreSystem.RandomPicker.new(items)
