# 资源加载与缓存

`CoreResources` 是场景拥有的 Godot 资源服务，两版共同支持即时加载、后台请求、进度、重复请求协调、完成缓存、逻辑取消和退出清理。它直接依赖 Godot `ResourceLoader`，没有自建线程池或应用全局缓存。

把 `addons/godot_core_system/source/resource_system/core_resources.tscn` 作为子场景加入使用者；也可 `CoreResources.new()` 后由父节点 `add_child()`。必须进入场景树才能加载；无需启用 CoreSystem AutoLoad。退出树自动关闭，关闭后的实例不能重用，应创建新实例。

## API

| GDScript | C# 对应接口 | 行为 |
| --- | --- | --- |
| `load_resource(path)` | `Load(path)` | 返回 CoreResourceResult；同步加载可能阻塞，已有后台任务时返回 Busy |
| `request(path)` | `Request(path)` | 返回 CoreResourceRequest；同一拥有者、同一规范路径的待完成请求共享一个句柄 |
| `get_cached(path)` | `GetCached(path)` | 只查询完成缓存，缺失返回 null，绝不触发加载或等待 |
| `evict(path)` | `Evict(path)` | 移除本地缓存项，返回是否移除；不取消请求 |
| `clear_cache()` | `ClearCache()` | 清空完成缓存；已接受的请求继续，完成后仍可加入缓存 |
| `cancel(path)` | `Cancel(path)` | 放弃当前请求，返回是否接受；共享该句柄的调用者一起收到 Skip |
| `close()` | `Close()` | 永久关闭，清缓存并以 Unavailable 结清待处理句柄；可重复调用 |
| `cache_count / pending_count / inflight_count / is_closed` | 同名 PascalCase 属性 | 本拥有者的完成缓存数、有兴趣的请求数、尚未回收的原生任务数与关闭状态 |

路径必须是 `res://` 或 `user://` 文件路径；斜杠、`.` 和合法的 `..` 会规范化，拒绝越过根目录。相对路径、绝对磁盘路径和 `uid://` 不属于首版入口；调用者先解析为资源文件路径。键区分大小写，不修正错误的引用大小写。

结果属性 `error` 为 Godot Error，`resource` 为 Resource 或 null。正常成功为 OK；无效路径为 ERR_INVALID_PARAMETER，缺失或加载失败为 ERR_CANT_OPEN；未入树、排队删除或关闭为 ERR_UNAVAILABLE；即时加载遇到本拥有者尚未收集的原生任务为 ERR_BUSY。请求进度单调、不超过 1，成功时为 1；失败或取消保留最后进度，不伪造加载成功。

请求提供只读属性 `is_completed / result / progress`、完成信号 `completed(result: CoreResourceResult)` 和 `wait()`。即刻失败及缓存命中在方法返回前已经完成；使用 `wait()` 或先检查 `is_completed`，避免在完成后才连接信号而漏掉结果。C# 对应 `Completion: Task<CoreResourceResult>`，正常失败通过结果返回，不使 Task fault/cancel。

```gdscript
@onready var resources: CoreResources = $Resources

func request_template(path: String) -> void:
	var handle: CoreResourceRequest = resources.request(path)
	var result: CoreResourceResult = await handle.wait()
	if not is_inside_tree() or resources.is_closed:
		return
	if result.error != OK:
		push_warning("Resource request failed: %s" % error_string(result.error))
		return
	var template: Gradient = result.resource as Gradient
	if template == null:
		push_warning("Expected a Gradient resource.")
		return
	var private_copy: Gradient = template.duplicate() as Gradient
	private_copy.set_color(0, Color.RED)
```

## 生命周期与资源所有权

所有服务调用必须在 Godot 主线程执行，服务以 Always 模式逐帧收集任务，暂停场景树时也能完成。C# 错误线程调用抛 InvalidOperationException；GD 显式输出英文错误并拒绝操作，加载结果返回 ERR_INVALID_PARAMETER，查询返回 null、布尔操作返回 false。计数和请求状态也应在主线程读取。不要用 Task.Run 操作节点或在 ConfigureAwait(false) 后直接调用本服务。

