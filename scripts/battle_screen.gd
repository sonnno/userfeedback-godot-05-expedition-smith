class_name BattleScreen
extends Control
## 出征战斗：侧视推进，依次交战三组怪物；攻击最前方存活单位，同时结算伤害

const GROUND_Y_RATIO := 0.66
const SOLDIER_BASE_X := 130.0
const MONSTER_SPAWN_X := 1080.0
const CONTACT_GAP := 150.0
var march_speed := 130.0
var tick_interval := 1.0

var phase := "march"            # march | fight | group_clear | ended
var soldiers: Array = []
var monsters: Array = []
var group_index := 0
var tick_acc := 0.0
var gold_earned := 0
var floaters: Array = []
var lunge: Dictionary = {}      # 单位 id -> 突进计时
var uid_counter := 0
var ended := false
var result_victory := false

var field: Control
var info_label: Label
var tick_bar: HBar
var log_box: VBoxContainer
var soldier_cards: Array = []
var end_panel: PanelContainer
var _field_w := 1240.0
var _field_h := 470.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_init_soldiers()
	_spawn_group()
	phase = "march"
	info_label.text = "第 1 组怪物出现，队伍推进中……"

func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = Color("cfe3f2")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 顶部信息条
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UI.stylebox(Color("6b4a30"), Color("3b2a20"), 0, 0, 10))
	var h := UI.hbox(14)
	top.add_child(h)
	add_child(top)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 60
	h.add_child(UI.label("第 %d 天 · 出征" % Game.day, 21, Color("ffe9c4")))
	info_label = UI.label("", 17, Color("ffe9c4"))
	h.add_child(info_label)
	h.add_child(UI.spacer())
	tick_bar = HBar.new()
	tick_bar.custom_minimum_size = Vector2(180, 20)
	tick_bar.setup(1.0, 1.0, Color("f0b35e"), false, 14)
	h.add_child(tick_bar)
	var gold_l := UI.label("战利品 +%d 金币" % gold_earned, 17, Color("ffd94a"))
	gold_l.name = "GoldLabel"
	h.add_child(gold_l)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 68)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	add_child(margin)
	var v := UI.vbox(8)
	margin.add_child(v)

	field = BattleField.new()
	field.owner_screen = self
	field.custom_minimum_size = Vector2(0, 470)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(field)
	field.resized.connect(func(): _field_w = field.size.x; _field_h = field.size.y)

	var bottom := UI.hbox(10)
	v.add_child(bottom)
	# 士兵状态卡
	for i in Game.SOLDIER_NAMES.size():
		var card := _make_soldier_card(i)
		soldier_cards.append(card)
		bottom.add_child(card)
	# 战斗日志
	var log_panel := UI.panel(Color("fbf1de"), Color("8a5a2b"), 10, 1, 8)
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(log_panel)
	log_box = UI.vbox(2)
	log_panel.add_child(log_box)
	_add_log("队伍出征！士兵每秒攻击一次，优先攻击最前方的敌人。")

func _make_soldier_card(i: int) -> PanelContainer:
	var p := UI.panel(Color("fff8ec"), Color("8a5a2b"), 10, 1, 8)
	p.custom_minimum_size = Vector2(210, 118)
	var v := UI.vbox(4)
	p.add_child(v)
	v.add_child(UI.label(Game.SOLDIER_NAMES[i], 16))
	var hp_bar := HBar.new()
	hp_bar.setup(100.0, 100.0, Color("6fbf5f"), false, 14)
	v.add_child(hp_bar)
	var hp_l := UI.label("生命 100/100", 13)
	v.add_child(hp_l)
	var dur_bar := HBar.new()
	var w: Dictionary = Game.weapons[i]
	dur_bar.setup(w.durability, w.max_durability, Color("4f8ed9"), false, 12)
	v.add_child(dur_bar)
	var atk_l := UI.label("攻击 %.1f · 耐久 %d" % [w.attack, w.durability], 13)
	v.add_child(atk_l)
	p.set_meta("hp_bar", hp_bar)
	p.set_meta("hp_label", hp_l)
	p.set_meta("dur_bar", dur_bar)
	p.set_meta("atk_label", atk_l)
	return p

