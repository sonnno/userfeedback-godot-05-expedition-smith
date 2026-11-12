class_name BattleField
extends Control
## 战场绘制控件：所有绘制都发生在它自身的 _draw 上下文中

var owner_screen: Control

func _draw() -> void:
	if owner_screen == null:
		return
	owner_screen.draw_field_contents(self)
