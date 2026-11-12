class_name InterludeScreen
extends Control
## 日间隔夜：展示当天战果，花费金币升级锻打/装配工具（每项限一次）

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("efe0c4")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 40)
	add_child(margin)
	var v := UI.vbox(16)
	margin.add_child(v)

	var r: Dictionary = Game.pending_battle
	v.add_child(UI.label("第 %d 天 · 战报与休整" % r.day, 28))
	var result_panel := UI.panel()
	v.add_child(result_panel)
	var rv := UI.vbox(10)
	result_panel.add_child(rv)
	rv.add_child(UI.label("当天结果：%s" % ("胜利 ✓" if r.victory else "失败 ✖（次日可继续）"),
		20, Color("2e6b2e") if r.victory else Color("b3402e")))
	rv.add_child(UI.info_row("清空怪物组", "%d / 3" % r.groups_cleared))
	rv.add_child(UI.info_row("当天制作平均质量", "%.1f 分" % r.avg_quality))
	rv.add_child(UI.info_row("当天战利品", "%d 金币" % r.gold_earned, Color("b8860b")))
	rv.add_child(UI.info_row("当前金币", "%d 金币" % Game.gold, Color("b8860b")))
	rv.add_child(UI.label("次日士兵将恢复全部生命。", 16, Color("7a5a3a")))

	v.add_child(UI.label("工具升级（各花 20 金币，每项限一次；升级后扩大对应工序的满分判定范围）", 18))
	var up_row := UI.hbox(16)
	v.add_child(up_row)
	up_row.add_child(_upgrade_card("锻打工具", "forge",
		"满分命中圈：16px → 26px", Game.forge_upgraded))
	up_row.add_child(_upgrade_card("装配工具", "assemble",
		"满分对准距离：14px → 24px", Game.assemble_upgraded))

	v.add_child(UI.vspacer())
	var row := UI.hbox()
	v.add_child(row)
	row.add_child(UI.spacer())
	var btn := UI.button("开始第 %d 天 →" % (Game.day + 1), 19, 260, 52)
	btn.pressed.connect(_continue)
	row.add_child(btn)

func _upgrade_card(title: String, key: String, desc: String, upgraded: bool) -> PanelContainer:
	var p := UI.panel(Color("fff8ec"), Color("8a5a2b"), 12, 2, 14)
	p.custom_minimum_size = Vector2(360, 200)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label(title, 20))
	v.add_child(UI.label(desc, 16, Color("5b4632")))
	v.add_child(UI.label("状态：%s" % ("已升级 ✓" if upgraded else "未升级"), 16,
		Color("2e6b2e") if upgraded else Color("7a5a3a")))
	v.add_child(UI.vspacer())
	if upgraded:
		v.add_child(UI.label("已达上限", 16, Color("7a5a3a")))
	else:
		var b := UI.button("升级（20 金币）", 17, 260, 46)
		if Game.gold < Game.TOOL_UPGRADE_COST:
			b.disabled = true
			b.text = "金币不足（需 20）"
		b.pressed.connect(_do_upgrade.bind(key, b))
		v.add_child(b)
	return p

func _do_upgrade(key: String, b: Button) -> void:
	if Game.gold < Game.TOOL_UPGRADE_COST:
		return
	Game.gold -= Game.TOOL_UPGRADE_COST
	if key == "forge":
		Game.forge_upgraded = true
	else:
		Game.assemble_upgraded = true
	# 重建本界面以刷新金币与升级状态（不能 reload 主场景，否则会回到主菜单）
	var root: Node = get_parent()
	for c in root.get_children():
		c.queue_free()
	root.add_child(InterludeScreen.new())

func _continue() -> void:
	Game.begin_next_day()
	get_parent().goto_workshop()
