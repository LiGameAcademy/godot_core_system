# 配置系统

ConfigManager 的旧公开方法继续保留，脚本现可独立安装，无需 CoreSystem 或日志模块。完整接口、所有权、双语言映射和检查命令见[配置说明](configuration.md)，可运行用法见[独立示例](../../examples/configuration/README.md)。

```gdscript
const ConfigScript: Script = preload("res://addons/godot_core_system/source/config_system/config_manager.gd")
var settings: Node = ConfigScript.new("user://settings/player.cfg")
add_child(settings)
settings.set_value("audio", "volume", 0.8)
if not settings.save_config():
    push_error("Settings save failed: " + error_string(settings.last_error))
```

路径通过实例导出属性或显式构造参数提供。项目设置只提供构造时的默认值，不再作为动态只读属性；CoreSystem.config_manager 仍是可选的旧入口。显式路径构造立即加载；无参数构造在 ready 时加载，确保序列化的导出路径已经应用。未进入树的实例需显式加载。

修改和重置只影响内存，需要调用 save_config 才会保存。auto_save 设置及属性保留为旧元数据，不会触发自动保存；旧文档的自动保存和导出属性只读描述不符合实现，已更正。

缺失文件加载为空配置；其它加载错误保留原内存状态和修改标记。保存失败返回 false，并通过 last_error 提供 IO 结果，不依赖日志 getter。分段更新为合并，缺省键不删除；分段快照隔离嵌套集合。共享文件路径只由一个拥有者写入，调用者提供的可变集合和 Resource 仍需遵守自身所有权。

此处使用 Godot ConfigFile 原生写入，不提供与 JSON 存档相同的安全替换保证。#15/#40 的其它缺陷继续独立跟踪；全模块禁用、依赖缺失与启动/线程策略并未在本项中完成。
