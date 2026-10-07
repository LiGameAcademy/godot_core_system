# 独立存档槽位（#99，继续实施）

当前实现可独立运行槽位与内存快照操作；旧 SaveManager 的节点恢复、自动保存及 CoreSystem 兼容组装尚未接入。依赖 #98 独立策略和 #76 身份/版本/迁移接口，不代表这些前置已合并。

## 使用

```gdscript
const SaveSlots = preload("res://source/save_system/save_slots.gd")
const ResourceStrategy = preload("res://source/save_system/save_format_strategy/resource_save_strategy.gd")
var slots: SaveSlots = SaveSlots.new("user://saves", ResourceStrategy.new(), 1)

func read_slot() -> void:
	var result: SaveSlots.Result = await slots.load_snapshot("first")
	if result.error == OK:
		# 游戏层再使用 result.data 中的记录恢复已登记对象。
		print(result.data)

func finish() -> void:
	slots.close()
```

只有显式传入的策略被使用，没有自动创建 Resource/JSON/Binary 三个实例。策略由此槽位服务独占管理并负责 close，不能同时交给多个服务。配置目录和所选策略在构造后固定；migrations、legacy_path_ids、readonly_resources 在操作开始前配置，不在异步操作中改动。创建、操作、销毁均在主线程；同一服务进行中的其他请求返回 ERR_BUSY，不覆盖正在运行请求的结果。

save_snapshot 接受元数据与节点记录，经过完整预验证和迁移后写入。当前框架记录信封为 identity_kind、identity、data；无版本的旧 node_path 扁平记录也可进入显式转换。调用 load_snapshot 成功后更新当前槽位与拥有资源的内存快照，返回数据独立于内部快照。get_snapshot 每次返回独占副本的 CopyResult。游戏层负责从记录恢复已有或随后创建的对象。

list_slots 返回 saves 数组；损坏而无法提取元数据的文件不列入。当前读取列表不保证所列存档可被当前游戏schema加载，调用者应处理 load_snapshot 的版本结果。delete_slot 删除当前槽位时清理当前ID与内存快照。

## 失败与迁移

每次操作独立返回 SaveSlotResult：error、message、stage、save_id，以及读取的 data 或列表 saves。缺失返回 ERR_FILE_NOT_FOUND，无法解码返回 ERR_FILE_CORRUPT，不支持版本/缺迁移返回 ERR_UNAVAILABLE，策略写入失败返回 ERR_FILE_CANT_WRITE；提交重命名失败保留引擎 Error。没有共享的 last_error。

写入先保存到同目录、保持扩展名的临时槽位，再重命名为目标；策略失败时清理临时文件，不提前删除目标。Windows 实测支持覆盖已有槽位。此实现不承诺所有平台的断电耐久性、目录fsync或跨进程写入互斥。策略须遵守指定文件路径，不产生不可回滚的额外文件副作用。

migrate_slot(source, destination) 只允许不同且尚不存在的目标槽位；读取、内存迁移后另存，不改变当前槽位和快照。没有迁移成功就覆盖源文件的入口。外部进程并发修改文件不在本服务的互斥范围内。

Resource 策略现在保留完整元数据，框架/游戏版本和自定义字段不会在保存时丢失；读取使用 CACHE_MODE_IGNORE_DEEP，再由迁移入口复制可变资源。Resource、JSON、Binary 的完整支持类型矩阵与旧接口回归仍待接入后验收。

## 运行证据与剩余交付

Windows、Godot 4.7.2 stable mono 的独立宿主只安装 Resource 策略、槽位服务、5个身份/迁移脚本及 GameStateData，无 CoreSystem、配置管理器、IO线程或原生扩展。save_slot_checks 最终32项通过，退出0，无 SCRIPT ERROR 或退出对象/资源保留。测试实际写入和覆盖 tres 文件，比较失败写入/迁移前后的源字节，验证缺失、错误Resource类型、未来版本、元数据保留、A/内部快照/模板资源隔离、迁移目标已存在拒绝、列表/删除、清理暂存文件及显式/析构关闭。

初次运行发现 RefCounted 的 PREDELETE 不能调用自身方法，改为直接关闭所选策略并增加析构回归；初次日志不计验收。沙箱的 user://日志与证书读取限制、空Mono项目程序集诊断单列，不等同功能验证失败，也不当作通过证据。

尚需：接入旧 SaveManager，完成待恢复状态和自动保存/格式切换兼容；真实历史旧档夹具；JSON/Binary与#64/#65/#66/#67关联回归；公开支持类型矩阵和可选CoreSystem组装。原生扩展和导出验收沿用已延后安排，当前测试没有运行导出。PR保持draft，#99不关闭。
