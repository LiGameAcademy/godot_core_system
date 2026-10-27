# 存档对象身份与版本迁移提案（#76）

状态：2026-10-07 用户已采纳以下兼容政策；显式对象登记、版本预检查、旧记录转换与内存迁移链已实现并独立验证；文件另存和 SaveManager 集成尚未完成。
关联 [issue #76](https://github.com/LiGameAcademy/godot_core_system/issues/76)，核对 main `8d484f5`。
待恢复状态跨存档污染由 #67 独立处理，本提案不替代其修复。

## 当前契约与限制

SaveManager 保存节点绝对 NodePath，通过相同路径寻找对象；对象尚未出现时缓存状态并等待注册。
场景根改名或动态实例命名顺序改变时，路径可能不再匹配。
元数据保存 game_version，但加载没有独立数据版本检查或迁移入口。
Resource 策略保存 GameStateData；json 与 binary 共享 JSON 数据编码，binary 增加压缩/加密。
不能因为扩展名叫 binary 就宣称它能无损保存任意 Variant。

这些是源码确定的限制，未测量真实游戏的迁移需求。固定小场景可以继续采用路径身份。

## 建议决策与兼容替代

| 问题 | 建议 | 待决定的替代 |
| --- | --- | --- |
| 固定节点身份 | 保留 NodePath 模式，同时允许显式稳定 save_id | 全部强制 ID 会增加现有场景配置与迁移工作 |
| 动态对象创建 | 游戏层负责创建/删除；管理器仅恢复已注册实例或等待实例注册 | 存档创建对象需要模板注册表、校验和游戏生命周期适配，不作为默认 |
| 数据版本 | save_format_version 独立于展示用 game_version；应用结构另设 game_schema_version | 只用 game_version 简单，但发行版本不等于结构变化，难以精确迁移 |
| 不兼容输入 | 在更改场景状态前拒绝；只有明确迁移链才转换 | 静默接受可能导致部分错误恢复；尽力恢复必须为显式选项并报告缺失 |
| 缺失 ID | 保留本次加载的待恢复记录并给出诊断 | 缺失即整次失败适合严格游戏，但会禁止延后生成对象 |
| 重复 ID | 保存/注册及读取时拒绝重复，不采用最后覆盖 | 自动选一个实例可能把状态写错对象 |

用户已确认：保留旧 NodePath，新增可选稳定 save_id；动态对象由游戏创建；框架格式版本与游戏数据版本分开；无版本旧档继续接受，未知新版本在修改状态前拒绝；迁移另存且不覆盖原档。下面的接口与验证草案作为实施依据，不代表代码已经实现。

## 对象身份草案

为稳定对象提供显式 `save_id: StringName`（属性名需确认），由游戏或作者分配，
在存档范围内唯一且跨版本保持；不要从 node.name、实例 ID 或本次启动随机 UUID 推导。
没有稳定 ID 的对象继续使用绝对 NodePath。内部索引使用带类型的身份键，例如
`id:player` 与 `path:/root/World/Player`，避免两种身份字符串碰撞。

拟议节点记录示意：

```json
{"identity_kind":"id","identity":"player","data":{"health":80}}
```

这是供审阅的格式示意，当前文件不会按此格式写入。
稳定 ID 记录只按 ID 查找，不能缺失时悄悄退回旧路径并匹配错误对象。
固定场景作者维护 ID，动态实体由游戏分配并持久化逻辑身份，生成顺序变化不应影响它。
若游戏需要从存档重建动态实体，应先读取并校验实体描述，再由游戏创建并注册，最后应用状态。
不自动从存档脚本路径实例化任意节点，也不默认删除存档中未出现的运行对象。

## 版本与恢复过程草案

三类版本各自有职责：

- game_version：发行版本说明，不用于推断存档是否兼容。
- save_format_version：框架元数据、对象身份记录和编码信封的结构版本。
- game_schema_version：游戏 save()/load_data() 负载的结构版本，由游戏维护。

拟议加载顺序：读取/解码→验证结构与版本→在独立数据副本执行完整迁移链→
验证身份唯一性→准备匹配与待恢复状态→提交本次加载→逐对象 load_data。
不支持的未来版本、缺失迁移步骤或重复身份都必须在提交前失败，不覆盖当前 pending 状态或 current_save_id。
这要求 #62 的写入失败隔离、#63 的任务完成和 #67 的加载缓存修复先得到验收。

迁移使用明确的 `vN → vN+1` 数据函数，返回成功/数据或明确失败；不引入通用迁移框架。
框架迁移与游戏负载迁移分别注册，必须全部成功后才能提交。
迁移失败不能覆盖原始文件；需要升级文件时另存，成功后由调用方选择替换。
游戏 load_data 已产生的副作用不保证自动回滚，框架不能把“预验证”包装为整场景事务保证。

## 旧存档的待决处理

无 save_format_version 的文件可候选定义为 legacy v0，保留 node_path 的路径模式。
旧存档没有稳定 ID 时，不能自动推断改名后的新对象；游戏提供明确旧路径→稳定 ID 映射，
或承诺沿用旧路径。映射应检查重复/遗漏并记录诊断。
无版本旧档继续按 legacy v0 接受；未知新版本拒绝。具体旧负载 schema 的映射必须在实施配置与夹具中声明，不能依据发行版本猜测。

#65 的 dictionary_format=2 只代表 JSON 内字典键的编码信封，
不能与整个存档版本混用。#65/#66 的类型与 Resource 修复尚在独立 PR 验收，
本提案不能预先宣称所有格式等价或向旧读者兼容。

## 失败与缺失反馈草案

保留现有成功/失败返回，同时提供结构化最近加载结果或结果信号，载明：
save_id、版本、阶段、失败原因、已应用/待恢复数量、未匹配身份。
具体采用读取方法还是信号待确认；不要仅写日志让调用方猜测恢复是否完整。
重复 ID 需包括冲突对象或记录位置；缺失 ID 区分尚未注册与已失效的对象。
待恢复状态只属于一次成功加载，不跨存档累积；重新成功加载时替换，失败时保留上次有效状态。
运行对象注册时消费一次，并允许显式查询和清理未匹配记录。

## 序列化能力范围

| 格式 | 当前可依据的实现 | 需要公开的边界 |
| --- | --- | --- |
| resource/.tres | Godot ResourceSaver/ResourceLoader 保存 GameStateData | 非持久化资源、自定义脚本、嵌套可变 Resource 的恢复与实例隔离需各自验证 |
| json | 自有 Variant 编解码与 JSONSerializationStrategy | 仅承诺明确支持的类型；非字符串字典键与 Resource 隔离依赖 #65/#66 验收 |
| binary | 同一 JSON 编解码后压缩/加密 | 与 JSON 同一类型能力，压缩/加密不增加可保存类型 |

对象 ID 解决匹配问题，不能修复无法编码的负载类型。
实施时给三种策略运行同一支持类型矩阵，对不支持类型明确失败，不偷偷降级成字符串或路径。
既有 XOR 加密算法安全性不属于本议题，不将其表述为强加密。

## 已确认政策与实施细节

1. 采用 NodePath 与显式稳定 ID 共存，没有 ID 的对象继续路径模式。
2. 动态对象由游戏层创建/删除，管理器恢复已有或延迟注册的实例。
3. 框架格式与游戏数据版本分开，game_version 仅作发行说明；接受有效的无版本旧档，拒绝未知新版本。
4. 保留可查询的待恢复状态；结构化结果的具体方法/信号及错误码在实现 PR 中展示和验收。
5. 迁移文件另存，原档不覆盖；旧路径到 ID 的具体映射由需要改名迁移的游戏显式提供。

## 实施与验收矩阵

第一阶段确定并文档化兼容支持范围和诊断；之后添加身份共存与预验证，再实现所需的历史迁移。
需要小型可运行场景及真实旧存档夹具，验证失败前运行状态保持不变，不能只检验输出字典字段。

| 场景 | 若采纳建议，期望结果 |
| --- | --- |
| 固定场景无 ID，路径未改 | 旧路径存档继续恢复 |
| 场景根改名，Player 有稳定 ID | health 恢复到 Player，路径变化不影响匹配 |
| 动态对象生成顺序互换 | 状态按稳定 ID 对应；管理器不擅自创建/删除对象 |
| 两节点或两记录使用同一 ID | 提交前失败，报告冲突，不把后一个覆盖前一个 |
| 对象延迟注册或永不注册 | 一次消费或保持可查询的待恢复记录，无跨存档污染 |
| legacy v0 + 明确旧路径映射 | 迁移到新身份；缺映射按已选兼容政策处理，不猜测 |
| 连续迁移 v0→v1→v2 | 每步成功后才提交；中途失败保留原文件和运行状态 |
| 更高未支持版本/断开的迁移链 | 明确拒绝，当前存档 ID 和待恢复状态不变 |
| 同 game_version，不同 schema | 按 schema 处理；不同 game_version，同 schema 可读 |
| resource/json/binary 的类型矩阵 | 各自报告支持与失败，Resource 修改 A 不污染 B/模板 |

## 已实现的基础接口

`source/save_system/save_object_registry.gd` 仅登记调用方提供的对象，使用弱引用，不查找场景或创建对象。`register_node(node, save_id)` 提供稳定 ID；省略 ID 时保存当前绝对路径。重复 ID 拒绝，同一对象重复登记相同身份幂等；改变身份前先 `unregister_node`。`resolve(kind, identity)` 返回仍有效的已登记对象，找不到返回 null；路径登记在场景改名后失效，稳定 ID 仍指向同一对象。`get_keys()` 给出排序后的有效身份，`clear()` 清理登记但不释放游戏对象。节点访问限主线程。

`source/save_system/save_version_contract.gd` 的 `check(metadata, current_schema_version, legacy_schema_version)` 返回带 error、message、format_version、schema_version 的结果。缺少框架版本表示 legacy v0；缺少游戏 schema 使用调用方配置的旧 schema（默认 1）。框架当前版本为 1，已声明框架版本的存档必须声明游戏 schema。实际 JSON 解码产生的整数浮点值也能读取；布尔、字符串、非整数、非有限值等错误类型被拒绝。未来版本返回 ERR_UNAVAILABLE，损坏元数据返回 ERR_INVALID_DATA；检查不修改输入。

旧 schema 通过 `check` 只表示可以进入后续转换阶段，**不表示已有完整迁移链或允许直接恢复**。`current_metadata` 只生成已完成转换的新快照元数据；不能用它把旧记录直接标记成新格式。该元数据复制会隔离字典和数组，不承诺其中的 Resource 独占；资源恢复隔离仍由 #99 快照拥有者负责。

在 Windows、Godot 4.7.2 stable mono 的独立宿主中，只复制上述两个脚本和 `tests/standalone_save` 两个检查脚本，创建 config_version=5 的 project.godot，没有 CoreSystem 或其他模块。分别执行 `--headless --verbose --path <宿主> --script tests/standalone_save/save_version_checks.gd`（42 项）和 `save_identity_checks.gd`（24 项）。两次退出码 0，无脚本错误、对象或资源保留。沙箱拒绝 user:// 日志写入、系统证书读取，空宿主缺少 .NET assembly，属于环境诊断，不作为功能通过证据。

版本案例包含真实 JSON 解码、无版本旧元数据、独立 schema、未来版本、损坏字段、检查与标记不修改原元数据。身份案例包含真实节点的场景改名、创建顺序互换、重复 ID、主线程限制、失效弱引用及清理不销毁对象。此阶段未验证真实旧档文件恢复、延迟恢复缓存或三种格式的资源隔离。后续内存迁移验证如下。

PR 保持 draft，issue 保持开放。后续实施必须接入 #99 独立存档组合，并与现有失败/隔离回归共同验证。

### 旧记录转换、资源拥有权与内存迁移

`save_record_contract.gd` 的 read(snapshot, current_schema_version, legacy_schema_version, legacy_path_ids) 将旧的扁平 node_path 记录转换为当前身份信封，保留 payload 中的 node_path 以兼容游戏的 load_data。旧路径可显式映射到稳定 ID；未映射对象保留路径，不猜测新对象。当前信封也经过类型、绝对路径和身份唯一性检查。重复身份（包括映射导致的碰撞）返回 ERR_ALREADY_IN_USE，并给出记录索引；失败不暴露部分输出。这里仅复制容器，Resource 值仍为只读借用引用。

`save_snapshot_copy.gd` 的 copy(value, readonly_resources) 创建可变快照。字典、带类型数组、PackedArray、可变 Resource 的持久化属性及外部嵌套资源按实例复制；同一快照内的资源别名保留，不同调用各自拥有资源。Texture、AudioStream、Script、Shader、PackedScene 按只读资产契约共享；自定义静态配置可通过 readonly_resources 显式共享。这些共享对象不得在迁移或恢复时修改。运行 Node、Callable、Signal、可变 Resource 引用环及超过64层的容器结构明确拒绝，不自动转成字符串。带必需构造参数等无法 duplicate 的自定义资源也不能保证复制成功。当前测试不等于所有 Resource 类的类型支持矩阵。

`save_migration.gd` 的 prepare(snapshot, current_schema, migrations, legacy_schema, legacy_path_ids, readonly_resources) 是内存入口：先读版本/转换身份，检查整个 vN→vN+1 回调链齐全，再创建拥有资源的副本。migrations 是 Dictionary[int, Callable]，键为源游戏schema；回调签名为 Dictionary→Dictionary（或返回 null 失败），返回完整快照。回调可保留源 schema 或声明下一版本，框架验证成功后标记下一版本。每步重新验证身份与版本、复制新引入的资源，然后进入下一步；禁止版本倒退、跳跃和返回旧信封。未来版本、缺步骤、失败回调和冲突输出都不产生可提交的部分数据。

回调只修改传入快照，不访问文件或运行对象、不修改共享只读资源。框架无法撤销调用方自行制造的外部副作用，也无法将 GDScript 运行错误当作正常错误返回；回调须符合签名并独立测试。此入口不操作磁盘、不调用 load_data、不改变 pending/current_save_id。另存政策仍需在 #99 的槽位操作接入，尚未交付。

同一独立宿主新增 record 检查19项、copy最终检查15项、migration最终检查12项，共新增46项，连同此前66项为112项。复制用真实自定义 Resource、嵌套数组、StandardMaterial3D、BoxShape3D及ImageTexture 验证A/B/模板隔离与只读共享。迁移验证两步顺序、全链预检查、中途失败保留输入资源、重复身份与未来输出拒绝、同schema仍拥有资源；均退出0，无脚本错误或退出对象/资源保留。初次复制检查发现空对象值判断和fixture数组类型错误，已修正；初次失败日志不作验收，copy/migration仅采用最终日志。
