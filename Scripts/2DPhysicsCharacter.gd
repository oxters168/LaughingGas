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
var currentPhysicals: PhysicalData = PhysicalData.new()

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
	currentPhysicals.velocity = linear_velocity
	detect_wall()

func detect_wall():
	var collider = NodeHelpers.get_child_of_type(self, CollisionShape2D)
	collider_bounds = collider.shape.get_rect()
	var global_right = Node2DHelpers.get_global_right(self)
	var global_up = Node2DHelpers.get_global_up(self)
	print_debug("pos: ", global_position, " right: ", global_right, " up: ", global_up, "size: ", collider_bounds)

	var rightRayBot = PhysicsRayQueryParameters2D.new()
	rightRayBot.from = global_position + global_right * (collider_bounds.size.x / 2 + rightDetectOffset) + -global_up * (bottomDetectOffset  + sideDetectVerticalOffset)
	rightRayBot.to = rightRayBot.from + global_right * wallDetectionDistance
	rightRayBot.exclude = [get_rid()]
	var rightRayCenter = PhysicsRayQueryParameters2D.new()
	rightRayCenter.from = global_position + global_up * (collider_bounds.size.y / 2) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset)
	rightRayCenter.to = rightRayCenter.from + global_right * wallDetectionDistance
	rightRayCenter.exclude = [get_rid()]
	var rightRayTop = PhysicsRayQueryParameters2D.new()
	rightRayTop.from = global_position + global_up * (collider_bounds.size.y + topDetectOffset + sideDetectVerticalOffset) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset)
	rightRayTop.to = rightRayTop.from + global_right * wallDetectionDistance
	rightRayTop.exclude = [get_rid()]
	currentPhysicals.rightWall = wall_cast(debug_wall_rays, wallMask, [rightRayTop, rightRayCenter, rightRayBot])

	var leftRayBot = PhysicsRayQueryParameters2D.new()
	leftRayBot.from = global_position + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset) + -global_up * (bottomDetectOffset + sideDetectVerticalOffset)
	leftRayBot.to = leftRayBot.from + -global_right * wallDetectionDistance
	leftRayBot.exclude = [get_rid()]
	var leftRayCenter = PhysicsRayQueryParameters2D.new()
	leftRayCenter.from = global_position + global_up * (collider_bounds.size.y / 2) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset)
	leftRayCenter.to = leftRayCenter.from + -global_right * wallDetectionDistance
	leftRayCenter.exclude = [get_rid()]
	var leftRayTop = PhysicsRayQueryParameters2D.new()
	leftRayTop.from = global_position + global_up * (collider_bounds.size.y + topDetectOffset + sideDetectVerticalOffset) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset)
	leftRayTop.to = leftRayTop.from + -global_right * wallDetectionDistance
	leftRayTop.exclude = [get_rid()]
	currentPhysicals.leftWall = wall_cast(debug_wall_rays, wallMask, [leftRayTop, leftRayCenter, leftRayBot])

	var topRightRay = PhysicsRayQueryParameters2D.new()
	topRightRay.from = global_position + global_up * (collider_bounds.size.y + topDetectOffset) + global_right * (collider_bounds.size.x / 2 + rightDetectOffset + verticalDetectSideOffset)
	topRightRay.to = topRightRay.from + global_up * wallDetectionDistance
	topRightRay.exclude = [get_rid()]
	var topCenterRay = PhysicsRayQueryParameters2D.new()
	topCenterRay.from = global_position + global_up * (collider_bounds.size.y + topDetectOffset)
	topCenterRay.to = topCenterRay.from + global_up * wallDetectionDistance
	topCenterRay.exclude = [get_rid()]
	var topLeftRay = PhysicsRayQueryParameters2D.new()
	topLeftRay.from = global_position + global_up * (collider_bounds.size.y + topDetectOffset) + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset + verticalDetectSideOffset)
	topLeftRay.to = topLeftRay.from + global_up * wallDetectionDistance
	topLeftRay.exclude = [get_rid()]
	currentPhysicals.topWall = wall_cast(debug_wall_rays, ceilingMask, [topLeftRay, topCenterRay, topRightRay])

	var botRightRay = PhysicsRayQueryParameters2D.new()
	botRightRay.from = global_position + global_right * (collider_bounds.size.x / 2 + rightDetectOffset + verticalDetectSideOffset) + -global_up * (bottomDetectOffset)
	botRightRay.to = botRightRay.from + -global_up * wallDetectionDistance
	botRightRay.exclude = [get_rid()]
	var botCenterRay = PhysicsRayQueryParameters2D.new()
	botCenterRay.from = global_position + -global_up * (bottomDetectOffset)
	botCenterRay.to = botCenterRay.from + -global_up * wallDetectionDistance
	botCenterRay.exclude = [get_rid()]
	var botLeftRay = PhysicsRayQueryParameters2D.new()
	botLeftRay.from = global_position + -global_right * (collider_bounds.size.x / 2 + leftDetectOffset + verticalDetectSideOffset) + -global_up * (bottomDetectOffset)
	botLeftRay.to = botLeftRay.from + -global_up * wallDetectionDistance
	botLeftRay.exclude = [get_rid()]
	currentPhysicals.botWall = wall_cast(debug_wall_rays, groundMask, [botLeftRay, botCenterRay, botRightRay])

	if debug_wall_rays:
		DebugDraw.draw_box_2d(global_position + global_up * collider_bounds.size.y / 2, collider_bounds.size, Color.GREEN, get_parent())
		DebugDraw.set_text("RightWall", currentPhysicals.rightWall.name if currentPhysicals.rightWall else "null")
		DebugDraw.set_text("LeftWall", currentPhysicals.leftWall.name if currentPhysicals.leftWall else "null")
		DebugDraw.set_text("TopWall", currentPhysicals.topWall.name if currentPhysicals.topWall else "null")
		DebugDraw.set_text("BottomWall", currentPhysicals.botWall.name if currentPhysicals.botWall else "null")
func wall_cast(debug: bool, mask: int, rays: Array[PhysicsRayQueryParameters2D]) -> CollisionObject2D:
	var wall_hit: CollisionObject2D
	for current_ray in rays:
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(current_ray)
		if debug:
			DebugDraw.draw_line_2d(current_ray.from, current_ray.to, Color.GREEN if result else Color.RED, get_parent())
		if result:
			wall_hit = result.collider
			break
	return wall_hit
