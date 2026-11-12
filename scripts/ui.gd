class_name UI
extends RefCounted
## 通用 UI 构建工具：统一卡通风格

static func stylebox(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 12,
		border_w: int = 0, pad: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	return s

static func stylebox_tex(tex: Texture2D) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	return s

static func label(text: String, size: int = 18, color: Color = Color("3b2a20")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String, size: int = 18, min_w: int = 0, min_h: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.add_theme_font_size_override("font_size", size)
	var normal := stylebox(Color("f0b35e"), Color("8a5a2b"), 10, 2, 8)
	var hover := stylebox(Color("ffc97e"), Color("8a5a2b"), 10, 2, 8)
	var pressed := stylebox(Color("d9964a"), Color("8a5a2b"), 10, 2, 8)
	var disabled := stylebox(Color("b7b0a8"), Color("7d766d"), 10, 2, 8)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", Color("3b2a20"))
	b.add_theme_color_override("font_hover_color", Color("2a1d15"))
	b.add_theme_color_override("font_disabled_color", Color("e8e2d8"))
	return b

static func panel(bg: Color = Color("f6ead6"), border: Color = Color("8a5a2b"),
		radius: int = 14, border_w: int = 2, pad: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stylebox(bg, border, radius, border_w, pad))
	return p

static func chip(text: String, bg: Color, fg: Color = Color.WHITE, size: int = 15) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stylebox(bg, bg.darkened(0.25), 999, 1, 6))
	var l := label(text, size, fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func vspacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

# 带标题的信息行
static func info_row(title: String, value: String, value_color: Color = Color("3b2a20")) -> HBoxContainer:
	var h := hbox(6)
	var t := label(title, 16)
	t.custom_minimum_size.x = 150
	h.add_child(t)
	var v := label(value, 16, value_color)
	h.add_child(v)
	return h
