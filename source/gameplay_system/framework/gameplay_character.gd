extends GameplayPawn
class_name GameplayCharacter

## 游戏角色基类
## 提供更复杂的角色控制和状态管理

# 角色状态
enum CharacterState {
	NONE,           # 无状态
	IDLE,           # 待机
	WALKING,        # 行走
	RUNNING,        # 奔跑
	JUMPING,        # 跳跃
	FALLING,        # 下落
	LANDING,        # 着陆
	CROUCHING,      # 蹲伏
	SLIDING,        # 滑行
	CLIMBING,       # 攀爬
	SWIMMING,       # 游泳
	ATTACKING,      # 攻击
	STUNNED,        # 眩晕
	DEAD            # 死亡
}

# 当前状态
var current_state: CharacterState = CharacterState.NONE:
	set(value):
		if current_state != value:
			var old_state = current_state
			current_state = value
			_on_state_changed(old_state, current_state)

# 移动参数
@export_group("Movement Parameters")
@export var max_walk_speed: float = 300.0           # 最大行走速度
@export var max_run_speed: float = 600.0            # 最大奔跑速度
@export var acceleration: float = 2000.0            # 加速度
@export var deceleration: float = 2000.0            # 减速度
@export var braking_deceleration: float = 2000.0    # 制动减速度
@export var ground_friction: float = 8.0            # 地面摩擦力
@export var air_control: float = 0.5                # 空中控制度
@export var gravity_scale: float = 1.0              # 重力缩放
@export var max_step_height: float = 45.0           # 最大台阶高度

func _ready() -> void:
	super()
	# 设置初始状态
	current_state = CharacterState.IDLE
	
	# 设置移动组件参数
	if movement_component:
		movement_component.gravity_scale = gravity_scale
	
	# 注册动画状态
	if animation_player:
		animation_player.register_state_animation(&"idle", &"idle")
		animation_player.register_state_animation(&"walk", &"walk")
		animation_player.register_state_animation(&"run", &"run")
		animation_player.register_state_animation(&"jump", &"jump")
		animation_player.register_state_animation(&"fall", &"fall")
		animation_player.register_state_animation(&"land", &"land")

## 状态变化处理
func _on_state_changed(old_state: CharacterState, new_state: CharacterState) -> void:
	# 播放对应状态的动画
	if animation_player:
		match new_state:
			CharacterState.IDLE:
				animation_player.play_state(&"idle")
			CharacterState.WALKING:
				animation_player.play_state(&"walk")
			CharacterState.RUNNING:
				animation_player.play_state(&"run")
			CharacterState.JUMPING:
				animation_player.play_state(&"jump")
			CharacterState.FALLING:
				animation_player.play_state(&"fall")
			CharacterState.LANDING:
				animation_player.play_state(&"land")

## 物理更新
func _physics_process(delta: float) -> void:
	# 更新状态
	_update_character_state()

## 更新角色状态
func _update_character_state() -> void:
	if not movement_component:
		return
		
	# 获取当前速度
	var velocity = movement_component.get_velocity()
	var speed = velocity.length()
	
	# 根据速度和状态更新当前状态
	if movement_component.is_on_floor():
		if speed < 0.1:
			current_state = CharacterState.IDLE
		elif speed <= max_walk_speed:
			current_state = CharacterState.WALKING
		else:
			current_state = CharacterState.RUNNING
	else:
		if velocity.y < 0:
			current_state = CharacterState.JUMPING
		else:
			current_state = CharacterState.FALLING

## 移动输入处理
func move_left() -> void:
	super()
	if movement_component:
		movement_component.set_velocity(Vector2(-max_walk_speed if not Input.is_action_pressed("run") else -max_run_speed, movement_component.get_velocity().y))

func move_right() -> void:
	super()
	if movement_component:
		movement_component.set_velocity(Vector2(max_walk_speed if not Input.is_action_pressed("run") else max_run_speed, movement_component.get_velocity().y))

## 获取当前状态名称
func get_state_name() -> String:
	return CharacterState.keys()[current_state]

## 检查是否处于指定状态
func is_in_state(state: CharacterState) -> bool:
	return current_state == state
