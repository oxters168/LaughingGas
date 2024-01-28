extends Path2D
class_name PathNodes2D
@export var path_nodes : Array[PathNode2D]

func _ready(): 
	for path_node in path_nodes: 
		curve.add_point(path_node.position)
