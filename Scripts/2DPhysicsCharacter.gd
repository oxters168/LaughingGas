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

@export var deadzone: float = 0.1

@onready var _initial_scale: Vector2 = rendered_flippable_node.scale
var invertFlip: bool
@export var animation_player: AnimationPlayer
@export var rendered_flippable_node: Node2D

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

func _init():
	currentInput = InputData.new()
	prevInput = InputData.new()
	currentPhysicals = PhysicalData.new()

func _process(_delta):
	currentPhysicals.velocity = linear_velocity
	grab_input()
	detect_wall()
	tick_state()
	apply_animation()
	#DebugDraw.set_text("Velocity", Vector2(MathHelpers.to_decimal_places(currentPhysicals.velocity.x, 2), MathHelpers.to_decimal_places(currentPhysicals.velocity.y, 2)))
	#DebugDraw.set_text("CurrentState", SpecificState.keys()[currentState])
	#DebugDraw.set_text("Position", position)
func _physics_process(delta):
	retrieve_surrounding_velocity()
	move_character(delta)
	prevInput = currentInput
	#DebugDraw.set_text("PhysicsDelta", delta)

func grab_input():
	var input_vector = Input.get_vector("move_hor_neg", "move_hor_pos", "move_ver_neg", "move_ver_pos")
	currentInput.horizontal = input_vector.x
	currentInput.vertical = input_vector.y
	currentInput.jump = Input.is_action_pressed("jump")
	currentInput.sprint = Input.is_action_pressed("sprint")

func tick_state():
	var nextState = PhysicsCharacter2D.get_next_state(currentState, prevState, currentInput, currentPhysicals, deadzone)
	prevState = currentState
	currentState = nextState

func apply_animation():
	var flipX: bool = PhysicsCharacter2D.is_facing_right(currentState)
	set_flip_state(!flipX if invertFlip else flipX)
	var prevAnimeState = PhysicsCharacter2D.get_anime_from_state(prevState)
	var currentAnimeState = PhysicsCharacter2D.get_anime_from_state(currentState)
	if (prevAnimeState != currentAnimeState):
		var sent_name = AnimeState.keys()[currentAnimeState]
		var speed_scale = 1
		if currentAnimeState == AnimeState.Walk:
			sent_name = AnimeState.keys()[AnimeState.Run]
			speed_scale = 2
		elif currentAnimeState == AnimeState.Run:
			speed_scale = 4
		set_playing_animation(sent_name, speed_scale)

static func is_facing_right(state: SpecificState) -> bool:
	var right_states = [SpecificState.IdleRight, SpecificState.WalkRight, SpecificState.RunRight, SpecificState.JumpFaceRight, SpecificState.JumpMoveRight, SpecificState.FallFaceRight, SpecificState.FallMoveRight, SpecificState.ClimbRightIdle, SpecificState.ClimbRightUp, SpecificState.ClimbRightDown, SpecificState.ClimbTopIdleRight, SpecificState.ClimbTopMoveRight]
	return right_states.has(state)

func set_flip_state(flipX: bool):
	rendered_flippable_node.scale = Vector2(_initial_scale.x * (1 if flipX else -1), _initial_scale.y)
func set_playing_animation(anime_name: String, speed_scale: float = 1):
	if animation_player != null:
		animation_player.speed_scale = speed_scale
		if (animation_player.has_animation(anime_name)):
			animation_player.play(anime_name)
		else:
			animation_player.play("RESET")

