extends BTNode
class_name BTDecoratorNode

## 装饰节点基类

## 子节点
@export var child: BTNode

func initialize(tree_ref: BTTree, parent_node: BTNode = null) -> void:
	super(tree_ref, parent_node)
	if child:
		child.initialize(tree, self)

func reset() -> void:
	super()
	if child:
		child.reset()
