# 日志系统

日志脚本可直接 preload，无需 CoreSystem 或 setting.gd。CoreSystem.logger 保留为可选旧入口；完整真实 API 和英文示例见[日志说明](logger_system.md)，独立安装与双语言边界见[配置及诊断说明](configuration.md)。

日志等级为 DEBUG / INFO / WARNING / ERROR / FATAL。debug、info、warning、error、fatal 接收消息和可选字典上下文；set_level 过滤格式化控制台及文件输出。warning/error/fatal 保留旧版引擎诊断，独立于这个阈值；error/fatal 还输出调用栈。

set_color、set_colors、reset_colors、get_colors 管理实例颜色；项目 color_* 设置可选，并有本地默认值。文件输出默认关闭，先通过 set_file_path 指定路径，再 enable_file_logging(true)，通过 last_file_error 读取打开结果。禁用输出、切换路径和退出场景树会关闭旧句柄，也可显式 close_file。以 WRITE 打开，保留覆盖截断行为；共享路径只有一个写入拥有者。

旧文档的日志轮换、configure_file_logging 和公开 log(level) 方法不属于当前实现，已移除错误示例。C# CoreLogger 是接收显式输出函数的纯过滤类；颜色、上下文、调用栈和内建文件输出是 GD 扩展，不宣称日志 API 已完全相同。更进一步的日志扩展留在 P3；文件日志不替代游戏存档。