func move_character(delta):
		var horizontalForce: float = 0
		var verticalForce: float = 0

		var prevAnimeState: AnimeState = PhysicsCharacter2D.get_anime_from_state(prevState)
		var currentAnimeState: AnimeState = PhysicsCharacter2D.get_anime_from_state(currentState)
		var isFacingRight = PhysicsCharacter2D.is_facing_right(currentState)

		var otherObjectPredictedVelocity: Vector2 = (otherObjectVelocity - otherObjectPrevVelocity);
		
		var horizontalVelocity: float = 0
		if currentAnimeState == AnimeState.Idle || currentAnimeState == AnimeState.Walk || currentAnimeState == AnimeState.Run || currentAnimeState == AnimeState.SideClimb || currentAnimeState == AnimeState.SideClimbIdle || currentAnimeState == AnimeState.TopClimb || currentAnimeState == AnimeState.TopClimbIdle || currentState == SpecificState.FallMoveLeft || currentState == SpecificState.FallMoveRight || currentState == SpecificState.JumpMoveLeft || currentState == SpecificState.JumpMoveRight:
			if currentAnimeState == AnimeState.TopClimb:
				horizontalVelocity = (1 if isFacingRight else -1) * climbSpeed
			elif currentAnimeState != AnimeState.Idle && currentAnimeState != AnimeState.TopClimbIdle && currentAnimeState != AnimeState.SideClimb && currentAnimeState != AnimeState.SideClimbIdle:
				if !currentInput.sprint:
					horizontalVelocity = (1 if isFacingRight else -1) * walkSpeed
				else:
					horizontalVelocity = (1 if isFacingRight else -1) * runSeed
		horizontalForce = PhysicsHelpers.calculate_required_force_for_speed_1d(mass, linear_velocity.x, (otherObjectVelocity.x + otherObjectPredictedVelocity.x) + horizontalVelocity, delta)

		if currentAnimeState == AnimeState.SideClimb || currentAnimeState == AnimeState.SideClimbIdle || currentAnimeState == AnimeState.TopClimb || currentAnimeState == AnimeState.TopClimbIdle || (currentAnimeState == AnimeState.Jump && prevAnimeState != AnimeState.Jump):
			var verticalSpeed: float = 0
			if currentState == SpecificState.ClimbRightUp || currentState == SpecificState.ClimbLeftUp:
				verticalSpeed = -climbSpeed
			elif currentState == SpecificState.ClimbLeftDown || currentState == SpecificState.ClimbRightDown:
				verticalSpeed = climbSpeed
			elif currentAnimeState != AnimeState.SideClimbIdle && currentAnimeState != AnimeState.TopClimb && currentAnimeState != AnimeState.TopClimbIdle:
				if abs(currentInput.horizontal) > deadzone && currentInput.sprint:
					verticalSpeed = -runJumpSpeed
				else:
					verticalSpeed = -walkJumpSpeed
			
			verticalForce = PhysicsHelpers.calculate_required_force_for_speed_1d(mass, linear_velocity.y, (otherObjectVelocity.y + otherObjectPredictedVelocity.y) + verticalSpeed, delta, true)

		# Added weight when falling for better feel
		if currentAnimeState == AnimeState.AirFall && currentPhysicals.velocity.y < -Constants.EPSILON:
			verticalForce -= mass * addedFallAcceleration

		# When the jump button stops being held then stop ascending
		if currentAnimeState == AnimeState.Jump && currentPhysicals.velocity.y > 0 && prevInput.jump && !currentInput.jump:
			verticalForce = PhysicsHelpers.calculate_required_force_for_speed_1d(mass, linear_velocity.y, 0, delta)
		
		#DebugDraw.set_text("HorizontalForce:", horizontalForce)
		#DebugDraw.set_text("VerticalForce:", verticalForce)
		if abs(horizontalForce) > Constants.EPSILON:
			apply_central_force(Vector2.RIGHT * horizontalForce)
		if abs(verticalForce) > Constants.EPSILON:
			apply_central_force(Vector2.DOWN * verticalForce)

func detect_wall():
	var collider = NodeHelpers.get_child_of_type(self, CollisionShape2D)
	collider_bounds = collider.shape.get_rect()
	var global_right = Node2DHelpers.get_global_right(self)
	var global_up = Node2DHelpers.get_global_up(self)
	# print_debug("pos: ", global_position, " right: ", global_right, " up: ", global_up, "size: ", collider_bounds)

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

