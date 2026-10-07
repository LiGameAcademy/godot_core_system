# 独立使用 IO、线程与存档格式

这些工具可直接 preload，无需 CoreSystem Autoload、插件启用或日志、配置、场景、音频模块。它们保留既有路径和存档编码；独立安装不代表存档版本迁移已经完成。

## 安装与验证

`tools/create_io_module_host.ps1 -Destination <新的绝对目录>` 按显式清单创建验证工程，拒绝覆盖已有目录。`module_manifest.txt` 列出模块文件，工程的主场景执行独立测试。先用 Godot 4.7.2 导入，再运行：

```powershell
godot --headless --editor --path <宿主目录> --import
godot --headless --verbose --path <宿主目录>
```

清单包含 17 个脚本及对应 UID：AsyncIOManager、SingleThread、ModuleThread；序列化、压缩和混淆策略；存档格式接口、异步格式基类、JSON、Binary、Resource 格式和 GameStateData。仅需命名线程时安装两个 threading 脚本及 UID 即可。仅需 Resource 存档时安装 GameStateData、格式接口、Resource 格式及 UID。IO 与异步格式可按工具清单安装，不需要复制整个插件。

## IO 所有权

```gdscript
const AsyncIO = preload("res://source/utils/async_io_manager.gd")

var io: AsyncIO = AsyncIO.new()

func start_save() -> void:
	io.io_completed.connect(_on_completed)
	var task_id: String = io.write_file_async("user://settings.json", {"volume": 0.8})
	if task_id.is_empty():
		push_error("IO 已关闭，任务未提交")

func _on_completed(task_id: String, success: bool, result: Variant) -> void:
	print(task_id, success, result)

func _exit_tree() -> void:
	io.close()
```

构造不启动线程。首次主线程提交才创建一个自有工作线程；任务结果通过主线程信号返回，并携带提交时取得的唯一 ID。并发调用不能假定下一个信号就是自己的结果。异步存档格式基类负责按 ID 匹配。

IO 提交和关闭在主线程执行。策略通过构造参数或 setter 显式提供；设置策略须在提交前或所有任务结束后完成，不能在工作线程使用策略期间更换其配置。可传入第四个构造参数 `Callable` 接收 `(level: StringName, message: String)`；回调延后至主线程。未配置回调时错误与警告交给 Godot，普通完成消息保持静默。策略自身的解析错误仍通过 Godot 诊断输出。

`close()` 可重复调用，关闭后提交返回空 ID。它等待正在运行的文件操作结束，取消未交付结果的任务，每个此类 IO 任务只报告一次 `success=false, result=null`。失败通知不证明文件没有变化，也不保证回滚已经开始的写入。所有者须在主线程关闭后释放对象；不要让工作线程负责释放最后一个所有者引用。

## 命名线程与格式

ModuleThread 构造不创建工作线程，`submit_task()` 或 `create_thread()` 按名称创建。公开任务 ID 在管理器生命周期内唯一。`unload_thread()` 与 `clear_threads()` 等待运行中的任务，移除队列和未交付通知；它们在主线程执行。`clear_threads()` 保持可复用重置语义；新增的 `close()` 是终止操作，之后提交返回空 ID、显式创建返回 null。命名线程的关闭取消完成通知，与 IO 的失败结果通知不同。

JSON/Binary 格式构造不启动 IO 线程，保存或读取时才启动，使用结束必须 `close()`。Resource 格式同步执行，不创建线程。Resource 节点数据接受由 Dictionary 组成的普通或带类型 Array，并显式转换为 GameStateData 的带类型集合；非法元素返回 false。

JSON 使用现有 Variant 编码。Binary 在其上使用 Gzip 和 XOR；XOR 只是数据混淆，不能保护机密或验证数据真实性。此变更不修改现有文件格式、密钥语义或 Resource 缓存策略。

## 验收范围

独立空工程覆盖延迟线程创建、并发 ID 与数据匹配、编码失败保留旧文件、不存在目录失败、超过 2 MB 且压缩比大于 100 倍的数据往返、三个格式、命名线程重置与关闭、IO 取消与主线程诊断。详细退出检查需使用 `--verbose`，同时核对脚本错误和对象/资源保留报告。

该工作依赖 #63 的结果匹配与 #71 的命名线程 ID 修复，并接入已合并 #110 的关闭协议。发布时须先合并这些前置 PR。Godot 原生导出及真实游戏接入须纳入发布验收，本独立宿主不替代这些步骤。
