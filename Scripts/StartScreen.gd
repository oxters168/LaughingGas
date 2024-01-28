extends Node2D

@export var start_btn: Button
@export var first_level: PackedScene

func _ready():
	start_btn.pressed.connect(start_game)

func start_game():
	get_tree().change_scene_to_packed(first_level)
