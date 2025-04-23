# AsyncIOTest.gd
extends Control

# --- 引用 ---
const AsyncIOManager = preload("res://addons/godot_core_system/source/utils/async_io_manager.gd")
const JSONSerializationStrategy = preload("res://addons/godot_core_system/source/utils/io_strategies/serialization/json_serialization_strategy.gd")
const GzipCompressionStrategy = preload("res://addons/godot_core_system/source/utils/io_strategies/compression/gzip_compression_strategy.gd")
const XOREncryptionStrategy = preload("res://addons/godot_core_system/source/utils/io_strategies/encryption/xor_encryption_strategy.gd")

# --- UI 节点 ---
@onready var log_label: RichTextLabel = $VBoxContainer/LogLabel
@onready var test_basic_btn: Button = $VBoxContainer/TestBasicBtn
@onready var test_compress_btn: Button = $VBoxContainer/TestCompressBtn
@onready var test_encrypt_btn: Button = $VBoxContainer/TestEncryptBtn
@onready var test_all_btn: Button = $VBoxContainer/TestAllBtn
@onready var clear_log_btn: Button = $VBoxContainer/ClearLogBtn

# --- 测试配置 ---
const TEST_DIR = "user://async_io_test/"
const BASIC_FILE = TEST_DIR + "basic_test.json"
const COMPRESS_FILE = TEST_DIR + "compress_test.json.gz"
const ENCRYPT_FILE = TEST_DIR + "encrypt_test.xor"
const ALL_FILE = TEST_DIR + "all_strategies.dat"
const ENCRYPTION_KEY = "my_secret_key"

var test_data := {
	"name": "AsyncIO Test",
	"version": 1.0,
	"data": [1.0, 2.0, 3.0, "hello", {"nested": true}], # 改为浮点数
	"timestamp": Time.get_unix_time_from_system()
}

# --- 状态 ---
var io_manager_default: AsyncIOManager
var io_manager_compress: AsyncIOManager
var io_manager_encrypt: AsyncIOManager
var io_manager_all: AsyncIOManager
var is_testing := false

func _ready() -> void:
	# 确保测试目录存在
	DirAccess.make_dir_recursive_absolute(TEST_DIR)

	# 初始化不同配置的 IO 管理器实例
	io_manager_default = AsyncIOManager.new() # JSON, NoCompress, NoEncrypt
	io_manager_compress = AsyncIOManager.new(
		JSONSerializationStrategy.new(),
		GzipCompressionStrategy.new()
	)
	io_manager_encrypt = AsyncIOManager.new(
		JSONSerializationStrategy.new(),
		null, # No Compression
		XOREncryptionStrategy.new()
	)
	io_manager_all = AsyncIOManager.new(
		JSONSerializationStrategy.new(),
		GzipCompressionStrategy.new(),
		XOREncryptionStrategy.new()
	)

	# 连接按钮信号
	test_basic_btn.pressed.connect(_run_basic_test)
	test_compress_btn.pressed.connect(_run_compress_test)
	test_encrypt_btn.pressed.connect(_run_encrypt_test)
	test_all_btn.pressed.connect(_run_all_strategies_test)
	clear_log_btn.pressed.connect(log_label.clear)

	_log("测试场景准备就绪。")

# --- 日志函数 ---
func _log(message: String, type: String = "info") -> void:
	var color = "white"
	match type:
		"success": color = "lime"
		"error": color = "red"
		"warning": color = "yellow"
		"title": color = "aqua"
	log_label.add_text("[color=%s]%s[/color]\n" % [color, message])
	print(message) # 同时打印到控制台

func _set_buttons_disabled(disabled: bool) -> void:
	test_basic_btn.disabled = disabled
	test_compress_btn.disabled = disabled
	test_encrypt_btn.disabled = disabled
	test_all_btn.disabled = disabled
	is_testing = disabled

# --- 异步等待辅助函数 ---
# 等待特定的 IO 任务完成
func _await_io_task(io_manager: AsyncIOManager, task_id: String) -> Dictionary:
	var result_data := {"success": false, "result": null}
	var signal_result = await io_manager.io_completed
	# signal_result 是一个数组 [received_task_id, received_success, received_result]
	if signal_result.size() == 3:
		if signal_result[0] == task_id:
			result_data.success = signal_result[1]
			result_data.result = signal_result[2]
		else:
			_log("错误：收到的信号 Task ID (%s) 与预期的 (%s) 不符！" % [signal_result[0], task_id], "error")
			result_data.result = {"error": "Task ID mismatch"}
	else:
		_log("错误：收到的 io_completed 信号格式不正确: %s" % str(signal_result), "error")
		result_data.result = {"error": "Incorrect signal format"}
	return result_data

# --- 测试函数 ---

