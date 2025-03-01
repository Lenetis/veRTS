class_name PlayerCamera

extends Camera3D

@onready var raycast = $RayCast3D

@export var player: PlayerController

@export_category("Satellite")
@export var satellite_position_offset: Vector3 = Vector3(0, 30, 0)
@export var satellite_rotation: Vector3 = Vector3(-90, 0, 0)
@export var satellite_lerp_weight: float = 10
@export var satellite_move_speed_far: float = 50  # move speed on max zoom-out. Should be greater or equal than satellite_move_speed_near
@export var satellite_move_speed_near: float = 15  # move speed on max zoom-in. Should be lesser or equal than satellite_move_speed_far
@export var satellite_zoom_speed: float = 15
@export var satellite_max_height: float = 50
@export var satellite_min_height: float = 20

@export_category("Unit")
@export var unit_position_offset: Vector3 = Vector3(0, 5, 0)
@export var unit_rotation: Vector3 = Vector3(-30, 0, 0)
@export var unit_lerp_weight: float = 5

var target_position: Vector3 = position
var target_rotation: Vector3 = rotation_degrees

var move_vector: Vector3

# 0 - no zoom, 1 - unzoom, -1 - zoom
var zoom_direction: int


func _ready() -> void:
	player.view_toggled.connect(change_view)
	change_view(player.current_view)

	player.satellite_move.connect(on_move)
	player.satellite_zoom.connect(on_zoom)
	player.satellite_unzoom.connect(on_unzoom)
	player.satellite_select.connect(on_select)
	player.satellite_deselect.connect(on_deselect)
	player.satellite_order.connect(on_order)
	player.satellite_cancel_order.connect(on_cancel_order)
	player.satellite_weapon.connect(on_weapon)
	player.satellite_weapon2.connect(on_weapon2)


func change_view(view_mode: ViewMode.Mode) -> void:
	print("Camera change")
	if view_mode == ViewMode.Mode.SATELLITE:
		target_rotation = satellite_rotation
	else:
		target_rotation = unit_rotation


func on_move(direction: Vector2) -> void:
	move_vector = Vectors.to_vector3(direction.normalized())


func on_zoom() -> void:
	zoom_direction = -1


func on_unzoom() -> void:
	zoom_direction = 1


func on_select() -> void:
	var unit: BaseUnit = raycast.get_collider() as BaseUnit
	if unit != null:
		unit.activate()


func on_deselect() -> void:
	#var unit: BaseUnit = raycast.get_collider() as BaseUnit
	#if unit != null:
	#	unit.deactivate()
	for unit in player.active_units:  # deselect all units
		unit.deactivate()


func on_order() -> void:
	for unit in player.active_units:
		unit.add_destination(Vectors.to_vector2(target_position))


func on_cancel_order() -> void:
	for unit in player.active_units:
		unit.pop_destination()


func on_weapon() -> void:
	print("BUM")


func on_weapon2() -> void:
	print("BUM2")


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
	_process_zoom(delta)
	_process_move(delta)

	position = position.lerp(
		target_position + satellite_position_offset, satellite_lerp_weight * delta
	)
	rotation_degrees = rotation_degrees.lerp(target_rotation, satellite_lerp_weight * delta)


func _process_zoom(delta: float) -> void:
	if zoom_direction == 0:
		return

	satellite_position_offset.y += zoom_direction * satellite_zoom_speed * delta
	if satellite_position_offset.y > satellite_max_height:
		satellite_position_offset.y = satellite_max_height
	elif satellite_position_offset.y < satellite_min_height:
		satellite_position_offset.y = satellite_min_height
	zoom_direction = 0


func _process_move(delta: float) -> void:
	if move_vector == Vector3.ZERO:
		return

	# how high the target is: 0 - min_height; 1 - max_height
	var height_percentage: float = (
		(satellite_position_offset.y - satellite_min_height)
		/ (satellite_max_height - satellite_min_height)
	)
	var move_speed: float = (
		satellite_move_speed_near
		+ height_percentage * (satellite_move_speed_far - satellite_move_speed_near)
	)
	target_position += move_vector * move_speed * delta
	move_vector = Vector3.ZERO
