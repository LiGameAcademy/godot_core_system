extends Control

## 虚拟轴可视化器
## 用于可视化显示虚拟轴的当前值和方向

var current_axis := Vector2.ZERO
var axis_color := Color.GREEN
var deadzone_color := Color.RED
var background_color := Color(0.2, 0.2, 0.2, 0.5)

# 可视化参数
const CIRCLE_RADIUS = 100.0
const DEADZONE_RADIUS = 20.0
const INDICATOR_SIZE = 10.0

func _ready() -> void:
	# 确保控件能接收绘制调用
	custom_minimum_size = Vector2(CIRCLE_RADIUS * 2, CIRCLE_RADIUS * 2)
	queue_redraw()

func update_axis(axis_value: Vector2) -> void:
	current_axis = axis_value
	queue_redraw()

func _draw() -> void:
	var center = size / 2
	
	# 绘制背景圆
	draw_circle(center, CIRCLE_RADIUS, background_color)
	
	# 绘制死区圆
	draw_circle(center, DEADZONE_RADIUS, deadzone_color)
	
	# 绘制坐标轴
	draw_line(center + Vector2(-CIRCLE_RADIUS, 0), 
			  center + Vector2(CIRCLE_RADIUS, 0), 
			  Color.WHITE_SMOKE)
	draw_line(center + Vector2(0, -CIRCLE_RADIUS), 
			  center + Vector2(0, CIRCLE_RADIUS), 
			  Color.WHITE_SMOKE)
	
	# 绘制当前轴值指示器
	var indicator_pos = center + current_axis * CIRCLE_RADIUS
	draw_circle(indicator_pos, INDICATOR_SIZE, axis_color)
	
	# 绘制从中心到指示器的线
	if current_axis.length() > 0:
		draw_line(center, indicator_pos, axis_color)
	
	# 绘制轴值文本
	var text = "X: %.2f\nY: %.2f" % [current_axis.x, current_axis.y]
	draw_string(ThemeDB.fallback_font, 
				center + Vector2(CIRCLE_RADIUS + 10, 0), 
				text)

func set_deadzone(value: float) -> void:
	# 更新死区可视化
	queue_redraw()

func set_sensitivity(value: float) -> void:
	# 更新灵敏度可视化
	queue_redraw()
