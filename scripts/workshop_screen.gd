class_name WorkshopScreen
extends Control
## 工坊主界面：订单列表 + 三道工序 + 交付 + 出征入口

var state := "idle"
var order_column: VBoxContainer
var center_host: Control
var center_wrap: PanelContainer
var top_material_box: HBoxContainer
var expedition_btn: Button
var hint_label: Label
var order_overlay: PanelContainer
var overlay_dim: ColorRect

# 当前制作中的武器数据
var cur_order := -1
var cur_type := ""
var cur_mat := ""
var cur_attach := Game.A_NONE
var cast_score := 0.0
var forge_score := 0.0
var assemble_score := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_topbar()
	_build_body()
	_build_order_overlay()
	_show_idle()
	_refresh_orders()
	_refresh_topbar()
	set_process_unhandled_input(true)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("f3e2c6")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 墙面与地面的分界
	var floor := ColorRect.new()
	floor.color = Color("d9b98c")
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor.anchor_top = 0.82
	add_child(floor)

func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.stylebox(Color("6b4a30"), Color("3b2a20"), 0, 0, 10))
	var h := UI.hbox(14)
	bar.add_child(h)
	add_child(bar)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 64
	h.add_child(UI.label("远征铁匠 · 工坊", 22, Color("ffe9c4")))
	h.add_child(UI.chip("第 %d / 3 天" % Game.day, Color("8a5a2b"), Color.WHITE, 16))
	h.add_child(UI.chip("金币 %d" % Game.gold, Color("c9932b"), Color.WHITE, 16))
	h.add_child(UI.spacer())
	top_material_box = UI.hbox(8)
	h.add_child(top_material_box)
	var order_btn := UI.button("订单 (I)", 15, 120, 38)
	order_btn.pressed.connect(_toggle_order_overlay)
	h.add_child(order_btn)

func _build_body() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 76)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	add_child(margin)
	var h := UI.hbox(14)
	margin.add_child(h)

	# 左侧订单栏
	var left := UI.panel(Color("fbf1de"), Color("8a5a2b"), 14, 2, 10)
	left.custom_minimum_size.x = 300
	h.add_child(left)
	var lv := UI.vbox(10)
	left.add_child(lv)
	lv.add_child(UI.label("今日订单（3 名士兵）", 19))
	order_column = UI.vbox(10)
	lv.add_child(order_column)
	lv.add_child(UI.vspacer())
	expedition_btn = UI.button("▶ 三人装备完毕，开始出征", 17, 260, 54)
	expedition_btn.pressed.connect(_start_expedition)
	lv.add_child(expedition_btn)

	# 中间工序区
	center_wrap = UI.panel(Color("fff8ec"), Color("8a5a2b"), 14, 2, 8)
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(center_wrap)
	center_host = Control.new()
	center_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_wrap.add_child(center_host)

func _build_order_overlay() -> void:
	overlay_dim = ColorRect.new()
	overlay_dim.color = Color(0, 0, 0, 0.45)
	overlay_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_dim.visible = false
	overlay_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_toggle_order_overlay())
	add_child(overlay_dim)
	order_overlay = UI.panel(Color("fbf1de"), Color("8a5a2b"), 16, 3, 18)
	order_overlay.custom_minimum_size = Vector2(720, 470)
	order_overlay.size = Vector2(720, 470)
	order_overlay.visible = false
	add_child(order_overlay)
	var v := UI.vbox(12)
	order_overlay.add_child(v)
	v.add_child(UI.label("今日订单总览（按 I 或点击空白处关闭）", 22))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var list := UI.vbox(10)
	scroll.add_child(list)
	for o in Game.orders:
		list.add_child(_order_detail_card(o))
	var close := UI.button("关闭 (I)", 16, 180, 42)
	close.pressed.connect(_toggle_order_overlay)
	v.add_child(close)

func _order_detail_card(o: Dictionary) -> PanelContainer:
	var p := UI.panel(Color("fff8ec"), Color("c9a378"), 10, 1, 10)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.label("%s 的订单%s" % [o.soldier_name, "（已交付）" if o.delivered else ""], 18,
		Color("2e6b2e") if o.delivered else Color("3b2a20")))
	var row := UI.hbox(8)
	v.add_child(row)
	row.add_child(UI.chip(Game.TYPE_NAME[o.weapon_type], Color("8a5a2b")))
	row.add_child(UI.chip(Game.MATERIAL_NAME[o.material], Game.MATERIAL_DARK[o.material]))
	row.add_child(UI.chip(Game.ATTACH_NAME[o.attachment],
		Color("4f8ed9") if o.attachment == Game.A_DUR else Color("d9534f")))
	return p

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			_toggle_order_overlay()
		elif event.keycode == KEY_ESCAPE and order_overlay.visible:
			_toggle_order_overlay()

# ---------------- 状态切换 ----------------
func _clear_center() -> void:
	for c in center_host.get_children():
		c.queue_free()