func retrieve_surrounding_velocity():
	otherObjectPrevVelocity = otherObjectVelocity;
	# Get other object's velocity if climbing or standing on it to keep up with it
	if (currentPhysicals.rightWall != null && (currentState == SpecificState.ClimbRightIdle || currentState == SpecificState.ClimbRightUp || currentState == SpecificState.ClimbRightDown)):
		var rightWallPhysics = currentPhysicals.rightWall
		if (rightWallPhysics != null && rightWallPhysics is RigidBody2D):
			otherObjectVelocity = (rightWallPhysics as RigidBody2D).linear_velocity
	elif (currentPhysicals.leftWall != null && (currentState == SpecificState.ClimbLeftIdle || currentState == SpecificState.ClimbLeftUp || currentState == SpecificState.ClimbLeftDown)):
		var leftWallPhysics = currentPhysicals.leftWall
		if (leftWallPhysics != null && leftWallPhysics is RigidBody2D):
			otherObjectVelocity = (leftWallPhysics as RigidBody2D).linear_velocity
	elif (currentPhysicals.topWall != null && (currentState == SpecificState.ClimbTopIdleLeft || currentState == SpecificState.ClimbTopIdleRight || currentState == SpecificState.ClimbTopMoveLeft || currentState == SpecificState.ClimbTopMoveRight)):
		var topWallPhysics = currentPhysicals.topWall
		if (topWallPhysics != null && topWallPhysics is RigidBody2D):
			otherObjectVelocity = (topWallPhysics as RigidBody2D).linear_velocity
	elif (currentPhysicals.botWall != null):
		var botWallPhysics = currentPhysicals.botWall
		if (botWallPhysics != null && botWallPhysics is RigidBody2D):
			otherObjectVelocity = (botWallPhysics as RigidBody2D).linear_velocity #Might want to remove y value because object is below us and we are only standing on it, not grabbing on to it

	# Cancel out any velocities that can't be achieved
	if ((currentPhysicals.rightWall && otherObjectVelocity.x > Constants.EPSILON) || (currentPhysicals.leftWall && otherObjectVelocity.x < -Constants.EPSILON)):
			otherObjectVelocity = Vector2(0, otherObjectVelocity.y)
	if ((currentPhysicals.topWall && otherObjectVelocity.y > Constants.EPSILON) || (currentPhysicals.botWall && otherObjectVelocity.y < -Constants.EPSILON)):
			otherObjectVelocity = Vector2(otherObjectVelocity.x, 0)

