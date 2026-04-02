extends SceneTree

## 无 GUI：供 CI / 命令行快速验证 #31
## 用法（项目根目录）：
##   godot --path . --headless -s res://addons/godot_core_system/test/gzip_issue31/gzip_issue31_test_cli.gd
## 退出码：0=通过，1=失败

const GzipCompressionStrategy = preload(
	"res://addons/godot_core_system/source/utils/io_strategies/compression/gzip_compression_strategy.gd"
)

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var raw: PackedByteArray = "x".repeat(500_000).to_utf8_buffer()
	var gz: PackedByteArray = raw.compress(FileAccess.COMPRESSION_GZIP)
	var strat := GzipCompressionStrategy.new()
	var out: PackedByteArray = strat.decompress(gz)
	var ok: bool = out == raw
	print("[gzip_issue31_cli] raw=%d gz=%d out=%d ok=%s" % [raw.size(), gz.size(), out.size(), ok])
	quit(0 if ok else 1)
