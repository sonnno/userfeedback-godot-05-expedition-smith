class_name ForgingGame
extends Control
## 锻打工序：刀坯上 5 个目标点，依次点击，越准分越高，每个点只记分一次
## 升级锻打工具后，满分判定范围扩大

signal finished(score: float)

const TARGET_COUNT := 5
const BASE_PERFECT_RADIUS := 16.0
const UPGRADED_PERFECT_RADIUS := 26.0
const MAX_RADIUS := 52.0

var perfect_radius := BASE_PERFECT_RADIUS
var targets: Array = []        # {pos, hit, score, ring}
var current := 0
var done := false
var result_score := 0
var result_locked := false
var _finish_timer := 0.0
var _hint: Label
var _score_label: Label
var _blade_rect := Rect2()
var _sparks: Array = []        # 点击火花 {pos, t, color}

func _ready() -> void:
	custom_minimum_size = Vector2(900, 470)
	mouse_filter = Control.MOUSE_FILTER_STOP
	perfect_radius = UPGRADED_PERFECT_RADIUS if Game.forge_upgraded else BASE_PERFECT_RADIUS
	var title := UI.label("② 锻打：依次点击刀坯上发光的 5 个目标点（鼠标点击，或 Tab 切换后回车）", 20)
	title.position = Vector2(24, 14)
	add_child(title)
	_score_label = UI.label("已锤击 0 / 5", 18, Color("2e6b2e"))
	_score_label.position = Vector2(24, 46)
	add_child(_score_label)
	_hint = UI.label("点击越靠近圆心得分越高，每个目标只记分一次。工具升级后黄圈（满分范围）更大。", 16, Color("7a5a3a"))
	_hint.position = Vector2(24, 420)
	add_child(_hint)
	_blade_rect = Rect2(150, 110, 600, 260)
	_generate_targets()

func _generate_targets() -> void:
	targets.clear()
	var tries := 0
	while targets.size() < TARGET_COUNT and tries < 400:
		tries += 1
		var p := Vector2(
			Game.rng.randf_range(_blade_rect.position.x + 50, _blade_rect.end.x - 50),
			Game.rng.randf_range(_blade_rect.position.y + 40, _blade_rect.end.y - 40))
		var ok := true
		for t in targets:
			if p.distance_to(t.pos) < 95.0:
				ok = false
				break
		if ok:
			targets.append({"pos": p, "hit": false, "score": 0.0})

func _process(delta: float) -> void:
	for sp in _sparks:
		sp.t += delta
	_sparks = _sparks.filter(func(sp): return sp.t < 0.5)
	if not _sparks.is_empty():
		queue_redraw()
	if result_locked:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			finished.emit(result_score)
			set_physics_process(false)

func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_hit(event.position)
		accept_event()

func _try_hit(click_pos: Vector2) -> void:
	if current >= targets.size():
		return
	var t: Dictionary = targets[current]
	var d := click_pos.distance_to(t.pos)
	var sc := _score_for(d)
	t.hit = true
	t.score = sc
	t.ring = d
	_sparks.append({"pos": click_pos, "t": 0.0,
		"color": Color("ffd94a") if sc >= 90.0 else Color("e8642a")})
	current += 1
	_score_label.text = "已锤击 %d / 5    上次得分：%d" % [current, int(sc)]
	if current >= TARGET_COUNT:
		_finish()
	queue_redraw()

func _score_for(d: float) -> float:
	if d <= perfect_radius:
		return 100.0
	if d >= MAX_RADIUS:
		return 0.0
	# 满分圈外线性衰减
	return round(clampf(100.0 * (1.0 - (d - perfect_radius) / (MAX_RADIUS - perfect_radius)), 0.0, 100.0))

func _finish() -> void:
	done = true
	var total := 0.0
	for t in targets:
		total += t.score
	result_score = round(total / TARGET_COUNT)
	result_locked = true
	_finish_timer = 1.4
	_score_label.text = "锻打完成！平均得分：%d" % int(result_score)
	_hint.text = "五道锤痕已成型，准备进入装配工序。"

func _draw() -> void:
	# 铁砧台面
	draw_rect(Rect2(90, 380, 720, 26), Color("5b4632"), true)
	# 刀坯
	var mat_col: Color = Game.MATERIAL_COLOR[Game.M_IRON]
	draw_rect(_blade_rect, mat_col.lightened(0.25), true)
	draw_rect(_blade_rect, Color("4a4038"), false, 3.0)
	# 刀坯纹理
	for i in 4:
		var y := _blade_rect.position.y + 40 + i * 55
		draw_line(Vector2(_blade_rect.position.x + 14, y),
			Vector2(_blade_rect.end.x - 14, y), Color(0, 0, 0, 0.12), 2.0)
	# 目标点
	for i in targets.size():
		var t: Dictionary = targets[i]
		var p: Vector2 = t.pos
		if t.hit:
			# 已锤击：显示命中点与得分
			draw_circle(p, 7.0, Color("5b4632"))
			draw_string(ThemeDB.fallback_font, p + Vector2(10, -8),
				"%d分" % int(t.score), HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
				Color("2e6b2e") if t.score >= 90.0 else Color("8a5a2b"))
		elif i == current:
			# 当前目标：脉动光圈
			var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.12
			draw_arc(p, MAX_RADIUS * pulse, 0, TAU, 40, Color(0, 0, 0, 0.25), 2.0)
			draw_arc(p, perfect_radius * pulse, 0, TAU, 40, Color("ffd94a"), 3.0)
			draw_circle(p, 9.0 * pulse, Color("d9534f"))
			draw_circle(p, 4.0, Color("fff3c4"))
			draw_string(ThemeDB.fallback_font, p + Vector2(12, 5), "锤这里！",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d9534f"))
		else:
			draw_circle(p, 8.0, Color(0, 0, 0, 0.2))
	# 火花
	for sp in _sparks:
		var k: float = sp.t / 0.5
		var r: float = 6.0 + k * 18.0
		draw_arc(sp.pos, r, 0, TAU, 20, Color(sp.color, 1.0 - k), 2.0)
	# 右侧说明面板
	draw_rect(Rect2(800, 110, 340, 240), Color("f6ead6"), true)
	draw_rect(Rect2(800, 110, 340, 240), Color("8a5a2b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(818, 142), "锻打工具", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3b2a20"))
	draw_string(ThemeDB.fallback_font, Vector2(818, 176),
		"状态：%s" % ("已升级（满分圈更大）" if Game.forge_upgraded else "普通"),
		HORIZONTAL_ALIGNMENT_LEFT, 300, 16, Color("2e6b2e") if Game.forge_upgraded else Color("7a5a3a"))
	draw_string(ThemeDB.fallback_font, Vector2(818, 214),
		"黄圈内：100 分\n黄圈外：随距离衰减\n每个目标仅记分一次",
		HORIZONTAL_ALIGNMENT_LEFT, 300, 16, Color("5b4632"))
	draw_arc(Vector2(950, 300), perfect_radius, 0, TAU, 32, Color("ffd94a"), 3.0)
	draw_circle(Vector2(950, 300), 6.0, Color("d9534f"))
