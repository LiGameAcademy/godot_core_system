extends Node2D

const SaveManager = CoreSystem.SaveManager

@onready var player: Node = $Player
@onready var status_label: Label = %StatusLabel
@onready var save_list: ItemList = %SaveList
@onready var line_edit_name: LineEdit = %LineEditName
@onready var line_edit_level: LineEdit = %LineEditLevel
@onready var line_edit_exp: LineEdit = %LineEditExp
@onready var label: Label = %Label

@onready var _save_manager : CoreSystem.SaveManager = CoreSystem.save_manager
var _logger : CoreSystem.Logger = CoreSystem.logger

func _ready():
	# 连接信号
	_save_manager.save_created.connect(_on_save_created)
	_save_manager.save_loaded.connect(_on_save_loaded)
	_save_manager.save_deleted.connect(_on_save_deleted)
	_save_manager.auto_save_created.connect(_on_auto_save_created)

	line_edit_name.text_changed.connect(_on_name_text_changed)
	line_edit_level.text_changed.connect(_on_level_text_changed)
	line_edit_exp.text_changed.connect(_on_exp_text_changed)
	
	# 更新存档列表
	_update_save_list()
	_update_player_display()
	label.text = "自动存档：{0}".format(["是" if _save_manager.auto_save_enabled else "否"])

## 更新存档列表
func _update_save_list():
	save_list.clear()
	var saves : Array[Dictionary] = await _save_manager.get_save_list()
	for save in saves:
		save_list.add_item(save.save_id)

## 保存游戏
func save_game() -> void:
	var timestamp = Time.get_unix_time_from_system()
	var save_name = "save_%d" % timestamp
	
	status_label.text = "正在创建存档..."
	var success = await _save_manager.create_save(save_name)
	status_label.text = "存档创建" + ("成功" if success else "失败")
	if success:
		_update_save_list()

func load_game() -> void:
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		status_label.text = "请先选择一个存档"
		return
	
	var save_name = save_list.get_item_text(selected_items[0])
	status_label.text = "正在加载存档..."
	var success = await _save_manager.load_save(save_name)
	status_label.text = "存档加载" + ("成功" if success else "失败")
	if success:
		_update_player_display()

func delete() -> void:
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		status_label.text = "请先选择一个存档"
		return
	
	var save_name = save_list.get_item_text(selected_items[0])
	status_label.text = "正在删除存档..."
	var success = _save_manager.delete_save(save_name)
	status_label.text = "存档删除" + ("成功" if success else "失败")
	if success:
		_update_save_list()

func _update_player_display() -> void:
	line_edit_name.text = player.player_name
	line_edit_level.text = str(player.player_level)
	line_edit_exp.text = str(player.player_exp)

func _on_name_text_changed(new_text: String) -> void:
	player.player_name = line_edit_name.text

func _on_level_text_changed(new_text: String) -> void:
	player.player_level = int(line_edit_level.text)

func _on_exp_text_changed(new_text: String) -> void:
	player.player_exp = int(line_edit_exp.text)

## 创建新存档按钮回调
func _on_create_button_pressed() -> void:
	save_game()

## 加载存档按钮回调
func _on_load_button_pressed():
	load_game()

## 删除存档按钮回调
func _on_delete_button_pressed():
	delete()

## 存档创建回调
func _on_save_created(save_name: String):
	_logger.debug("存档已创建：" + save_name)

## 存档加载回调
func _on_save_loaded(save_name: String):
	_logger.debug("存档已加载：" + save_name)
	_update_player_display()

## 存档删除回调
func _on_save_deleted(save_name: String):
	_logger.debug("存档已删除：%s" % save_name)

## 自动存档创建回调
func _on_auto_save_created():
	_logger.debug("自动存档已创建")
	_update_save_list()
