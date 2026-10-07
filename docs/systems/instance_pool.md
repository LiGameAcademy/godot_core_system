# CoreInstancePool：实例缓存与所有权

本模块是主线程上的节点实例池，管理缓存、租出身份和最终释放。它不加载场景、不创建缺失实例，也不替游戏重置生命、计时器、信号或材质。两版同范围实现；资源加载继续由 CoreResources 负责，原 EntityManager 的配置/创建逻辑尚未迁移。

| GDScript | C# | 契约 |
| --- | --- | --- |
| CoreInstancePool.new(capacity = 256) | new CoreInstancePool(capacity = 256) | 容量限制空闲缓存，非活跃节点数量 |
| take() | Take() | LIFO 返回无父节点的缓存实例；空池、关闭或清理中返回 null |
| recycle(node) | Recycle(node) | 接纳新节点或自己的租出节点；OK 表示已消费所有权 |
| cached_count / leased_count | CachedCount / LeasedCount | 清理失效记录后的缓存/租出数量 |
| clear() | Clear() | 立即释放缓存；保留租出节点及其归还资格 |
| close() | Close() / Dispose() | 不可重新开启；释放缓存及所有已接纳的租出节点 |
| capacity / is_closed | Capacity / IsClosed | 只读状态 |

## 回收、失败与释放

调用者先停止角色、断开每次激活的临时订阅并移出父节点，再回收。首次成功回收后归池所有；Take 只租出，不能转交其他池。新创建且尚未回收的对象仍由调用者负责。池使用保留元数据键 `_core_instance_pool_owner` 维护身份，不应由外部修改，也不要复制带该元数据的运行节点作为新模板。

- null、已排队删除或仍有父节点：InvalidParameter，保持调用者所有权。
- 重复回收或属于其他池（包括其租出节点）：AlreadyInUse。
- 关闭后回收：Unavailable；释放期间重入回收：Busy。
- 达到容量（含零容量）时，成功回收会立即 Free 该节点，返回 OK；之后不能再访问它。
- Clear 释放无父节点缓存；Close 对无父节点对象立即 Free，对挂树租出对象 QueueFree。重复关闭安全。没有终结器代替显式 Close。
- 外部已释放/排队删除的缓存会跳过；外部把缓存重新挂树时，池发现后放弃该对象所有权，不会抢回或销毁它。调用者应通过 Take 挂树。

池操作要求 Godot 主线程。C# 越界容量抛 ArgumentOutOfRangeException，非主线程调用抛 InvalidOperationException；GD 负容量报告英文错误后使用零容量，非主线程报告英文错误并拒绝操作。以上语言机制差异不影响正常共同流程。

## 实例与资源

归还池前停止处理、碰撞和可见表现；再次激活时显式恢复运行状态。`_Ready` 通常只在第一次挂树执行，不能作为每次取出的重置钩子。共享纹理与静态 Resource 配置保持只读；需要修改的 Gradient/材质/嵌套数据由角色按真实需要复制。池不会自动深复制资源。

本模块不承诺池化一定提高 FPS：它减少重复创建成本，也会保留节点和资源，占用更多内存。持续移动、绘制与战斗计算仍然存在；应在实际工作负载上测量。

## GDScript 使用

```gdscript
var pool: CoreInstancePool = CoreInstancePool.new(64)

func spawn(scene: PackedScene, parent: Node) -> Node:
	var actor: Node = pool.take()
	if actor == null:
		actor = scene.instantiate()
	parent.add_child(actor)
	return actor

func retire(actor: Node, parent: Node) -> Error:
	parent.remove_child(actor)
	return pool.recycle(actor)
```

实际角色在 spawn 后调用其激活方法，在 retire 前停止/重置；拥有者退出调用 pool.close()。示例见 [instance_pool](../../examples/instance_pool/README.md)。

旧 ResourceManager 的 get_instance / recycle_instance / get_instance_count / clear_instance_pool 现委托此池，每个 ID 默认容量 256。旧回收入口为兼容用法会先移出父节点（它不负责停止游戏状态）；空池返回 null，计数只统计缓存，clear 释放缓存并保留租出归还资格，管理器退出关闭全部池。重复/失效/跨池失败输出英文错误。新代码优先显式持有 CoreInstancePool。

## 验证

2026-10-07 / Godot 4.7.2：共同契约 27 项、GD 旧适配器 3 项，共 GD 30 / C# 27 项核心通过；两版各 9 项真实按钮/场景检查通过。涵盖空池、失效/排队删除、重复/跨池归还、容量、租出/关闭、释放重入，以及 A/B/模板私有资源与退出清理。C# 独立宿主构建零警告/错误。导出继续延后。

```powershell
godot --headless --path <host> --script res://addons/godot_core_system/test/unit/instance_pool_checks.gd --quit-after 400
godot --headless --path <host> --script res://addons/godot_core_system/test/unit/instance_pool_example_checks.gd --quit-after 400
```

使用无旧全模块 AutoLoad 的临时宿主，先编辑器导入。必须同时有 PASS、零退出码且无意外脚本错误；仅 --quit-after 自动退出不算通过。