# 测试基础读写 (JSON, NoCompress, NoEncrypt)
func _run_basic_test() -> void:
	if is_testing: return
	_set_buttons_disabled(true)
	_log("--- 开始基础测试 ---", "title")

	# 1. 写入
	_log("1. 尝试写入文件: %s" % BASIC_FILE)
	var write_task_id = io_manager_default.write_file_async(BASIC_FILE, test_data)
	var write_result = await _await_io_task(io_manager_default, write_task_id)
	assert(write_result.success, "基础写入失败！")
	if write_result.success:
		_log("   写入成功。", "success")
	else:
		_log("   写入失败: %s" % str(write_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 2. 读取
	_log("2. 尝试读取文件: %s" % BASIC_FILE)
	var read_task_id = io_manager_default.read_file_async(BASIC_FILE)
	var read_result = await _await_io_task(io_manager_default, read_task_id)
	assert(read_result.success, "基础读取失败！")
	if read_result.success:
		_log("   读取成功。", "success")
		# 比较数据 (注意：JSON 可能改变字典顺序，需要更健壮的比较)
		assert(read_result.result == test_data, "基础读写数据不一致！ %s vs %s" % [str(read_result.result), str(test_data)])
		if read_result.result == test_data:
			_log("   数据验证成功。", "success")
		else:
			_log("   数据验证失败！", "error")
			_log("      读取: %s" % str(read_result.result))
			_log("      原始: %s" % str(test_data))
	else:
		_log("   读取失败: %s" % str(read_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 3. 删除
	_log("3. 尝试删除文件: %s" % BASIC_FILE)
	var delete_task_id = io_manager_default.delete_file_async(BASIC_FILE)
	var delete_result = await _await_io_task(io_manager_default, delete_task_id)
	assert(delete_result.success, "基础删除失败！")
	if delete_result.success:
		_log("   删除成功。", "success")
		# 验证文件是否真的不存在
		assert(not FileAccess.file_exists(BASIC_FILE), "基础删除后文件仍然存在！")
		if not FileAccess.file_exists(BASIC_FILE):
			_log("   文件确认已删除。", "success")
		else:
			_log("   删除后文件仍然存在！", "error")
	else:
		_log("   删除失败: %s" % str(delete_result.result), "error")

	_log("--- 基础测试完成 ---", "title")
	_set_buttons_disabled(false)

# 测试带压缩的读写 (JSON, Gzip, NoEncrypt)
func _run_compress_test() -> void:
	if is_testing: return
	_set_buttons_disabled(true)
	_log("--- 开始压缩测试 ---", "title")

	# 1. 写入 (压缩)
	_log("1. 尝试写入压缩文件: %s" % COMPRESS_FILE)
	var write_task_id = io_manager_compress.write_file_async(COMPRESS_FILE, test_data)
	var write_result = await _await_io_task(io_manager_compress, write_task_id)
	assert(write_result.success, "压缩写入失败！")
	if write_result.success: _log("   写入成功。", "success")
	else:
		_log("   写入失败: %s" % str(write_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 2. 读取 (解压)
	_log("2. 尝试读取压缩文件: %s" % COMPRESS_FILE)
	var read_task_id = io_manager_compress.read_file_async(COMPRESS_FILE)
	var read_result = await _await_io_task(io_manager_compress, read_task_id)
	assert(read_result.success, "压缩读取失败！")
	if read_result.success:
		_log("   读取成功。", "success")
		assert(read_result.result == test_data, "压缩读写数据不一致！")
		if read_result.result == test_data: _log("   数据验证成功。", "success")
		else: _log("   数据验证失败！", "error")
	else:
		_log("   读取失败: %s" % str(read_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 3. 删除
	_log("3. 尝试删除文件: %s" % COMPRESS_FILE)
	var delete_task_id = io_manager_compress.delete_file_async(COMPRESS_FILE)
	var delete_result = await _await_io_task(io_manager_compress, delete_task_id)
	assert(delete_result.success, "压缩删除失败！")
	if delete_result.success: _log("   删除成功。", "success")
	else: _log("   删除失败: %s" % str(delete_result.result), "error")

	_log("--- 压缩测试完成 ---", "title")
	_set_buttons_disabled(false)

# 测试带加密的读写 (JSON, NoCompress, XOR)
func _run_encrypt_test() -> void:
	if is_testing: return
	_set_buttons_disabled(true)
	_log("--- 开始加密测试 ---", "title")

	# 1. 写入 (加密)
	_log("1. 尝试写入加密文件: %s" % ENCRYPT_FILE)
	var write_task_id = io_manager_encrypt.write_file_async(ENCRYPT_FILE, test_data, ENCRYPTION_KEY)
	var write_result = await _await_io_task(io_manager_encrypt, write_task_id)
	assert(write_result.success, "加密写入失败！")
	if write_result.success: _log("   写入成功。", "success")
	else:
		_log("   写入失败: %s" % str(write_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 2. 读取 (解密)
	_log("2. 尝试读取加密文件: %s" % ENCRYPT_FILE)
	var read_task_id = io_manager_encrypt.read_file_async(ENCRYPT_FILE, ENCRYPTION_KEY)
	var read_result = await _await_io_task(io_manager_encrypt, read_task_id)
	assert(read_result.success, "加密读取失败！")
	if read_result.success:
		_log("   读取成功。", "success")
		assert(read_result.result == test_data, "加密读写数据不一致！")
		if read_result.result == test_data: _log("   数据验证成功。", "success")
		else: _log("   数据验证失败！", "error")
	else:
		_log("   读取失败: %s" % str(read_result.result), "error")
		# 尝试用错误的密钥读取
		_log("   尝试用错误密钥读取...")
		read_task_id = io_manager_encrypt.read_file_async(ENCRYPT_FILE, "wrong_key")
		read_result = await _await_io_task(io_manager_encrypt, read_task_id)
		assert(read_result.success, "用错误密钥读取未失败！(可能策略未报错)") # 简单的XOR可能不会失败，但数据会错
		if read_result.success:
			_log("     读取成功（数据可能错误）: %s" % str(read_result.result), "warning")
			assert(read_result.result != test_data, "错误密钥读取数据竟然一致！")
			if read_result.result != test_data: _log("     数据确认不一致。", "success")
			else: _log("     错误密钥读取数据一致！", "error")
		else:
			_log("     读取失败（符合预期）: %s" % str(read_result.result), "success")

		_set_buttons_disabled(false)
		# return # 可以选择在这里停止或继续删除

	# 3. 删除
	_log("3. 尝试删除文件: %s" % ENCRYPT_FILE)
	var delete_task_id = io_manager_encrypt.delete_file_async(ENCRYPT_FILE)
	var delete_result = await _await_io_task(io_manager_encrypt, delete_task_id)
	assert(delete_result.success, "加密删除失败！")
	if delete_result.success: _log("   删除成功。", "success")
	else: _log("   删除失败: %s" % str(delete_result.result), "error")

	_log("--- 加密测试完成 ---", "title")
	_set_buttons_disabled(false)


# 测试所有策略组合 (JSON, Gzip, XOR)
func _run_all_strategies_test() -> void:
	if is_testing: return
	_set_buttons_disabled(true)
	_log("--- 开始组合策略测试 ---", "title")

	# 1. 写入 (压缩+加密)
	_log("1. 尝试写入组合策略文件: %s" % ALL_FILE)
	var write_task_id = io_manager_all.write_file_async(ALL_FILE, test_data, ENCRYPTION_KEY)
	var write_result = await _await_io_task(io_manager_all, write_task_id)
	assert(write_result.success, "组合策略写入失败！")
	if write_result.success: _log("   写入成功。", "success")
	else:
		_log("   写入失败: %s" % str(write_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 2. 读取 (解密+解压)
	_log("2. 尝试读取组合策略文件: %s" % ALL_FILE)
	var read_task_id = io_manager_all.read_file_async(ALL_FILE, ENCRYPTION_KEY)
	var read_result = await _await_io_task(io_manager_all, read_task_id)
	assert(read_result.success, "组合策略读取失败！")
	if read_result.success:
		_log("   读取成功。", "success")
		assert(read_result.result == test_data, "组合策略读写数据不一致！")
		if read_result.result == test_data: _log("   数据验证成功。", "success")
		else: _log("   数据验证失败！", "error")
	else:
		_log("   读取失败: %s" % str(read_result.result), "error")
		_set_buttons_disabled(false)
		return

	# 3. 删除
	_log("3. 尝试删除文件: %s" % ALL_FILE)
	var delete_task_id = io_manager_all.delete_file_async(ALL_FILE)
	var delete_result = await _await_io_task(io_manager_all, delete_task_id)
	assert(delete_result.success, "组合策略删除失败！")
	if delete_result.success: _log("   删除成功。", "success")
	else: _log("   删除失败: %s" % str(delete_result.result), "error")

	_log("--- 组合策略测试完成 ---", "title")
	_set_buttons_disabled(false)


func _notification(what: int) -> void:
	# 确保退出时清理 IO 管理器（和它们的线程）
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(io_manager_default): io_manager_default.queue_free() # 或直接调用 _shutdown
		if is_instance_valid(io_manager_compress): io_manager_compress.queue_free()
		if is_instance_valid(io_manager_encrypt): io_manager_encrypt.queue_free()
		if is_instance_valid(io_manager_all): io_manager_all.queue_free()
		# 可选：清理测试目录
		# var dir = DirAccess.open(TEST_DIR.get_base_dir())
		# if dir and dir.dir_exists(TEST_DIR.get_file()):
		# 	dir.remove_absolute(TEST_DIR)
