# 命名线程任务 ID

`ModuleThread.submit_task()` 与 `task_completed_on_thread` 保持公开的 String ID 契约。
SingleThread 内部仍使用 int ID；管理器按线程记录映射，并用自身递增计数生成公开 ID。
ID 在同一管理器生命周期内唯一，卸载并重建同名线程不会复用。不同管理器的 ID 不保证互不重复。

提交接口先校验 Callable。无效 Callable 返回空字符串；有效任务的返回 ID 与聚合完成信号中的 ID 相同。
直接使用 `create_thread()` 返回的 SingleThread 提交任务不属于管理器的映射，不产生聚合任务完成通知。

卸载先断开带线程名的实际绑定回调、移除映射，再等待工作线程停止。
尚未发出的聚合完成通知被取消；运行中的函数会执行到返回，排队任务可能被丢弃。
调用方应在主线程管理卸载和清理，不要从正在被卸载的任务内停止自身线程。
等待工作线程期间不持有管理器互斥锁，允许运行中的任务调用提交接口。
`all_tasks_finished_on_thread` 保持 SingleThread 原有的队列为空通知语义，不新增批次保证。

自动回归：在配置 CoreSystem Autoload 的 Godot 工程运行
`res://addons/godot_core_system/test/unit/module_thread_checks.tscn`。
检查两个线程、结果与公开 ID 对应、卸载后的绑定断开和同名线程重建。
仍需在真实工程验证长任务卸载时的等待、业务取消处理及线程退出。
