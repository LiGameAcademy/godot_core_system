# 输入系统演示 (Input System Demo)

本目录包含了输入系统各个子模块的演示示例。

## 目录结构
```
input_demo/
├── basic/                # 基础功能演示
│   ├── basic_demo.tscn  # 基础演示场景
│   └── basic_demo.gd    # 基础演示脚本
├── virtual_axis/        # 虚拟轴系统演示
│   ├── character.tscn   # 角色场景
│   └── movement_demo.gd # 移动演示脚本
├── input_state/        # 输入状态系统演示
│   ├── combo_demo.tscn # 连击演示场景
│   └── combo_demo.gd   # 连击演示脚本
├── input_buffer/       # 输入缓冲系统演示
│   ├── buffer_demo.tscn # 缓冲演示场景
│   └── buffer_demo.gd  # 缓冲演示脚本
├── input_recorder/     # 输入记录器演示
│   ├── recorder_demo.tscn # 记录演示场景
│   └── recorder_demo.gd   # 记录演示脚本
└── event_processor/    # 事件处理器演示
    ├── processor_demo.tscn # 处理器演示场景
    └── processor_demo.gd   # 处理器演示脚本
```

## 演示内容
1. 基础功能演示
   - 输入系统初始化
   - 基本输入检测
   - 配置管理

2. 虚拟轴系统演示
   - 角色移动控制
   - 死区和灵敏度调节
   - 轴值可视化

3. 输入状态系统演示
   - 连击检测
   - 长按判定
   - 状态可视化

4. 输入缓冲系统演示
   - 技能释放
   - 缓冲窗口配置
   - 缓冲可视化

5. 输入记录器演示
   - 输入序列记录
   - 回放功能
   - 存档和加载

6. 事件处理器演示
   - 事件过滤
   - 优先级处理
   - 事件队列管理