# ---------------- 初始化 ----------------
func _init_soldiers() -> void:
	soldiers.clear()
	for i in Game.weapons.size():
		var w: Dictionary = Game.weapons[i]
		soldiers.append({
			"id": _new_uid(),
			"index": i,
			"name": Game.SOLDIER_NAMES[i],
			"hp": 100,
			"max_hp": 100,
			"weapon": w,
			"durability": w.durability,
			"alive": true,
			"x": SOLDIER_BASE_X + i * 70.0,
		})
		lunge.clear()

func _spawn_group() -> void:
	monsters.clear()
	var hp := 25 + (Game.day - 1) * 15
	var dmg := 5 + (Game.day - 1) * 2
	for i in 3:
		monsters.append({
			"id": _new_uid(),
			"name": "怪物 %d-%d" % [group_index + 1, i + 1],
			"hp": hp,
			"max_hp": hp,
			"damage": dmg,
			"alive": true,
			"x": MONSTER_SPAWN_X - i * 64.0,
		})
	if is_instance_valid(info_label):
		info_label.text = "第 %d / 3 组怪物（生命 %d，伤害 %d）" % [group_index + 1, hp, dmg]
	if is_instance_valid(field):
		field.queue_redraw()

func _new_uid() -> int:
	uid_counter += 1
	return uid_counter

# ---------------- 主循环 ----------------
func _process(delta: float) -> void:
	if ended:
		_update_floaters(delta)
		return
	if phase == "march":
		_process_march(delta)
	elif phase == "fight":
		tick_acc += delta
		tick_bar.set_value(tick_interval - tick_acc, tick_interval)
		if tick_acc >= tick_interval:
			tick_acc = 0.0
			_combat_tick()
	_update_floaters(delta)
	_update_lunge(delta)
	field.queue_redraw()
	_update_soldier_cards()

func _process_march(delta: float) -> void:
	var front_s: Dictionary = _front_soldier()
	var front_m: Dictionary = _front_monster()
	if front_s.is_empty() or front_m.is_empty():
		return
	var target_gap := CONTACT_GAP
	var gap: float = front_m.x - front_s.x
	if gap <= target_gap:
		phase = "fight"
		tick_acc = 0.0
		if is_instance_valid(info_label):
			info_label.text = "接敌！自动交战中……"
		_add_log("与第 %d 组怪物接战。" % (group_index + 1))
		return
	# 士兵整体向右推进
	var step: float = minf(march_speed * delta, gap - target_gap)
	for s in soldiers:
		if s.alive:
			s.x += step

func _front_soldier() -> Dictionary:
	var best: Dictionary = {}
	for s in soldiers:
		if s.alive and (best.is_empty() or s.x > best.x):
			best = s
	return best

func _front_monster() -> Dictionary:
	var best: Dictionary = {}
	for m in monsters:
		if m.alive and (best.is_empty() or m.x < best.x):
			best = m
	return best

func _alive_soldiers() -> int:
	var n := 0
	for s in soldiers:
		if s.alive:
			n += 1
	return n

func _alive_monsters() -> int:
	var n := 0
	for m in monsters:
		if m.alive:
			n += 1
	return n

