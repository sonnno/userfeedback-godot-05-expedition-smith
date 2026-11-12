class_name HelpOverlay
extends PanelContainer
## 游戏内操作提示 / 玩法说明

signal closed

func _ready() -> void:
	custom_minimum_size = Vector2(860, 600)
	add_theme_stylebox_override("panel", UI.stylebox(Color("fbf1de"), Color("8a5a2b"), 16, 3, 20))
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	var v := UI.vbox(12)
	margin.add_child(v)
	v.add_child(UI.label("操作提示与玩法说明", 26))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var inner := UI.vbox(10)
	scroll.add_child(inner)

	_add_section(inner, "整体流程", [
		"• 一局共三天。每天三名士兵各下一张订单，为三人各锻造一件武器后开始出征。",
		"• 每天提供铜、铁、钢各 3 份，每件武器消耗 1 份材料。",
		"• 第三天战斗结束后显示三天总结。",
	])
	_add_section(inner, "鼠标 / 键盘操作", [
		"• 浇铸：按住鼠标左键（或空格）注入熔液，松开停止并结算。",
		"• 锻打：鼠标依次点击 5 个发光目标点。",
		"• 装配：鼠标拖动手柄到插槽松开；也可用方向键移动、回车释放。",
		"• I 键：随时查看今日订单；Esc：暂停 / 关闭弹层；按钮也可用 Tab + 回车操作。",
	])
	_add_section(inner, "三道工序与质量", [
		"• 浇铸：填充停在 90% 附近（85%~95%）满分，超过 100% 满溢会大幅降质。",
		"• 锻打：点击越靠近目标圆心得分越高，每个目标点只记分一次。",
		"• 装配：手柄释放位置越靠近插槽得分越高。",
		"• 三道工序各 0~100 分，总质量为三者平均分。",
	])
	_add_section(inner, "订单匹配", [
		"• 类别（剑/斧）或材料不符订单：有效质量减半。",
		"• 附件选错：没有附件加成（攻击附件 +3 攻击，耐久附件 +10 耐久）。",
		"• 每张订单只能交付一次。",
	])
	_add_section(inner, "出征战斗", [
		"• 侧视场景自动推进，依次与三组怪物交战；双方优先攻击最前方存活单位。",
		"• 士兵每秒攻击一次，同一时刻的伤害同时结算。",
		"• 武器攻击 = 材料基础攻击 ×（0.5 + 有效质量/100），铜/铁/钢基础为 10/14/18。",
		"• 耐久 = 10 + 有效质量/5（向下取整），每次攻击耗 1 点；耗尽后改为 2 点徒手攻击。",
		"• 士兵全灭则当天失败，同归于尽也算失败；清空三组为当天胜利。",
		"• 每击败一组得 10 金币，当天全胜额外得 10 金币。次日士兵恢复全部生命。",
	])
	_add_section(inner, "升级与暂停", [
		"• 次日休整时可各花 20 金币升级锻打或装配工具，每项限一次，扩大满分判定范围。",
		"• 暂停会冻结制作与战斗；重新开始会清空订单、材料、升级和全部成绩。",
	])
	var row := UI.hbox()
	v.add_child(row)
	row.add_child(UI.spacer())
	var b := UI.button("知道了", 18, 200, 46)
	b.pressed.connect(func(): closed.emit())
	row.add_child(b)
	row.add_child(UI.spacer())

func _add_section(parent: Node, title: String, lines: Array) -> void:
	parent.add_child(UI.label(title, 19, Color("8a5a2b")))
	for line in lines:
		parent.add_child(UI.label(line, 15, Color("3b2a20")))
