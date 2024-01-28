extends Button
class_name RestartButton
func _on_pressed(): 
	SceneChangeLogic.restore(get_tree().current_scene)

func _ready():
	connect("button_down", _on_pressed)

func _process(delta):
	pass
