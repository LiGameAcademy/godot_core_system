extends Control

## 手动验证 GitHub #31：高压缩比 GZIP 解压缓冲区不足。
## 运行场景：res://addons/godot_core_system/test/gzip_issue31/gzip_issue31_test.tscn

const GzipCompressionStrategy = preload(
	"res://addons/godot_core_system/source/utils/io_strategies/compression/gzip_compression_strategy.gd"
)

@onready var _log: RichTextLabel = $VBoxContainer/LogLabel
@onready var _btn_run: Button = $VBoxContainer/RunBtn
@onready var _btn_clear: Button = $VBoxContainer/ClearBtn

func _ready() -> void:
	_btn_run.pressed.connect(_on_run_pressed)
	_btn_clear.pressed.connect(_log.clear)


func _on_run_pressed() -> void:
	_log.clear()
	_line("title", "=== Issue #31 GZIP 解压测试 ===")
	_run_all()


func _line(kind: String, text: String) -> void:
	var color := "white"
	match kind:
		"success":
			color = "lime"
		"error":
			color = "red"
		"warning":
			color = "yellow"
		"title":
			color = "aqua"
	_log.add_text("[color=%s]%s[/color]\n" % [color, text])
	print(text)


func _run_all() -> void:
	# 1) 高压缩比负载：重复字符 → gzip 远小于原始未压缩大小
	var uncompressed_bytes: int = 2_000_000
	var raw: PackedByteArray = "x".repeat(uncompressed_bytes).to_utf8_buffer()
	var gz: PackedByteArray = raw.compress(FileAccess.COMPRESSION_GZIP)
	var ratio: float = float(raw.size()) / float(max(gz.size(), 1))
	_line("title", "未压缩: %d bytes | gzip: %d bytes | 约 %.1f : 1" % [raw.size(), gz.size(), ratio])

	# 2) 说明旧逻辑为何必失败：不调用 decompress(过小缓冲)，否则 Godot C++ 会在控制台报 compression.cpp 错误。
	var legacy_buf_cap: int = max(gz.size() * 10, 1024)
	var need_out: int = raw.size()
	var isize_tail: int = (
		gz[gz.size() - 4]
		| (gz[gz.size() - 3] << 8)
		| (gz[gz.size() - 2] << 16)
		| (gz[gz.size() - 1] << 24)
	)
	_line(
		"warning",
		"旧估算缓冲上限=%d（gzip×10，与插件旧版思路一致），未压缩需=%d；gzip 尾 ISIZE=%d（mod 2^32）。上限<需求 → 修复前 decompress 必失败（#31）。"
		% [legacy_buf_cap, need_out, isize_tail]
	)

	# 3) 当前策略类
	var strat := GzipCompressionStrategy.new()
	var fixed_out: PackedByteArray = strat.decompress(gz)
	_line("title", "GzipCompressionStrategy.decompress: 输出长度=%d" % fixed_out.size())

	if fixed_out == raw:
		_line("success", "PASS: 往返字节与原文一致。")
	else:
		_line("error", "FAIL: 解压结果与原文不一致。")
