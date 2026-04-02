# Godot Core System

<div align="center">

English | [简体中文](README.md)

![Godot v4.4](https://img.shields.io/badge/Godot-v4.4-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/Liweimin0512/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A highly modular and extensible core system framework designed for Godot 4.4+

[Getting Started](#-getting-started) •
[Documentation](docs/) •
[Examples](examples/) •
[Contributing](docs/CONTRIBUTING.md) •
[Support and Help](#-support--help)

</div>

## ✨ Features

- 🎮 **State Machine System** - Flexible and powerful state management for game logic
- 💾 **Serialization System** - Easy-to-use save/load functionality with config management
- 🎵 **Audio System** - Comprehensive audio management with categories and transitions
- 🎯 **Input System** - Unified input handling with action mapping and event management
- 📝 **Logger System** - Detailed logging system with multiple output channels
- 🎨 **Resource System** - Efficient resource loading and management
- 🎬 **Scene System** - Scene transition and management made easy
- 🏷️ **Tag System** - Flexible object tagging and categorization system
- 🔄 **Trigger System** - Event-driven trigger system with conditions and actions
- ⚡ **Frame Splitter** - Performance optimization tool for distributing heavy tasks across frames
- 🔧 **Plugin Architecture** - Easy to extend and customize
- 📱 **Project Settings Integration** - Configure all systems through Godot's project settings
- 🛠️ **Development Tools** - Built-in debugging and development tools

## 🚀 Getting Started

### System Requirements

- Godot Engine 4.4+
- Basic knowledge of GDScript and Godot Engine

### Installation Steps

1. Download the latest release from the [releases page](https://github.com/Liweimin0512/godot_core_system/releases)
2. Copy the `godot_core_system` folder to your Godot project's `addons` directory
3. Enable the plugin in Godot:
   - Open Project Settings (Project -> Project Settings)
   - Switch to the Plugins tab
   - Find "Godot Core System" and enable it

### Basic Usage

```gdscript
extends Node

func _ready():
    # Access managers through CoreSystem singleton
    CoreSystem.state_machine_manager  # State Machine Manager
    CoreSystem.save_manager          # Save Manager
    CoreSystem.audio_manager         # Audio Manager
    CoreSystem.input_manager         # Input Manager
    CoreSystem.logger               # Logger
    CoreSystem.resource_manager     # Resource Manager
    CoreSystem.scene_manager        # Scene Manager
    CoreSystem.tag_manager         # Tag Manager
    CoreSystem.trigger_manager     # Trigger Manager
```

## 📚 Documentation

Detailed documentation for each system:

| System               | Description                           | Documentation                             |
| -------------------- | ------------------------------------- | ----------------------------------------- |
| State Machine System | Game state management and transitions | [View Docs](docs/systems/state_machine_system.md) |
| Audio System         | Sound and music management            | [View Docs](docs/systems/audio_system.md)         |
| Input System         | Input control and event handling      | [View Docs](docs/systems/input_system.md)         |
| Logger System        | Logging and debugging                 | [View Docs](docs/systems/logger_system.md)        |
| Resource System      | Resource loading and management       | [View Docs](docs/systems/resource_system.md)      |
| Scene System         | Scene switching and management        | [View Docs](docs/systems/scene_system.md)         |
| Tag System           | Object tagging and categorization     | [View Docs](docs/systems/tag_system.md)           |
| Trigger System       | Event-driven triggers and conditions  | [View Docs](docs/systems/trigger_system.md)       |
| Config System        | Configuration management              | [View Docs](docs/systems/config_system.md)        |
| Save System          | Game save management                  | [View Docs](docs/systems/save_system.md)          |

Detailed documentation for each utility:

| Utility Name         | Description                           | Documentation                             |
|-------------------|----------------------------------|----------------------------------------|
| Frame Splitter       | Performance optimization tool         | [View Docs](docs/utils/frame_splitter.md)       |
| Async IO Manager     | Non-blocking file I/O, strategies   | [View Docs](docs/utils/async_io_manager.md)   |
| Threading System     | Simplified multi-threading management | [View Docs](docs/utils/threading_system.md)     |
| Random Picker        | Weighted random selection tool        | [View Docs](docs/utils/random_picker.md)      |

## 🌟 Example Projects

Visit our [example projects](examples/) to understand the framework's practical applications and best practices.

### Complete Game Examples

- [GodotPlatform2D](https://github.com/LiGameAcademy/GodotPlatform2D) - A 2D platform game example developed using the godot_core_system framework, demonstrating practical application of the framework in actual game development.
- [Exocave : 2d platform jumping puzzle game. Gravity flip as the core mechanism](https://github.com/youer0219/Exocave) - Developed using the godot_core_system framework's scene_system.

## 🤝 Contributing

We welcome all forms of contributions! Whether it's new features, bug fixes, or documentation improvements. See our [Contributing Guidelines](docs/CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💖 Support & Help

If you encounter any issues or have suggestions:

1. Check the [detailed documentation](docs/)
2. Search through [existing issues](https://github.com/Liweimin0512/godot_core_system/issues)
3. Create a new [issue](https://github.com/Liweimin0512/godot_core_system/issues/new)

### Community

- Join our [Discord Community](https://discord.gg/V5nuzC2BcJ)
- Follow us on [itch.io](https://godot-li.itch.io/)
- Star ⭐ the project to show your support!

## 🙏 Acknowledgments

- Thanks to all developers who contributed to this project!
- Special thanks to every student at [Li's Game Academy](https://wx.zsxq.com/group/28885154818841)!
- Built with ❤️ by the Godot community

---

<div align="center">
    <strong>Built by Liweimin0512 with ❤️</strong><br>
    <sub>Making game development easier</sub>
</div>