# ---------------- 战斗回合（同一时刻伤害同时结算） ----------------
func _combat_tick() -> void:
	# 1. 收集本回合所有攻击意图
	var pending: Array = []   # {target_id, amount, side, attacker}
	for s in soldiers:
		if not s.alive:
			continue
		var target: Dictionary = _front_monster()
		if target.is_empty():
			break
		var amount: float = _soldier_attack(s)
		pending.append({"target_id": target.id, "amount": amount, "side": "monster",
			"attacker": s, "target": target})
		# 耐久消耗：有武器每次攻击 -1，耗尽后徒手
		if s.durability > 0:
			s.durability -= 1
		lunge[s.id] = 0.18
	for m in monsters:
		if not m.alive:
			continue
		var target2: Dictionary = _front_soldier()
		if target2.is_empty():
			break
		pending.append({"target_id": target2.id, "amount": m.damage, "side": "soldier",
			"attacker": m, "target": target2})
		lunge[m.id] = 0.18
	# 2. 同时结算伤害
	for hit in pending:
		var t: Dictionary = hit.target
		if not t.alive:
			continue
		t.hp -= hit.amount
		_spawn_floater(t.x, _unit_y() - 90.0,
			"-%s" % _fmt(hit.amount),
			Color("d9534f") if hit.side == "soldier" else Color("b8860b"))
		if hit.side == "soldier":
			_add_log("%s 受到 %s 点伤害" % [t.name, _fmt(hit.amount)])
		else:
			_add_log("%s 命中 %s，造成 %s 点伤害" % [hit.attacker.name, t.name, _fmt(hit.amount)])
	# 3. 死亡处理
	for s in soldiers:
		if s.alive and s.hp <= 0:
			s.alive = false
			s.hp = 0
			_add_log("💀 %s 倒下，退出战斗！" % s.name)
			_spawn_floater(s.x, _unit_y() - 110.0, "倒下", Color("7a3b3b"))
	for m in monsters:
		if m.alive and m.hp <= 0:
			m.alive = false
			m.hp = 0
			_add_log("✔ %s 被击败。" % m.name)
	# 4. 胜负判定（同归于尽算失败）
	var soldiers_left := _alive_soldiers()
	var monsters_left := _alive_monsters()
	if soldiers_left == 0:
		_end_battle(false)
		return
	if monsters_left == 0:
		group_index += 1
		gold_earned += 10
		_set_gold_label()
		if group_index >= 3:
			# 当天全胜额外 10 金币
			gold_earned += 10
			_set_gold_label()
			_end_battle(true)
		else:
			phase = "march"
			_spawn_group()
			_add_log("第 %d 组怪物清空，获得 10 金币，继续推进！" % group_index)

func _soldier_attack(s: Dictionary) -> float:
	var w: Dictionary = s.weapon
	if s.durability > 0:
		# 实际攻击 = 基础 ×（0.5 + 有效质量/100），附件攻击 +3 已含在 w.attack
		return w.attack
	return 2.0   # 武器耗尽，徒手 2 点

func _fmt(x: float) -> String:
	if absf(x - round(x)) < 0.01:
		return str(int(round(x)))
	return "%.1f" % x

func _set_gold_label() -> void:
	var l: Label = find_child("GoldLabel", true, false)
	if l:
		l.text = "战利品 +%d 金币" % gold_earned

func _end_battle(victory: bool) -> void:
	ended = true
	phase = "ended"
	result_victory = victory
	Game.record_battle(victory, group_index, gold_earned)
	if is_instance_valid(info_label):
		if victory:
			info_label.text = "当天胜利！三组怪物全部清空。"
		else:
			info_label.text = "士兵全灭，当天失败（同归于尽也算失败）。"
	if victory:
		_add_log("🏆 全胜！额外获得 10 金币，今日共 %d 金币。" % gold_earned)
	else:
		_add_log("战败……次日士兵将恢复生命，可继续远征。")
	if is_inside_tree():
		_show_end_panel()

func _show_end_panel() -> void:
	end_panel = UI.panel(Color("fbf1de"), Color("8a5a2b"), 16, 3, 20)
	end_panel.size = Vector2(520, 330)
	end_panel.position = Vector2(380, 180)
	add_child(end_panel)
	var v := UI.vbox(14)
	end_panel.add_child(v)
	v.add_child(UI.label("🏆 当天胜利！" if result_victory else "💀 当天失败", 26,
		Color("2e6b2e") if result_victory else Color("b3402e")))
	v.add_child(UI.label("清空怪物组：%d / 3" % group_index, 18))
	v.add_child(UI.label("获得金币：%d（每组 10，全胜额外 10）" % gold_earned, 18))
	var survivors := 0
	for s in soldiers:
		if s.alive:
			survivors += 1
	v.add_child(UI.label("幸存士兵：%d / 3" % survivors, 18))
	v.add_child(UI.vspacer())
	var btn := UI.button("继续 →", 18, 220, 48)
	btn.pressed.connect(func(): get_parent().goto_interlude())
	var row := UI.hbox()
	v.add_child(row)
	row.add_child(UI.spacer())
	row.add_child(btn)
	row.add_child(UI.spacer())

# ---------------- 飘字 / 突进 / 卡片 ----------------
func _spawn_floater(x: float, y: float, text: String, col: Color) -> void:
	floaters.append({"x": x, "y": y, "text": text, "color": col, "t": 0.0})

func _update_floaters(delta: float) -> void:
	for f in floaters:
		f.t += delta
		f.y -= 34.0 * delta
	floaters = floaters.filter(func(f): return f.t < 1.1)

