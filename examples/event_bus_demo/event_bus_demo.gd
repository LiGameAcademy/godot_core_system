extends Node2D

const CoreEventBus = CoreSystem.CoreEventBus

var event_bus : CoreEventBus = CoreSystem.event_bus

func _ready():
	# 启用调试模式和历史记录
	event_bus.debug_mode = true
	event_bus.enable_history = true
	
	# 1. 基本订阅（普通优先级）
	event_bus.subscribe("player_move", _on_player_move)
	
	# 2. 高优先级订阅
	event_bus.subscribe("player_move", _on_player_move_high_priority, 
		event_bus.Priority.HIGH)
	
	# 3. 低优先级订阅
	event_bus.subscribe("player_move", _on_player_move_low_priority, 
		event_bus.Priority.LOW)
	
	# 4. 一次性订阅
	event_bus.subscribe_once("player_attack", _on_player_attack_once)
	
	# 5. 带过滤器的订阅（只处理向右移动）
	event_bus.subscribe("player_move", _on_player_move_right,
		event_bus.Priority.NORMAL,
		false,
		func(payload): return payload[0] == "right"
	)
	
	# 延迟1秒后开始演示
	await get_tree().create_timer(1.0).timeout
	_start_demo()

## 开始演示
func _start_demo():
	print("\n=== 开始EventBus演示 ===")
	
	# 1. 测试不同优先级的事件处理
	print("\n1. 测试事件优先级：")
	event_bus.push_event("player_move", ["left", 100])
	
	# 2. 测试一次性订阅
	print("\n2. 测试一次性订阅：")
	event_bus.push_event("player_attack", ["sword", 50])
	print("再次触发player_attack事件（不会有响应）：")
	event_bus.push_event("player_attack", ["sword", 30])
	
	# 3. 测试事件过滤器
	print("\n3. 测试事件过滤器：")
	print("向左移动（过滤器不会响应）：")
	event_bus.push_event("player_move", ["left", 50])
	print("向右移动（过滤器会响应）：")
	event_bus.push_event("player_move", ["right", 50])
	
	# 4. 测试延迟事件
	print("\n4. 测试延迟事件：")
	event_bus.push_event("player_move", ["up", 100], false)
	
	# 5. 测试历史记录
	await get_tree().create_timer(0.5).timeout
	print("\n5. 显示事件历史：")
	var history = event_bus.get_event_history()
	for event in history:
		print("事件：%s，参数：%s" % [event.event_name, event.payload])
	
	# 6. Issue #48：subscribe_unique_script（同脚本多实例时仅保留最后一次订阅）
	print("\n6. Issue #48 · subscribe_unique_script：")
	_run_issue48_test()
	
	print("\n=== EventBus演示结束 ===")

## 玩家移动事件回调
func _on_player_move(direction, distance):
	print("普通优先级：玩家向%s移动了%d单位" % [direction, distance])

## 高优先级玩家移动事件回调
func _on_player_move_high_priority(direction, distance):
	print("高优先级：玩家向%s移动了%d单位" % [direction, distance])

## 低优先级玩家移动事件回调
func _on_player_move_low_priority(direction, distance):
	print("低优先级：玩家向%s移动了%d单位" % [direction, distance])

## 一次性订阅事件回调
func _on_player_attack_once(weapon, damage):
	print("一次性订阅：玩家使用%s造成了%d点伤害" % [weapon, damage])


## 过滤器订阅事件回调
func _on_player_move_right(direction, distance):
	print("过滤器订阅：玩家向右移动了%d单位" % [distance])


const _ISSUE48_EVENT := "issue48_demo"

## Issue #48：验证 [method CoreEventBus.subscribe_unique_script] — 同一 [Script] 的多个实例对同一事件订阅时，新订阅会移除旧实例上的同类连接。
func _run_issue48_test() -> void:
	var a := Issue48Listener.new("A")
	var b := Issue48Listener.new("B")
	var other := Issue48OtherListener.new("其它脚本")

	event_bus.subscribe_unique_script(_ISSUE48_EVENT, Callable(a, "on_issue48"))
	print("  仅 A 订阅 unique_script 后，订阅数: %d（期望 1）" % event_bus.get_subscriber_count(_ISSUE48_EVENT))

	event_bus.subscribe_unique_script(_ISSUE48_EVENT, Callable(b, "on_issue48"))
	print("  B 再 subscribe_unique_script 后，订阅数: %d（期望 1，A 已被移除）" % event_bus.get_subscriber_count(_ISSUE48_EVENT))

	print("  推送事件（应只有 B 响应）：")
	event_bus.push_event(_ISSUE48_EVENT, ["round1"])

	event_bus.subscribe(_ISSUE48_EVENT, Callable(other, "on_issue48"))
	print("  其它脚本用普通 subscribe 追加后，订阅数: %d（期望 2）" % event_bus.get_subscriber_count(_ISSUE48_EVENT))

	print("  再次推送（B 与 其它脚本 各响应一次）：")
	event_bus.push_event(_ISSUE48_EVENT, ["round2"])


## #48 测试用：同脚本多实例（与 [method CoreEventBus.subscribe_unique_script] 配对）
class Issue48Listener extends RefCounted:
	var label: String

	func _init(p_label: String) -> void:
		label = p_label

	func on_issue48(msg: String) -> void:
		print("    [Issue48 同脚本·%s] %s" % [label, msg])


## #48 对照：不同脚本，不应被 subscribe_unique_script 误删
class Issue48OtherListener extends RefCounted:
	var label: String

	func _init(p_label: String) -> void:
		label = p_label

	func on_issue48(msg: String) -> void:
		print("    [Issue48 其它脚本·%s] %s" % [label, msg])
