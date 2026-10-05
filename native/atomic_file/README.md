# Windows 安全文件替换

这是版本化 JSON 服务使用的最小 C11 GDExtension，不依赖 godot-cpp。当前提供并验证 Windows x64 / Godot 4.7.2 的 DLL；最低引擎版本为 4.7。其他架构不提供预编译库，使用这些平台时应移除本目录的 `.gdextension` 注册文件，按平台实现并验证替换后端。不要把这个 Windows 发布包标为全平台支持。

`CoreAtomicFile.replace(source, target)` 接受同一目录的两个不同绝对路径，返回 Godot Error。拒绝目录、源或目标重解析点以及跨目录移动。临时文件先通过 FlushFileBuffers 刷入磁盘，再调用 MoveFileExW 的 REPLACE_EXISTING / WRITE_THROUGH，明确不启用跨卷复制，不先删除目标。锁定或替换失败时保留旧目标；调用方清理临时文件。父目录仍是受信配置，不是文件系统沙箱；单个文件只使用一个写入拥有者，不保证断电后的目录持久性。

加载失败时 CoreSaveStore 在 Windows 返回 ERR_UNAVAILABLE，不退回 Godot 的先删除后移动。发布或导出项目时必须包含 `.gdextension` 和匹配 DLL，并对导出结果执行实际读写检查。

## 构建

仓库包含构建产物，也保留完整源代码。Windows x64 TinyCC 0.9.27 构建已验证；编译器自行从官方发行包获取，不安装项目级系统依赖：

```powershell
./build.ps1 -Compiler C:/tools/tcc/tcc.exe
```

脚本使用 TinyCC/GCC 风格参数；不适用于 MSVC cl。使用其他编译器时自行调整命令并重新执行检查。

`vendor/gdextension_interface.h` 是 Godot 4.7.2 官方引擎通过 `--headless --dump-gdextension-interface` 生成的接口头，保留原 MIT 许可和版权声明；不是手写插件代码。Godot String / StringName 的存储尺寸以当前 Windows x64 ABI 为准，不将该绑定直接复用到未经验证的架构。

验证覆盖首次创建、覆盖、缺失源、相同路径、目录目标和目标被外部进程锁定。DLL 摘要可用 `Get-FileHash -Algorithm SHA256 bin/core_atomic_file.windows.x86_64.dll` 重算；不同编译器的二进制摘要不要求一致。
