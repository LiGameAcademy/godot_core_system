# 最小输入重绑定

CoreInputs 是直接使用 Godot InputMap 的独立服务，不依赖旧 InputManager 或 AutoLoad。它负责已有动作组的键盘及鼠标绑定配置，不拥有输入录制、连招缓冲、虚拟轴或游戏行为。

```gdscript
var inputs: CoreInputs = CoreInputs.new()

func initialize_bindings() -> Error:
	return inputs.register_actions([&"jump", &"interact"])

func rebind_jump() -> Error:
	var binding: CoreInputBinding = CoreInputBinding.new(CoreInputBinding.Kind.PHYSICAL_KEY, KEY_SPACE)
	return inputs.rebind(&"jump", binding)
```

注册前必须由项目设置或宿主创建动作，注册动作不超过 64 个，名称长度 1–128，不能重复。注册记录当前默认事件的独立副本；之后的恢复不调用 load_from_project_settings，不重置其他动作。每个受管动作只由一个服务在 Godot 主线程修改，不同时启用旧 InputManager 对同组动作写入。释放服务不自动恢复绑定，业务场景可退出，应用拥有者继续持有它。

## 绑定与捕获

CoreInputBinding 包含 Kind（0：逻辑键，1：物理键，2：鼠标按钮）、Code 与 Ctrl/Alt/Shift/Meta 四个布尔修饰键。使用当前 Godot Key 中可命名的有效键和 MouseButton 1–9，不将 Unknown、任意整数或合并修饰键掩码当键码。配置事件只选择一种键身份，不支持 key_label、左右位置或 command_or_control_autoremap；这些键盘默认事件注册时明确拒绝，不悄悄丢字段。

`from_event(event, physical, true)` 用于捕获：只接受按下，忽略释放、键盘 echo、鼠标移动及单独 Shift/Ctrl/Alt/Meta。真实键盘事件含逻辑和物理字段，由 physical 显式选择。捕获状态、超时及取消键由宿主 UI 拥有；服务不监听全局输入。无效绑定的 to_event 返回 null，C# 对应抛参数异常。

冲突在受管组中检查相同 Code 与四个修饰键；同码的逻辑/物理键保守视为冲突，重复项也拒绝。不同布局下逻辑/物理不同码仍可能对应同一个实际键，因此建议同组使用一致的键身份，不能把配置冲突检查当作跨布局等价证明。其他动作及 UI 内置动作不参与检查。

查询动作应使用精确修饰键匹配，例如 `event.is_action_pressed(action, false, true)`。默认的非精确匹配允许额外修饰键，不属于这个冲突契约。逻辑与物理键含义见 [Godot InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html)，动态动作接口见 [InputMap](https://docs.godotengine.org/en/stable/classes/class_inputmap.html)。

## 应用、恢复与保存

rebind 替换一个动作全部键盘/鼠标项为一项；现有手柄及其他事件、死区、非受管动作保持不变。批量配置采用 `{"Actions":{"jump":[{"Kind":1,"Code":32,"Ctrl":false,"Alt":false,"Shift":false,"Meta":false}],"interact":[]}}`。必须精确包含受管组，每动作 0–16 项，空数组表示解绑键盘/鼠标。未知字段、无效类型或冲突先返回错误，不修改任何动作；缺少已注册引擎动作时整组拒绝。

to_data 返回全新数据，修改它不会更改 InputMap。apply_data 先验证完整候选配置，再应用；restore_defaults 恢复注册时所有事件的独立副本，包括手柄事件，死区保持当前值。恢复前检查整组仍存在，避免只恢复一部分。它不自动写磁盘。

与现有 CoreSaveStore 组合：

```gdscript
func create_binding_store() -> CoreSaveStore:
	var directory: CoreSaveDirectory = CoreSaveDirectory.new(ProjectSettings.globalize_path("user://core_system"))
	return directory.create_store("input_bindings", 1, inputs.validate_data)
```

保存 `inputs.to_data()`；读取成功且 found 后再调用 apply_data。读取失败时保留当前绑定与文件；调用方显示错误。CoreInputs 自身没有隐式 IO、自动保存或自动加载。与 C# CoreInputProfile 使用相同字段、整数 Kind 和版本化 JSON 外层；动作组或格式变化需显式升级版本。

## 示例与验证

[独立示例](../../examples/input_bindings/input_bindings_example.tscn)支持两个动作、逻辑/物理切换、捕获、Escape/按钮取消、恢复、保存和加载。鼠标绑定点击控件外空白处，控件点击由 GUI 消费。每实例创建独立临时动作，退出仅清理自己的动作；保存使用稳定的 0/1 示例标识映射，避免实例 ID 写入文件。默认路径 user://core_system/input_bindings_example.json。

Godot 4.7.2 中用 `--headless --script res://addons/godot_core_system/test/unit/input_contract_checks.gd` 运行契约检查；`input_example_checks.gd` 验证真实输入分发、按钮、A/B 隔离、失败保留及退出清理。不代表导出或不同键盘布局人工验收通过。

当前 GD 32 项契约与 14 项示例检查通过；C# 对应 31 项与 14 项通过。input_interop_checks.gd 配合 C# input_interop_checks.tscn 对同一个专用绝对路径文件执行 GD 写入 → C# 读取/修改/写入 → GD 读取，已验证真实双向 JSON 互读；仅操作调用方提供的专用测试文件。
