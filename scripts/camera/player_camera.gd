class_name PlayerCamera

extends Camera3D

@export var player: PlayerController

@export_category("Satellite")
@export var satellite_position_offset: Vector3 = Vector3(0, 30, 0)
@export var satellite_rotation: Vector3 = Vector3(-90, 0, 0)
@export var satellite_lerp_weight: float = 5
@export var satellite_move_speed: float = 5

@export_category("Unit")
@export var unit_position_offset: Vector3 = Vector3(0, 5, 0)
@export var unit_rotation: Vector3 = Vector3(-30, 0, 0)
@export var unit_lerp_weight: float = 5

var target_position: Vector3 = position
var target_rotation: Vector3 = rotation_degrees

var move_vector: Vector3


func _ready() -> void:
	player.view_toggled.connect(change_view)
	change_view(player.current_view)

	player.satellite_move.connect(on_move)
	player.satellite_action.connect(on_action)
	player.satellite_secondary.connect(on_secondary)


func change_view(view_mode: ViewMode.Mode) -> void:
	print("Camera change")
	if view_mode == ViewMode.Mode.SATELLITE:
		target_rotation = satellite_rotation
	else:
		target_rotation = unit_rotation


func _process(delta: float) -> void:
	match player.current_view:
		ViewMode.Mode.UNIT:
			_unit_process(delta)
		ViewMode.Mode.SATELLITE:
			_satellite_process(delta)


func _unit_process(delta: float) -> void:
	position = position.lerp(target_position + unit_position_offset, unit_lerp_weight * delta)
	rotation_degrees = rotation_degrees.lerp(target_rotation, unit_lerp_weight * delta)


func _satellite_process(delta: float) -> void:
	target_position += move_vector
	move_vector = Vector3.ZERO
	position = position.lerp(
		target_position + satellite_position_offset, satellite_lerp_weight * delta
	)
	rotation_degrees = rotation_degrees.lerp(target_rotation, satellite_lerp_weight * delta)


func on_move(direction: Vector2) -> void:
	move_vector = Vectors.to_vector3(direction.normalized())


func on_action() -> void:
	print("sAction!")


func on_secondary() -> void:
	print("sSecondary!")
