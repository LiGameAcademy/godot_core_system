# 分层状态机系统

## 概述
分层状态机系统提供了一个灵活、可扩展的状态管理解决方案。系统支持状态嵌套、状态历史记录、事件处理和变量共享等特性，特别适合用于游戏AI、UI交互和游戏流程控制等场景。

## 核心概念

### 状态（State）
- 代表一个具体的行为或状态
- 可以有自己的进入/退出逻辑
- 支持更新（每帧）和物理更新（固定帧率）
- 可以处理事件
- 可以访问和修改共享变量

### 状态机（StateMachine）
- 管理多个状态之间的转换
- 维护当前活动状态
- 处理状态切换逻辑
- 支持状态历史记录
- 管理共享变量

### 分层特性
- 状态可以包含子状态机
- 子状态可以访问父状态的变量
- 事件可以在状态层级间传播
- 支持状态的继承和复用

## 使用示例

### 1. 基础状态机
```gdscript
# 创建一个简单的状态
class_name IdleState extends BaseState
func enter(msg := {}):
    super.enter(msg)
    print("进入空闲状态")

func update(delta: float):
    if agent.is_moving:
        transition_to("move")

# 使用状态机
var state_machine = BaseStateMachine.new()
state_machine.add_state("idle", IdleState)
state_machine.add_state("move", MoveState)
state_machine.transition_to("idle")
```

### 2. 分层状态机
```gdscript
# 创建一个包含子状态机的状态
class_name CombatState extends BaseState
var sub_state_machine: BaseStateMachine

func _init():
    sub_state_machine = BaseStateMachine.new(self)
    sub_state_machine.add_state("attack", AttackState)
    sub_state_machine.add_state("defend", DefendState)

func enter(msg := {}):
    super.enter(msg)
    sub_state_machine.transition_to("attack")

# 在主状态机中使用
main_state_machine.add_state("combat", CombatState)
main_state_machine.add_state("explore", ExploreState)
```

### 3. 事件处理
```gdscript
# 在状态中处理事件
class_name PlayerState extends BaseState
func _on_damage_taken(amount: int):
    if amount > 50:
        transition_to("hurt")
    elif parent_state:
        parent_state.handle_event("damage_taken", [amount])

# 触发事件
state_machine.handle_event("damage_taken", [30])
```

## 最佳实践

1. 状态组织
   - 将相关状态组织在同一个状态机中
   - 使用有意义的状态名称
   - 保持状态逻辑简单明确

2. 状态切换
   - 在适当的时机切换状态
   - 使用msg参数传递必要的切换信息
   - 善用状态历史记录功能

3. 变量管理
   - 合理使用共享变量
   - 注意变量的作用域
   - 及时清理不需要的变量

4. 事件处理
   - 合理使用事件传播机制
   - 避免事件处理循环
   - 保持事件参数简单明确

## 注意事项

1. 状态机初始化
   - 确保在使用前正确初始化状态机
   - 设置必要的初始状态
   - 正确配置状态机的代理对象

2. 性能考虑
   - 避免在update中进行密集计算
   - 合理使用物理更新
   - 及时清理不需要的状态和变量

3. 调试
   - 使用状态机提供的信号进行调试
   - 监控状态切换和事件传播
   - 检查变量的变化

## 状态机系统

状态机系统提供了一种强大而灵活的方式来管理游戏状态和转换。它旨在处理复杂的游戏逻辑，同时保持代码的清晰性和可维护性。

### 特性

- 🔄 **层级状态机**：支持嵌套状态机
- 🎮 **游戏专用状态**：内置支持常见游戏状态（菜单、游戏、暂停）
- 📊 **状态管理**：清晰的状态转换和更新 API
- 🎯 **输入处理**：每个状态集成的输入处理
- 🔍 **调试功能**：内置状态跟踪调试功能

### 核心组件

#### BaseState（基础状态）

所有状态的基础类。提供：
- 状态生命周期方法（进入、退出、更新）
- 输入处理
- 状态转换管理

```gdscript
class MyState extends BaseState:
    func _enter(msg := {}) -> void:
        # 进入状态时调用
        pass
        
    func _exit() -> void:
        # 退出状态时调用
        pass
        
    func _update(delta: float) -> void:
        # 每帧调用
        pass
        
    func _handle_input(event: InputEvent) -> void:
        # 处理输入事件
        pass
```

#### BaseStateMachine（基础状态机）

管理状态集合及其转换：
- 状态注册和切换
- 状态更新和输入传播
- 支持层级状态机

```gdscript
class MyStateMachine extends BaseStateMachine:
    func _ready() -> void:
        # 注册状态
        add_state("idle", IdleState.new(self))
        add_state("walk", WalkState.new(self))
        
        # 设置初始状态
        start("idle")
```

