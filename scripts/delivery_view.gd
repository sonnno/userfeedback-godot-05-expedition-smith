class_name DeliveryView
extends Control
## 交付展示：三道工序得分、成品属性、需求匹配情况（每张订单仅交付一次）

signal confirmed()

var weapon: Dictionary
var order: Dictionary

func _init(w: Dictionary) -> void:
	weapon = w
	order = Game.orders[w.order_index]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	add_child(margin)
	var v := UI.vbox(12)
	margin.add_child(v)
	v.add_child(UI.label("成品交付 — %s 的订单" % order.soldier_name, 24))

	var top := UI.hbox(20)
	v.add_child(top)
	# 成品外观
	var icon_wrap := UI.panel(Color("fff6e6"), Color("8a5a2b"), 14, 2, 14)
	top.add_child(icon_wrap)
	var icon := WeaponIcon.new()
	icon.setup(weapon.weapon_type, weapon.material, weapon.attachment, 130)
	icon_wrap.add_child(icon)
	# 工序得分
	var score_panel := UI.panel()
	top.add_child(score_panel)
	var sv := UI.vbox(8)
	score_panel.add_child(sv)
	sv.add_child(UI.label("工序得分（0~100）", 18))
	sv.add_child(UI.info_row("浇铸", "%d 分" % int(weapon.cast_score)))
	sv.add_child(UI.info_row("锻打", "%d 分" % int(weapon.forge_score)))
	sv.add_child(UI.info_row("装配", "%d 分" % int(weapon.assemble_score)))
	sv.add_child(UI.info_row("总质量（平均）", "%.1f 分" % weapon.quality, Color("2e6b2e")))
	sv.add_child(UI.info_row("有效质量", "%.1f 分" % weapon.effective_quality,
		Color("b3402e") if weapon.effective_quality != weapon.quality else Color("2e6b2e")))
	# 属性与匹配
	var attr_panel := UI.panel()
	top.add_child(attr_panel)
	var av := UI.vbox(8)
	attr_panel.add_child(av)
	av.add_child(UI.label("成品属性与需求匹配", 18))
	av.add_child(UI.info_row("武器类别", "%s（%s）" % [Game.TYPE_NAME[weapon.weapon_type],
		"匹配" if weapon.type_match else "不符·质量减半"],
		Color("2e6b2e") if weapon.type_match else Color("b3402e")))
	av.add_child(UI.info_row("材料", "%s（%s）" % [Game.MATERIAL_NAME[weapon.material],
		"匹配" if weapon.material_match else "不符·质量减半"],
		Color("2e6b2e") if weapon.material_match else Color("b3402e")))
	av.add_child(UI.info_row("附件", "%s（%s）" % [Game.ATTACH_NAME[weapon.attachment],
		"匹配·有加成" if weapon.attachment_match else "选错·无加成"],
		Color("2e6b2e") if weapon.attachment_match else Color("b3402e")))
	av.add_child(UI.info_row("实际攻击", "%.1f" % weapon.attack, Color("b3402e")))
	av.add_child(UI.info_row("武器耐久", "%d 点" % weapon.durability, Color("4f8ed9")))

	var note := ""
	if not weapon.type_match or not weapon.material_match:
		note = "类别或材料不符订单：有效质量已减半，战斗表现会打折扣。"
	elif not weapon.attachment_match:
		note = "附件选择错误：本件武器没有附件加成。"
	else:
		note = "完全符合订单需求，士兵将发挥这件武器的全部性能！"
	v.add_child(UI.label(note, 17, Color("8a5a2b")))
	v.add_child(UI.vspacer())
	var row := UI.hbox()
	v.add_child(row)
	row.add_child(UI.spacer())
	var btn := UI.button("确认交付（本订单仅此一次）", 18, 300, 50)
	btn.pressed.connect(func(): confirmed.emit())
	row.add_child(btn)
