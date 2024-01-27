extends Camera2D
class_name PlayerCamera2D

@export var player : PhysicsCharacter2D
@export var internal_bounds : Rect2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_position = to_local(player.global_position)
	#if internal_bounds.has_point(player_position) == false: 
		#print("MOVING CAMERA TO " + str(player_position))
		#var global_player_position = to_global(player_position);
		#global_player_position.y += 26
		#position = global_player_position
