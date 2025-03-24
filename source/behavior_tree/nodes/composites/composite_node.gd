extends BTNode
class_name BTCompositeNode

## 组合节点基类

## 子节点列表
@export var children: Array[BTNode] = []
## 当前执行的子节点索引
var current_child_index: int = 0

func initialize(tree_ref: BTTree, parent_node: BTNode = null) -> void:
	super(tree_ref, parent_node)
	for child in children:
		child.initialize(tree, self)

func reset() -> void:
	super()
	current_child_index = 0
	for child in children:
		child.reset()

## 添加子节点
func add_child(child: BTNode) -> void:
	children.append(child)
	if tree:
		child.initialize(tree, self)

## 移除子节点
func remove_child(child: BTNode) -> void:
	var index = children.find(child)
	if index != -1:
		children.remove_at(index)
		child.initialize(null, null)
