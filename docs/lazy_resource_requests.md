# 懒加载请求收尾

ResourceManager 为每条路径维护一个实际原生加载请求。
重复 LAZY 加载复用该请求，不累计请求次数；待加载数量从请求表计算。
`load_threaded_request` 返回错误时不插入缓存或待加载记录。

加载途中清缓存不能取消 ResourceLoader 的原生工作。
管理器保留请求并继续轮询，完成时调用 `load_threaded_get` 收尾，但不重新缓存或发送 resource_loaded。
如果清缓存后又请求同一路径，则恢复该请求的发布意图，仍只调用一次原生请求。
清空全部缓存对每个在途请求采用相同规则。

同步获取待加载路径会通过 `load_threaded_get` 等待并消费现有请求，
从请求表移除后才发送 resource_loaded。加载失败会移除请求与空缓存项，不留下残余计数。
信号回调同步获取其它待加载路径时，轮询快照会跳过已消费的记录。

这里的“清缓存”指管理器缓存，并不强制清除 Godot 全局 ResourceLoader 缓存。
管理器需要继续处于树中处理在途请求；退出树时的跨实例请求协调不属于此次改动。
API 默认用于主线程，不保证多个 ResourceManager 并发管理同一路径的协调。

自动回归：运行 `res://addons/godot_core_system/test/unit/lazy_resource_checks.tscn`。
覆盖重复请求、清缓存后收尾/重新请求、清全部缓存、同步获取、缺失与损坏资源。
人工验收应使用较大资源，在真实加载过程中清缓存并重试，检查完成信号与内存使用。
