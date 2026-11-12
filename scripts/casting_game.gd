class_name CastingGame
extends Control
## 浇铸工序：按住鼠标（或空格）注入熔液，松开停止；接近 90% 最佳，满溢降质

signal finished(score: float)

const FILL_SPEED := 36.0          # 每秒填充百分比
const IDEAL := 90.0
const GOOD_BAND := 5.0            # 85~95 为最佳区间
const OVERFLOW_VISUAL := 115.0    # 画面上允许的满溢高度

var fill := 0.0
var holding := false
var done := false
var result_score := 0.0
var result_locked := false

var _bar_rect := Rect2()
var _hint: Label
var _score_label: Label
var _fill_label: Label
var _finish_timer := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(900, 470)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var title := UI.label("① 浇铸：按住鼠标左键 / 空格注入熔液，松开停止", 20)
	title.position = Vector2(24, 14)
	add_child(title)
	_fill_label = UI.label("填充 0%", 18, Color("8a3b1f"))
	_fill_label.position = Vector2(24, 46)
	add_child(_fill_label)
	_score_label = UI.label("", 22, Color("2e6b2e"))
	_score_label.position = Vector2(700, 46)
	add_child(_score_label)
	_hint = UI.label("目标：停在 90% 附近（85%~95% 满分）。超过 100% 会满溢，质量大幅下降！", 16, Color("7a5a3a"))
	_hint.position = Vector2(24, 420)
	add_child(_hint)

func _process(delta: float) -> void:
	if result_locked:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			finished.emit(result_score)
			set_physics_process(false)
		return
	if done:
		return
	if holding:
		fill += FILL_SPEED * delta
		if fill >= OVERFLOW_VISUAL:
			fill = OVERFLOW_VISUAL
			_finish_fill()
		_fill_label.text = "填充 %d%%" % int(fill)
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		holding = event.pressed
		if not holding:
			_finish_fill()
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		holding = true
		accept_event()
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_SPACE:
		holding = false
		_finish_fill()
		accept_event()

func _finish_fill() -> void:
	if done:
		return
	done = true
	holding = false
	result_score = _score_for(fill)
	result_locked = true
	_finish_timer = 1.4
	_score_label.text = "浇铸得分：%d" % int(result_score)
	_fill_label.text = "填充 %d%%" % int(fill)
	_hint.text = _comment(result_score)
	queue_redraw()

func _score_for(f: float) -> float:
	if f <= 100.0:
		# 距 90% 越近越高：85~95 满分，两侧线性衰减
		var d := absf(f - IDEAL)
		if d <= GOOD_BAND:
			return 100.0
		return clampf(100.0 - (d - GOOD_BAND) * 2.6, 0.0, 100.0)
	# 满溢惩罚
	var over := f - 100.0
	return clampf(60.0 - over * 3.2, 10.0, 60.0)

func _comment(sc: float) -> String:
	if sc >= 95.0:
		return "完美浇铸！火候恰到好处。"
	if sc >= 75.0:
		return "不错的浇铸，还有提升空间。"
	if fill > 100.0:
		return "熔液满溢！成品质量受损。"
	return "填充偏差较大，质量一般。"

func _draw() -> void:
	var area := Rect2(120, 90, 320, 310)
	_bar_rect = area
	# 模具外框
	draw_rect(area, Color("5b4632"), true)
	draw_rect(area.grow(4), Color("2c2018"), false, 4.0)
	# 100% 参考线与 90% 目标线
	var h100 := area.size.y * (1.0 - 100.0 / OVERFLOW_VISUAL)
	var h90 := area.size.y * (1.0 - IDEAL / OVERFLOW_VISUAL)
	draw_line(Vector2(area.position.x, area.position.y + h100),
		Vector2(area.end.x, area.position.y + h100), Color("d9534f"), 3.0)
	draw_line(Vector2(area.position.x, area.position.y + h90),
		Vector2(area.end.x, area.position.y + h90), Color("ffd94a"), 3.0)
	# 理想区间带
	var band_top := area.size.y * (1.0 - 95.0 / OVERFLOW_VISUAL)
	var band_bot := area.size.y * (1.0 - 85.0 / OVERFLOW_VISUAL)
	draw_rect(Rect2(area.position.x + 3, area.position.y + band_top,
		area.size.x - 6, band_bot - band_top), Color(1, 0.85, 0.3, 0.25), true)
	# 熔液
	var shown := clampf(fill, 0.0, OVERFLOW_VISUAL)
	if shown > 0.0:
		var fh := area.size.y * (shown / OVERFLOW_VISUAL)
		var fr := Rect2(area.position.x + 5, area.end.y - fh, area.size.x - 10, fh - 4)
		draw_rect(fr, Color("e8642a"), true)
		draw_rect(Rect2(fr.position, Vector2(fr.size.x, minf(10.0, fr.size.y))), Color("ffb35c"), true)
		if fill > 100.0:
			# 满溢飞溅
			for i in 6:
				var px := area.position.x + 20.0 + (i * 53) % int(area.size.x - 40)
				draw_circle(Vector2(px, area.position.y - 6.0 - (i % 3) * 5.0), 4.0, Color("e8642a"))
	# 刻度文字
	draw_string(ThemeDB.fallback_font, Vector2(area.end.x + 14, area.position.y + h100 + 4),
		"100% 满溢线", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d9534f"))
	draw_string(ThemeDB.fallback_font, Vector2(area.end.x + 14, area.position.y + h90 + 4),
		"90% 目标", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8860b"))
	# 右侧坩埚与提示画
	var pot := Rect2(620, 150, 180, 150)
	draw_rect(pot, Color("6b4a30"), true)
	draw_rect(pot, Color("2c2018"), false, 4.0)
	draw_rect(Rect2(pot.position.x + 12, pot.position.y + 12, pot.size.x - 24, 34),
		Color("e8642a") if holding else Color("8a3b1f"), true)
	draw_string(ThemeDB.fallback_font, Vector2(620, 340),
		"按住：注入熔液\n松开：停止并结算", HORIZONTAL_ALIGNMENT_LEFT, 180, 18, Color("5b4632"))
