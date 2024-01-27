extends RigidBody2D
class_name PhysicsCharacter2D

class InputData:
	var horizontal: float
	var vertical: float
	var jump: bool
	var sprint: bool
class PhysicalData:
	var velocity: Vector2
	var leftWall: CollisionObject2D
	var rightWall: CollisionObject2D
	var topWall: CollisionObject2D
	var botWall: CollisionObject2D

enum SpecificState { IdleLeft, IdleRight, WalkLeft, WalkRight, RunLeft, RunRight, JumpFaceLeft, JumpFaceRight, JumpMoveLeft, JumpMoveRight, FallFaceLeft, FallFaceRight, FallMoveLeft, FallMoveRight, ClimbLeftIdle, ClimbLeftUp, ClimbLeftDown, ClimbRightIdle, ClimbRightUp, ClimbRightDown, ClimbTopIdleLeft, ClimbTopIdleRight, ClimbTopMoveLeft, ClimbTopMoveRight }
enum AnimeState { Idle, Walk, Run, Jump, AirFall, Land, TopClimb, TopClimbIdle, SideClimb, SideClimbIdle }

func _init():
	currentPhysicals = PhysicalData.new()

var currentInput: InputData
var prevInput: InputData
var prevState: SpecificState
var currentState: SpecificState
var currentPhysicals: PhysicalData

@export var walkSpeed: float = 2.5
@export var runSeed: float = 4
@export var climbSpeed: float = 2
@export var walkJumpSpeed: float = 5
@export var runJumpSpeed: float = 4
@export var addedFallAcceleration: float = 9.8
@export var wallDetectionDistance: float = 0.01
@export var groundMask: int = ~0
@export var wallMask: int = ~0
@export var ceilingMask: int = ~0

var invertFlip: bool

@export var leftDetectOffset: float
@export var rightDetectOffset: float
@export var topDetectOffset: float
@export var bottomDetectOffset: float
@export var sideDetectVerticalOffset: float
@export var verticalDetectSideOffset: float

@export var debug_wall_rays: bool = true
var collider_bounds: Rect2

var otherObjectVelocity: Vector2
var otherObjectPrevVelocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# currentPhysicals.velocity = linear_velocity
	detect_wall()

func detect_wall():
	var collider = NodeHelpers.get_child_of_type(self, CollisionShape2D)
	collider_bounds = collider.shape.get_rect()
	if debug_wall_rays:
		DebugDraw.draw_box(Vector3(global_position.x, global_position.y, 0), Vector3(collider_bounds.size.x, collider_bounds.size.y, 0), Color.GREEN)
	var global_right = Node2DHelpers.get_global_right(self)
	var global_up = Node2DHelpers.get_global_up(self)

	var rightRayBot = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.x / 2 + rightDetectOffset) + -global_up * (bottomDetectOffset  + sideDetectVerticalOffset)
	rightRayBot.to = global_right
	var rightRayCenter = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y / 2) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset)
	rightRayBot.to = global_right
	var rightRayTop = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y + topDetectOffset + sideDetectVerticalOffset) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset)
	rightRayBot.to = global_right
	currentPhysicals.rightWall = wall_cast(debug_wall_rays, wallMask, [rightRayTop, rightRayCenter, rightRayBot])

	var leftRayBot = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset) + -global_up * (bottomDetectOffset + sideDetectVerticalOffset)
	rightRayBot.to = -global_right
	var leftRayCenter = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y / 2) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset)
	rightRayBot.to = -global_right
	var leftRayTop = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y + topDetectOffset + sideDetectVerticalOffset) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset)
	rightRayBot.to = -global_right
	currentPhysicals.leftWall = wall_cast(debug_wall_rays, wallMask, [leftRayTop, leftRayCenter, leftRayBot])

	var topRightRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y + topDetectOffset) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset + verticalDetectSideOffset)
	rightRayBot.to = global_up
	var topCenterRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y + topDetectOffset)
	rightRayBot.to = global_up
	var topLeftRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.y + topDetectOffset) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset + verticalDetectSideOffset)
	rightRayBot.to = global_up
	currentPhysicals.topWall = wall_cast(debug_wall_rays, ceilingMask, [topLeftRay, topCenterRay, topRightRay])

	var botRightRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.x / 2 + rightDetectOffset + verticalDetectSideOffset) + -global_up * (bottomDetectOffset)
	rightRayBot.to = -global_up
	var botCenterRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + -global_right * (bottomDetectOffset)
	rightRayBot.to = -global_up
	var botLeftRay = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset + verticalDetectSideOffset) + -global_up * (bottomDetectOffset)
	rightRayBot.to = -global_up
	currentPhysicals.botWall = wall_cast(debug_wall_rays, groundMask, [botLeftRay, botCenterRay, botRightRay])
func wall_cast(debug: bool, mask: int, rays: Array[PhysicsRayQueryParameters2D]) -> CollisionObject2D:
	var wall_hit: CollisionObject2D
	for current_ray in rays:
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(current_ray)
		if debug:
			DebugDraw.draw_ray_3d(Vector3(current_ray.from.x, current_ray.from.y, 0), Vector3(current_ray.to.x, current_ray.to.y, 0), wallDetectionDistance, Color.GREEN if result else Color.RED)
		if result:
			wall_hit = result.collider
			break
	return wall_hit
