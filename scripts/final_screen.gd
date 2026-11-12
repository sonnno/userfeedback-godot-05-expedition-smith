class_name FinalScreen
extends Control
## 第三天结束：三天制作质量、胜负与总战利品总结

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("efe0c4")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 46)
	add_child(margin)
	var v := UI.vbox(14)
	margin.add_child(v)

	v.add_child(UI.label("远征结束 · 三天总结", 30))
	var wins := Game.victories()
	var title_col := Color("2e6b2e") if wins >= 2 else Color("b3402e")
	v.add_child(UI.label("总战绩：%d 胜 / %d 败" % [wins, 3 - wins], 22, title_col))

	var table := UI.panel()
	v.add_child(table)
	var tv := UI.vbox(8)
	table.add_child(tv)
	var header := UI.hbox(10)
	tv.add_child(header)
	for t in ["天数", "平均制作质量", "清空怪物组", "胜负", "当天金币"]:
		var l := UI.label(t, 17, Color("8a5a2b"))
		l.custom_minimum_size.x = 180
		header.add_child(l)
	for r in Game.day_results:
		var row := UI.hbox(10)
		tv.add_child(row)
		var cells := [
			"第 %d 天" % r.day,
			"%.1f 分" % r.avg_quality,
			"%d / 3" % r.groups_cleared,
			"胜利" if r.victory else "失败",
			"+%d 金币" % r.gold_earned,
		]
		var cols := [Color("3b2a20"), Color("3b2a20"), Color("3b2a20"),
			Color("2e6b2e") if r.victory else Color("b3402e"), Color("b8860b")]
		for i in cells.size():
			var l := UI.label(cells[i], 16, cols[i])
			l.custom_minimum_size.x = 180
			row.add_child(l)

	var total_panel := UI.panel(Color("fbf1de"), Color("c9932b"), 12, 2, 14)
	v.add_child(total_panel)
	var ttv := UI.vbox(8)
	total_panel.add_child(ttv)
	ttv.add_child(UI.label("总战利品：%d 金币" % Game.total_gold_earned(), 22, Color("b8860b")))
	ttv.add_child(UI.label("剩余金币：%d（含工具升级花费）" % Game.gold, 18))
	var all_quality := 0.0
	for r in Game.day_results:
		all_quality += r.avg_quality
	var avg3: float = round(all_quality / 3.0 * 10.0) / 10.0
	ttv.add_child(UI.label("三天平均制作质量：%.1f 分" % avg3, 18, Color("2e6b2e")))

	v.add_child(UI.vspacer())
	var row := UI.hbox(16)
	v.add_child(row)
	row.add_child(UI.spacer())
	var again := UI.button("重新开始（清空全部进度）", 18, 300, 50)
	again.pressed.connect(_restart)
	row.add_child(again)
	var menu := UI.button("返回主菜单", 18, 220, 50)
	menu.pressed.connect(func(): get_parent().goto_menu())
	row.add_child(menu)

func _restart() -> void:
	Game.reset()
	get_parent().goto_workshop()
