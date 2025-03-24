extends BTConditionNode
class_name BTBlackboardConditionNode

## 黑板条件节点：使用表达式检查黑板中的值
## 表达式示例：
## - "health > 50"
## - "ammo <= 0"
## - "state == 'idle'"
## - "position.x < target.x"
## - "items.size() >= 5"

## 条件表达式
@export_multiline var expression: String = ""

var _expression: Expression
var _identifiers: Array[String] = []

func _init() -> void:
	_expression = Expression.new()

func initialize(tree_ref: BTTree, parent_node: BTNode = null) -> void:
	super(tree_ref, parent_node)
	_parse_expression()

## 解析表达式
func _parse_expression() -> void:
	if expression.is_empty():
		push_error("Expression is empty")
		return
	
	# 提取标识符
	_identifiers.clear()
	var regex = RegEx.new()
	regex.compile("\\b[a-zA-Z_][a-zA-Z0-9_]*(?:\\.[a-zA-Z_][a-zA-Z0-9_]*)*\\b")
	for result in regex.search_all(expression):
		var id = result.get_string()
		if not _identifiers.has(id):
			_identifiers.append(id)
	
	# 创建表达式
	var error = _expression.parse(expression, _identifiers)
	if error != OK:
		push_error("Failed to parse expression: %s\nError: %s" % [expression, _expression.get_error_text()])

func check_condition() -> bool:
	if not tree or _expression.get_error_text():
		return false
	
	# 准备变量值
	var values = []
	for id in _identifiers:
		values.append(tree.get_blackboard_value(id))
	
	# 执行表达式
	var result = _expression.execute(values, tree)
	if _expression.has_execute_failed():
		push_error("Failed to execute expression: %s\nError: %s" % [expression, _expression.get_error_text()])
		return false
	
	return bool(result)
