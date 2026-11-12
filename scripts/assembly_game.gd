class_name AssemblyGame
extends Control
## 装配工序：先选择附件，再拖动手柄对准刀身插槽，释放时越准分越高
## 升级装配工具后，满分判定范围扩大

signal finished(score: float, attachment: String)

const BASE_PERFECT_DISTANCE := 14.0
const UPGRADED_PERFECT_DISTANCE := 24.0
const MAX_DISTANCE := 80.0

var perfect_distance := BASE_PERFECT_DISTANCE
var chosen_attachment := Game.A_NONE
var slot_pos := Vector2.ZERO
var handle_pos := Vector2.ZERO
var dragging := false
var done := false
var result_score := 0
var result_locked := false
var _finish_timer := 0.0
var _hint: Label
var _score_label: Label
var _attach_buttons: Array = []
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(900, 470)
	mouse_filter = Control.MOUSE_FILTER_STOP
	perfect_distance = UPGRADED_PERFECT_DISTANCE if Game.assemble_upgraded else BASE_PERFECT_DISTANCE
	slot_pos = Vector2(470, 250)
	handle_pos = Vector2(200, 380)
	var title := UI.label("③ 装配：选择附件，然后按住鼠标拖动手柄到刀身插槽处松开", 20)
	title.position = Vector2(24, 14)
	add_child(title)
	_score_label = UI.label("", 18, Color("2e6b2e"))
	_score_label.position = Vector2(24, 46)
	add_child(_score_label)
	_hint = UI.label("提示：也可用方向键移动手柄，回车释放。先确认订单需要哪种附件！", 16, Color("7a5a3a"))
	_hint.position = Vector2(24, 424)
	add_child(_hint)
	_build_attachment_choice()

func _build_attachment_choice() -> void:
	var cap := UI.panel(Color("f6ead6"), Color("8a5a2b"), 12, 2, 10)
	cap.position = Vector2(770, 100)
	cap.custom_minimum_size.x = 360
	add_child(cap)
	var inner := UI.vbox(8)
	cap.add_child(inner)
	inner.add_child(UI.label("选择附件（选错无加成）", 17))
	for a in [Game.A_NONE, Game.A_ATK, Game.A_DUR]:
		var b := UI.button(Game.ATTACH_NAME[a], 16, 300, 40)
		b.pressed.connect(_on_attachment.bind(a))
		_attach_buttons.append({"button": b, "attach": a})
		inner.add_child(b)
	_refresh_buttons()

func _on_attachment(a: String) -> void:
	if done:
		return
	chosen_attachment = a
	_refresh_buttons()
	queue_redraw()

func _refresh_buttons() -> void:
	for item in _attach_buttons:
		var b: Button = item.button
		var a: String = item.attach
		b.text = Game.ATTACH_NAME[a] + ("  ✓" if a == chosen_attachment else "")
		b.disabled = done

func _process(delta: float) -> void:
	if result_locked:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			finished.emit(result_score, chosen_attachment)
			set_physics_process(false)
		return
	if done:
		return
	# 键盘移动
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	if Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if move != Vector2.ZERO:
		handle_pos += move.normalized() * 260.0 * delta
		_clamp_handle()
		_update_distance_label()
		queue_redraw()

func _clamp_handle() -> void:
	handle_pos.x = clampf(handle_pos.x, 90.0, 740.0)
	handle_pos.y = clampf(handle_pos.y, 120.0, 400.0)

func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.distance_to(handle_pos) <= 34.0:
				dragging = true
				_drag_offset = handle_pos - event.position
				accept_event()
		else:
			if dragging:
				dragging = false
				_release()
				accept_event()
	elif event is InputEventMouseMotion and dragging:
		handle_pos = event.position + _drag_offset
		_clamp_handle()
		_update_distance_label()
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_release()
		accept_event()

func _update_distance_label() -> void:
	if done:
		return
	var d := handle_pos.distance_to(slot_pos)
	_score_label.text = "对准偏差：%.0f px（%s 内满分）" % [d, int(perfect_distance)]

