# Godot 核心系统

<div align="center">

简体中文 | [English](README.md)

![Godot v4.4](https://img.shields.io/badge/Godot-v4.4-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/Liweimin0512/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

一个为 Godot 4.4+ 设计的高度模块化、易扩展的核心系统框架

[快速开始](#-快速开始) •
[文档](docs/) •
[示例](examples/) •
[贡献](docs/CONTRIBUTING.md) •
[支持与帮助](#-支持与帮助)

</div>

## ✨ 特性

- 🔧 **插件架构** : 易于扩展和自定义
- 📱 **项目设置集成** : 通过 Godot 的项目设置配置所有系统
- 🛠️ **开发工具** : 内置调试和开发工具
- ManagerOfManagers : MOM 结构，易扩展和自定义
  - 🎮 **状态机系统** : 灵活强大的游戏逻辑状态管理
  - 💾 **序列化系统** : 易用的存档/读档功能和配置管理
  - 🎵 **音频系统** : 全面的音频管理，支持分类和过渡
  - 🎯 **输入系统** : 统一的输入处理，支持动作映射和事件管理
  - 📝 **日志系统** : 详细的日志系统，支持多种输出通道
  - 🎨 **资源系统** : 高效的资源加载和管理
  - 🎬 **场景系统** : 简化场景转换和管理
  - 🏷️ **标签系统** : 灵活的对象标签和分类系统
  - 🔄 **触发器系统** : 事件驱动的触发器系统，支持条件和动作
- 更多实用工具类：
  - ⚡ **分帧执行器** : 性能优化工具，将耗时任务分散到多帧执行
  - 

## 🚀 快速开始

### 系统要求

- Godot Engine 4.4+
- 基本的 GDScript 和 Godot 引擎知识

### 安装步骤

1. 从[发布页面](https://github.com/Liweimin0512/godot_core_system/releases)下载最新版本
2. 将 `godot_core_system` 文件夹复制到你的 Godot 项目的 `addons` 目录下
3. 在 Godot 编辑器中启用插件：
   - 打开项目设置（Project -> Project Settings）
   - 切换到插件标签页（Plugins）
   - 找到 "Godot Core System" 并启用

### 基础使用

```gdscript
extends Node

func _ready():
 # 通过 CoreSystem 单例访问各个管理器
 CoreSystem.state_machine_manager  # 状态机管理器
 CoreSystem.save_manager          # 存档管理器
 CoreSystem.audio_manager         # 音频管理器
 CoreSystem.input_manager         # 输入管理器
 CoreSystem.logger               # 日志管理器
 CoreSystem.resource_manager     # 资源管理器
 CoreSystem.scene_manager        # 场景管理器
 CoreSystem.tag_manager         # 标签管理器
 CoreSystem.trigger_manager     # 触发器管理器
```

## 📚 文档

每个系统的详细文档：

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

### 完整游戏示例

- [GodotPlatform2D](https://github.com/LiGameAcademy/GodotPlatform2D) - 一个使用 godot_core_system 框架开发的 2D 平台游戏示例，展示了框架在实际游戏开发中的应用。
- [Exocave : 2d平台跳跃解密游戏。以重力翻转为核心机制](https://github.com/youer0219/Exocave) - 使用 godot_core_system 框架的 scene_system。

## 🤝 参与贡献

我们欢迎各种形式的贡献！无论是新功能、bug 修复，还是文档改进。详情请查看[贡献指南](docs/CONTRIBUTING.md)。

## 📄 开源协议

本项目采用 MIT 开源协议 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 💖 支持与帮助

如果你遇到问题或有任何建议：

1. 查看[详细文档](docs/)
2. 搜索[已存在的 issues](https://github.com/Liweimin0512/godot_core_system/issues)
3. 创建新的[issue](https://github.com/Liweimin0512/godot_core_system/issues/new)

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
