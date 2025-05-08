# [待发布]

### ✨ 新增 (Added)

*   **线程实用工具集 (`Threading Utilities`)**:
    *   引入 `SingleThread` 和 `ModuleThread`，简化后台任务和多线程管理。
    *   提供线程安全的任务提交和信号反馈。
*   **加权随机选择器 (`RandomPicker`)**: 新增工具类，方便实现基于权重的随机选择。

### 🔄 变更 (Changed)

*   **异步 IO 管理器 (`AsyncIOManager`)**: 重构为更灵活的工具类 (`RefCounted`)，不再是单例模块，解耦其使用。
*   **配置系统 (`ConfigManager`)**:
    *   **核心重构**: 切换为使用 Godot 内置的 `ConfigFile` 进行**同步**读写 `.cfg` 文件，移除异步操作和 `AsyncIOManager` 依赖。
    *   **默认值处理**: 框架不再加载硬编码默认值，`get_value` 需提供默认参数，`reset_config` 清空内存并发送信号，由游戏项目负责应用默认值。
    *   **API 简化**: 利用 `ConfigFile` 的原生类型支持简化了 API。
*   **存档系统 (`SaveManager`)**:
    *   **核心重构**: 采用**策略模式 (Strategy Pattern)**，支持多种存档格式（Resource, JSON, Binary）。
    *   **异步**: 全面使用 `async/await` 进行文件操作。
    *   **功能增强**: 改进了配置管理、错误处理、接口统一性，并添加了加密支持。
*   **事件总线 (`EventBus`)**: 重构为使用 Godot 内置信号系统，更符合原生习惯。
*   **场景系统 (`SceneSystem`)**: 重构以更贴近 Godot 原生的场景管理方式。
*   **日志系统 (`Logger`)**: 添加颜色标识，使日志输出更清晰。
*   **开发流程**: 创建 `release` 分支用于发布，主开发流程移至 `dev` 分支。

### 🗑️ 移除 (Removed)

*   `release` 分支不再包含 `test` 目录。
*   移除了旧的、单一格式的存档系统实现。

### 🛠️ 修复 (Fixed)

*   重构路径处理以适应不同安装方式 (#28)。
*   修复 2D 场景切换后相机缩放未更新的问题 (#28)。
*   修复部分资源 UID 问题 (#28)。

### 🔒 安全 (Security)

*   为存档系统添加了文件加密支持（主要通过 Binary 策略）。
*   (规划中) 添加存档数据验证机制 