# save_demo

## 手动测试 GitHub Issue #51（`create_auto_save` 误报 Failed to clean old auto saves）

**现象（旧版）**：`_clean_old_auto_saves` 无返回值，`await` 得到 `null`，`cleanup_success` 恒为假，每次成功自动存档后都会打 warning。

**修复后**：清理函数返回 `bool`，且使用列表项中的 `save_id` 调用 `delete_save`。

**步骤**：

1. 运行场景 `save_demo.tscn`。
2. 点击 **「测试 #51 自动存档清理」**（约 5 秒：临时将 `max_auto_saves` 设为 2，连续 4 次 `create_auto_save`，每次间隔 1.1s 避免同一时间戳 ID 冲突）。
3. 查看 **输出 / 日志**：不应再出现 `[WARNING] Failed to clean old auto saves`。
4. 界面状态行会提示当前自动存档条数（应不超过当时的 `max_auto_saves`）。

也可在项目设置 `godot_core_system/save_system/auto_save/max_saves` 中自行改小后，多次调用 `CoreSystem.save_manager.create_auto_save()` 做同样验证。

---

# save_demo.gd 需要展示的功能：

# 1. 基础存档功能
- 手动保存/加载
- 自动保存（定时器触发）
- 存档列表显示
- 存档删除

# 2. 不同存档格式
- Resource 格式（展示 Godot 原生资源保存）
- JSON 格式（展示可读性）
- Binary 格式（展示加密和压缩）

# 3. 存档数据展示
- 元数据显示（时间戳、版本等）
- 游戏状态显示（玩家位置、分数等）
- 存档文件大小对比

# 4. 错误处理
- 存档失败处理
- 加载失败处理
- 文件不存在处理