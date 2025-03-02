class_name PlayerCamera

extends Camera3D

## NEEDS TO BE A CHILD OF PLAYER CONTROLLER

@onready var raycast = $RayCast3D
@onready var base_raycast = $RayCast3DBase

@export var player: PlayerController

@export_category("Orbital Shooting")
@export var projectile_small: PackedScene
@export var cooldown_small: float = 0.25
@export var projectile_big: PackedScene
@export var cooldown_big: float = 10

var current_cooldown_small: float = 0
var current_cooldown_big: float = 0

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
@export var unit_position_offset: Vector3 = Vector3(0, 10, 16)
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
	player.satellite_build.connect(on_build)
	player.satellite_build2.connect(on_build2)

	for i in range(1, 10):
		set_cull_mask_value(i, false)

	set_cull_mask_value(1, true)  # objects that are always visible
	set_cull_mask_value(player.get_normal_visibility_layer(), true)  # player world UI (selection markers etc)
	update_cull_mask()


func update_cull_mask() -> void:
	if player.current_view == ViewMode.Mode.SATELLITE:
		set_cull_mask_value(player.get_satellite_visibility_layer(), true)
	else:
		set_cull_mask_value(player.get_satellite_visibility_layer(), false)


func change_view(view_mode: ViewMode.Mode) -> void:
	print("Camera change")
	if view_mode == ViewMode.Mode.SATELLITE:
		target_rotation = satellite_rotation
	else:
		target_rotation = unit_rotation

	update_cull_mask()


func try_build(building: PackedScene) -> void:
	var base: PlayerBase = base_raycast.get_collider() as PlayerBase
	if base != null and base.player == player:
		var build_position: Vector3 = base_raycast.get_collision_point()
		build_position.y = 0
		var new_building: Building = building.instantiate()
		if not player.pay_money(new_building.cost):
			new_building.queue_free()  # this is very stupid and I am sorry
			return
		new_building.player = player
		new_building.position = build_position
		get_tree().get_root().get_children()[0].add_child(new_building)
	else:
		print("Cannot build")


func try_shoot(projectile: PackedScene) -> bool:
	var collider: Area3D = base_raycast.get_collider()
	var ok: bool = false
	if collider != null and collider.is_in_group("ground"):
		ok = true
	else:
		var base: PlayerBase = collider as PlayerBase
		if base != null and base.player == player:
			ok = true

	if ok:
		var new_projectile: BaseProjectile = projectile.instantiate()
		new_projectile.position = base_raycast.get_collision_point()
		new_projectile.position.y = 0
		new_projectile.player = player
		get_tree().get_root().get_children()[0].add_child(new_projectile)
		return true
	return false


func on_move(direction: Vector2) -> void:
	move_vector = Vectors.to_vector3(direction.normalized())
	# spaghetti, cancelling the rotation that the parent has made
	move_vector = move_vector.rotated(Vector3.UP, -get_parent().rotation.y)


func on_zoom() -> void:
	zoom_direction = -1


func on_unzoom() -> void:
	zoom_direction = 1


func on_select() -> void:
	var unit: BaseUnit = raycast.get_collider() as BaseUnit
	if unit != null and unit.player == player:
		unit.activate()


func on_deselect() -> void:
	#var unit: BaseUnit = raycast.get_collider() as BaseUnit
	#if unit != null:
	#	unit.deactivate()
	for unit in player.active_units:  # deselect all units
		unit.deactivate()


func on_order() -> void:
	for unit in player.active_units:
		unit.add_destination(Vectors.to_vector2(get_parent().to_global(target_position)))


func on_cancel_order() -> void:
	for unit in player.active_units:
		unit.pop_back_destination()


func on_weapon() -> void:
	if current_cooldown_small >= cooldown_small:
		if try_shoot(projectile_small):
			current_cooldown_small = 0


func on_weapon2() -> void:
	if current_cooldown_big >= cooldown_big:
		if try_shoot(projectile_big):
			current_cooldown_big = 0


func on_build() -> void:
	try_build(player.buildings[0])


func on_build2() -> void:
	try_build(player.buildings[1])


func _process(delta: float) -> void:
	match player.current_view:
		ViewMode.Mode.UNIT:
			_unit_process(delta)
		ViewMode.Mode.SATELLITE:
			_satellite_process(delta)

	current_cooldown_small += delta
	current_cooldown_big += delta


func _unit_process(delta: float) -> void:
	position = position.lerp(target_position + unit_position_offset, unit_lerp_weight * delta)
	rotation_degrees = rotation_degrees.lerp(target_rotation, unit_lerp_weight * delta)

	if player.active_units.size() > 0:
		var center_position: Vector3 = Vector3.ZERO
		for unit in player.active_units:
			center_position += unit.position
		center_position /= player.active_units.size()
		target_position = get_parent().to_local(center_position)


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
