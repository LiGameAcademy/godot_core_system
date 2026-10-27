# 输入扩展独立接入

InputManager 不再获取 CoreSystem.config_manager，InputConfigAdapter 不再查找或订阅总入口。两者可在不启用插件的工程使用。观察、改键和配置持久化分别由显式拥有者负责。

## 安装与示例

运行 `tools/create_input_module_host.ps1 -Destination <新的绝对目录>` 创建宿主。工具拒绝覆盖已有目录，`module_manifest.txt` 明确列出 10 个脚本、对应 UID 和 InputManager 场景；只安装所需输入文件，不复制其他模块。先用 Godot 4.7.2 导入，再运行主场景，或打开 `examples/input_extensions/input_extensions.tscn`。

示例支持跳跃、虚拟轴、录制/读取回放、改键、取消捕获及可选偏好保存与恢复。它使用一个动作组拥有者、一个观察器和独立 ConfigFile，不启用 CoreSystem。回放产生数据，游戏逻辑决定怎样消费；示例不会把回放记录当作游戏规则或自动移动对象。

## 动作组的拥有者

```gdscript
const Inputs = preload("res://source/input_system/core_inputs.gd")
const Manager = preload("res://source/input_system/input_manager.gd")

var bindings: Inputs = Inputs.new()
var observer: Manager = Manager.new()

func _ready() -> void:
	# 动作先由工程 InputMap 或宿主建立。
	if bindings.register_actions([&"jump", &"move_right"]) != OK:
		observer.free()
		observer = null
		return
	observer.use_bindings(bindings)
	add_child(observer)

func _exit_tree() -> void:
	if is_instance_valid(observer):
		observer.close()
	bindings.close()
```

CoreInputs 是键盘/鼠标绑定的唯一修改入口。同一动作不能被第二个 CoreInputs 实例重复声明；失败返回 `ERR_ALREADY_IN_USE`，不会部分占用动作。InputManager 共用已有实例，不再创建另一写入者。所有 InputMap 修改及释放动作组在主线程执行；工作线程注册、应用或恢复返回 `ERR_UNAVAILABLE`。

改键与恢复默认只修改所声明动作的键盘/鼠标事件，保留当前手柄事件与动作死区，不操作其他动作。`close()` 释放动作组修改权，保留用户当前 InputMap；之后可重新注册。恢复原按键须在关闭前显式 `restore_defaults()`。宿主负责删除自己创建的临时动作，库不会删除工程定义。

观察器通过 `tracked_actions` 或 `use_bindings()` 确定观察范围。无参数旧构造仍可观察启动时已有动作，但没有绑定拥有者时不能改键。旧 `config_manager` 属性保留为可显式赋值的引用，默认 null，观察器不会自动读取或保存配置。

普通动作使用原 `_input` 阶段；改键捕获使用 `_unhandled_input`，UI 按钮先处理事件，取消按钮不会成为新按键。默认处理器返回“未消费”时，正常动作继续传递；过滤器拒绝和处理器消费时停止传递。Keyboard/Mouse/Joypad/Touch 处理器仍是可扩展的默认钩子。KeyRemapHandler 只捕获键盘/鼠标按下，支持带逻辑及物理键码的真实事件。

## 可选配置持久化

InputConfigAdapter 无参数构造只保存在内存；调用保存返回 `ERR_UNCONFIGURED`。需要文件时传入三个 Callable：读取输入节、设置输入节、保存文件。保存函数返回 Godot Error；写入输入节先于保存文件执行。请检查保存结果，不用日志猜测是否落盘。

```gdscript
const Adapter = preload("res://source/input_system/config/input_config_adapter.gd")

var file: ConfigFile = ConfigFile.new()
var preferences: Adapter

func setup_preferences() -> void:
	preferences = Adapter.new(null,
		func() -> Variant: return file.get_value("input", "data", {}),
		func(data: Dictionary) -> void: file.set_value("input", "data", data),
		func() -> Error: return file.save("user://input.cfg"))
```

读取外部文件后显式 `reload_config()`，适配器不会订阅外部配置服务。空输入节恢复默认；非 Dictionary 节或错误的节类型返回 `ERR_INVALID_DATA` 并保留内存配置。InputConfig 的 `update_config()` 现在返回 Error；原来忽略返回值的调用仍可使用。默认值与新设置的合并允许新值覆盖默认，字典/数组数据以副本传递。InputEvent 或其他 Resource 不能靠 Array 的深复制保证独占，优先使用 CoreInputBinding 的数据表示。

配置只保存数据，不直接修改 InputMap。宿主验证配置后调用共享 CoreInputs 的 `apply_data()`；轴、死区与设备偏好同样显式应用。外部保存失败不会自动回滚内存配置；文件替换保证由所传入的存储服务提供。

所有者退出时调用适配器 `close()`，断开 InputConfig 订阅并释放回调捕获。输入观察器关闭会停止处理、取消捕获、断开轴订阅、清理缓冲/录制/播放/动作状态；传入的 CoreInputs 和持久化适配器仍由宿主关闭。观察器退出后需要新实例，不支持热重启。

## 原扩展映射与语言覆盖

| 原扩展 | 独立用法与依赖 | 本项核对的 C# 覆盖 |
| --- | --- | --- |
| 动作/强度/边沿 | InputState；InputManager 可观察动作组 | 不宣称有对应旧 InputState API |
| 边沿防抖 #50 | InputState.edge_debounce_ms，默认关闭 | 尚无对应扩展 |
| 输入缓冲 | InputBuffer；主线程清理到期记录 | 尚无对应扩展 |
| 虚拟轴 | InputVirtualAxis；显式声明实际动作，不修改 InputMap | 尚无对应扩展 |
| 录制/回放与记录文件 | InputRecorder；调用方消费回放数据 | 尚无对应扩展 |
| 过滤/组合/手势/捕获 | InputEventProcessor 的已有处理器与过滤器 | 现有改键示例支持捕获；不宣称具备全部处理器 |
| 改键与冲突 | 一个 CoreInputs、CoreInputBinding | 现有 CoreInputs/CoreInputBinding 与 profile 数据；本项未修改 C# 的拥有者检查 |
| 偏好数据 | InputConfig、可选 InputConfigAdapter 回调 | 可组合现有 CoreConfig 或保存服务；尚无同名适配器 |

上述 C# 栏依据当前配对仓库源码，不代表已发布的支持承诺。两语言共同 profile 结构未更改；GDScript 新增动作占用检查与保持当前手柄事件的默认恢复语义，需要配对版本另行验收。不能把 C# 的改键服务描述成已迁移所有旧输入扩展。

GDScript 的动作占用表只约束这份 CoreInputs 脚本的实例，不能阻止游戏直接调用 InputMap 或 C# 服务写入。跨语言组合时仍须由宿主明确选择一个写入者，其余观察器共享它或只读观察。

## 验证边界

独立宿主覆盖正常动作、过滤、虚拟轴、手势、录制/回放文件、错误记录保留、容量边界、同组重复声明、真实按键捕获、取消、偏好保存/恢复、A/B 配置及退出清理。#50 使用独立 InputState 行为回归，不能把它与原始机械键盘硬件实测混淆。

旧 CoreInputs 合同与原改键按钮示例另行运行，包含 Windows CoreAtomicFile 原生后端。兼容宿主只把测试文件的 user:// 存储目录改到工程内可写目录，原子后端与按钮逻辑不变。此处是编辑器运行证据，原生扩展导出仍按既有安排验收；未宣称所有平台或 C# 扩展已验证。
