# Issue #31 — GZIP 高压缩比解压测试

## 背景

未压缩数据很大、gzip 包很小时，若仅用「压缩包大小 × 10」作为 `PackedByteArray.decompress` 的缓冲区，会失败（Godot 返回空或错误）。修复后使用 **RFC 1952 尾部 ISIZE** 与重试放大缓冲区。

## 说明

- 启动项目时若出现 `user://config.cfg not found`，来自 **CoreSystem / ConfigManager** 自动加载，与本测试无关，可忽略。
- 测试**不再**调用「过小缓冲区」的 `PackedByteArray.decompress`，以免 Godot 在 C++ 层打印 `compression.cpp` 错误；改为用数值说明旧缓冲上限小于未压缩长度。

## 如何测试

### 1. 编辑器里跑场景（推荐）

1. 在 Godot 中打开场景：  
   `res://addons/godot_core_system/test/gzip_issue31/gzip_issue31_test.tscn`
2. 运行 → 点击 **「运行测试」**。
3. 预期：
   - **旧估算** `decompress(gzip.size * 10)` 往往得到 **输出长度 0**（复现问题）。
   - **GzipCompressionStrategy.decompress** 输出长度等于原文，并显示 **PASS**。

### 2. 命令行（无界面）

在项目根目录执行：

```bash
godot --path . --headless -s res://addons/godot_core_system/test/gzip_issue31/gzip_issue31_test_cli.gd
```

- 退出码 `0`：解压与原文一致。  
- 退出码 `1`：失败。

## 参考

- Issue: [godot_core_system#31](https://github.com/LiGameAcademy/godot_core_system/issues/31)
