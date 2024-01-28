extends Area2D
class_name SceneChangeLogic

static var fail_scene = ResourceLoader.load("res://Scenes/fail.tscn")
static var last_level_path : String = "null"

static func fail(level : PlayableLevel): 
	var level_path = level.get_tree().current_scene.scene_file_path
	print("LL" + level_path)
	level.get_tree().change_scene_to_packed(fail_scene)
	last_level_path = level_path

static func restore(callee): 
	callee.get_tree().change_scene_to_file(last_level_path)
