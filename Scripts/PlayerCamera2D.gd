extends Camera2D
class_name PlayerCamera2D

@export var player : PhysicsCharacter2D
@export var internal_bounds : Rect2
@export var player_offset : Vector2
@export var fast_move_threshold : float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_position = to_local(player.global_position)
	if internal_bounds.has_point(player_position) == false: 
		#print("MOVING CAMERA TO " + str(player_position))
		var global_player_position = to_global(player_position);
		var target_position = global_player_position + player_offset
		var target_offset = target_position - global_position
		if target_offset.length() > fast_move_threshold: 
			print("A")
			position.y = global_player_position.y - internal_bounds.size.y
			position.x = global_player_position.x
		else: 
			print("B")
			translate(target_offset * delta)
