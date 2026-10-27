# #92 补充验收记录

当前确认支持 Godot 4.7.2；用户已明确选择“旧版本兼容后续验证”。这份记录补充 PR #93 的初始试用，避免把语言断言通过等同于整个游戏可正常运行。

## 已通过的原生边界

`test/unit/localization_native_checks.tscn` 在 4.7.2 Mono 的开发宿主，以及标准版 4.7.2 的 Windows 调试导出包中各通过 19 项：

- 同一个 Open 的两个 PO 上下文分别查询。
- 英语和法语的 0 / 1 / 2 复数，特别验证法语 0 使用单数。
- 法语缺失文案回退到项目英语；完全未知的键保留原文。
- 动态 Label 响应原生翻译通知；与文案键相同的玩家输入关闭自动翻译。
- 同 locale 替换资源后显式通知刷新，缓存文字更新但业务语言事件不增加。
- 原生伪本地化仍可用，实际 locale 和用户偏好不被改写。
- fixture 只移除自己的翻译资源。

原生 PO 格式和上下文/复数接口沿用 [Godot gettext 指南](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html)。没有实现新的翻译查找或复数算法。

## 复跑与导出

从仓库根目录执行下面的 Windows PowerShell 脚本。使用标准版 Godot 4.7.2 和相同版本的 Windows 导出模板；Mono 仅跑宿主检查时可加 `-SkipExport`。

```powershell
./test/tools/run_localization_acceptance.ps1 -GodotPath 'C:/tools/Godot_4.7.2_console.exe'
```

也可传 `-WorkDirectory` 指定一个空的目录，必须在插件目录之外。脚本复制测试所需的插件内容，不通过 junction 导入原仓库；导入产生的资源只写入副本。默认保留临时宿主、日志、exe 和 pck，输出其位置。

脚本先导入，再恢复没有全局翻译资源的测试项目，执行原生边界、偏好规则与演示场景；随后构建 Windows 调试导出包并执行原生边界场景。成功必须同时有正常退出、PASS 标志和没有脚本/资源/节点错误，不能只看退出码。

本机受限运行环境会输出系统根证书读取失败，以及编辑器缓存/设置目录不可写。脚本只放行这些已知环境诊断，保留原始日志；其它 ERROR、脚本错误、断言失败和资源泄漏诊断均判为失败。因此这里的通过表示相关行为通过，不表示引擎日志完全没有诊断。

导出检查仅覆盖 Windows x86_64、纯 GDScript、调试模板和原生语言行为；不包含导出包中的持久化重启、C#、Web、移动端、正式字体打包或完整游戏流程。本机 4.6 只有导出运行时，不能读取 4.7.2 生成的 PCK v4，该尝试不算作 4.6 插件兼容性测试。

## 两个真实工程的接入尝试

对塔防 GDScript 工程和 quickstart-arpg 的 Godot 工程创建隔离副本，原工程未修改。接入 CoreSystem 并保持无关模块关闭，注册两份原生 PO 作为测试目录，启用语言模块和 ConfigManager。

塔防副本的金币显示改成以下两处：收到金币更新时保存显示所需的数值并用 tr() 格式化；收到翻译通知时用同一个数值重新生成文字。业务金币仍由原游戏根节点管理。

```gdscript
var _displayed_coin: int = 0

func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
        lab_coin.text = tr("INTEGRATION_COINS").format({"count": _displayed_coin})

func update_coin_display(coin: int) -> void:
    _displayed_coin = coin
    lab_coin.text = tr("INTEGRATION_COINS").format({"count": coin})
    # 原有塔按钮费用刷新逻辑接在此处。
```

通用宿主场景 `test/integration/localization_host_checks.tscn` 从项目自定义设置读取目标；没有配置时明确失败，不声称是插件通用单元场景：

```ini
[localization_acceptance]
mode="tower"
scene="res://main.tscn"
```

ARPG 使用 mode="arpg"、scene="res://scenes/main.tscn"。两者都需启用 localization_manager / config_manager / logger，将配置路径设为 res://localization-checks.cfg，并预先在 Localization 列表添加 `test/integration/fixtures/localization/host_en.po` 和 `host_zh_tw.po`。

| 宿主 | 语言检查 | 完整宿主验收 |
| --- | --- | --- |
| 塔防 | 11 项断言通过：无额外金币事件也能刷新，金币/生命不因切语言改变，后续金币更新和配置保存可用 | **未通过**：enemy_05.tscn 引用缺失的 enemy_tank_01_1.tres；塔场景脚本还查找不存在的 SpriteTower 节点 |
| ARPG | 已准备健康/法力显示及数值保留检查，但未得到完整可用宿主结果 | **未通过**：data/ability_status/dash_status.tres 有未解决的 Git 冲突标记，导入/启动还出现资源及 Autoload 错误 |

不能用塔防日志中的 PASS 行掩盖同一日志的资源/节点错误。两个原工程的启动问题应先在各自工程中处理，再复跑宿主检查和真实游戏长流程；本次不替这些工程选择冲突版本或补无关素材。

因此 #92 保留开放，剩余验收是两个完整实际工程、游戏内长流程、导出保存恢复及其它平台/旧版本兼容。当前服务 API 和语言匹配策略未改动。
