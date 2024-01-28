extends Area2D
class_name FailArea

func _on_body_entered(body):
	if body is PhysicsCharacter2D:
		print_debug("You fail!")
		SceneChangeLogic.fail(body.get_tree().current_scene)

func _ready():
	body_entered.connect(_on_body_entered)

