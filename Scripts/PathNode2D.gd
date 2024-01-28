@tool
extends AnimatedSprite2D
class_name PathNode2D

func _ready(): 
	if not Engine.is_editor_hint():
		visible = false
