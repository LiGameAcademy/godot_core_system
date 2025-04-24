# 随机选择池（RandomPicker）

## 功能特性

- **高效算法**：  
  - 使用别名算法（Alias Method）实现`O(1)`时间复杂度的基于权重的随机选择  
  - 提供手动/自动重建概率表的参数控制，优化高频操作场景性能  
- **动态操作**：  
  - 支持添加、删除、更新物品及权重，支持批量操作  
  - 物品变动后自动或手动重建概率表（通过方法参数选择）  
- **灵活配置**：  
  - 支持多种输入格式（数组、字典），自动转换为统一结构（参考示例代码）  
  - 可选择是否检查重复项、是否自动重建表
- **安全机制**：  
  - 自动过滤无效权重（非正数）  
  - 提供池状态监控（空池检测、剩余数量查询）  
  - 支持重复项合并与清理

---

## 使用示例

### 基础用法
```gdscript
# 初始化池（关闭自动重建和重复检查以优化性能）
var pool = CoreSystem.RandomPicker.new([
	["sword", 10], 
	{"data": "gem", "weight": 5}
], check_repeat=false)

# 添加单个物品（手动控制重建）
pool.add_item("shield", 8.0, rebuild=false, check_repeat=false)

# 批量添加并手动重建
var new_items = [
	["potion", 15],
	{"data": "key", "weight": 1}
]
pool.add_items(new_items, rebuild=false)
pool.rebuild_alias_table()  # 显式重建

# 获取随机物品（不移除）
var loot = pool.get_random_item()

# 批量移除并自动重建
pool.remove_items(["sword", "gem"], rebuild=true)
```

### 动态操作与信号
```gdscript
# 连接信号
pool.item_picked.connect(func(item): 
	print("选中物品：", item)
)
pool.pool_emptied.connect(func(): 
	print("★ 池已清空！")
)

# 动态更新权重并触发重建
pool.update_item_weight("potion", 20.0)
pool.add_item("dragon_sword", 5.0)

# 清空池（触发信号）
while not pool.is_empty():
	pool.get_random_item(true)  # 移除选中项
```

---
## 最佳实践

1. **数据有效性**：  
   - 权重必须为正数，否则添加/更新操作会被拒绝
   - 总权重为`0`时，无法构建别名表，`get_random_item`返回`null`

2. **性能优化**：  
   - 高频操作（如批量添加）建议关闭`rebuild`和`check_repeat`，最后手动调用`rebuild_alias_table()`。  
   - 压力测试表明，10万级物品池的单次随机访问平均耗时低于`0.001ms`，但初始化时间约`580ms`(轻薄本简单测试)，因此大数据量需要审慎清理重复项或重建概率表和别名表
   - 如果可以确保数据无重复，可以在随机池初始化时将`check_repeat`参数设为`false`以优化性能(10万数据下大概快`100ms`)

---

## API 参考

### 核心方法
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| **`add_item`**<br>`(item_data, item_weight, rebuild:=true, check_repeat:=true)` | `item_data`: 任意数据<br>`item_weight`: 正浮点数<br>`rebuild`: 是否重建表<br>`check_repeat`: 是否检查重复 | `bool` | 添加单个物品，返回成功状态 |
| **`add_items`**<br>`(items, rebuild:=true, check_repeat:=true)` | `items`: 数组（混合格式）<br>`rebuild`: 是否重建表<br>`check_repeat`: 是否检查重复 | `int` | 返回成功添加数量 |
| **`remove_item`**<br>`(item_data, rebuild:=true)` | `item_data`: 要删除的数据<br>`rebuild`: 是否重建表 | `bool` | 返回是否删除成功 |
| **`remove_items`**<br>`(item_datas, rebuild:=true)` | `item_datas`: 要删除的数据数组<br>`rebuild`: 是否重建表 | `int` | 返回成功删除数量 |
| **`update_item_weight`**<br>`(item_data, new_weight, rebuild:=true)` | `item_data`: 目标数据<br>`new_weight`: 新权重<br>`rebuild`: 是否重建表 | `bool` | 返回是否更新成功 |
| **`update_items_weights`**<br>`(updates, rebuild:=true)` | `updates`: 更新项数组（混合格式）<br>`rebuild`: 是否重建表 | `int` | 返回成功更新数量 |
| **`get_random_item`**<br>`(should_remove:=false)` | `should_remove`: 是否移除选中项 | `Variant` | 返回随机数据（空池返回`null`） |

### 辅助方法
| 方法 | 说明 |
|------|------|
| `get_item_weight(item_data: Variant) -> float` | 查询指定物品的权重（未找到返回`-1`） |
| `get_items_weights(item_datas: Array) -> Dictionary` | 返回存在的物品权重字典（`{数据: 权重}`） |
| `remove_duplicates()` | 清理重复项（保留第一项，返回移除数量） |
| `get_remaining_count() -> int` | 获取池中物品总数 |
| `is_empty() -> bool` | 检查池是否为空 |
| `rebuild_alias_table()` | 手动重建别名表和概率表 |
| `clear()` | 清空所有物品 |
| `has_item(item_data: Variant) -> bool` | 判断是否存在物品 |

### 信号
| 信号 | 说明 |
|------|------|
| `item_picked(item_data: Variant)` | 当`get_random_item`选中物品时触发 |
| `pool_emptied` | 当池中物品被清空时触发 |

---