func _update_lunge(delta: float) -> void:
	var keys := lunge.keys()
	for k in keys:
		lunge[k] -= delta
		if lunge[k] <= 0.0:
			lunge.erase(k)

func _update_soldier_cards() -> void:
	if soldier_cards.is_empty():
		return
	for i in soldiers.size():
		var s: Dictionary = soldiers[i]
		var card: PanelContainer = soldier_cards[i]
		var hp_bar: HBar = card.get_meta("hp_bar")
		var hp_l: Label = card.get_meta("hp_label")
		var dur_bar: HBar = card.get_meta("dur_bar")
		var atk_l: Label = card.get_meta("atk_label")
		hp_bar.set_value(maxf(s.hp, 0.0), s.max_hp)
		hp_l.text = "生命 %s/%d%s" % [_fmt(maxf(s.hp, 0.0)), s.max_hp, "" if s.alive else "（阵亡）"]
		var w: Dictionary = s.weapon
		dur_bar.set_value(s.durability, w.max_durability)
		var atk_now: float = _soldier_attack(s)
		atk_l.text = "攻击 %s · 耐久 %d%s" % [_fmt(atk_now), s.durability,
			"（徒手）" if s.durability <= 0 and s.alive else ""]
		card.modulate = Color(1, 1, 1, 1.0) if s.alive else Color(0.45, 0.45, 0.45, 1.0)

func _add_log(text: String) -> void:
	if not is_instance_valid(log_box):
		return
	var l := UI.label(text, 13, Color("5b4632"))
	log_box.add_child(l)
	while log_box.get_child_count() > 7:
		log_box.get_child(0).queue_free()

# ---------------- 战场绘制 ----------------
func _unit_y() -> float:
	return _field_h * GROUND_Y_RATIO

func _lunge_offset(unit: Dictionary, dir_sign: float) -> float:
	if not lunge.has(unit.id):
		return 0.0
	var k: float = lunge[unit.id] / 0.18
	return dir_sign * 22.0 * k

func draw_field_contents(canvas: Control) -> void:
	var w := _field_w
	var h := _field_h
	# 天空
	canvas.draw_rect(Rect2(0, 0, w, h), Color("cfe3f2"), true)
	# 远山
	var m1 := PackedVector2Array([Vector2(0, h * 0.55), Vector2(w * 0.25, h * 0.3),
		Vector2(w * 0.5, h * 0.52), Vector2(w * 0.75, h * 0.34), Vector2(w, h * 0.55)])
	canvas.draw_colored_polygon(m1, Color("9db89a"))
	# 地面
	var gy := _unit_y()
	canvas.draw_rect(Rect2(0, gy, w, h - gy), Color("8fae6a"), true)
	canvas.draw_line(Vector2(0, gy), Vector2(w, gy), Color("6f8a52"), 4.0)
	# 路径小旗
	for gx in [300.0, 620.0, 900.0]:
		canvas.draw_line(Vector2(gx, gy), Vector2(gx, gy - 46), Color("6b4a30"), 3.0)
		canvas.draw_rect(Rect2(gx, gy - 46, 22, 14), Color("d9534f"), true)
	# 怪物
	for m in monsters:
		if not m.alive:
			continue
		var mx: float = m.x + _lunge_offset(m, -1.0)
		_draw_monster(canvas, mx, gy, m)
	# 士兵
	for s in soldiers:
		if not s.alive:
			continue
		var sx: float = s.x + _lunge_offset(s, 1.0)
		_draw_soldier(canvas, sx, gy, s)
	# 飘字
	for f in floaters:
		var alpha := clampf(1.0 - f.t / 1.1, 0.0, 1.0)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(f.x - 14, f.y), f.text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(f.color, alpha))

