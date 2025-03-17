extends GameplayController
class_name GameplayPlayerController

## 玩家控制器
## 处理玩家输入并控制Pawn

# 输入管理器引用
@onready var input_manager = get_node("/root/InputManager")

# 玩家状态
var player_state: GameplayPlayerState


func _init(state: GameplayPlayerState = null, mode: GameplayGameMode = null) -> void:
	super(mode)
	# 使用传入的状态或创建默认状态
	player_state = state if state else create_player_state()
	add_child(player_state)


func _ready() -> void:
	# 注册移动轴
	input_manager.register_axis("movement", "move_right", "move_left")
	# 连接输入信号
	input_manager.action_triggered.connect(_on_action_triggered)
	input_manager.axis_changed.connect(_on_axis_changed)


func _physics_process(_delta: float) -> void:
	if possessed_pawn:
		# 处理移动输入
		var movement = input_manager.get_axis_value("movement")
		if movement.x != 0:
			possessed_pawn.add_movement_input(Vector2(movement.x, 0))


## 处理动作输入
func _on_action_triggered(action_name: String, _event: InputEvent) -> void:
	if not possessed_pawn:
		return
		
	match action_name:
		"jump":
			possessed_pawn.jump()
		# 可以添加更多动作处理...


## 处理轴输入
func _on_axis_changed(axis_name: String, value: Vector2) -> void:
	if not possessed_pawn:
		return
		
	match axis_name:
		"movement":
			if value.x < 0:
				possessed_pawn.sprite.flip_h = true
			elif value.x > 0:
				possessed_pawn.sprite.flip_h = false


## 当接管Pawn时
func _possess() -> void:
	super()
	# 设置相机为当前相机
	if possessed_pawn:
		possessed_pawn.camera.make_current()


## 当释放Pawn时
func _unpossess() -> void:
	super()
	# 重置相机
	if possessed_pawn:
		possessed_pawn.camera.clear_current()


## 创建玩家状态（可在子类中重写）
func create_player_state() -> GameplayPlayerState:
	return GameplayPlayerState.new()
