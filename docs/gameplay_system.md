# 游戏性系统

## 主要类

### GameplayManager（游戏玩法管理器）

1. **职责**

- 作为 Gameplay 框架的入口点
- 管理游戏模式的创建和切换
- 管理控制器的创建和生命周期
- 提供对当前游戏模式和控制器的访问

2. **主要接口**

- initialize_game_mode()：初始化游戏模式
- create_player_controller()：创建玩家控制器
- create_ai_controller()：创建AI控制器
- get_current_game_mode()：获取当前游戏模式

### GameMode（游戏模式）

1. **职责**

- 定义游戏规则和流程
- 管理游戏状态的切换
- 控制玩家的生成和重生
- 处理游戏开始、结束等核心事件

2. **主要接口**

- begin_play()：开始游戏
- end_game()：结束游戏
- spawn_player()：生成玩家
- get_game_state()：获取当前游戏状态

### GameState（游戏状态）

1. **职责**

- 管理特定游戏状态下的逻辑
- 处理状态进入和退出
- 更新状态相关的数据

2. **主要接口**

- on_state_begin()：状态开始时调用
- on_state_end()：状态结束时调用
- on_state_update()：状态更新时调用

### Controller（控制器基类）

1. **职责**

- 定义控制 Pawn 的基本接口
- 管理 Pawn 的持有和释放
- 提供控制权转换的机制

2. **主要接口**

- possess()：接管 Pawn 的控制
- unpossess()：释放 Pawn 的控制
- _possess()：接管时的具体实现
- _unpossess()：释放时的具体实现

### PlayerController（玩家控制器）

1. **职责**

- 处理玩家输入
- 控制玩家角色的行为
- 管理玩家相关的UI和摄像机

2. **主要接口**

- _handle_input()：处理输入事件
- _possess()：接管玩家角色时的处理
- _unpossess()：释放玩家角色时的处理

### AIController（AI控制器）

1. **职责**

- 管理AI的行为逻辑
- 处理AI决策
- 控制AI角色的行动

2. **主要接口**

- _setup_behavior_tree()：设置行为树
- update_blackboard()：更新黑板数据
- get_blackboard_value()：获取黑板数据

### Pawn（可控制角色）

1. **职责**

- 提供可被控制的基本功能
- 实现基础的移动和交互
- 管理生命值和状态

2. **主要接口**

- move_left()/move_right()：基本移动
- jump()：跳跃
- take_damage()：受到伤害
- _die()：死亡处理

## 类之间的关系

### 层次关系

``` mermaid
graph TD
    CoreSystem
        └── GameplayManager
            ├── GameMode
            │    └── GameState
            └── Controller
            ├── PlayerController
            └── AIController
```

### 数据流

``` mermaid
CopyInsert
GameplayManager ─────┐
     │              │
  GameMode    Controller
     │              │
GameState         Pawn
``` 

## 职责划分

- GameplayManager：整体管理和协调
- GameMode：游戏规则和流程
- GameState：状态管理
- Controller：行为控制
- Pawn：具体实现

## 架构优点

- 清晰的分层：
  - 每个类都有明确的职责
  - 依赖关系清晰
  - 易于理解和维护
- 灵活的扩展：
  - 可以方便地添加新的游戏模式
  - 可以创建不同类型的控制器
  - 可以实现各种游戏状态
- 良好的复用：
  - 基类提供通用功能
  - 接口统一规范
  - 便于在不同项目中使用
