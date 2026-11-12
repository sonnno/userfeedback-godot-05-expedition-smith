class_name PauseOverlay
extends CanvasLayer
## 暂停菜单：继续、操作提示、重新开始、返回主菜单（暂停冻结制作与战斗）

signal resume_pressed
signal restart_pressed
signal menu_pressed

var dim: ColorRect
var panel: PanelContainer
var help: HelpOverlay
var help_dim: ColorRect

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	panel = UI.panel(Color("fbf1de"), Color("8a5a2b"), 16, 3, 22)
	panel.custom_minimum_size = Vector2(420, 400)
	add_child(panel)
	var v := UI.vbox(16)
	panel.add_child(v)
	v.add_child(UI.label("游戏暂停", 28))
	v.add_child(UI.label("制作与战斗均已冻结", 16, Color("7a5a3a")))
	v.add_child(UI.vspacer())
	for data in [
		["继续游戏", _on_resume],
		["操作提示", _show_help],
		["重新开始（清空全部进度）", _on_restart],
		["返回主菜单", _on_menu],
	]:
		var b := UI.button(data[0], 18, 340, 50)
		b.pressed.connect(data[1])
		v.add_child(b)
	v.add_child(UI.vspacer())
	# 帮助层（默认隐藏）
	help_dim = ColorRect.new()
	help_dim.color = Color(0, 0, 0, 0.35)
	help_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_dim.visible = false
	add_child(help_dim)
	help = HelpOverlay.new()
	help.visible = false
	add_child(help)
	help.closed.connect(_hide_help)
	_center_panel()
	get_tree().root.size_changed.connect(_center_panel)

func _center_panel() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	panel.position = (vp_size - panel.custom_minimum_size) * 0.5
	help.position = (vp_size - help.custom_minimum_size) * 0.5

func _show_help() -> void:
	help.visible = true
	help_dim.visible = true
	_center_panel()

func _hide_help() -> void:
	help.visible = false
	help_dim.visible = false

func _on_resume() -> void:
	resume_pressed.emit()

func _on_restart() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "确认重新开始？"
	dlg.dialog_text = "将清空订单、材料变化、工具升级和全部成绩，立即开始新的一局。"
	dlg.ok_button_text = "重新开始"
	dlg.cancel_button_text = "取消"
	add_child(dlg)
	dlg.confirmed.connect(func():
		dlg.queue_free()
		restart_pressed.emit())
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _on_menu() -> void:
	menu_pressed.emit()
