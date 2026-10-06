# GDScript 旧标签适配层（已弃用）

新代码请使用 [CoreTags](core_tags.md)。旧类名保留为迁移适配层，成员资格由 CoreTags 统一管理；对象查询注册表仍是 GDScript 专属扩展。完整 API、迁移表及检查命令见 [英文说明](tag_system.md)。

## 迁移必须注意的变化

- 非精确查询改为单向：持有 `unit.scout` 可以满足 `unit`，持有 `unit` 不代表持有 `unit.scout`。
- `get_tags()` 返回排序后的显式完整路径；`get_all_tags()` 返回显式记录，不再扩展全部注册后代。
- `CoreGameplayTag.create` 接收完整合法路径。路径固定，不能通过修改名称或挂接父节点改变身份。`name`、`parent`、`children` 在公开 API 中只读，子列表是快照，父子关系为弱引用。
- 同一拥有者重复创建容器时返回同一个存活容器；注册表弱引用拥有者及容器，查询时读取真实成员并清理失效引用，移除旧反向索引及清理计时器。
- 所有查询路径先完整校验；空 All 为真，空 Any 为假。对象查询的空 All 返回全部存活注册对象，空 Any 返回空数组。已释放或等待删除的对象被排除。

## 本地使用

GameplayTagContainer 是 Resource，可直接创建，不需要 CoreSystem，也不能加入场景树。旧信号仍携带 CoreGameplayTag，在成员更新后通知。迁移至 CoreTags 后信号携带完整路径字符串。

```gdscript
var tags: CoreTags = CoreTags.new()
tags.add("unit.scout")
var classified: bool = tags.has("unit", false)
```

CoreSystem.tag_manager 仅在访问时创建。旧 `module_enable/gameplay_tag_manager` 配置继续有效；显式设置 `module_enable/tag_manager` 时优先使用后者。需要旧对象查询时传入拥有者，并自行保存容器，注册表不负责延长其生命。路径定义注册与对象显式成员资格互不等价。

[旧演示](../../examples/tag_demo/README.md) 已迁移为本地 CoreTags，角色拥有独立规则模型，场景根协调按钮和信号。无需 AutoLoad 或游戏素材。Godot 4.7.2 下兼容层 46 项、演示 17 项检查通过且独立退出无保留对象警告；旧 CoreSystem 其他模块的退出保留问题仍单独记录。未新增来源计数、叠层、序列化或全局索引优化。
