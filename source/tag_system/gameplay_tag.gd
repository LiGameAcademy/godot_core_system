@tool
extends RefCounted
class_name CoreGameplayTag

## 核心系统标签对象（运行时）
## 用于标签的层级结构管理和运行时操作
## 注意：与godot_ability_system的GameplayTag（Resource）区分

## 标签名称
var name: String

## 父标签
var parent: CoreGameplayTag

## 子标签
var children: Array[CoreGameplayTag] = []

static func create(tag_name: String) -> CoreGameplayTag:
	var tag := CoreGameplayTag.new()
	tag.name = tag_name
	return tag

## 添加子标签
func add_child(child: CoreGameplayTag) -> void:
	if not child in children:
		children.append(child)
		child.parent = self

## 移除子标签
func remove_child(child: CoreGameplayTag) -> void:
	if child in children:
		children.erase(child)
		child.parent = null

## 获取完整路径
func get_full_path() -> String:
	if parent:
		return parent.get_full_path() + "." + name
	return name

## 获取所有子标签（递归）
func get_all_children() -> Array[CoreGameplayTag]:
	var result: Array[CoreGameplayTag] = []
	for child in children:
		result.append(child)
		result.append_array(child.get_all_children())
	return result

## 检查是否匹配目标标签
## exact: 是否精确匹配。如果为false，则会检查层级关系
func matches(other: CoreGameplayTag, exact: bool = true) -> bool:
	if exact:
		return get_full_path() == other.get_full_path()
	
	# 检查是否是目标标签的父标签
	var current := other
	while current:
		if current == self:
			return true
		current = current.parent
	
	# 检查是否是目标标签的子标签
	current = self
	while current:
		if current == other:
			return true
		current = current.parent
	
	return false