func _draw_soldier(canvas: Control, x: float, ground_y: float, s: Dictionary) -> void:
	var skin := Color("f0c8a0")
	var tunic: Color = [Color("4f8ed9"), Color("6fbf5f"), Color("c9932b")][s.index]
	# 身体
	canvas.draw_rect(Rect2(x - 16, ground_y - 62, 32, 38), tunic, true)
	canvas.draw_rect(Rect2(x - 16, ground_y - 62, 32, 38), Color("3b2a20"), false, 2.0)
	# 头
	canvas.draw_circle(Vector2(x, ground_y - 76), 14.0, skin)
	canvas.draw_circle(Vector2(x, ground_y - 76), 14.0, Color("3b2a20"), false, 2.0)
	# 头盔
	canvas.draw_arc(Vector2(x, ground_y - 78), 15.0, PI, TAU, 16, Color("7a8593"), 4.0)
	# 腿
	canvas.draw_line(Vector2(x - 8, ground_y - 24), Vector2(x - 8, ground_y), Color("4a3a2a"), 5.0)
	canvas.draw_line(Vector2(x + 8, ground_y - 24), Vector2(x + 8, ground_y), Color("4a3a2a"), 5.0)
	# 武器（外观随材料/类别/附件变化）
	var w: Dictionary = s.weapon
	var col: Color = Game.MATERIAL_COLOR[w.material]
	var wx := x + 26.0
	if w.weapon_type == Game.T_SWORD:
		canvas.draw_line(Vector2(wx, ground_y - 70), Vector2(wx, ground_y - 20), col, 5.0)
		canvas.draw_line(Vector2(wx - 7, ground_y - 40), Vector2(wx + 7, ground_y - 40), Color("6b4a30"), 3.0)
	else:
		canvas.draw_line(Vector2(wx, ground_y - 72), Vector2(wx, ground_y - 16), Color("8a5a32"), 4.0)
		canvas.draw_circle(Vector2(wx, ground_y - 66), 9.0, col)
	# 名字与血条
	canvas.draw_string(ThemeDB.fallback_font, Vector2(x - 30, ground_y + 18), s.name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("3b2a20"))
	var bw := 64.0
	var ratio := clampf(s.hp / s.max_hp, 0.0, 1.0)
	canvas.draw_rect(Rect2(x - bw * 0.5, ground_y + 24, bw, 7), Color("40342b"), true)
	canvas.draw_rect(Rect2(x - bw * 0.5 + 1, ground_y + 25, (bw - 2) * ratio, 5), Color("6fbf5f"), true)
	# 耐久小标记
	if s.durability <= 0:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x - 20, ground_y - 96), "徒手",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b3402e"))

func _draw_monster(canvas: Control, x: float, ground_y: float, m: Dictionary) -> void:
	var body_col: Color = [Color("9a5db3"), Color("b35d7a"), Color("5d8fb3")][int(m.id) % 3]
	# 身体
	canvas.draw_circle(Vector2(x, ground_y - 38), 24.0, body_col)
	canvas.draw_circle(Vector2(x, ground_y - 38), 24.0, Color("2c1830"), false, 2.0)
	# 眼睛
	canvas.draw_circle(Vector2(x - 8, ground_y - 44), 4.0, Color("ffe9c4"))
	canvas.draw_circle(Vector2(x + 8, ground_y - 44), 4.0, Color("ffe9c4"))
	canvas.draw_circle(Vector2(x - 8, ground_y - 44), 2.0, Color("2c1830"))
	canvas.draw_circle(Vector2(x + 8, ground_y - 44), 2.0, Color("2c1830"))
	# 獠牙
	canvas.draw_line(Vector2(x - 6, ground_y - 28), Vector2(x - 3, ground_y - 20), Color("fff"), 3.0)
	canvas.draw_line(Vector2(x + 6, ground_y - 28), Vector2(x + 3, ground_y - 20), Color("fff"), 3.0)
	# 脚
	canvas.draw_line(Vector2(x - 12, ground_y - 16), Vector2(x - 14, ground_y), Color("2c1830"), 5.0)
	canvas.draw_line(Vector2(x + 12, ground_y - 16), Vector2(x + 14, ground_y), Color("2c1830"), 5.0)
	# 血条
	var bw := 60.0
	var ratio := clampf(m.hp / m.max_hp, 0.0, 1.0)
	canvas.draw_rect(Rect2(x - bw * 0.5, ground_y - 78, bw, 7), Color("40342b"), true)
	canvas.draw_rect(Rect2(x - bw * 0.5 + 1, ground_y - 77, (bw - 2) * ratio, 5), Color("d9534f"), true)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(x - 26, ground_y - 84),
		"%s/%s" % [_fmt(maxf(m.hp, 0.0)), _fmt(m.max_hp)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("3b2a20"))
