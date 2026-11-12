class_name SetupView
extends Control
## 开工设置：选择武器类别与材料（材料库存实时显示，不符订单会警告）

signal confirmed(wtype: String, material: String)
signal cancelled()

var order: Dictionary
var wtype: String
var chosen_material: String
var _type_buttons: Array = []
var _mat_buttons: Array = []
var _warn: Label

func _init(ord: Dictionary) -> void:
	order = ord
	wtype = ord.weapon_type
	chosen_material = ord.material

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var v := UI.vbox(14)
	margin.add_child(v)
	v.add_child(UI.label("开工设置 — 订单来自 %s" % order.soldier_name, 24))
	var need := UI.hbox(10)
	need.add_child(UI.chip("需求：%s" % Game.TYPE_NAME[order.weapon_type], Color("8a5a2b")))
	need.add_child(UI.chip("材料：%s" % Game.MATERIAL_NAME[order.material], Game.MATERIAL_DARK[order.material]))
	need.add_child(UI.chip("附件：%s（装配时选择）" % Game.ATTACH_NAME[order.attachment],
		Color("4f8ed9") if order.attachment == Game.A_DUR else Color("d9534f")))
	v.add_child(need)

	v.add_child(UI.label("① 选择武器类别", 18))
	var type_row := UI.hbox(12)
	v.add_child(type_row)
	for t in Game.WEAPON_TYPES:
		var b := UI.button(Game.TYPE_NAME[t], 18, 140, 52)
		b.pressed.connect(_set_type.bind(t))
		_type_buttons.append({"button": b, "type": t})
		type_row.add_child(b)

	v.add_child(UI.label("② 选择材料（每件消耗 1 份，每天每种 3 份）", 18))
	var mat_row := UI.hbox(12)
	v.add_child(mat_row)
	for m in Game.MATERIALS:
		var b := UI.button("%s（剩余 %d）" % [Game.MATERIAL_NAME[m], Game.materials[m]], 17, 170, 52)
		b.pressed.connect(_set_material.bind(m))
		_mat_buttons.append({"button": b, "mat": m})
		mat_row.add_child(b)

	_warn = UI.label("", 17, Color("b3402e"))
	v.add_child(_warn)
	v.add_child(UI.vspacer())

	var btn_row := UI.hbox(14)
	v.add_child(btn_row)
	var cancel := UI.button("取消（返回订单）", 17, 200, 48)
	cancel.pressed.connect(func(): cancelled.emit())
	btn_row.add_child(cancel)
	btn_row.add_child(UI.spacer())
	var ok := UI.button("开始浇铸 →", 18, 220, 48)
	ok.pressed.connect(_confirm)
	btn_row.add_child(ok)
	_refresh()

func _set_type(t: String) -> void:
	wtype = t
	_refresh()

func _set_material(m: String) -> void:
	if Game.materials.get(m, 0) > 0:
		chosen_material = m
	_refresh()

func _confirm() -> void:
	if Game.materials.get(chosen_material, 0) <= 0:
		return
	confirmed.emit(wtype, chosen_material)

func _refresh() -> void:
	for item in _type_buttons:
		var b: Button = item.button
		b.text = Game.TYPE_NAME[item.type] + ("  ✓" if item.type == wtype else "")
		if item.type != order.weapon_type:
			b.text += "（订单不符）"
	for item in _mat_buttons:
		var b: Button = item.button
		var stock: int = Game.materials[item.mat]
		b.text = "%s（剩余 %d）%s" % [Game.MATERIAL_NAME[item.mat], stock,
			"  ✓" if item.mat == chosen_material else ""]
		b.disabled = stock <= 0
		if item.mat != order.material:
			b.text += " ⚠不符"
	var warns: Array[String] = []
	if wtype != order.weapon_type:
		warns.append("⚠ 类别不符订单，成品有效质量将减半！")
	if chosen_material != order.material:
		warns.append("⚠ 材料不符订单，成品有效质量将减半！")
	if Game.materials.get(chosen_material, 0) <= 0:
		warns.append("✖ 该材料已用完，无法开工。")
	_warn.text = "\n".join(warns)
