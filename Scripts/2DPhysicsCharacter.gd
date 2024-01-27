extends RigidBody2D

class InputData:
  var horizontal: float
  var vertical: float
  var jump: bool
  var sprint: bool
class PhysicalData:
  var velocity: Vector2
  var leftWall: CollisionShape2D
  var rightWall: CollisionShape2D
  var topWall: CollisionShape2D
  var botWall: CollisionShape2D

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

var invertFlip: bool

@export var leftDetectOffset: float
@export var rightDetectOffset: float
@export var topDetectOffset: float
@export var bottomDetectOffset: float
@export var sideDetectVerticalOffset: float
@export var verticalDetectSideOffset: float

@export var debugWallRays: bool = true
var colliderBounds: Rect2

var otherObjectVelocity: Vector2
var otherObjectPrevVelocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  currentPhysicals.velocity = linear_velocity

# func detect_wall()
#   colliderBounds = transform.GetTotalBounds(Space.Self, true);

#   var rightRayBot = new Ray2D(transform.position + transform.right * (colliderBounds.size.x / 2 + rightDetectOffset) + -transform.up * (bottomDetectOffset  + sideDetectVerticalOffset), transform.right);
#   var rightRayCenter = new Ray2D(transform.position + transform.up * (colliderBounds.extents.y) + transform.right * (colliderBounds.extents.x + rightDetectOffset), transform.right);
#   var rightRayTop = new Ray2D(transform.position + transform.up * (colliderBounds.size.y + topDetectOffset + sideDetectVerticalOffset) + transform.right * (colliderBounds.size.x / 2 + rightDetectOffset), transform.right);
#   currentPhysicals.rightWall = WallCast(debugWallRays, wallMask, rightRayTop, rightRayCenter, rightRayBot);

#   var leftRayBot = new Ray2D(transform.position + -transform.right * (colliderBounds.size.x / 2 + leftDetectOffset) + -transform.up * (bottomDetectOffset + sideDetectVerticalOffset), -transform.right);
#   var leftRayCenter = new Ray2D(transform.position + transform.up * (colliderBounds.extents.y) + -transform.right * (colliderBounds.extents.x + leftDetectOffset), -transform.right);
#   var leftRayTop = new Ray2D(transform.position + transform.up * (colliderBounds.size.y + topDetectOffset + sideDetectVerticalOffset) + -transform.right * (colliderBounds.size.x / 2 + leftDetectOffset), -transform.right);
#   currentPhysicals.leftWall = WallCast(debugWallRays, wallMask, leftRayTop, leftRayCenter, leftRayBot);

#   var topRightRay = new Ray2D(transform.position + transform.up * (colliderBounds.size.y + topDetectOffset) + transform.right * (colliderBounds.extents.x + rightDetectOffset + verticalDetectSideOffset), transform.up);
#   var topCenterRay = new Ray2D(transform.position + transform.up * (colliderBounds.size.y + topDetectOffset), transform.up);
#   var topLeftRay = new Ray2D(transform.position + transform.up * (colliderBounds.size.y + topDetectOffset) + -transform.right * (colliderBounds.extents.x + leftDetectOffset + verticalDetectSideOffset), transform.up);
#   currentPhysicals.topWall = WallCast(debugWallRays, ceilingMask, topLeftRay, topCenterRay, topRightRay);

#   var botRightRay = new Ray2D(transform.position + transform.right * (colliderBounds.extents.x + rightDetectOffset + verticalDetectSideOffset) + -transform.up * (bottomDetectOffset), -transform.up);
#   var botCenterRay = new Ray2D(transform.position + -transform.up * (bottomDetectOffset), -transform.up);
#   var botLeftRay = new Ray2D(transform.position + -transform.right * (colliderBounds.extents.x + leftDetectOffset + verticalDetectSideOffset) + -transform.up * (bottomDetectOffset), -transform.up);
#   currentPhysicals.botWall = WallCast(debugWallRays, groundMask, botLeftRay, botCenterRay, botRightRay);
func wall_cast(debug: bool, mask: int, rays: Array[PhysicsRayQueryParameters2D]) -> CollisionShape2D:
  var wall_hit: CollisionShape2D
  for current_ray in rays:
    var space_state = get_world_2d().direct_space_state
    var result = space_state.intersect_ray(current_ray)
    if result:
      wall_hit = result.collider
      break
  return wall_hit
  # Collider2D wallHit = null;
  # foreach (var rightRay in rays)
  # {
  #     var rightHitInfo = Physics2D.Raycast(rightRay.origin, rightRay.direction, wallDetectionDistance, mask);
  #     if (debug)
  #         Debug.DrawRay(rightRay.origin, rightRay.direction * wallDetectionDistance, rightHitInfo.transform != null ? Color.green : Color.red);
  #     if (rightHitInfo)
  #     {
  #         wallHit = rightHitInfo.collider;
  #         break;
  #     }
  # }
  # return wallHit;