func _release() -> void:
	if done:
		return
	done = true
	dragging = false
	var d := handle_pos.distance_to(slot_pos)
	if d <= perfect_distance:
		result_score = 100.0
	else:
		result_score = round(clampf(100.0 * (1.0 - (d - perfect_distance) / (MAX_DISTANCE - perfect_distance)), 0.0, 100.0))
	result_locked = true
	_finish_timer = 1.4
	_score_label.text = "装配得分：%d    附件：%s" % [int(result_score), Game.ATTACH_NAME[chosen_attachment]]
	_hint.text = "装配完成，即将交付成品。"
	_refresh_buttons()
	queue_redraw()

func _draw() -> void:
	# 工作台
	draw_rect(Rect2(70, 90, 680, 320), Color("c9a378"), true)
	draw_rect(Rect2(70, 90, 680, 320), Color("7a5a3a"), false, 3.0)
	# 刀身（水平放置，插槽在右端）
	var blade_y := slot_pos.y
	draw_rect(Rect2(120, blade_y - 18, 320, 36), Color("b8c2cc"), true)
	draw_rect(Rect2(120, blade_y - 18, 320, 36), Color("5b6470"), false, 2.0)
	# 插槽（目标）
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.1
	draw_arc(slot_pos, perfect_distance * pulse, 0, TAU, 40, Color("ffd94a"), 3.0)
	draw_arc(slot_pos, MAX_DISTANCE, 0, TAU, 40, Color(0, 0, 0, 0.25), 2.0)
	draw_rect(Rect2(slot_pos.x - 12, slot_pos.y - 22, 24, 44), Color("3b2a20"), true)
	draw_string(ThemeDB.fallback_font, slot_pos + Vector2(-28, -40), "刀身插槽",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("3b2a20"))
	# 对准虚线
	if not done:
		var d := handle_pos.distance_to(slot_pos)
		var col := Color("2e6b2e") if d <= perfect_distance else Color("d9534f")
		_draw_dashed_line(handle_pos, slot_pos, col)
	# 手柄（可拖动）
	var hcol := Color("8a5a32") if not done else Color("6b4a30")
	draw_circle(handle_pos, 26.0, hcol)
	draw_circle(handle_pos, 26.0, Color("3b2a20"), false, 3.0)
	draw_circle(handle_pos, 10.0, Color("c9a378"))
	if not done:
		draw_string(ThemeDB.fallback_font, handle_pos + Vector2(-20, 48), "拖我",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("3b2a20"))
	# 附件预览
	if chosen_attachment != Game.A_NONE:
		var p := Vector2(640, 130)
		if chosen_attachment == Game.A_ATK:
			var gem := PackedVector2Array([p + Vector2(0, -14), p + Vector2(12, 0),
				p + Vector2(0, 14), p + Vector2(-12, 0)])
			draw_colored_polygon(gem, Color("d9534f"))
			draw_polyline(gem + PackedVector2Array([gem[0]]), Color("7c2320"), 2.0)
		else:
			var shield := PackedVector2Array([p + Vector2(-12, -12), p + Vector2(12, -12),
				p + Vector2(12, 2), p + Vector2(0, 16), p + Vector2(-12, 2)])
			draw_colored_polygon(shield, Color("4f8ed9"))
			draw_polyline(shield + PackedVector2Array([shield[0]]), Color("274f80"), 2.0)
	# 结算评价
	if done:
		var msg := "完美装配！" if result_score >= 95.0 else ("装配合格" if result_score >= 60.0 else "装配偏差较大")
		draw_string(ThemeDB.fallback_font, Vector2(300, 150), msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("2e6b2e"))

func _draw_dashed_line(a: Vector2, b: Vector2, col: Color) -> void:
	var dist := a.distance_to(b)
	var n := int(dist / 12.0)
	for i in n:
		if i % 2 == 0:
			var t0 := float(i) / n
			var t1 := float(i + 1) / n
			draw_line(a.lerp(b, t0), a.lerp(b, t1), col, 2.0)
