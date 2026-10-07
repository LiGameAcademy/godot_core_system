# Godot 核心系统

<div align="center">

简体中文 | [English](README.md)

![Godot 验证基线](https://img.shields.io/badge/Godot-tested%20on%204.7.2-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/LiGameAcademy/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](docs/CONTRIBUTING.md)

为 Godot 独立开发者提供可按需采用的基础系统，减少重复工程，让小型游戏更容易完成和维护。

[快速开始](#-快速开始) •
[文档](docs/) •
[示例](examples/) •
[项目定位与运营方案](docs/open_source_operations_plan.md) •
[贡献](docs/CONTRIBUTING.md) •
[支持与帮助](#-支持与帮助)

</div>

## 可以用它完成什么

围绕一个具体问题选择模块，从对应示例开始接入。框架定位为轻量、简单但好用的基础系统框架，以小型 API、明确的拥有关系和失败行为减少重复工作。

| 用户任务 | 能力与实际边界 | 从这里开始 |
| --- | --- | --- |
| 给菜单与关卡加入切换和淡入淡出 | CoreScenes 提供完成结果、重复请求保护及可选的持久转场节点；资源加载仍是同步的 | [接口](docs/systems/native_scenes.md) · [两场景示例](examples/native_scenes/README.md) |
| 保存与读取经过校验的数据快照 | CoreSaveStore 提供版本化 JSON、显式校验与错误结果，区分文件缺失和损坏；Windows 文件替换依赖原生扩展 | [接口与计数示例](docs/systems/core_save_store.md) |
| 让玩家修改键盘与鼠标绑定 | CoreInputs 管理显式动作组，检查冲突、恢复默认，并保留手柄事件 | [接口与捕获、持久化示例](docs/systems/core_inputs.md) |
| 管理状态转换和倒计时 | 值状态机、行为状态机和显式推进的计时器，让生命周期规则可观察 | [状态机](docs/systems/state_machine_system.md) · [计时器](docs/systems/core_timer.md) |
| 清理事件订阅，控制暂停与倍速 | 订阅令牌和时间作用域，由拥有者负责使用和释放 | [事件](docs/systems/core_event_bus.md) · [时间](docs/systems/core_time_scope.md) |
| 做局部分类与规则条件判断 | 本地标签和触发器支持显式规则组合 | [标签示例](examples/tags/README.md) · [触发器示例](examples/triggers/README.md) |

音频、配置、资源管理、旧版输入/存档/场景能力及线程、分帧工具也有对应文档。它们与上表独立服务的功能范围不同，按具体需求选择。

### 轻量意味着什么

- 按项目需要采用能力，游戏数值、胜负条件和 UI 由游戏自身管理。
- 以 Godot 场景、Resource 和信号为基础；共同生命周期从真实项目需求中提炼。
- CoreSystem 为旧管理器提供方便的应用级入口；CoreScenes、CoreInputs、CoreSaveStore 等独立服务不要求启用该 AutoLoad。
- 同一状态明确一个拥有者和修改入口，避免旧管理器与独立服务同时处理同一操作。

独立持有服务不等于所有模块已提供单独下载包。依赖清单与安装成本是[运营方案](docs/open_source_operations_plan.md)中的后续接入优化项。

## 🚀 快速开始

### 系统要求

- 当前独立服务的验证记录使用 Godot 4.7.2 / Windows x64 的编辑器与无界面宿主，具体范围见各模块说明。
- 随附 Windows x64 持久化扩展需要 Godot Engine 4.7+；导出包与其他平台仍需单独验收。
- 基本的 GDScript 和 Godot 引擎知识。

项目早期面向 Godot 4.4；该历史目标不代表当前检出的兼容性保证。Windows 存档示例需加载[原生扩展](native/atomic_file/README.md)，导出时需包含 DLL。与 C# 的共同语义逐模块记录，两版覆盖范围不同。

### 安装步骤

1. 获取选定提交或标签的仓库内容，记录版本以便复现接入；使用[发布包](https://github.com/LiGameAcademy/godot_core_system/releases)时先核对该包的兼容说明。
2. 将仓库内容放到 `addons/godot_core_system/`，确保 `plugin.cfg` 直接位于该目录。此仓库是插件，需使用已有或新建的 Godot 宿主工程。
3. 使用旧管理器时，在项目设置 → 插件中启用 `godot_core_system`；插件会注册 CoreSystem AutoLoad。
4. 使用独立服务时，按模块说明配置依赖与拥有者，启用 CoreSystem 为可选步骤；场景转场仍需要持久拥有者，Windows 存档示例仍需原生扩展。

### 第一次成功接入

先运行[两场景示例](examples/native_scenes/README.md)：注册其中的 SceneExampleHost AutoLoad，运行 `scene_a.tscn`，点击按钮观察完整切换与淡入淡出。随后按接口说明，将服务拥有关系接入自己的持久应用节点。

存档从[计数示例](examples/save_contract/save_contract_example.tscn)开始，配置步骤见[存档说明](docs/systems/core_save_store.md)。改键从 [input_bindings](examples/input_bindings/) 开始，初始化与持久化步骤见[输入说明](docs/systems/core_inputs.md)。

旧接口仍在下方文档中保留。新独立 API 的存档格式、事件路由等属于单独契约，替换旧调用前需要核对对应迁移说明。

## 📚 文档

旧管理器与完整系统范围的详细文档：

| 系统名称           | 功能描述                           | 文档链接                                |
|-------------------|----------------------------------|----------------------------------------|
| 状态机系统         | 游戏逻辑状态管理                   | [查看文档](docs/systems/state_machine_system_zh.md) |
| 音频系统           | 音频管理和过渡                     | [查看文档](docs/systems/audio_system_zh.md)       |
| 输入系统           | 输入处理和事件管理                 | [查看文档](docs/systems/input_system_zh.md)       |
| 日志系统           | 多通道日志记录                     | [查看文档](docs/systems/logger_system_zh.md)      |
| 资源系统           | 资源加载和管理                     | [查看文档](docs/systems/resource_system_zh.md)    |
| 场景系统           | 场景转换和管理                     | [查看文档](docs/systems/scene_system_zh.md)       |
| 标签系统           | 对象标签和分类                     | [查看文档](docs/systems/tag_system_zh.md)         |
| 触发器系统         | 事件驱动的触发器和条件             | [查看文档](docs/systems/trigger_system_zh.md)       |
| 配置系统           | 配置管理                           | [查看文档](docs/systems/config_system_zh.md)        |
| 存档系统           | 游戏存档管理                       | [查看文档](docs/systems/save_system_zh.md)          |

每个工具的详细文档：

| 工具名称           | 功能描述                          | 文档链接                                |
|-------------------|-----------------------------------|----------------------------------------|
| 分帧执行器         | 性能优化工具                       | [查看文档](docs/utils/frame_splitter_zh.md)       |
| 异步 IO 管理器     | 非阻塞的文件读写、策略化处理       | [查看文档](docs/utils/async_io_manager_zh.md)   |
| 线程系统           | 简化多线程管理                     | [查看文档](docs/utils/threading_system_zh.md)     |
| 随机选择器         | 带权重的随机选择工具               | [查看文档](docs/utils/random_picker_zh.md)      |

## 🌟 示例项目

访问我们的[示例项目](examples/)，了解框架的实际应用场景和使用方式。

### 历史游戏示例

以下链接展示此前的项目使用情况。作为新版案例宣传前，需要重新核对其当前插件版本和兼容范围。

- [GodotPlatform2D](https://github.com/LiGameAcademy/GodotPlatform2D) - 一个使用 godot_core_system 框架开发的 2D 平台游戏示例，展示了框架在实际游戏开发中的应用。
- [Exocave : 2d平台跳跃解密游戏。以重力翻转为核心机制](https://github.com/youer0219/Exocave) - 使用 godot_core_system 框架的 scene_system。

## 🤝 参与贡献

我们欢迎各种形式的贡献！无论是新功能、bug 修复，还是文档改进。详情请查看[贡献指南](docs/CONTRIBUTING.md)。

## 📄 开源协议

本项目采用 MIT 开源协议 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 💖 支持与帮助

如果你遇到问题或有任何建议：

1. 查看[详细文档](docs/)
2. 搜索[已存在的 issues](https://github.com/LiGameAcademy/godot_core_system/issues)
3. 创建新的 [issue](https://github.com/LiGameAcademy/godot_core_system/issues/new)，提供插件提交/版本、Godot 版本、操作系统、最小复现步骤、预期行为与实际结果。

欢迎提供真实接入反馈：使用了哪个模块、在哪一步遇到困难、是否继续在项目中使用。[运营方案](docs/open_source_operations_plan.md)记录采用试点和发布准备，文中里程碑均为待执行计划。

### 社区交流

- 加入我们的 [Discord 社区](https://discord.gg/V5nuzC2BcJ)
- 关注我们的 [itch.io](https://godot-li.itch.io/) 主页
- 为项目点亮 ⭐ 以示支持！

## 🙏 致谢

- 感谢所有为项目做出贡献的开发者！
- 感谢[老李游戏学院](https://wx.zsxq.com/group/28885154818841)的每一位同学！

---

<div align="center">
  <strong>由 老李游戏学院 用 ❤️ 构建</strong><br>
  <sub>让游戏开发变得更简单</sub>
</div>

原生主场景切换与独立淡入淡出见 [CoreScenes](docs/systems/native_scenes.md)，提供独立示例、生命周期检查及 C# 行为映射；旧场景接口继续保留。

引擎暂停/倍速的独占作用域及退出恢复见 [CoreTime](docs/systems/core_time_scope.md)，与 C# 生命周期对齐；旧 TimeManager 的私有时钟仍独立保留。

与 C# 对齐的同步发布、快照分发及订阅令牌见 [最小 CoreEventBus](docs/systems/core_event_bus.md)。旧优先级、过滤与延迟事件模块保留为独立扩展。

与 C# 对齐的版本化 JSON 见 [CoreSaveStore](docs/systems/core_save_store.md)。Windows x64 的安全替换使用随附 [原生扩展](native/atomic_file/README.md)，导出时需要包含 DLL；其他平台需独立验证打包。旧存档管理器格式保留。

与 C# 对齐的键鼠重绑定见 [CoreInputs](docs/systems/core_inputs.md)：显式动作组、配置校验、冲突检查、默认恢复和独立捕获/持久化示例。旧录制、缓冲与虚拟轴保留为独立扩展。
