extends GutTest

class TestNode extends Node:
	var received: bool = false
	var test_count: int = 0
	var received_payload: Array = []
	var call_order: Array = []
	
	func increase() -> void:
		test_count += 1
	
	func record_payload(payload: Array) -> void:
		received_payload = payload
	
	func mark_received() -> void:
		received = true
	
	func record_order(value: String) -> void:
		call_order.append(value)

var event_bus : CoreSystem.EventBus
var test_node : TestNode

func before_each():
	event_bus = CoreSystem.EventBus.new()
	test_node = TestNode.new()
	add_child_autoqfree(test_node)

func test_subscribe_normal_method():
	event_bus.subscribe("test_event", test_node.record_payload)
	event_bus.push_event("test_event", ["test_data"])
	assert_eq(test_node.received_payload, ["test_data"], "Normal method subscription should receive payload")

func test_subscribe_anonymous_method():
	event_bus.subscribe("test_event", test_node.record_payload)
	event_bus.push_event("test_event", ["test_data"])
	assert_eq(test_node.received_payload, ["test_data"], "Anonymous method subscription should receive payload")

func test_subscribe_once():
	event_bus.subscribe_once("test_event", test_node.increase)
	event_bus.push_event("test_event")
	event_bus.push_event("test_event")
	assert_eq(test_node.test_count, 1, "Once subscription should only be called once")

func test_priority_order():
	event_bus.subscribe("test_event", test_node.record_order.bind("high"), CoreSystem.EventBus.Priority.HIGH)
	event_bus.subscribe("test_event", test_node.record_order.bind("normal"), CoreSystem.EventBus.Priority.NORMAL)
	event_bus.subscribe("test_event", test_node.record_order.bind("low"), CoreSystem.EventBus.Priority.LOW)
	
	event_bus.push_event("test_event")
	assert_eq(test_node.call_order, ["high", "normal", "low"], "Events should be handled in priority order")

func test_filter():
	test_node.received = false
	event_bus.subscribe(
		"test_event", 
		test_node.mark_received,
		CoreSystem.EventBus.Priority.NORMAL,
		false,
		func(payload: Array): return payload.size() > 0
	)
	
	event_bus.push_event("test_event", [])  # 不应该触发
	assert_false(test_node.received, "Empty payload should be filtered")
	
	event_bus.push_event("test_event", ["data"])  # 应该触发
	assert_true(test_node.received, "Non-empty payload should not be filtered")

func test_weak_reference_cleanup():
	var local_node = TestNode.new()
	add_child_autoqfree(local_node)
	event_bus.subscribe("test_event", local_node.mark_received)
	
	local_node.queue_free()
	await get_tree().process_frame
	
	assert_eq(event_bus.get_subscriber_count("test_event"), 0, "Subscription should be removed after object is freed")

func test_unsubscribe():
	event_bus.subscribe("test_event", test_node.mark_received)
	event_bus.unsubscribe("test_event", test_node.mark_received)
	
	event_bus.push_event("test_event")
	assert_false(test_node.received, "Unsubscribed callback should not be called")

func test_unsubscribe_all():
	event_bus.subscribe("test_event", test_node.mark_received)
	event_bus.unsubscribe_all(test_node.mark_received)
	
	event_bus.push_event("test_event")
	assert_false(test_node.received, "All callbacks should be unsubscribed")

func test_event_history():
	event_bus.enable_history = true
	event_bus.push_event("test_event", ["data"])
	
	var history = event_bus.get_event_history()
	assert_eq(history.size(), 1, "Event history should contain one event")
	assert_eq(history[0].event_name, "test_event", "Event name should be recorded")
	assert_eq(history[0].payload, ["data"], "Event payload should be recorded")

func test_history_limit():
	event_bus.enable_history = true
	event_bus.max_history_length = 2
	
	event_bus.push_event("event1")
	event_bus.push_event("event2")
	event_bus.push_event("event3")
	
	var history = event_bus.get_event_history()
	assert_eq(history.size(), 2, "Event history should be limited")
	assert_eq(history[0].event_name, "event2", "Older events should be removed")
	assert_eq(history[1].event_name, "event3", "Recent events should be kept")

func test_deferred_event():
	test_node.received = false
	event_bus.push_event("test_event", [], false)  # 延迟执行
	assert_false(test_node.received, "Deferred event should not execute immediately")
	
	await get_tree().process_frame
	assert_true(test_node.received, "Deferred event should execute after frame")

func test_multiple_anonymous_methods():
	test_node.received = false
	event_bus.subscribe("test_event", test_node.record_order.bind("1"))
	event_bus.subscribe("test_event", test_node.record_order.bind("2"))
	event_bus.subscribe("test_event", test_node.mark_received)
	
	event_bus.push_event("test_event")
	assert_true(test_node.received, "Last method should be called")
	assert_eq(test_node.call_order, ["1", "2"], "All methods should be called in order")

func test_invalid_callback_cleanup():
	var local_node = TestNode.new()
	add_child_autoqfree(local_node)
	
	event_bus.subscribe("test_event", local_node.increase)
	assert_eq(event_bus.get_subscriber_count("test_event"), 1)
	
	local_node.queue_free()
	await get_tree().process_frame
	
	event_bus.push_event("test_event")
	assert_eq(event_bus.get_subscriber_count("test_event"), 0, "Invalid subscription should be removed")
