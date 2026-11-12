class_name MainMenuScreen
extends Control
## 主菜单：新游戏、操作提示、退出

var help: HelpOverlay
var help_dim: ColorRect
var title_icon: WeaponIcon

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("f3e2c6")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 地面
	var floor := ColorRect.new()
	floor.color = Color("d9b98c")
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor.anchor_top = 0.75
	add_child(floor)

	var v := UI.vbox(18)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)

	title_icon = WeaponIcon.new()
	title_icon.setup(Game.T_AXE, Game.M_STEEL, Game.A_ATK, 120)
	v.add_child(title_icon)
	var title := UI.label("远征铁匠", 46, Color("6b4a30"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UI.label("为三名士兵锻造武器，观看队伍出征远征", 19, Color("8a5a2b"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UI.label(" "))
	for data in [
		["新 游 戏", _start_new],
		["操作提示", _show_help],
		["退出游戏", _quit],
	]:
		var b := UI.button(data[0], 22, 320, 58)
		b.pressed.connect(data[1])
		var row := UI.hbox()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(b)
		v.add_child(row)
	var tip := UI.label("鼠标 + 键盘均可操作 · 游戏中按 Esc 暂停 · 按 I 查看订单", 15, Color("7a5a3a"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tip)

	help_dim = ColorRect.new()
	help_dim.color = Color(0, 0, 0, 0.4)
	help_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_dim.visible = false
	add_child(help_dim)
	help = HelpOverlay.new()
	help.visible = false
	add_child(help)
	help.closed.connect(func():
		help.visible = false
		help_dim.visible = false)

func _show_help() -> void:
	help.visible = true
	help_dim.visible = true
	help.position = (size - help.custom_minimum_size) * 0.5

func _start_new() -> void:
	Game.reset()
	get_parent().goto_workshop()

func _quit() -> void:
	get_tree().quit()