static func get_next_state(currentState: SpecificState, prevState: SpecificState, currentInput: InputData, currentPhysicals: PhysicalData, deadzone: float = Constants.EPSILON) -> SpecificState:
	var nextState = currentState

	if (currentState == SpecificState.IdleLeft):
		if (currentInput.horizontal > deadzone):
			nextState = SpecificState.IdleRight
		elif (currentInput.sprint && currentInput.horizontal < -deadzone):
			nextState = SpecificState.RunLeft
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.WalkLeft
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallFaceLeft
		elif (currentInput.jump):
			nextState = SpecificState.JumpFaceLeft
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleLeft
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallFaceLeft
	if (currentState == SpecificState.IdleRight):
		if (currentInput.sprint && currentInput.horizontal > deadzone):
			nextState = SpecificState.RunRight;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.WalkRight;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.IdleLeft;
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.jump):
			nextState = SpecificState.JumpFaceRight;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleRight;
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.WalkLeft):
		if (currentInput.sprint && currentInput.horizontal < -deadzone):
			nextState = SpecificState.RunLeft;
		elif (currentInput.horizontal > -deadzone):
			nextState = SpecificState.IdleLeft;
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveLeft;
		elif (currentInput.jump):
			nextState = SpecificState.JumpMoveLeft;
		elif (currentPhysicals.leftWall):
			nextState = SpecificState.ClimbLeftIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveLeft;
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallMoveLeft;
	if (currentState == SpecificState.WalkRight):
		if (currentInput.sprint && currentInput.horizontal > deadzone):
			nextState = SpecificState.RunRight;
		elif (currentInput.horizontal < deadzone):
			nextState = SpecificState.IdleRight;
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveRight;
		elif (currentInput.jump):
			nextState = SpecificState.JumpMoveRight;
		elif (currentPhysicals.rightWall):
			nextState = SpecificState.ClimbRightIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveRight;
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallMoveRight;
	if (currentState == SpecificState.RunLeft):
		if (!currentInput.sprint && currentInput.horizontal < -deadzone):
			nextState = SpecificState.WalkLeft;
		elif (currentInput.horizontal > -deadzone):
			nextState = SpecificState.IdleLeft;
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveLeft;
		elif (currentInput.jump):
			nextState = SpecificState.JumpMoveLeft;
		elif (currentPhysicals.leftWall):
			nextState = SpecificState.ClimbLeftIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveLeft;
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallMoveLeft;
	if (currentState == SpecificState.RunRight):
		if (!currentInput.sprint && currentInput.horizontal > deadzone):
			nextState = SpecificState.WalkRight;
		elif (currentInput.horizontal < deadzone):
			nextState = SpecificState.IdleRight;
		elif (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveRight;
		elif (currentInput.jump):
			nextState = SpecificState.JumpMoveRight;
		elif (currentPhysicals.rightWall):
			nextState = SpecificState.ClimbRightIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveRight;
		elif (!currentPhysicals.botWall):
			nextState = SpecificState.FallMoveRight;
	if (currentState == SpecificState.JumpFaceLeft):
		if (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.JumpMoveLeft;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.JumpFaceRight;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleLeft;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleLeft;
	if (currentState == SpecificState.JumpFaceRight):
		if (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.JumpMoveRight;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.JumpFaceLeft;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleRight;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleRight;
	if (currentState == SpecificState.JumpMoveLeft):
		if (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveLeft;
		elif (currentInput.horizontal > -deadzone):
			nextState = SpecificState.JumpFaceLeft;
		elif (currentPhysicals.botWall && currentInput.sprint && currentInput.horizontal < -deadzone):
			nextState = SpecificState.RunLeft;
		elif (currentPhysicals.botWall && currentInput.horizontal < -deadzone):
			nextState = SpecificState.WalkLeft;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleLeft;
		elif (currentPhysicals.leftWall):
			nextState = SpecificState.ClimbLeftIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveLeft;
	if (currentState == SpecificState.JumpMoveRight):
		if (currentPhysicals.velocity.y < -deadzone):
			nextState = SpecificState.FallMoveRight;
		elif (currentInput.horizontal < deadzone):
			nextState = SpecificState.JumpFaceRight;
		elif (currentPhysicals.botWall && currentInput.sprint && currentInput.horizontal > deadzone):
			nextState = SpecificState.RunRight;
		elif (currentPhysicals.botWall && currentInput.horizontal > deadzone):
			nextState = SpecificState.WalkRight;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleRight;
		elif (currentPhysicals.rightWall):
			nextState = SpecificState.ClimbRightIdle;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopMoveRight;
	if (currentState == SpecificState.FallFaceLeft):
		if (currentPhysicals.botWall):
			nextState = SpecificState.IdleLeft;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.FallMoveLeft;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.FallFaceRight):
		if (currentPhysicals.botWall):
			nextState = SpecificState.IdleRight;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.FallMoveRight;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.FallMoveLeft):
		if (currentPhysicals.botWall && currentInput.sprint && currentInput.horizontal < -deadzone):
			nextState = SpecificState.RunLeft;
		elif (currentPhysicals.botWall && currentInput.horizontal < -deadzone):
			nextState = SpecificState.WalkLeft;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleLeft;
		elif (currentInput.horizontal > -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentPhysicals.leftWall):
			nextState = SpecificState.ClimbLeftIdle;
	if (currentState == SpecificState.FallMoveRight):
		if (currentPhysicals.botWall && currentInput.sprint && currentInput.horizontal > deadzone):
			nextState = SpecificState.RunRight;
		elif (currentPhysicals.botWall && currentInput.horizontal > deadzone):
			nextState = SpecificState.WalkRight;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.IdleRight;
		elif (currentInput.horizontal < deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentPhysicals.rightWall):
			nextState = SpecificState.ClimbRightIdle;
	if (currentState == SpecificState.ClimbLeftIdle):
		if (currentInput.horizontal > -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbLeftUp;
		elif (currentInput.vertical < -deadzone && !currentPhysicals.botWall):
			nextState = SpecificState.ClimbLeftDown;
		elif (!currentPhysicals.leftWall):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.ClimbRightIdle):
		if (currentInput.horizontal < deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbRightUp;
		elif (currentInput.vertical < -deadzone && !currentPhysicals.botWall):
			nextState = SpecificState.ClimbRightDown;
		elif (!currentPhysicals.rightWall):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.ClimbLeftUp):
		if (currentInput.horizontal > -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.vertical < deadzone):
			nextState = SpecificState.ClimbLeftIdle;
		elif (!currentPhysicals.leftWall):
			nextState = SpecificState.FallMoveLeft;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleLeft;
		elif (!currentPhysicals.leftWall):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.ClimbRightUp):
		if (currentInput.horizontal < deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentInput.vertical < deadzone):
			nextState = SpecificState.ClimbRightIdle;
		elif (!currentPhysicals.rightWall):
			nextState = SpecificState.FallMoveRight;
		elif (currentPhysicals.topWall && currentInput.vertical > deadzone):
			nextState = SpecificState.ClimbTopIdleRight;
		elif (!currentPhysicals.rightWall):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.ClimbLeftDown):
		if (currentInput.horizontal > -deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.vertical > -deadzone):
			nextState = SpecificState.ClimbLeftIdle;
		elif (!currentPhysicals.leftWall):
			nextState = SpecificState.FallMoveLeft;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.ClimbLeftIdle;
		elif (!currentPhysicals.leftWall):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.ClimbRightDown):
		if (currentInput.horizontal < deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentInput.vertical > -deadzone):
			nextState = SpecificState.ClimbRightIdle;
		elif (!currentPhysicals.rightWall):
			nextState = SpecificState.FallMoveRight;
		elif (currentPhysicals.botWall):
			nextState = SpecificState.ClimbRightIdle;
		elif (!currentPhysicals.rightWall):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.ClimbTopIdleLeft):
		if (currentInput.vertical < deadzone):
			nextState = SpecificState.FallFaceLeft;
		elif (currentInput.horizontal < -deadzone && !currentPhysicals.leftWall):
			nextState = SpecificState.ClimbTopMoveLeft;
		elif (currentInput.horizontal > deadzone):
			nextState = SpecificState.ClimbTopIdleRight;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.ClimbTopIdleRight):
		if (currentInput.vertical < deadzone):
			nextState = SpecificState.FallFaceRight;
		elif (currentInput.horizontal > deadzone && !currentPhysicals.rightWall):
			nextState = SpecificState.ClimbTopMoveRight;
		elif (currentInput.horizontal < -deadzone):
			nextState = SpecificState.ClimbTopIdleLeft;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallFaceRight;
	if (currentState == SpecificState.ClimbTopMoveLeft):
		if (currentInput.vertical < deadzone):
			nextState = SpecificState.FallMoveLeft;
		elif (currentInput.horizontal > -deadzone):
			nextState = SpecificState.ClimbTopIdleLeft;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallMoveLeft;
		elif (currentPhysicals.leftWall):
			nextState = SpecificState.ClimbTopIdleLeft;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallFaceLeft;
	if (currentState == SpecificState.ClimbTopMoveRight):
		if (currentInput.vertical < deadzone):
			nextState = SpecificState.FallMoveRight;
		elif (currentInput.horizontal < deadzone):
			nextState = SpecificState.ClimbTopIdleRight;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallMoveRight;
		elif (currentPhysicals.rightWall):
			nextState = SpecificState.ClimbTopIdleRight;
		elif (!currentPhysicals.topWall):
			nextState = SpecificState.FallFaceRight;
	return nextState

