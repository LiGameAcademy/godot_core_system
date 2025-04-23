# TODOList

## 目前的几个问题

- 异步IO管理器能不能支持更多的格式
- 不同存档策略的之间的兼容方式
- 非回调函数的返回方式（存档策略）
- [x] 部分属性存入插件设置

## 保存的逻辑执行顺序

- `pause_form`调用`GameInstance.save_manager.save_game()`;
- `GameInstance.save_manager`模块调用框架层的SaveManager的`create_auto_save()`
- `create_auto_save()`调用自身的`create_save(auto_save_id)`提供ID格式"auto_时间戳.tres"
- `create_save(save_id: String = "")`首先收集数据（字典）**？能不能使用Resource**
- `_collect_node_states()`方法收集节点数据并返回数据的数组`Array[Resource]`
- `create_save`方法收集数据后调用具体存档策略的`save`方法

## 存档策略的设计

提供给插件使用者渐进的、更丰富的存档方案选择。
1. Resource方案：文本文件，Godot原生方案，简单直接但不能加密；
2. JSON方案：文本文件，几乎没有冗余的数据。但是它无法支持复杂的类型；
3. 二进制方案：支持压缩和自定义的加解密方案，更高效，但也更复杂；

强烈建议使用 ConfigFile 重构 ConfigManager.gd，除非配置文件必须加密/压缩。
AsyncIOManager 的核心价值在于处理耗时 IO（大文件、网络、复杂处理），存档是其主要应用场景之一。
当前 AsyncIOManager 因硬编码 JSON 而局限性很大。
必须通过实现序列化策略模式来扩展 AsyncIOManager，使其能够处理 Resource、纯二进制、Godot Variant 等多种数据格式，这样才能真正发挥其潜力。
应将 AsyncIOManager 重构为可实例化的 RefCounted 类。