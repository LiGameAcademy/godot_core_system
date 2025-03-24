extends BTCompositeNode
class_name BTParallelNode

## 并行节点：同时执行所有子节点

## 并行策略
enum Policy {
	REQUIRE_ALL,  # 需要所有子节点成功才成功
	REQUIRE_ONE   # 只需要一个子节点成功就成功
}

## 成功策略
@export var success_policy: Policy = Policy.REQUIRE_ALL
## 失败策略
@export var failure_policy: Policy = Policy.REQUIRE_ONE

## 子节点状态
var child_status: Array[Status] = []

func initialize(tree_ref: BTTree, parent_node: BTNode = null) -> void:
	super(tree_ref, parent_node)
	child_status.resize(children.size())
	child_status.fill(Status.INVALID)

func reset() -> void:
	super()
	child_status.resize(children.size())
	child_status.fill(Status.INVALID)

func _update() -> Status:
	var success_count: int = 0
	var failure_count: int = 0
	var running_count: int = 0
	
	for i in children.size():
		if child_status[i] == Status.INVALID:
			child_status[i] = children[i].tick()
		
		match child_status[i]:
			Status.SUCCESS:
				success_count += 1
				if success_policy == Policy.REQUIRE_ONE:
					return Status.SUCCESS
			Status.FAILURE:
				failure_count += 1
				if failure_policy == Policy.REQUIRE_ONE:
					return Status.FAILURE
			Status.RUNNING:
				running_count += 1
	
	if success_policy == Policy.REQUIRE_ALL and success_count == children.size():
		return Status.SUCCESS
	
	if failure_policy == Policy.REQUIRE_ALL and failure_count == children.size():
		return Status.FAILURE
	
	if running_count > 0:
		return Status.RUNNING
	
	return Status.FAILURE
