extends PathFollow2D
class_name Endoscope
@onready var sprite = $AnimatedSprite2D
@export var path_nodes : PathNodes2D
@export var follow_velocity : float
@onready var trigger : FailArea = $FailArea
var path : Path2D
#Help from: https://gamedevacademy.org/pathfollow2d-in-godot-complete-guide/
func _ready():
	path = get_node("..")
	add_child(sprite)
	add_child(trigger)

func _process(delta):
	set_progress(get_progress() + follow_velocity * delta)
	#print(str(path.curve.point_count))
	#print(str(position))
	#if self.h_offset >= path.curve.get_baked_length():
		#print_debug('Endoscope the end of the path!')
