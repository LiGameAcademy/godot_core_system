# 模块按需启用与依赖契约提案（#75）

状态：待讨论，尚未改变运行实现。关联 [issue #75](https://github.com/LiGameAcademy/godot_core_system/issues/75)。
核对基线：main `8d484f5`。模块开关名称错配已由 #70 修复；本提案讨论启用后的依赖和创建时机。

## 当前限制

CoreSystem 的公开属性在 @onready 初始化时创建选定模块，不是首次使用才创建。
禁用分支通过 logger.warning 报警，而禁用 logger 的 getter 又会进入该分支，有递归风险。
AudioManager 初始化时取得 ConfigManager；SceneManager、EntityManager 在 ready 时连接 ResourceManager。
SaveManager 一次构造 resource/binary/json 三种策略，后两者构造 AsyncIOManager 和 SingleThread，
即使只使用 resource 格式也会建立它们。此处为源码核对，不代表已实测全部禁用组合。

## 建议决策及替代选择

| 决策 | 建议的第一阶段 | 替代选择及代价 |
| --- | --- | --- |
| 模块创建时机 | 保持启动时创建选定模块，先校验依赖，再按依赖顺序创建 | 首次访问创建可减少闲置模块，但改变 ready/信号连接/副作用时机，需要另行迁移 |
| Logger | 允许禁用；启动诊断使用引擎 API，模块日志调用在缺省时采用引擎诊断 | Logger 强制开启改动较小，但失去独立开关意义，应明确告知 |
| 依赖被禁用 | 拒绝创建依赖方并报告依赖链，不自动改写 ProjectSettings | 自动启用更方便，但用户关闭的模块仍被创建；注入替代服务需要真实使用场景 |
| 存档策略 | 按实际格式第一次使用时创建并缓存，默认 resource 不创建异步工作器 | 保留预创建最少改动，但必须公开线程成本与退出责任 |

建议保留全部默认开关为开启，已有正常工程保持 ready 后模块可用。
不新增全局 DI 容器，不把首次访问创建作为本阶段默认模式。
以上均为建议，需要维护者确认后再实现。

## 候选依赖表

表格描述拟支持的契约，并非当前已支持所有组合。实施时逐项追踪直接调用与辅助类调用。

| 使用方 | 必需服务或启用条件 | 需要修改的位置 |
| --- | --- | --- |
| audio_manager | config_manager | 构造前校验；拒绝在 null 配置上读取音量 |
| scene_manager、entity_manager | resource_manager | 构造前校验；依赖先入树，之后才连接加载信号 |
| input_manager 的配置适配功能 | config_manager | InputConfigAdapter 明确前置条件；基础输入是否允许无配置仍待决定 |
| trigger_manager 的 EventBus 订阅功能 | subscribe_event_bus=true 时需要 event_bus | 不在未启用订阅时无条件取得 EventBus；手动 handle_event 保持可用 |
| save_manager 的 binary/json 加密策略 | config_manager 提供现有密钥配置 | 创建对应策略前验证；resource 策略不要求配置服务 |
| 各模块和线程/序列化工具的日志调用 | logger 可选（若采纳建议） | 排查直接 CoreSystem.logger 及捕获 logger 的字段，不能只修启动入口 |
| tag 容器、trigger 对象等辅助对象 | 调用时分别需要 tag_manager、trigger_manager | 禁用相应模块时拒绝相关功能并诊断，不因一次访问暗中开启模块 |

仅修 _get_module 的日志递归不足以支持 logger=false；辅助线程退出和策略错误路径也要验证。
无业务依赖的 event_bus、time_manager、state_machine_manager 等不应为诊断创建其它模块。

## 启动与错误契约草案

1. 从 #70 的规范设置名及旧名后备规则读取选定模块集，配置不因创建过程而改变。
2. 在创建任何消费者前检查必需依赖；禁用和依赖缺失分别记录原因。
3. 依赖先创建并达到可调用状态，再构造消费者；拒绝循环依赖，记录完整依赖链。
4. 缺失依赖的消费者不实例化；独立模块仍可启动。公开 getter 返回 null，调用方检查可用性。
5. 通过一个只读启动诊断列表报告 module_id、原因与依赖链；同一失败不在每帧反复重试或刷日志。
6. 启动诊断不能调用会创建 Logger 的 getter；只使用已创建的实例或引擎 push_error/push_warning。

是否“部分启动”还是整个启动失败必须确认。建议部分启动并明确报告不可用消费者，
让仅使用 EventBus 的工程不因无关配置错误丧失它；对消费者 API 的 null 检查是兼容迁移点。
动态修改开关后的热启停不属于第一阶段；需要重启工程生效。

## 存档策略与线程责任

以现有格式名选取策略脚本，第一次实际使用时构造，不预建所有实例。
无效格式返回明确失败，不能把字符串后备值当策略对象调用。
切换格式允许复用已创建策略；销毁时清理各已创建异步工作器，等待在途任务符合 #63 契约。
resource-only 的最小工程新增 AsyncIOManager 工作线程数应为 0；
首次用 json/binary 时各建立其当前实现所需的工作器，再次切回同一格式不重复建立。
这里不要求合并所有策略为一个线程，也不改变存档文件格式。

## 待确认的具体选择

- 是否接受“保持显式启动选定模块，暂不改首次访问创建”？
- Logger 允许关闭并补全后备调用，还是作为强制基础设施移除独立关闭承诺？
- 缺依赖时部分启动并拒绝消费者，还是整个启动失败；是否要求自动启用依赖？
- 基础输入无配置是否要支持？resource 存档无配置是否要支持？
- 是否接受策略首次使用才创建，以及由策略负责退出工作器？

## 实施与验收范围

先实现开关/依赖校验与引擎诊断，再逐模块迁移可选 Logger 调用，最后延迟构造策略。
仍用一个 issue 分支；仅在上述选择确定且实现完成后将草案 PR 转为可合并 PR。

| 隔离工程组合 | 若采纳建议，期望行为 |
| --- | --- |
| 仅 event_bus，关闭 logger 及其它模块 | ready 后可订阅/推送；无日志递归，无额外模块 |
| resource_manager，关闭 logger | 立即/懒加载成功与失败均可收尾，诊断走引擎 |
| audio=true，config=false | audio 不创建，报告 audio→config 缺失，独立模块正常 |
| scene/entity=true，resource=false | 拒绝对应消费者，原场景正常，不出现 null 信号调用 |
| trigger=true，subscribe_event_bus=false，event_bus=false | 手动事件与周期触发可用，不创建 EventBus |
| save=resource，config=false，仅必要模块 | resource 存读可用，新增异步存档线程为 0 |
| save=json/binary，config=false | 在使用对应格式前拒绝并诊断，不覆盖已有存档 |
| 所有默认开关开启 | 原公开属性可用，音频/输入/场景回归正常 |
| 先 resource 再 json 再 resource 再 json | 对应工作器首次使用才创建，不重复创建，退出可停止 |

自动测试需记录模块实例集、通知、实际线程构造/退出数量，不能仅检查开关布尔值。
再在真实游戏测试 ready 时机和配置持久化。这份 PR 只交付源码核对、方案和验收矩阵，未执行方案运行验证。
