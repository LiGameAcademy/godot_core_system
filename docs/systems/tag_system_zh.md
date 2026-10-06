# 原版标签扩展的兼容边界

当前双语言共同实现请使用 [CoreTags](core_tags.md)。CoreGameplayTag、GameplayTagContainer 与 CoreSystem.tag_manager 保留为原版 GDScript 扩展，不表示 C# 已实现全局对象索引。

GameplayTagContainer 是 Resource，不是 Node，不能调用 add_child(container)，也不是场景中的子节点。通过 CoreSystem.tag_manager.create_tag_container() 创建；传入 owner 时才选择接入旧对象索引，并由拥有者保留返回的容器。

原版非精确查询沿注册对象树双向匹配，父标签可能满足更具体的子标签条件；CoreTags 采用单向层级查询，不沿用此行为。原版 get_tags() 返回叶名称，get_all_tags() 展开注册后代，不代表对象显式拥有全部后代。原版没有已实现的序列化/反序列化 API，不能据此宣称持久化支持。

完整兼容说明见 [原版标签说明](tag_system.md)。新独立示例见 [tags](../../examples/tags/README.md)，不依赖 AutoLoad、对象索引或具体游戏。