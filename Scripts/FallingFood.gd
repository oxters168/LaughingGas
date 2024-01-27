extends RigidBody2D
class_name FallingFood
@export var sprite : AnimatedSprite2D
@export var terminal_gravitational_velocity : int = 980

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#const force = PhysicsHelpers.calculate_required_force_for_speed_1d(
		#1.0, 
		#0.0, 
		#terminal_gravitational_velocity, 
	#	delta
	#)
	#apply_central_force()
	#sprite.translate(Vector2.DOWN * force * delta * delta)