先提交缓存、任务和关闭状态，再完成句柄。完成回调可以查询状态、清缓存、请求其他资源或关闭服务。C# 常规 Godot 主线程 await 恢复在主线程；使用者自行选择的异步调度仍由使用者管理。

取消表示放弃结果，Godot 没有公开的原生加载取消接口。原生任务仍会完成并被收集，取消的结果不会被晚到成功覆盖，也不会填入缓存。同一路径在收集前再次 request 会创建新句柄并接续原任务。取消影响共享句柄的所有调用者，首版不提供每个等待者的独立取消。

普通 close 不等待正在加载的任务：路径移交给内部临时清理节点，它不持有使用者、请求或缓存。关闭后的计数全部为零，移交后的后台任务不再计入该服务。清理节点完成后释放。应用退出没有后续帧时才等待并收集剩余原生任务。失败任务也要收集，避免保留 Godot 原生加载令牌。多个服务保持各自请求和缓存，Godot 内部仍可能共享相同资源。

使用 CacheMode.REUSE；缓存资源按只读约定共享。evict、clear 和 close 只释放本服务引用，不强制从 Godot 全局缓存卸载，也不销毁调用者持有的资源。修改 Gradient、材质、碰撞形状等资源前按实际结构复制；有嵌套可变资源时需另外验证复制深度。此例只验证无嵌套的 Gradient，不声称浅复制可以隔离任意资源图。

## 旧 ResourceManager 迁移

原 `CoreSystem.resource_manager` 保留加载入口及原信号，由 CoreResources 子节点承接加载；取消了 null 缓存占位和独立计数权威。

| 原接口 | 当前行为与变化 |
| --- | --- |
| `load_resource(path, IMMEDIATE)` | 同步返回 Resource/null，缓存命中不重复通知，新成功加载发 resource_loaded |
| `load_resource(path, LAZY)` | 请求后台加载，同一原始路径只连接一次完成通知，通常先返回 null；失败输出英文错误 |
| `get_cached_resource(path)` | 现在是纯查询；需要加载时显式调用 load_resource，不再隐藏阻塞重载 |
| `clear_resource_cache(path = "")` | 清对应或全部缓存，同时放弃对应待完成请求，防止晚到结果重新填缓存；发 resource_unloaded |
| `set_lazy_load_interval(interval)` | 弃用，输出英文警告；加载改为每帧收集，该参数不再延迟通知 |

`resource_unloaded` 表示释放本地缓存与兴趣，不表示强制销毁资源。旧 get_instance、recycle_instance、get_instance_count、clear_instance_pool 原池职责仍在该文件，空池、重复回收及清理语义将在 P2 下一步处理，不能视为已经迁移或对齐。本服务尚未接管旧 SceneManager 的预载，也不改变 EntityManager 的初始化与创建逻辑。

旧说明中曾出现源码不存在的 load/load_async/load_multiple_async、引用计数、预载列表和自动清理 API，现已删除；没有这些接口。

## 独立示例与验证

打开 [resource_loading_example.tscn](../../examples/resource_loading/resource_loading_example.tscn) 按 F6；操作和检查见 [示例说明](../../examples/resource_loading/README.md)。两版场景、Gradient 模板及检查不依赖任何游戏工程、素材或 AutoLoad。

2026-10-07 / Godot 4.7.2：GD 40 项核心检查（含 4 项旧适配器检查）、C# 36 项共同核心检查，两版各 11 项真实示例按钮检查通过。C# 隔离完整插件和塔防宿主构建为零警告/零错误。原生失败用例会故意输出一次 Failed loading resource 英文引擎错误，随后断言 CantOpen、任务回收和无缓存；最终需 PASS 与零退出码。检查包括后台延迟、重复/规范路径、取消接续和放弃、暂停、关闭重入、已关闭实例重入树、拥有者离开、退出前尚未挂树的清理节点、应用退出及 A/B 副本隔离。导出验收仍待开发完成后另行执行。

引擎 API 依据：[ResourceLoader](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html)。本页的接口、兼容与验证结论以本仓库实现及实际 4.7.2 检查为准。
