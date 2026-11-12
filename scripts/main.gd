extends Control
## 根节点：全局主题（含中文字体回退）、场景路由、暂停控制

const MainMenuScreen := preload("res://scripts/main_menu_screen.gd")
const WorkshopScreen := preload("res://scripts/workshop_screen.gd")
const BattleScreen := preload("res://scripts/battle_screen.gd")
const InterludeScreen := preload("res://scripts/interlude_screen.gd")
const FinalScreen := preload("res://scripts/final_screen.gd")
const PauseOverlay := preload("res://scripts/pause_overlay.gd")

var screen_container: Control
var pause_overlay: PauseOverlay
var current: Control
var paused_game := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_theme()
	screen_container = Control.new()
	screen_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_container)
	pause_overlay = PauseOverlay.new()
	pause_overlay.visible = false
	add_child(pause_overlay)
	pause_overlay.resume_pressed.connect(toggle_pause)
	pause_overlay.restart_pressed.connect(_restart_game)
	pause_overlay.menu_pressed.connect(_back_to_menu)
	goto_menu()
	get_tree().root.size_changed.connect(_center_pause)

func _apply_theme() -> void:
	var theme := Theme.new()
	# Windows / macOS / Linux 常见中文字体回退，保证中文正常显示
	var font_paths := [
		"C:/Windows/Fonts/msyh.ttc",
		"C:/Windows/Fonts/simhei.ttf",
		"C:/Windows/Fonts/simsun.ttc",
		"/System/Library/Fonts/PingFang.ttc",
		"/System/Library/Fonts/STHeiti Medium.ttc",
		"/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
		"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
	]
	for path in font_paths:
		if FileAccess.file_exists(path):
			var f := FontFile.new()
			if f.load_dynamic_font(path) == OK:
				theme.default_font = f
				break
	theme.default_font_size = 16
	get_tree().root.theme = theme

# ---------------- 路由 ----------------
func _swap(screen: Control) -> void:
	for c in screen_container.get_children():
		c.queue_free()
	current = screen
	screen_container.add_child(screen)
	paused_game = false
	get_tree().paused = false
	pause_overlay.visible = false

func goto_menu() -> void:
	_swap(MainMenuScreen.new())

func goto_workshop() -> void:
	_swap(WorkshopScreen.new())

func goto_battle() -> void:
	_swap(BattleScreen.new())

func goto_interlude() -> void:
	if Game.day >= 3:
		_swap(FinalScreen.new())
	else:
		_swap(InterludeScreen.new())

func _restart_game() -> void:
	Game.reset()
	goto_workshop()

func _back_to_menu() -> void:
	goto_menu()

# ---------------- 暂停 ----------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# 主菜单不暂停；工坊的订单弹层自行处理 Esc
		if current is MainMenuScreen:
			return
		if current is WorkshopScreen and current.order_overlay.visible:
			return
		toggle_pause()

func toggle_pause() -> void:
	paused_game = not paused_game
	get_tree().paused = paused_game
	pause_overlay.visible = paused_game
	if paused_game:
		_center_pause()

func _center_pause() -> void:
	if pause_overlay and pause_overlay.panel:
		pause_overlay._center_panel()
