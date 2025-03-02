@tool

class_name LineSegment

extends MeshInstance3D

@export var from: Vector3:
	set(value):
		from = value
		update_segment()

@export var to: Vector3:
	set(value):
		to = value
		update_segment()


func _ready():
	update_segment()


func update_segment():
	if not is_inside_tree():
		return
	position = from
	if from != to:
		look_at(to)
		position = (from + to) / 2
		scale.z = from.distance_to(to)
