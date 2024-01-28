extends Node

@export var collision_area: Area2D
@export var next_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	collision_area.body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_body_entered(body):
	if body is PhysicsCharacter2D:
		get_tree().change_scene_to_packed(next_scene)
