class_name Building

extends BaseUnit

@export var cost: float = 1000
@export var spawned_unit: PackedScene
@export var unit_spawn_time: float = 10
@export var unit_spawn_distance: float = 3

var current_unit_spawn_time: float = 0


func _spawn_unit() -> void:
	if spawned_unit == null:
		return
	var new_unit: BaseUnit = spawned_unit.instantiate()
	new_unit.player = self.player

	var spawn_offset: Vector3 = Vector3(unit_spawn_distance, 0, 0).rotated(
		Vector3.UP, randf_range(0, 360)
	)

	new_unit.transform = global_transform
	new_unit.position += spawn_offset
	get_tree().get_root().add_child(new_unit)


func _process(delta: float) -> void:
	super(delta)

	current_unit_spawn_time += delta

	if current_unit_spawn_time >= unit_spawn_time:
		current_unit_spawn_time = 0
		_spawn_unit()
