# 更新日志

所有重要的更改都会记录在这个文件中。

本文档格式基于[Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [待发布]

### 新增

- 新增 `Threading` 系统，用于管理多线程
  - 提供线程池和线程安全的队列
  - 支持异步任务和同步任务
  - 提供线程安全的计数器和锁
- 新增`RandomPicker`工具类，用于加权随机

### 变更

- 重构 `ConfigManager` (`config_manager.gd`) 配置系统：
  - **核心更改:** 底层实现从自定义字典和 `AsyncIOManager` 切换为使用 Godot 内置的 `ConfigFile` 类进行同步读写 `.cfg` 格式文件。
  - **继承:** 基类从 `Node` 更改为 `RefCounted`，使其成为更通用的工具类，不再需要放入场景树。
  - **异步移除:** 移除了所有异步操作和对 `AsyncIOManager` 的依赖，配置文件读写现在是同步的（对于小文件性能足够）。
  - **默认值处理:**
    - 框架层不再提供和加载硬编码的默认配置文件 (`default_config.gd` 被移除或其职责改变)。
    - 定义默认值的责任完全转移给最终的游戏项目。
    - `get_value` 方法现在需要调用者提供一个默认值参数。
    - `reset_config` 方法（原 `reset_to_default`）现在只清空内存中的配置，并发出 `config_reset` 信号，由游戏项目监听并应用其默认值。
  - **API 简化:**
    - 移除了手动类型转换逻辑（如解析 Vector2），`ConfigFile` 原生支持多种 Godot 类型。
    - 移除了 `_merge_config` 等内部方法。
    - `get_section` 现在只返回文件中实际存在的键值。
    - `set_section` 采用"覆盖或添加"策略（不删除旧键），因 `ConfigFile` API 限制。
    - 移除了 `erase_value` 方法。
    - 添加了 `has_key` 方法。
  - **设置来源:** 配置路径和自动保存选项现在直接从 `ProjectSettings` 读取。
- 创建`release`分支，并移除其`test`目录，后续发布版不再包含`test`目录
  - 注意：
    - 避免在`release`分支上进行开发，请在`dev`分支上进行开发
    - 避免将`release`分支合并到其他分支，导致`test`目录被意外移除
- 使用godot的内置信号系统重构EventBus事件总线
- 使用godot的内置current_scene重构SceneSystem场景系统
- `Logger`日志类提供颜色标识，显示更清楚

### 废弃

### 移除

- 在`release`分支上移除`test`目录, 后续发布版不再包含`test`目录

### 修复

- 重构路径以适应不同安装情况 #28
- 修复2D场景切换后相机实际缩放没有更新的BUG #28
- 部分UID修复 #28

### 安全

## [0.0.2]

### 新增

- 新增 `FrameSplitter` 工具类，用于将耗时操作分散到多帧执行，避免卡顿
  - 支持数组、范围、迭代器和自定义处理模式
  - 提供进度反馈和完成信号
  - 动态调整每帧处理量
  - 详细的使用文档和示例

### 变更

- 重构 `InputManager` 输入系统
  - 添加输入缓冲系统，提升游戏手感
  - 集成 `ConfigManager` 进行输入配置管理
  - 添加输入重映射功能和事件通知
  - 优化虚拟轴和动作处理
  - 添加输入系统配置管理
  - 网络输入系统改进
- 重构`SceneSystem`场景系统
  - 更接近Godot原生场景系统的使用体验
