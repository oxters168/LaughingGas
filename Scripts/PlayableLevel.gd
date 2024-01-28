extends Node2D
class_name PlayableLevel

func _ready():
	SceneChangeLogic.last_level_path = get_tree().current_scene.scene_file_path
	print(SceneChangeLogic.last_level_path)

func _process(delta):
	pass
