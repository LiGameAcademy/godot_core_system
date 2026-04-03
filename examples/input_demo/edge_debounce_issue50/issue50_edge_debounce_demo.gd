extends Control

## Issue #50：InputState 边沿防抖（[member InputState.edge_debounce_ms]）。
## 机械键盘触点抖动是典型动机，但**不依赖**机械键盘验收：
## - 「同帧模拟」：同一帧内连续 [method InputState.update_action]，在防抖开启时压缩过密的 just 边沿。
## - 「分时模拟」（可选）：用 [code]await[/code] 等待超过 [code]edge_debounce_ms[/code] 再切边沿，应能再次看到 just。

const DEMO_ACTION := &"issue50_demo_action"

@onready var _log: RichTextLabel = %LogLabel


func _ready() -> void:
	_append_log(
		"[b]Issue #50 · InputState 边沿防抖[/b]\n"
		+ "使用独立 [code]InputState.new()[/code]，不占用全局 InputManager。\n"
		+ "点击下方按钮运行模拟；无需机械键盘。\n\n"
	)

func _append_log(bbcode: String) -> void:
	if _log:
		_log.text += bbcode

func _run_same_frame_suite(debounce_ms: float, title: String) -> void:
	var st := InputState.new()
	st.edge_debounce_ms = debounce_ms
	var action := String(DEMO_ACTION)

	st.update_action(action, true, 1.0)
	var jp1 := st.is_just_pressed(action)
	st.update_action(action, false, 0.0)
	var jr := st.is_just_released(action)
	st.update_action(action, true, 1.0)
	var jp2 := st.is_just_pressed(action)

	_append_log(
		"[b]%s[/b]\n" % title
		+ "  just_pressed #1: [code]%s[/code]  just_released: [code]%s[/code]  just_pressed #2: [code]%s[/code]\n"
		% [jp1, jr, jp2]
	)

func _run_spaced_edges_async() -> void:
	var st := InputState.new()
	st.edge_debounce_ms = 40.0
	var action := String(DEMO_ACTION)

	st.update_action(action, true, 1.0)
	var a := st.is_just_pressed(action)
	_append_log("  第 1 次按下 just_pressed: [code]%s[/code]\n" % a)

	await get_tree().create_timer(0.05).timeout
	st.update_action(action, false, 0.0)
	var b := st.is_just_released(action)
	_append_log("  50ms 后释放 just_released: [code]%s[/code]\n" % b)

	await get_tree().create_timer(0.05).timeout
	st.update_action(action, true, 1.0)
	var c := st.is_just_pressed(action)
	_append_log("  再等 50ms 再按下 just_pressed: [code]%s[/code]\n" % c)

func _on_spaced_edges_pressed() -> void:
	_append_log("\n[color=cyan]── 分时边沿（每步间隔 > 防抖窗口）──[/color]\n")
	await _run_spaced_edges_async()

func _on_same_frame_pressed() -> void:
	_append_log("\n[color=cyan]── 同帧三连：按下 → 释放 → 再按下 ──[/color]\n")
	_run_same_frame_suite(0.0, "关闭防抖 (0 ms)")
	_run_same_frame_suite(30.0, "开启防抖 (30 ms)")

func _on_clear_pressed() -> void:
	if _log:
		_log.text = ""