static func get_anime_from_state(state: SpecificState) -> AnimeState:
	var animeState = AnimeState.Idle

	if [SpecificState.WalkLeft, SpecificState.WalkRight].has(state):
		animeState = AnimeState.Walk
	if [SpecificState.IdleLeft, SpecificState.IdleRight].has(state):
		animeState = AnimeState.Idle
	if [SpecificState.RunLeft, SpecificState.RunRight].has(state):
		animeState = AnimeState.Run
	if [SpecificState.JumpFaceLeft, SpecificState.JumpFaceRight, SpecificState.JumpMoveLeft, SpecificState.JumpMoveRight].has(state):
		animeState = AnimeState.Jump
	if [SpecificState.FallFaceLeft, SpecificState.FallFaceRight, SpecificState.FallMoveLeft, SpecificState.FallMoveRight].has(state):
		animeState = AnimeState.AirFall
	if [SpecificState.ClimbLeftIdle, SpecificState.ClimbRightIdle].has(state):
		animeState = AnimeState.SideClimbIdle
	if [SpecificState.ClimbLeftUp, SpecificState.ClimbLeftDown, SpecificState.ClimbRightUp, SpecificState.ClimbRightDown].has(state):
		animeState = AnimeState.SideClimb
	if [SpecificState.ClimbTopIdleLeft, SpecificState.ClimbTopIdleRight].has(state):
		animeState = AnimeState.TopClimbIdle
	if [SpecificState.ClimbTopMoveLeft, SpecificState.ClimbTopMoveRight].has(state):
		animeState = AnimeState.TopClimb

	return animeState
