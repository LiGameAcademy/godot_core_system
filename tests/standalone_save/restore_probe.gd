extends Node

var marker: String = ""

func load_data(data: Dictionary) -> void:
	marker = data.get("marker", "")
