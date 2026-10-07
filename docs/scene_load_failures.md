# 场景加载失败与重试

`change_scene_async` 在实例化前检查 PackedScene 类型及 can_instantiate。
缺失文件、非场景资源、空 PackedScene、失效实例及未注册 CUSTOM 转场会在替换当前场景前失败。
栈场景仅在有效时取出；没有父节点的栈场景不调用 move_to_front。

失败统一释放切换锁、隐藏转场遮罩，记录原因，然后发送：

1. `scene_loading_finished()`：平衡已经发出的开始通知。
2. `scene_loading_failed(scene_path: String, reason: String)`：说明此请求失败。

此时可以重试；原场景保持不变，不发送 scene_changed，不调用成功 callback。
被并行切换锁拒绝的请求仍仅记录警告，不发送开始/完成/失败信号。
开始/完成信号负责加载状态，是否成功由 scene_changed 或 scene_loading_failed 判断。
失败通知的处理器若立即发起另一个切换，请将通知中的路径当作原请求路径。

成功切换时，scene_changed 的 old_scene 在旧场景已释放时为 null；
使用 push_to_stack 保留旧场景时，它仍是有效实例。消费者必须先检查旧场景有效性。
这避免失效实例参数中断成功切换的收尾通知。

自动回归：运行 `res://addons/godot_core_system/test/unit/scene_failure_checks.tscn`。
检查四种拒绝路径、原场景保持、锁释放、有效场景重试和开始/完成信号平衡。
人工验收仍需检查真实游戏转场、成功回调、场景栈以及失败提示的显示和关闭。
自定义转场自身的脚本异常、信号未返回或场景脚本异常不在此处提供超时/异常捕获机制。
