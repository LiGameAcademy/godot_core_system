extends BaseStateMachine
class_name ExampleGameStateMachine


func _ready() -> void:
    # 添加主要状态
    add_state(&"menu", MenuState.new())
    add_state(&"gameplay", GameplayState.new())
    add_state(&"pause", PauseState.new())

## 菜单状态
class MenuState extends BaseState:
    func _enter(_msg := {}) -> void:
        print("进入菜单状态")

    func _handle_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_accept"):
            switch_to(&"gameplay")

## 游戏状态（包含子状态机）
class GameplayState extends BaseStateMachine:
    func _ready() -> void:
        # 添加子状态
        add_state(&"explore", ExploreState.new())		# 添加探索状态
        add_state(&"battle", BattleState.new())		# 添加战斗状态
        add_state(&"dialog", DialogState.new())		# 添加对话状态
        print("gameplay state ready")
    
    func _enter(msg := {}) -> void:
        print("进入游戏状态")
        # 如果msg中指定了resume，则恢复到上一个状态
        if current_state == null:  # 只在没有当前状态时才启动
            start(&"explore", {}, msg.get("resume", false))
    
    func _handle_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_cancel"):
            print("退出游戏状态 ui_cancel")
            switch_to(&"pause", {"resume": true}) # 传递resume标记
    
    func _exit() -> void:
        print("退出游戏状态")
        stop()
    
    ## 探索状态
    class ExploreState extends BaseState:
        func _enter(_msg := {}) -> void:
            print("进入探索状态")
        
        func _handle_input(event: InputEvent) -> void:
            if event.is_action_pressed("ui_accept"):
                switch_to(&"battle")
            elif event.is_action_pressed("ui_focus_next"):
                switch_to(&"dialog")
    
    ## 战斗状态
    class BattleState extends BaseState:
        func _enter(_msg := {}) -> void:
            print("进入战斗状态")
        
        func _exit() -> void:
            print("退出战斗状态")

        func _handle_input(event: InputEvent) -> void:
            if event.is_action_pressed("ui_cancel"):
                print("退出战斗状态 ui_cancel")
                switch_to(&"explore")
    
    ## 对话状态
    class DialogState extends BaseState:
        func _enter(_msg := {}) -> void:
            print("进入对话状态")
        
        func _handle_input(event: InputEvent) -> void:
            if event.is_action_pressed("ui_cancel"):
                switch_to(&"explore")

## 暂停状态
class PauseState extends BaseState:
    func _enter(_msg := {}) -> void:
        print("进入暂停状态")
    
    func _handle_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_cancel"):
            switch_to(&"gameplay", {"resume": true}) # 传递resume标记
        elif event.is_action_pressed("ui_home"):
            switch_to(&"menu")