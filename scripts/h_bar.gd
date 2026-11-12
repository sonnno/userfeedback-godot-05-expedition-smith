class_name HBar
extends Control
## 卡通水平数值条（生命/耐久/进度）

var ratio: float = 1.0
var fill_color: Color = Color("6fbf5f")
var back_color: Color = Color("40342b")
var border_color: Color = Color("2c2018")
var show_text := true
var bar_height := 18.0

func setup(value: float, maximum: float, color: Color, text: bool = true, height: float = 18.0) -> void:
	fill_color = color
	show_text = text
	bar_height = height
	custom_minimum_size.y = bar_height + 4.0
	set_value(value, maximum)

func set_value(value: float, maximum: float) -> void:
	ratio = clampf(value / maxf(maximum, 0.0001), 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := bar_height
	var y := (size.y - h) * 0.5
	draw_rect(Rect2(0, y, w, h), back_color, true)
	if ratio > 0.0:
		var fw := maxf(4.0, w * ratio)
		var col := fill_color if ratio > 0.001 else fill_color
		draw_rect(Rect2(1, y + 1, fw - 2.0, h - 2.0), col, true)
	draw_rect(Rect2(0, y, w, h), border_color, false, 2.0)
