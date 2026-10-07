# Godot Core System

<div align="center">

English | [简体中文](README_zh.md)

![Godot validation baseline](https://img.shields.io/badge/Godot-tested%20on%204.7.2-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/LiGameAcademy/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/LiGameAcademy/godot_core_system)](https://github.com/LiGameAcademy/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](docs/CONTRIBUTING.md)

Lightweight foundation systems for Godot indie developers: reduce repeated engineering and make small games easier to finish and maintain.

[Getting Started](#-getting-started) •
[Documentation](docs/) •
[Examples](examples/) •
[Direction & Operations Plan (中文)](docs/open_source_operations_plan.md) •
[Contributing](docs/CONTRIBUTING.md) •
[Support and Help](#-support--help)

</div>

## What you can build

Choose a system for a concrete task and start with its example. The project favors small APIs, explicit ownership and documented failure behavior.

| Task | Service and practical boundary | Start here |
| --- | --- | --- |
| Switch menus and levels with a fade | CoreScenes reports completion, rejects overlapping requests and uses an optional persistent transition. Resource loading is synchronous. | [API](docs/systems/native_scenes.md) · [Two-scene example](examples/native_scenes/README.md) |
| Save and load a validated snapshot | CoreSaveStore provides versioned JSON, validation and error results. It distinguishes missing files from invalid data; Windows replacement uses a native extension. | [API and counter example](docs/systems/core_save_store.md) |
| Read and persist local settings | ConfigFile state with explicit paths, optional diagnostics and no AutoLoad dependency. | [API](docs/systems/configuration.md) · [Configuration example](examples/configuration/README.md) |
| Change keyboard and mouse bindings | CoreInputs manages an explicit action group, checks conflicts and restores defaults while preserving joypad inputs. | [API and capture/persistence example](docs/systems/core_inputs.md) |
| Manage state transitions and countdowns | Value/behavior state machines and an explicitly stepped timer make lifecycle rules visible. | [State machines](docs/systems/state_machine_system.md) · [Timer](docs/systems/core_timer.md) |
| Scope events and engine pause/speed changes | Subscription tokens and time scopes give their owners explicit cleanup responsibilities. | [Events](docs/systems/core_event_bus.md) · [Time](docs/systems/core_time_scope.md) |
| Classify objects and evaluate rule conditions | Local tags and triggers support explicit rule composition. | [Tags example](examples/tags/README.md) · [Triggers example](examples/triggers/README.md) |

Audio, configuration, resource management, legacy input/save/scene features, threading and frame-splitting utilities are also documented below. Their scope differs from the independent services above.

### Lightweight by design

- Adopt capabilities around actual needs; keep game values, victory rules and UI in your game.
- Use Godot scenes, Resources and signals as the foundation. Add small shared lifecycle rules when real projects justify them.
- CoreSystem remains an application-service entry point for legacy managers. Independent services such as CoreScenes, CoreInputs and CoreSaveStore do not require that AutoLoad.
- Choose one owner and one modification gateway for each state. Avoid mixing legacy and independent services on the same operation.

Independent ownership does not yet mean every module has a separately packaged download. Dependency lists and installation friction are part of the [operations plan (中文)](docs/open_source_operations_plan.md).

## 🚀 Getting Started

### System Requirements

- Current independent-service validation records use Godot 4.7.2 / Windows x64, in editor and headless hosts. See each module's verification section.
- The included Windows x64 persistence extension requires Godot 4.7+. Exported packages and other platforms still need separate acceptance.
- Basic knowledge of GDScript and Godot Engine.

The project originated with Godot 4.4-era APIs. That historical target is not a compatibility guarantee for the current checkout. Shared behavior with C# is documented module by module; the two versions have different coverage.

The [versioned JSON service](docs/systems/core_save_store.md) uses a [Windows x64 native extension](native/atomic_file/README.md). Include its DLL when exporting; other platforms need validated packaging. This service has a separate format from the legacy save manager.

### Installation Steps

1. Obtain the repository contents from a selected commit or tag and record that revision. If using a [release](https://github.com/LiGameAcademy/godot_core_system/releases), check its compatibility notes.
2. Place the contents under `addons/godot_core_system/`, with `plugin.cfg` directly inside that directory. This repository is a plugin; use an existing or new Godot host project.
3. For legacy managers, enable `godot_core_system` in Project Settings → Plugins. The plugin registers the CoreSystem AutoLoad.
4. For an independent service, follow its setup and ownership instructions. Enabling CoreSystem is optional for these services; scene transitions still need a persistent owner, and Windows save examples need the native extension.

### First successful integration

Start with the [two-scene example](examples/native_scenes/README.md): register its SceneExampleHost AutoLoad, run `scene_a.tscn`, and use the button to switch through the fade. Then follow the API document to move ownership into your application's persistent node.

For persistence, run the [counter example](examples/save_contract/save_contract_example.tscn) using its [API document](docs/systems/core_save_store.md). For rebinding, use [input_bindings](examples/input_bindings/) and the setup in the [input document](docs/systems/core_inputs.md).

Legacy APIs remain documented below. Independent APIs are separate contracts, including save formats and event routing; replacing old calls requires checking the relevant migration notes.

## 📚 Documentation

Legacy managers and broader system documentation:

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

### Historical Game Examples

These links show earlier use of the project. Their current plugin revisions and compatibility need confirmation before they are used as cases for a new release.

- [GodotPlatform2D](https://github.com/LiGameAcademy/GodotPlatform2D) - A 2D platform game example developed using the godot_core_system framework, demonstrating practical application of the framework in actual game development.
- [Exocave : 2d platform jumping puzzle game. Gravity flip as the core mechanism](https://github.com/youer0219/Exocave) - Developed using the godot_core_system framework's scene_system.

## 🤝 Contributing

We welcome all forms of contributions! Whether it's new features, bug fixes, or documentation improvements. See our [Contributing Guidelines](docs/CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💖 Support & Help

If you encounter any issues or have suggestions:

1. Check the [detailed documentation](docs/)
2. Search through [existing issues](https://github.com/LiGameAcademy/godot_core_system/issues)
3. Create a new [issue](https://github.com/LiGameAcademy/godot_core_system/issues/new) with the plugin revision, Godot version, OS, minimal steps, expected behavior and actual result.

Real integration reports help us improve adoption: which module did you use, what blocked setup, and does it remain in your project? The [operations plan (中文)](docs/open_source_operations_plan.md) describes the proposed pilot and release preparation; its milestones are planned work.

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
## State and timer semantics

See [state machines](docs/systems/state_machine_system.md) for value flows, behavior lifecycle, optional nested driving and compatibility changes, and [independent timer](docs/systems/core_timer.md) for deterministic countdown rules.

Native main-scene switching and optional persistent fades are available through [CoreScenes](docs/systems/native_scenes.md), with a standalone example and C# behavior mapping. Legacy scene APIs remain available.

Exclusive engine pause/speed ownership and snapshot restoration are available through [CoreTime scopes](docs/systems/core_time_scope.md), with a standalone example and matching C# lifecycle behavior.

For synchronous snapshot events and disposable scene-owned tokens with C# lifecycle parity, see [minimal CoreEventBus](docs/systems/core_event_bus.md). Legacy event extensions remain separate.

Local classification and rule conditions with dual-language parity are available through [CoreTags](docs/systems/core_tags.md), with a [standalone example](examples/tags/README.md). Legacy object tagging remains a separate extension.

The [character tag demo](examples/tag_demo/README.md) also uses local CoreTags without AutoLoad. Old tag classes are deprecated adapters; see the [migration changes](docs/systems/tag_system.md).

Local [CoreTrigger](docs/systems/core_trigger.md) adds explicit condition/quota evaluation with a [standalone example](examples/triggers/README.md); event and timer ownership remain with the caller.

Caller-owned [CoreGameSession](docs/systems/core_game_session.md) adds a fixed identity, lifecycle phases, commit-before-notification and optional pause/resume adapters. The [count/timer example](examples/game_session/README.md) uses two independent end rules without a global manager or game assets.

Caller-owned [CoreEntities](docs/systems/entities.md) composes a loaded scene and an exclusive instance pool. [entities](examples/entities/README.md) demonstrates per-activation leases, reset and mutable Resource isolation without AutoLoad.

Independent audio now provides scene-owned CoreAudio/CoreMusic, exclusive CoreAudioBusScope and optional explicit CoreAudioPreferences. No CoreSystem AutoLoad is required; see [audio contracts](docs/systems/audio_system.md) and [minimal example](examples/audio/README.md). Legacy AudioManager migration changes are recorded in the contract.
