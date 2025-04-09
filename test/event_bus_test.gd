extends Node
class_name EventBusTest

## This script tests the EventBus system to identify potential subscription issues
## especially when restarting levels or switching scenes

# Configuration variables
var num_test_iterations: int = 100
var num_concurrent_events: int = 5
var num_subscribers_per_event: int = 10
var delay_between_tests: float = 0.05

# Test tracking
var _test_events: Array[String] = []
var _test_running: bool = false
var _event_received_counts: Dictionary = {}
var _subscription_records: Dictionary = {}
var _failures_detected: Array[String] = []

# Reference to the event bus
var _event_bus: Node

# UI elements for displaying results
var _ui_root: Control
var _results_label: Label
var _progress_bar: ProgressBar
var _start_button: Button

func _ready() -> void:
	# Get reference to the event bus
	_event_bus = CoreSystem.event_bus
	_event_bus.debug_mode = true
	
	# Set up UI
	_setup_ui()
	
	# Connect signals
	_start_button.pressed.connect(_run_all_tests)

func _setup_ui() -> void:
	# Create UI root
	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui_root)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.size = Vector2(600, 400)
	vbox.position -= vbox.size / 2
	_ui_root.add_child(vbox)
	
	# Add title
	var title = Label.new()
	title.text = "EventBus Test Suite"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = num_test_iterations
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_progress_bar)
	
	# Add results label
	_results_label = Label.new()
	_results_label.text = "Press Start to begin tests"
	_results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_results_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_results_label)
	
	# Add start button
	_start_button = Button.new()
	_start_button.text = "Start Tests"
	vbox.add_child(_start_button)

func _run_all_tests() -> void:
	if _test_running:
		return
	
	_test_running = true
	_start_button.disabled = true
	_failures_detected.clear()
	_progress_bar.value = 0
	_results_label.text = "Testing in progress..."
	
	# Generate test event names
	_test_events.clear()
	for i in range(num_concurrent_events):
		_test_events.append("test_event_" + str(i))
	
	# Reset tracking
	_event_received_counts.clear()
	_subscription_records.clear()
	
	# Run the tests
	_run_test_iteration(0)

func _run_test_iteration(iteration: int) -> void:
	if iteration >= num_test_iterations:
		_finish_tests()
		return
	
	# Update progress
	_progress_bar.value = iteration
	
	# For each iteration, we'll:
	# 1. Subscribe to events
	# 2. Push events
	# 3. Unsubscribe
	# 4. Verify all events were received
	# 5. Simulate freeing/recreating nodes (level restart)
	
	# Track which subscribers should receive which events
	var expected_counts = {}
	for event_name in _test_events:
		expected_counts[event_name] = 0
		_event_received_counts[event_name] = 0
	
	# Create a set of subscribers for this iteration
	var subscribers = []
	for i in range(num_subscribers_per_event * _test_events.size()):
		var subscriber = EventSubscriber.new()
		subscriber.name = "subscriber_" + str(i)
		subscribers.append(subscriber)
		add_child(subscriber)
	
	# Subscribe to events
	var subscriber_index = 0
	for event_name in _test_events:
		for i in range(num_subscribers_per_event):
			var subscriber = subscribers[subscriber_index]
			subscriber.subscribe_to_event(_event_bus, event_name)
			expected_counts[event_name] += 1
			subscriber_index += 1
	
	# Record subscription state
	_record_subscriptions()
	
	# Push events
	for event_name in _test_events:
		_event_bus.push_event(event_name)
	
	# Wait a frame to allow events to process
	await get_tree().process_frame
	
	# Verify all events were received correctly
	for event_name in _test_events:
		var expected = expected_counts[event_name]
		var actual = _get_total_received(event_name)
		
		if actual != expected:
			_failures_detected.append("Iteration %d: Event %s expected %d notifications, got %d" % 
				[iteration, event_name, expected, actual])
	
	# Clean up subscribers (simulate level restart/scene change)
	for subscriber in subscribers:
		subscriber.queue_free()
	
	# Wait a bit before next iteration
	await get_tree().create_timer(delay_between_tests).timeout
	
	# Run next iteration
	_run_test_iteration(iteration + 1)

func _finish_tests() -> void:
	_test_running = false
	_start_button.disabled = false
	
	if _failures_detected.size() == 0:
		_results_label.text = "All tests passed successfully!"
	else:
		var failure_text = "Test failures detected:\n\n"
		for failure in _failures_detected:
			failure_text += failure + "\n"
		_results_label.text = failure_text
	
	print("Event Bus Test completed with " + str(_failures_detected.size()) + " failures")

func _record_subscriptions() -> void:
	# Record current subscription state for debugging
	if !_event_bus.has_method("get_subscription_counts"):
		print("Event bus doesn't have get_subscription_counts method, can't record state")
		return
	
	var counts = _event_bus.get_subscription_counts()
	for event_name in counts.keys():
		_subscription_records[event_name] = counts[event_name]

func _get_total_received(event_name: String) -> int:
	return _event_received_counts.get(event_name, 0)

# Add event to received count
func _on_event_received(event_name: String) -> void:
	if _event_received_counts.has(event_name):
		_event_received_counts[event_name] += 1
	else:
		_event_received_counts[event_name] = 1

# Event subscriber helper class
class EventSubscriber extends Node:
	var _subscribed_events: Array[String] = []
	var _event_bus = null
	
	func subscribe_to_event(event_bus, event_name: String) -> void:
		_event_bus = event_bus
		_subscribed_events.append(event_name)
		event_bus.subscribe(event_name, _handle_event)
	
	func _handle_event() -> void:
		var parent = get_parent()
		if parent is EventBusTest:
			# Send the event name as the first item in the call stack
			var stack = get_stack()
			var event_name = stack[0].source
			parent._on_event_received(event_name)
		else:
			print("Parent is not EventBusTest")
	
	func _exit_tree() -> void:
		if _event_bus:
			for event_name in _subscribed_events:
				_event_bus.unsubscribe(event_name, _handle_event)
