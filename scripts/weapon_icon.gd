class_name WeaponIcon
extends Control
## 成品外观：类别（剑/斧）、材料（铜/铁/钢配色）、附件（徽记）一目了然

var weapon_type: String = Game.T_SWORD
var weapon_material: String = Game.M_COPPER
var attachment: String = Game.A_NONE

func setup(wtype: String, mat: String, attach: String, icon_size: float = 96.0) -> void:
	weapon_type = wtype
	weapon_material = mat
	attachment = attach
	custom_minimum_size = Vector2(icon_size, icon_size)

func _draw() -> void:
	var main: Color = Game.MATERIAL_COLOR[weapon_material]
	var dark: Color = Game.MATERIAL_DARK[weapon_material]
	var wood := Color("8a5a32")
	var wood_dark := Color("5e3b1f")
	var s := minf(size.x, size.y)
	var cx := size.x * 0.5

	# 手柄（竖向，底端）
	var grip_w := s * 0.13
	var grip_x := cx - grip_w * 0.5
	var grip_top := s * 0.62
	var grip_bottom := s * 0.92
	draw_rect(Rect2(grip_x, grip_top, grip_w, grip_bottom - grip_top), wood, true)
	draw_rect(Rect2(grip_x, grip_top, grip_w, grip_bottom - grip_top), wood_dark, false, 2.0)
	draw_circle(Vector2(cx, grip_bottom + s * 0.02), s * 0.055, wood_dark)

	if weapon_type == Game.T_SWORD:
		# 护手
		draw_rect(Rect2(cx - s * 0.2, s * 0.58, s * 0.4, s * 0.06), dark, true)
		# 剑身（三角形收尖）
		var blade := PackedVector2Array([
			Vector2(cx - s * 0.09, s * 0.58),
			Vector2(cx + s * 0.09, s * 0.58),
			Vector2(cx + s * 0.055, s * 0.14),
			Vector2(cx, s * 0.06),
			Vector2(cx - s * 0.055, s * 0.14),
		])
		draw_colored_polygon(blade, main)
		draw_polyline(blade + PackedVector2Array([blade[0]]), dark, 2.0)
		# 中线高光
		draw_line(Vector2(cx, s * 0.12), Vector2(cx, s * 0.56), Color(1, 1, 1, 0.45), 2.0)
	else:
		# 斧柄护手
		draw_rect(Rect2(cx - s * 0.13, s * 0.6, s * 0.26, s * 0.05), dark, true)
		# 斧头（双侧月牙）
		var head := PackedVector2Array([
			Vector2(cx - s * 0.07, s * 0.58),
			Vector2(cx - s * 0.34, s * 0.46),
			Vector2(cx - s * 0.3, s * 0.2),
			Vector2(cx - s * 0.09, s * 0.26),
			Vector2(cx + s * 0.09, s * 0.26),
			Vector2(cx + s * 0.3, s * 0.2),
			Vector2(cx + s * 0.34, s * 0.46),
			Vector2(cx + s * 0.07, s * 0.58),
		])
		draw_colored_polygon(head, main)
		draw_polyline(head + PackedVector2Array([head[0]]), dark, 2.0)
		draw_line(Vector2(cx - s * 0.24, s * 0.3), Vector2(cx - s * 0.12, s * 0.48), Color(1, 1, 1, 0.35), 2.0)

	# 附件徽记：攻击=红色锐石，耐久=蓝色护盾
	if attachment == Game.A_ATK:
		var pos := Vector2(cx + s * 0.26, s * 0.16)
		var gem := PackedVector2Array([
			pos + Vector2(0, -s * 0.07),
			pos + Vector2(s * 0.06, 0),
			pos + Vector2(0, s * 0.07),
			pos + Vector2(-s * 0.06, 0),
		])
		draw_colored_polygon(gem, Color("d9534f"))
		draw_polyline(gem + PackedVector2Array([gem[0]]), Color("7c2320"), 2.0)
	elif attachment == Game.A_DUR:
		var pos := Vector2(cx + s * 0.26, s * 0.16)
		var shield := PackedVector2Array([
			pos + Vector2(-s * 0.06, -s * 0.06),
			pos + Vector2(s * 0.06, -s * 0.06),
			pos + Vector2(s * 0.06, s * 0.01),
			pos + Vector2(0, s * 0.08),
			pos + Vector2(-s * 0.06, s * 0.01),
		])
		draw_colored_polygon(shield, Color("4f8ed9"))
		draw_polyline(shield + PackedVector2Array([shield[0]]), Color("274f80"), 2.0)
