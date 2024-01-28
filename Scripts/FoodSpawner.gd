extends Node2D
class_name FoodSpawner

var _food_stuff_prefab
var _spawned_food_stuff: Array
@export var spawn_length: float
@export var spawn_time: float = 0.5

var _time_passed: float

# Called when the node enters the scene tree for the first time.
func _init():
	_food_stuff_prefab = load("res://Prefabs/food_stuff.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_time_passed += delta
	if _time_passed > spawn_time:
		_time_passed = 0
		var food_stuff = _food_stuff_prefab.instantiate()
		var rand_offset = Vector2.RIGHT * randf_range(0, spawn_length) - Vector2.RIGHT * (spawn_length / 2)
		food_stuff.global_position = global_position + rand_offset
		add_child(food_stuff)
