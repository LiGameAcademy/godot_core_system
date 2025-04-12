extends RefCounted

var _remove_after_pick: bool
var _item_pool: Array[Dictionary]
var _logger : CoreSystem.Logger = CoreSystem.logger

signal item_picked(item_data: Variant)
signal pool_emptied

func _init(items: Array = []) -> void:
	if items.is_empty():
		return
	add_items(items)

## 添加随机项
## [param item_data] 随机项
## [param item_weight] 随机权重
## [return] 添加是否成功
func add_item(item_data: Variant, item_weight: float) -> bool:
	if item_weight <= 0:
		_logger.error("道具权重必须为正数 %s" %str(item_data))
		return false
	
	# 检查重复项
	for item in _item_pool:
		if item.data == item_data:
			_logger.warning("%s物品已经存在，添加失败！" %str(item_data))
			return false

	_item_pool.append({"data": item_data, "weight": item_weight})
	return true

## 批量添加随机项
## 每一项都需要包含字段data、weight
## [param items] 添加的数据
## [return] 返回成功添加的数量
func add_items(items: Array) -> int:
	var success_count := 0
	for item in items:
		if item is Array:
			if item.size() < 2:
				_logger.error("物品格式不合法！%s" %str(item))
			elif not (item[1] is float or item[1] is int):
				_logger.error("物品权重格式不合法！%s" %str(item))
			else:
				if add_item(item[0], item[1]):
					success_count += 1
		elif item is Dictionary:
			if not (item.has("data") and item.has("weight")):
				_logger.error("物品格式错误，必须包含 data 和 weight 字段 %s" %str(item))
				continue
			
			if add_item(item.data, item.weight):
				success_count += 1

	return success_count

## 删除指定项
## [param item_data] 要删除的物品数据
## 返回是否删除成功
func remove_item(item_data: Variant) -> bool:
	for i in range(_item_pool.size()):
		if _item_pool[i].data == item_data:
			_item_pool.remove_at(i)
			return true
	
	_logger.warning("要删除的物品不存在", {
		"item_data": item_data
	})
	return false

## 获取随机项
## [param should_remove] 是否删除随机项
## [return] 随机项
func get_random_item(should_remove: bool = false) -> Variant:
	if _item_pool.is_empty():
		return null
		
	var total_weight := 0.0
	var weights: Array[float] = []
	
	for item in _item_pool:
		total_weight += item.weight
		weights.append(total_weight)
	
	var random_value := randf() * total_weight
	
	# 二分查找优化
	var left := 0
	var right := weights.size() - 1
	
	while left < right:
		var mid := (left + right) / 2
		if weights[mid] <= random_value:
			left = mid + 1
		else:
			right = mid
			
	var selected_item: Dictionary = _item_pool[left]
	
	if should_remove:
		_item_pool.remove_at(left)
		
	if _item_pool.is_empty():
		pool_emptied.emit()
		
	item_picked.emit(selected_item.data)
	return selected_item.data

## 清空
func clear() -> void:
	_item_pool.clear()

## 获取随机项个数
func get_remaining_count() -> int:
	return _item_pool.size()

## 获取所有随机项
func get_all_items() -> Array[Dictionary]:
	return _item_pool.duplicate()

## 是否为空
func is_empty() -> bool:
	return _item_pool.is_empty()

## 检查物品是否存在
## [return] 是否存在
func has_item(item_data: Variant) -> bool:
	for item in _item_pool:
		if item.data == item_data:
			return true
	return false
