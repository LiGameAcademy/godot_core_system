# 版本化 JSON 数据持久化

CoreSaveDirectory / CoreSaveStore 是与 C# 最小持久化范围对齐的独立服务，不依赖旧 CoreSystem AutoLoad。旧存档槽、节点收集和压缩策略保留，不是该服务的兼容格式。

```gdscript
func validate_preferences(data: Dictionary) -> Error:
	if data.size() != 1 or not data.has("Muted") or not data.Muted is bool:
		return ERR_INVALID_DATA
	return OK

func save_preferences() -> CoreSaveResult:
	var directory: CoreSaveDirectory = CoreSaveDirectory.new(ProjectSettings.globalize_path("user://preferences"))
	var store: CoreSaveStore = directory.create_store("preferences", 1, validate_preferences)
	return store.save({"Muted": false})
```

目录必须是受信的绝对 OS 路径；先显式 globalize_path，不能直接传 user://。create_store 的标识只允许 ASCII 字母、数字、下划线和短横线，长度 1–64，拒绝 Windows 设备保留名。版本是正的 32 位整数。配置错误返回 null，可读 directory.last_error。

## 格式及自定义数据

外层只有 `Version` 和 `Data`，例如 `{"Version":1,"Data":{"Muted":false}}`。名称区分大小写。严格检查 JSON 语法、重复属性（包括转义后的同名键）、有限数字、版本整数与版本相等、对象载荷；不允许尾逗号或尾随内容。每文件最多 1 MiB，递归深度最多 64；整数限有符号 64 位，浮点使用 Godot double，不支持任意精度数字。

validator 是 `Dictionary -> Error`，必须检查必填字段、未知字段、嵌套结构、值类型和业务范围。它在读取交付前及写入前执行，应是无副作用的校验函数。插件无法替业务模型猜测未知字段是否合法。返回无效 Error 或非整数视为无效数据；脚本运行错误不能当成已转换的 Error。

自定义 Resource / RefCounted 数据应由宿主显式编码为 Dictionary，再在校验成功后构造新实例。只保存 JSON 类型（null、bool、int、有限 float、String、Array、字符串键 Dictionary），不保存 Node、Callable 或引擎对象。C# 使用 DTO / JsonRequired / validator；两版模型字段一致时可共享格式，但不自动把 Resource 映射成 DTO。版本升级由宿主设计，不自动迁移旧文件。

## 读取与失败

try_load 返回 CoreSaveResult。只有 `error == OK && found == true` 才使用 data。文件不存在返回 OK / found=false，且不创建默认文件；损坏、版本不符、验证与 IO 错误明确返回 Error / message，保留原文件。调用方应先读取到候选快照，成功后再更新内存，不能把所有读取失败当成缺失并覆盖旧档。

## 写入

先校验并序列化、检查大小，再创建同目录随机名称的临时文件，写完整并 flush，最后替换目标。失败尝试清理本次临时文件；原始错误保留在 error，清理错误另存 cleanup_error。save 不修改宿主内存数据。进程被强制终止可能留下临时文件，不自动恢复或加载它们。

Windows x64 使用 [最小原生扩展](../../native/atomic_file/README.md)，避免引擎覆盖重命名的先删后移。Windows 缺少扩展返回 ERR_UNAVAILABLE；其他平台使用 DirAccess.rename_absolute，未在本轮验证其文件系统与断电语义。原生后端与 C# Flush(true) 都在替换前刷写内容，但不承诺断电后的目录持久性或备份。可信目录、单个文件一个写入拥有者是前提，不提供文件系统沙箱、多进程合并或防篡改。

可传入 `replace: Callable(String, String) -> Error` 作为显式后端（或失败测试）。该后端必须自己保证失败保留目标、成功完成替换；不要传入先删目标的实现。序列化大小限制不是序列化过程的内存配额。

## 示例与检查

[独立计数示例](../../examples/save_contract/save_contract_example.tscn) 提供草稿加一、显式保存与加载三个按钮，不依赖塔防或 AutoLoad。Windows 宿主需加载原生扩展。

在独立宿主中执行 `--headless --script res://addons/godot_core_system/test/unit/save_contract_checks.gd`，覆盖 76 项核心检查；外部锁定目标检查在 `test/unit/save_locked_target_checks.gd`，由测试调用方持有禁止删除的文件句柄并传入目标绝对路径，仅操作专用测试目录。C# 对应 68 项独立检查；断言数量不同不代表范围完全等价。
