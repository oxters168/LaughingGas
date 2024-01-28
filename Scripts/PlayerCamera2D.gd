extends Camera2D
class_name PlayerCamera2D

@export var player : PhysicsCharacter2D
@export var internal_bounds : Rect2
@export var player_offset : Vector2
@export var reset_threshold : float
@export var camera_velocity : float
@export var display_camera_mode : bool = false

const CameraModes = {
	Reset = "Reset", 
	Follow = "Follow", 
	Still = "Still", 
	Unknown = "Unknown"
}

@onready var camera_mode = CameraModes.Unknown

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_position = to_local(player.global_position)
	var current_camera_mode = CameraModes.Unknown
	if internal_bounds.has_point(player_position) == false: 
		var global_player_position = to_global(player_position);
		var target_position = global_player_position + player_offset
		var target_offset = target_position - global_position
		if target_offset.length() > reset_threshold: 
			position.y = global_player_position.y - internal_bounds.size.y
			position.x = global_player_position.x
			current_camera_mode = CameraModes.Reset
		else: 
			translate(target_offset * camera_velocity * delta)
			current_camera_mode = CameraModes.Follow
	else: 
		current_camera_mode = CameraModes.Still
	if display_camera_mode == true and current_camera_mode != camera_mode: 
		print_debug("Camera mode update: " + str(current_camera_mode))
	camera_mode = current_camera_mode
