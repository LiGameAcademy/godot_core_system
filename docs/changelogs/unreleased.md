# [unreleased]

## ✨ 新增 (Added)

- CoreGameSession: caller-owned identity and Preparing/Running/Paused/Ended/Closed lifecycle, optional synchronous pause/resume adapters, snapshot queries and post-commit notifications. Adds count/timer examples, 63 rule checks and 13 actual scene checks matching the C# contract; no AutoLoad or game data is introduced. Export acceptance remains deferred.

## 🔄 变更 (Changed)

- **状态机**：`StateMachineManager` 增加注册项驱动开关（`run_update` / `run_physics` / `run_input`，默认全开，旧调用兼容）；新增 `set_registration_drive_flags`。`BaseStateMachine` 的 `update` / `physics_update` / `handle_input` 在委托子状态后直接调用本机 `_update` 等，减少一层转发。切换语义：`BaseState.transition_to` 委托所属状态机的 `transition_local`；本机子状态切换的显式 API 为 `transition_local`，`BaseStateMachine.transition_to` 与其等价。`switch` / `switch_to` 为弃用别名。

## 🗑️ 移除 (Removed)

## 🛠️ 修复 (Fixed)

- **状态机**：`BaseStateMachine` 继承 `BaseState` 时，原先继承的 `switch_to` 会误委托到父级；现由 `transition_local` 承担本机切换，`BaseState.transition_to` 委托 `transition_local`。

## 🔒 安全 (Security)
