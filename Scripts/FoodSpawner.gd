extends Node2D
class_name FoodSpawner

#var _food_stuff_prefab
var _spawned_food_stuff: Array
@export var prefab: PackedScene
@export var continuously_spawn: bool
@export var start_food_count: int = 100
@export var spawn_width: float = 512
@export var spawn_height: float = 1100
@export var spawn_time: float = 0.2
@export var despawn_dist: float = 1200

var _time_passed: float

# Called when the node enters the scene tree for the first time.
#func _init():
	#_food_stuff_prefab = load("res://Prefabs/food_stuff.tscn")

func _ready():
	for i in start_food_count:
		spawn_food(Vector2.ZERO, spawn_width, spawn_height)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var to_be_removed = []
	for food_stuff in _spawned_food_stuff:
		if food_stuff.position.y > despawn_dist:
			to_be_removed.append(food_stuff)
	for food_stuff in to_be_removed:
		_spawned_food_stuff.erase(food_stuff)
		food_stuff.queue_free()
		
	_time_passed += delta
	if _time_passed > spawn_time:
		_time_passed = 0
		spawn_food(Vector2.ZERO, spawn_width, 0)
	

func spawn_food(pos: Vector2, width: float, height: float):
	var food_stuff = prefab.instantiate()
	_spawned_food_stuff.append(food_stuff)
	
	var rand_ver_offset = Vector2.DOWN * randf_range(0, height)
	var rand_hor_offset = Vector2.RIGHT * randf_range(0, width) - Vector2.RIGHT * (width / 2)
	food_stuff.position = pos + rand_hor_offset + rand_ver_offset
	food_stuff.rotation = randf_range(0, 359)
	add_child(food_stuff)
