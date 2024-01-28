extends Node2D
class_name SecretLevelLoader

@export var secret_level: PackedScene

func _process(delta):
	if Input.is_action_just_pressed("secret_level"):
		get_tree().change_scene_to_packed(secret_level)
