extends Button

func _on_pressed(): 
	SceneLogic.restart_last_level(get_tree().current_scene)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	connect("button_down", _on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
