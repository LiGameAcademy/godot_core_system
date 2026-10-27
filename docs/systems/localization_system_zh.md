# 多语言模块（#92 试用版）

这个可选模块只管理语言偏好和启动恢复，翻译内容仍由 Godot 的 `TranslationServer`、`tr()`、`tr_n()` 和原生导入器处理。默认关闭；启用后使用已有 ConfigManager 保存选择，ConfigManager 关闭时仍可切换语言。

## 接入

1. 在项目设置的 Localization / Translations 中配置项目自己的原生翻译资源。CSV 通过 Godot 导入生成 `.translation`，也可以沿用项目的 PO 资源。
2. 启用 `godot_core_system/module_enable/localization_manager`。需要保存时同时启用 `module_enable/config_manager`，并配置可写的 ConfigManager 路径。
3. 通过 `CoreSystem.localization_manager` 调用；关闭时该 getter 返回 null，不实例化语言模块。

```gdscript
func choose_language(preference: String) -> void:
    var manager: CoreSystem.LocalizationManager = CoreSystem.localization_manager
    if manager == null:
        return
    var error: Error = manager.set_preferred_locale(preference, true)
    if error != OK:
        # 保存失败时实际语言可能已切换；界面应显示错误而非声称已保存。
        push_warning(error_string(error))
```

也可以单独实例化 `source/localization_system/localization_manager.tscn`。在加入场景树前，用 `configure_persistence(config)` 显式注入已有 ConfigManager；没有注入则只提供运行时切换。不要同时启用多个负责恢复偏好的实例。

## 偏好和实际语言

- `get_preferred_locale()` 返回用户选择，例如 `auto`、`zh_Hant`。配置键是 `[localization] preferred_locale`；保存 `auto` 时不写入某次解析出来的系统语言。
- `get_locale()` 直接读取 TranslationServer，是实际语言的唯一来源。外部直接调用原生 `set_locale()` 时，通过翻译变更通知更新 `locale_changed(old, new)`；不会改写用户偏好。
- `get_available_locales()` 读取已加载的原生翻译资源。模块不加载、清空或卸载宿主的翻译资源，也不在退出时恢复全局语言。
- `resolve_locale()` 保留系统语言的地区、文字信息，按原生 `compare_locales()` 相似度选择；并列时按 locale 字符顺序稳定选择。明确的简体、繁体文字系统不互选，常见中文地区映射为 Hans / Hant。通用 `zh` 没有表达简繁倾向，建议提供带地区或文字系统的选择。
- `auto` 没有系统语言候选时，尝试项目 `internationalization/locale/fallback`，空值按 en。显式选择找不到候选则返回 ERR_UNAVAILABLE，不改偏好或实际语言。这里是“选择语言”的回退；单条文案缺失的回退仍由 Godot 原生处理。

启动时通过 `get_startup_error()` 查询恢复结果。命令行 `--language` 和项目 `internationalization/locale/test` 覆盖启动实际语言，仍读取已存偏好；随后手动选择可以切换语言。资源未加载、损坏的偏好或不存在的已选语言会返回错误，保留原生当前语言，不静默修复用户配置。动态添加翻译资源后，可显式调用 `restore_preference()` 重试；本版不做 DLC 生命周期管理。

## 保存和通知

`set_preferred_locale(preference, persist=false)` 先校验、切换，再按需调用 ConfigManager 的 `set_value()` 和 `save_config()`。没有配置服务返回 ERR_UNCONFIGURED，磁盘失败返回 ERR_FILE_CANT_WRITE，旧配置键不是字符串返回 ERR_INVALID_DATA；这三种保存失败不会撤销已完成的切换，并发出 `preference_save_failed(preference, error)`。

`preference_changed` 只表示选择改变，`locale_changed` 只表示实际语言改变。重复选择相同语言不会重复发实际语言事件。信号回调里再次调用切换 API 返回 ERR_BUSY；需要再次选择时延后到本次调用结束。

同一语言下替换翻译资源，不会成为业务语言改变。资源拥有方应在完成资源增删后广播原生刷新通知，不能依赖再次设置相同 locale 自动刷新已缓存的文字：

```gdscript
func refresh_replaced_translations() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
```

这会通知当前场景树的控件和动态文字拥有者；多场景树/翻译域隔离并非本版承诺。模块不管理资源替换，也不额外发送 `locale_changed`。

静态 Label / Button 使用原生自动翻译即可；动态的金币文字等缓存结果，由所属界面响应 `NOTIFICATION_TRANSLATION_CHANGED` 后重新执行 `tr()`。模块不扫描 UI。玩家名字等输入内容应关闭自动翻译。占位符格式化、上下文和复数规则沿用原生接口，本模块不引入第二套插值器或字典。

## 试用演示

运行 `examples/localization_demo/localization_demo.tscn`：选择 English / 简体 / 繁体 / 跟随系统，收集金币，输入名字，勾选“记住我的选择”并重启验证恢复。演示自身带一个服务实例，试用时保持 CoreSystem 的语言模块关闭；真实工程使用上面的 CoreSystem 集成方式。

`demo.csv` 是唯一可编辑的文案来源；三个 `.translation` 文件是 Godot 原生导入生成的资源，随本试用提交以支持首次启动。修改 CSV 后在 Godot 重新导入，不直接编辑生成资源。导入器可能自动把演示翻译加入项目加载列表；接入真实游戏时，从 Localization 列表移除这些演示条目，仅保留自己的翻译。演示会保留宿主已注册的同一翻译资源，退出只移除自己添加的资源。SystemFont 使用本机字体；发布游戏需要自行提供支持目标文字的字体资源。

## 验证与边界

本次实测 Godot 4.7.2 Mono 的 GDScript 路径：语言选择、简繁匹配、外部切换通知、磁盘保存/重建服务恢复、无配置与保存失败、重入、演示按钮和资源清理；另测默认关闭、启用但配置关闭、正常启动恢复、命令行与项目测试语言覆盖，以及既有模块开关回归。实际 OpenGL 渲染检查了英文、简体和繁体画面。

单元场景是 `test/unit/localization_checks.tscn` 和 `localization_demo_checks.tscn`，需要没有全局翻译资源且语言模块关闭的隔离宿主。启动场景 `localization_module_checks.tscn` 通过项目自定义 `issue92/mode` 选择 disabled（默认）、runtime 或 persist；runtime 开启语言模块、关闭 ConfigManager，persist 开启两者并用配置文件预置 zh_TW。两种启用模式均预先在项目列表加载三份演示翻译；覆盖模式额外设置 locale/test=en 或启动参数 `--language en`。通过标志应为 PASS，不能只检查引擎退出码。

当前明确支持并实测 Godot 4.7.2，旧版兼容后续验证。补充的 `localization_native_checks.tscn` 在 4.7.2 Mono 宿主和标准版 Windows 调试导出包中各通过 19 项检查，覆盖 PO 上下文、英法复数规则（含 0）、缺失文本回退、输入保护、同 locale 资源替换刷新和伪本地化。导出测试使用纯 GDScript 的标准 Windows 模板；不代表 C#、Web、移动端或完整游戏导出已验收。

两个真实工程的隔离副本接入尝试尚未完成完整验收：塔防有缺失纹理与 SpriteTower 节点错误，ARPG 的资源有未解决 Git 冲突。塔防的 11 项语言断言通过，仍不能将带启动错误的整工程算作通过。详见 [验收记录与复现步骤](localization_acceptance_zh.md)。本次未修改原游戏工程，旧模块依赖和退出诊断也未重构。试用实现已在 PR #93 合并；Refs #92。