func _show_idle() -> void:
	state = "idle"
	_clear_center()
	var v := UI.vbox(16)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center_host.add_child(v)
	var l := UI.label("选择左侧一张未交付订单开始锻造", 24, Color("8a5a2b"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var l2 := UI.label("流程：开工设置 → 浇铸 → 锻打 → 装配 → 交付\n制作中可随时按 I 查看订单，按 Esc 暂停", 18, Color("7a5a3a"))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l2)
	_refresh_orders()

func _open_order(idx: int) -> void:
	if state != "idle" or Game.orders[idx].delivered:
		return
	cur_order = idx
	cur_type = ""
	cur_mat = ""
	cur_attach = Game.A_NONE
	cast_score = 0.0
	forge_score = 0.0
	assemble_score = 0.0
	state = "setup"
	_clear_center()
	var sv := SetupView.new(Game.orders[idx])
	sv.confirmed.connect(_on_setup_confirmed)
	sv.cancelled.connect(_show_idle)
	center_host.add_child(sv)

func _on_setup_confirmed(wtype: String, mat: String) -> void:
	cur_type = wtype
	cur_mat = mat
	# 材料在浇铸开始时锁定消耗
	if not Game.consume_material(mat):
		_show_idle()
		return
	_refresh_topbar()
	_start_casting()

func _start_casting() -> void:
	state = "cast"
	_clear_center()
	var g := CastingGame.new()
	g.finished.connect(_on_casting_done)
	center_host.add_child(g)

func _on_casting_done(score: float) -> void:
	cast_score = score
	_start_forging()

func _start_forging() -> void:
	state = "forge"
	_clear_center()
	var g := ForgingGame.new()
	g.finished.connect(_on_forging_done)
	center_host.add_child(g)

func _on_forging_done(score: float) -> void:
	forge_score = score
	_start_assembly()

func _start_assembly() -> void:
	state = "assemble"
	_clear_center()
	var g := AssemblyGame.new()
	g.finished.connect(_on_assembly_done)
	center_host.add_child(g)

func _on_assembly_done(score: float, attach: String) -> void:
	assemble_score = score
	cur_attach = attach
	var weapon := Game.build_weapon(cur_order, cur_type, cur_mat, cur_attach,
		cast_score, forge_score, assemble_score)
	state = "delivery"
	_clear_center()
	var dv := DeliveryView.new(weapon)
	dv.confirmed.connect(_on_delivery_confirmed.bind(weapon))
	center_host.add_child(dv)

func _on_delivery_confirmed(weapon: Dictionary) -> void:
	Game.deliver_weapon(weapon)
	cur_order = -1
	_refresh_topbar()
	_show_idle()

# ---------------- 列表 / 顶栏刷新 ----------------
func _refresh_orders() -> void:
	for c in order_column.get_children():
		c.queue_free()
	for i in Game.orders.size():
		var o: Dictionary = Game.orders[i]
		var card := UI.panel(
			Color("e8f5e4") if o.delivered else Color("fff8ec"),
			Color("6f9e5f") if o.delivered else Color("c9a378"), 10, 1, 8)
		order_column.add_child(card)
		var v := UI.vbox(6)
		card.add_child(v)
		v.add_child(UI.label(o.soldier_name, 17,
			Color("2e6b2e") if o.delivered else Color("3b2a20")))
		var row := UI.hbox(6)
		v.add_child(row)
		row.add_child(UI.chip(Game.TYPE_NAME[o.weapon_type], Color("8a5a2b"), Color.WHITE, 13))
		row.add_child(UI.chip(Game.MATERIAL_NAME[o.material], Game.MATERIAL_DARK[o.material], Color.WHITE, 13))
		row.add_child(UI.chip(Game.ATTACH_NAME[o.attachment].replace("附件", ""),
			Color("4f8ed9") if o.attachment == Game.A_DUR else Color("d9534f"), Color.WHITE, 13))
		if o.delivered:
			v.add_child(UI.label("✓ 已交付", 14, Color("2e6b2e")))
		else:
			var b := UI.button("开始锻造", 15, 200, 38)
			var idx := i
			b.pressed.connect(func(): _open_order(idx))
			v.add_child(b)
	expedition_btn.disabled = not Game.all_delivered()
	expedition_btn.text = "▶ 开始出征" if Game.all_delivered() else "需先交付全部 3 件武器"

func _refresh_topbar() -> void:
	for c in top_material_box.get_children():
		c.queue_free()
	for m in Game.MATERIALS:
		top_material_box.add_child(
			UI.chip("%s ×%d" % [Game.MATERIAL_NAME[m], Game.materials[m]],
				Game.MATERIAL_DARK[m], Color.WHITE, 15))

func _toggle_order_overlay() -> void:
	order_overlay.visible = not order_overlay.visible
	overlay_dim.visible = order_overlay.visible
	if order_overlay.visible:
		order_overlay.position = (size - order_overlay.size) * 0.5

func _start_expedition() -> void:
	if not Game.all_delivered():
		return
	get_parent().goto_battle()