#### StateMachineManager（状态机管理器）

**可选组件**：用于集中注册多台 `BaseStateMachine` 并统一驱动 `update` / `physics_update` / `handle_input`。若项目里只有一台状态机，也可在持有者（如 `Node`）的 `_process` 里直接调用 `state_machine.update(delta)`，**不必**注册到管理器。

- 状态机的中央注册
- 全局状态机更新（可按注册项关闭 physics/input，减少无意义回调）
- 调试信息与监控（`is_active` / `get_current_state` 等，多根状态机时建议传 `root_id`）

```gdscript
# 通过 CoreSystem 访问管理器（默认与旧版一致：三类驱动均开启）
CoreSystem.state_machine_manager.register_state_machine("player", player_state_machine)

# 仅需逻辑更新、自行处理输入时，可关闭管理器内的 physics / input
CoreSystem.state_machine_manager.register_state_machine(
    "flow", flow_state_machine, self, &"", {}, true, false, false
)
# 或注册后运行时修改：
CoreSystem.state_machine_manager.set_registration_drive_flags("flow", true, false, false)
```

## 使用示例

这是一个简单的角色状态机示例：

```gdscript
# 角色状态机
class CharacterStateMachine extends BaseStateMachine:
    func _ready() -> void:
        add_state("idle", IdleState.new(self))
        add_state("walk", WalkState.new(self))
        add_state("jump", JumpState.new(self))
        start("idle")

# 空闲状态
class IdleState extends BaseState:
    func _enter(msg := {}) -> void:
        owner.play_animation("idle")
    
    func _handle_input(event: InputEvent) -> void:
        if event.is_action_pressed("move"):
            transition_to("walk")
        elif event.is_action_pressed("jump"):
            transition_to("jump")

# 注册到管理器
func _ready() -> void:
    var character_sm = CharacterStateMachine.new(self)
    CoreSystem.state_machine_manager.register_state_machine("character", character_sm)
```

## 最佳实践

1. **状态组织**
   - 保持状态小而专注
   - 对复杂行为使用层级状态机
   - 考虑使用状态工厂进行动态状态创建

2. **状态转换（分层）**
   - [method BaseState.transition_to]：在 [member BaseState.state_machine] 所管理的那一层里切换（叶子对父机、子状态机要改外层时对 [member BaseState.state_machine] 调用）。
   - [method BaseStateMachine.transition_local]：只在本机子状态表内切换；子状态机脚本里要强调「只动内层」时优先用此名。
   - [method BaseStateMachine.transition_to] 在本类中与 [method BaseStateMachine.transition_local] 等价；叶子经 [method BaseState.transition_to] 会调到 [method BaseStateMachine.transition_local]。
   - 使用消息传递进行状态通信
   - 验证状态转换
   - 在 _exit() 中处理清理工作

3. **驱动方式**
   - 使用 `StateMachineManager` 时，按需要关闭 `run_physics` / `run_input`，避免每帧空转
   - 单台状态机可不用管理器，在持有者 `_process` 中调用 `update` 即可

4. **调试**
   - 启用状态转换的调试日志
   - 使用内置的状态监控工具
   - 添加状态验证检查

## API 参考

### BaseState（基础状态）
- `enter(msg: Dictionary)`: 进入状态
- `exit()`: 退出状态
- `update(delta: float)`: 更新状态逻辑
- `handle_input(event: InputEvent)`: 处理输入
- `transition_to(state_id: StringName, msg: Dictionary = {})`: 在 [member state_machine] 所管理的那一层子状态里切换（内部调用 [method BaseStateMachine.transition_local]）

### BaseStateMachine（基础状态机）
- `add_state(name: String, state: BaseState)`: 注册新状态
- `remove_state(name: String)`: 移除已注册的状态
- `start(initial_state: String)`: 启动状态机
- `stop()`: 停止状态机
- `transition_local(state_id: StringName, msg: Dictionary = {})`: 仅在本机子状态表内切换（显式 API，推荐在子状态机脚本里表达「只切内层」时使用）
- `transition_to(state_id: StringName, msg: Dictionary = {})`: 与 `transition_local` 等价；叶子通过 [method BaseState.transition_to] 会调到此处

### StateMachineManager（状态机管理器）
- `register_state_machine(id, state_machine, agent = null, initial_state = &"", msg = {}, run_update = true, run_physics = true, run_input = true)`: 注册状态机；后三个布尔参数控制是否由管理器在 `_process` / `_physics_process` / `_input` 中转发（默认均为 `true`，与旧版一致）
- `set_registration_drive_flags(id, run_update, run_physics, run_input)`: 运行时修改上述驱动开关
- `unregister_state_machine(name: String)`: 注销状态机
- `get_state_machine(name: String) -> BaseStateMachine`: 获取已注册的状态机
