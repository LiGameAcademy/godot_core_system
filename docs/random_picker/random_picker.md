# RandomPicker Pool

## Features

- **Efficient Algorithm**:  
  - Implements Alias Method for `O(1)` time complexity weighted random selection  
  - Provides manual/automatic probability table rebuild parameters to optimize high-frequency operations  
- **Dynamic Operations**:  
  - Supports add/remove/update items with weights, batch operations  
  - Automatic or manual probability table rebuild after item changes (controlled via method parameters)  
- **Flexible Configuration**:  
  - Supports multiple input formats (arrays/dictionaries), auto-converts to unified structure (see examples)  
  - Optional duplicate checking and auto-rebuild  
- **Safety Mechanisms**:  
  - Auto-filters invalid weights (non-positive values)  
  - Provides pool status monitoring (empty detection, item count query)  
  - Supports duplicate merging and cleanup

---

## Usage Examples

### Basic Usage
```gdscript
# Initialize pool (disable auto-rebuild and duplicate check for performance)
var pool = CoreSystem.RandomPicker.new([
	["sword", 10], 
	{"data": "gem", "weight": 5}
], check_repeat=false)

# Add single item (manual rebuild control)
pool.add_item("shield", 8.0, rebuild=false, check_repeat=false)

# Batch add with manual rebuild
var new_items = [
	["potion", 15],
	{"data": "key", "weight": 1}
]
pool.add_items(new_items, rebuild=false)
pool.rebuild_alias_table()  # Explicit rebuild

# Get random item (non-removal)
var loot = pool.get_random_item()

# Batch remove with auto-rebuild
pool.remove_items(["sword", "gem"], rebuild=true)
```

### Dynamic Operations & Signals
```gdscript
# Connect signals
pool.item_picked.connect(func(item): 
	print("Selected:", item)
)
pool.pool_emptied.connect(func(): 
	print("★ Pool emptied!")
)

# Update weight and trigger rebuild
pool.update_item_weight("potion", 20.0)
pool.add_item("dragon_sword", 5.0)

# Empty pool (trigger signal)
while not pool.is_empty():
	pool.get_random_item(true)  # Remove selected
```

---
## Best Practices

1. **Data Validity**:  
   - Weights must be positive, otherwise operations are rejected  
   - Returns `null` for `get_random_item` when total weight is `0`

2. **Performance Optimization**:  
   - For high-frequency operations (e.g., batch adds), disable `rebuild` and `check_repeat`, call `rebuild_alias_table()` manually.  
   - Stress tests show 100k items pool averages <`0.001ms` per random access, but ~`580ms` initialization (lightweight laptop). Manage duplicates carefully for large datasets.  
   - Set `check_repeat=false` during initialization if duplicates are impossible (saves ~`100ms` for 100k items).

---

## API Reference

### Core Methods
| Method | Parameters | Returns | Description |
|------|------|--------|------|
| **`add_item`**<br>`(item_data, item_weight, rebuild:=true, check_repeat:=true)` | `item_data`: Any data<br>`item_weight`: Positive float<br>`rebuild`: Rebuild table<br>`check_repeat`: Check duplicates | `bool` | Add single item, returns success |
| **`add_items`**<br>`(items, rebuild:=true, check_repeat:=true)` | `items`: Array (mixed formats)<br>`rebuild`: Rebuild table<br>`check_repeat`: Check duplicates | `int` | Returns successful additions count |
| **`remove_item`**<br>`(item_data, rebuild:=true)` | `item_data`: Target data<br>`rebuild`: Rebuild table | `bool` | Returns removal success |
| **`remove_items`**<br>`(item_datas, rebuild:=true)` | `item_datas`: Array of targets<br>`rebuild`: Rebuild table | `int` | Returns successful removals count |
| **`update_item_weight`**<br>`(item_data, new_weight, rebuild:=true)` | `item_data`: Target data<br>`new_weight`: New weight<br>`rebuild`: Rebuild table | `bool` | Returns update success |
| **`update_items_weights`**<br>`(updates, rebuild:=true)` | `updates`: Update array (mixed formats)<br>`rebuild`: Rebuild table | `int` | Returns successful updates count |
| **`get_random_item`**<br>`(should_remove:=false)` | `should_remove`: Remove item | `Variant` | Returns random data (`null` if empty) |

### Utility Methods
| Method | Description |
|------|------|
| `get_item_weight(item_data: Variant) -> float` | Get item's weight (returns `-1` if missing) |
| `get_items_weights(item_datas: Array) -> Dictionary` | Returns existing items' weights as `{data: weight}` |
| `remove_duplicates()` | Clean duplicates (keeps first occurrence, returns removed count) |
| `get_remaining_count() -> int` | Get total items count |
| `is_empty() -> bool` | Check if pool is empty |
| `rebuild_alias_table()` | Manually rebuild probability and alias tables |
| `clear()` | Clear all items |
| `has_item(item_data: Variant) -> bool` | Check item existence |

### Signals
| Signal | Description |
|------|------|
| `item_picked(item_data: Variant)` | Emitted when item is selected via `get_random_item` |
| `pool_emptied` | Emitted when pool becomes empty |
