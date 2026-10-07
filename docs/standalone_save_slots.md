# 独立存档槽位（#99，继续实施）

当前实现可独立运行槽位、节点登记/恢复和自动存档；CoreSystem 已提供显式兼容组装。JSON/Binary 与历史类型矩阵仍待组合验收。依赖 #98 独立策略和 #76 身份/版本/迁移接口，不代表这些前置已合并。

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

尚需：真实历史旧档夹具；JSON/Binary与#64/#65/#66/#67关联回归；公开支持类型矩阵。原生扩展和导出验收沿用已延后安排，当前测试没有运行导出。PR保持draft，#99不关闭。

## SaveManager 与旧入口兼容

SaveManager现在是独立Node，source/save_system/save_manager.tscn是对应可复用场景。传入SaveSettings和可选的已配置策略；配置在首次操作时复制，后续运行状态不写回配置Resource。只在首次使用时创建所选内置策略，最小Resource宿主不安装JSON/Binary也能运行。选用未安装或未知格式返回错误，保留当前策略；显式注册自定义策略可替换同名当前格式。格式切换关闭旧策略，保留当前ID与待恢复状态；策略实例只交给一个拥有者，不重新使用已关闭的异步策略。

register_saveable_node(node, save_id)显式登记；没有ID保留绝对路径，有ID不受场景改名影响。支持历史仅load_data的恢复对象或仅save的采集对象；两种方法都没有的对象拒绝。没有显式scene_scope时不查找场景、父节点或全局组。需要旧分组行为时由游戏根传入scene_scope，收集范围只在该对象及其子树；save_id属性仅在这个明确的分组适配过程中读取。改变已登记对象身份须先注销。

SaveRestoreState拥有当前pending图。加载先解码/迁移/校验，再为各个对象复制可变资源，然后采用当前槽位、替换pending并调用游戏load_data。失败不改变原槽位/pending；加载空快照也会替换pending。结果有applied_count、pending_count、pending_identities，另可查询/清理未消费身份。延迟注册在回调前删除pending记录，避免重复消费。注册/清理在正在进行的管理器操作中返回ERR_BUSY，游戏回调不得重入新的存档操作；游戏load_data已经发生的副作用无法回滚。

保存时把尚未出现的对象pending负载一同纳入快照，现有对象以当前save返回值覆盖同身份；只有保存成功后更新pending。这样不会因对象暂未创建而另存丢失其状态，也不把失败写入的状态提交到内存。删除当前槽位清理pending；关闭清理登记、pending、回调与策略。

create_save、load_save、delete_save、get_save_list、create_auto_save保留bool/数组/字符串形式。create_save_result、load_save_result、delete_save_result、get_save_list_result提供每请求结果。operation_finished仅通知已接受并结束的操作；开始阶段被拒绝的请求直接返回错误结果。自动存档ID增加时间与实例序号，按元数据时间保留配置数量。旧只读配置属性仍可读取；新的配置修改在首次操作前通过storage_settings进行，不再在运行中隐式读取ProjectSettings。

CoreSystem使用SaveLegacyAdapter传入旧ProjectSettings和明确树根范围；只有选择Binary时才通过显式密钥提供回调访问配置模块。既有encryption_key继续使用，新密钥须持久化成功才允许使用；失败时清除新密钥缓存，不能把未保存密钥用于存档。独立模块不自动生成/读取全局密钥；直接传入已配置策略时使用策略自身配置。XOR能力仍只是混淆，不表述为强加密。

新增独立管理器最终43项、密钥/旧配置适配10项、完整旧CoreSystem组装5项；与槽位32项合计90项。管理器测试使用真实Resource文件与节点，验证稳定ID跨场景改名、对象资源隔离、失败/空存档/切档pending、延迟一次消费、缺失对象另存、load-only兼容、自动存档保留数量、未安装格式与自定义替换、ReusableScene。适配器以真实ConfigFile证明旧密钥不重写、新密钥持久化及失败缓存回滚。CoreSystem宿主按addons路径完整复制source/setting，导入后运行旧分组路径保存/读取/列表/删除5项。各最终日志退出0，无脚本错误或对象/资源保留；沙箱日志/证书/编辑器缓存与空程序集提示另列。

初次管理器检查暴露旧档空元数据被列表误跳过：补完整读取区分有效空metadata与失败哨兵，增加回归；初次失败日志不计验收。旧私有字段_strategies/_pending_node_states等已由明确拥有者取代，依赖它们的历史测试须改为行为与公开结果检查。JSON/Binary及其私有编解码接口的兼容回归尚未完成，PR仍为draft。
