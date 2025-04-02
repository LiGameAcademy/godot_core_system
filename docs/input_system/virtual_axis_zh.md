# 虚拟轴系统 (Virtual Axis System)

## 简介
虚拟轴系统提供了一种灵活的方式来处理基于轴的输入，如角色移动、摄像机控制等。它支持组合多个输入动作形成一个虚拟轴，并提供死区和灵敏度调节。

## 功能特性
- 支持2D轴输入（X和Y轴）
- 可配置的死区和灵敏度
- 实时轴值更新
- 轴值变化信号通知

## 核心类
### InputVirtualAxis
主要的虚拟轴处理类，负责管理和更新轴状态。

#### 主要属性
- `_sensitivity`: 轴灵敏度
- `_deadzone`: 轴死区

#### 主要方法
- `register_axis(axis_name, positive_x, negative_x, positive_y, negative_y)`: 注册一个新的虚拟轴
- `update_axis(axis_name)`: 更新指定轴的状态
- `get_axis_value(axis_name)`: 获取轴的当前值
- `set_sensitivity(value)`: 设置轴灵敏度
- `set_deadzone(value)`: 设置轴死区

## 使用示例
```gdscript
# 注册一个用于角色移动的虚拟轴
virtual_axis.register_axis(
    "movement",
    "ui_right",  # X轴正向
    "ui_left",   # X轴负向
    "ui_up",     # Y轴正向
    "ui_down"    # Y轴负向
)

# 设置轴参数
virtual_axis.set_sensitivity(1.0)
virtual_axis.set_deadzone(0.2)

# 获取轴值
var movement = virtual_axis.get_axis_value("movement")
```

## 信号
- `axis_changed(axis_name: String, value: Vector2)`: 当轴值发生变化时触发

## 注意事项
- 确保在使用轴值之前已经注册了相应的轴
- 合理设置死区可以过滤掉不必要的小幅度输入
- 灵敏度值影响输入响应的速度

## 高级用法
### 轴值处理
```gdscript
# 处理带有死区的轴值
func process_axis_value(value: float) -> float:
    if abs(value) < _deadzone:
        return 0.0
    
    # 应用死区后的值映射
    var sign = sign(value)
    return sign * (abs(value) - _deadzone) / (1.0 - _deadzone)
```

### 自定义轴配置
```gdscript
# 配置特定游戏类型的轴设置
func setup_platformer_controls():
    # 平台游戏通常只需要水平移动
    virtual_axis.register_axis(
        "movement",
        "move_right",
        "move_left"
    )
    
    # 设置较小的死区以获得精确控制
    virtual_axis.set_deadzone(0.1)
```

## 性能考虑
- 只在必要时更新轴状态
- 避免每帧重复注册轴
- 及时注销不再使用的轴
