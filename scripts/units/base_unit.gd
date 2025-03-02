class_name BaseUnit

extends RigidBody3D

## WARNING, UNIT NEEDS A CANNON AS ITS DIRECT CHILD IF IT IS SUPPOSED TO SHOOT

const LINE_SEGMENT = preload("res://scenes/ui/line_segment.tscn")

@onready var range_area = $RangeArea3D
@onready var range_area_shape = $RangeArea3D/CollisionShape3D
var cannon: Cannon
var selection_marker: VisualInstance3D

## When a new destination is added, that is closer
## to the last destination than this value, it will be skipped
const MIN_NEW_DESTINATION_DISTANCE: float = 0.1

## Manual movement will last for this long after the move key is released. Must be greater than 0!
const MANUAL_MOVE_TIME: float = 0.05

## The unit considers itself stuck if it moves with this fraction of its maximum speed
const STUCK_SPEED_FRACTION: float = 0.125

## The unit cancels its current order after being stuck for this long
const STUCK_TIME_TO_CANCEL_ORDER: float = 1

## Autofiring units are waiting (AUTO_FIRE_DELAY * cooldown) longer to shoot
const AUTO_FIRE_DELAY = 0.3333

## The owner of this unit
@export var player: PlayerController

## Buildings are immovable
@export var movable: bool = true

## If true, the unit will start in game as selected
@export var start_selected: bool = false
@export var selectable: bool = true

@export_category("Stats")
@export var hp: float = 100
@export var cooldown: float = 2
@export var attack_range: float = 15
@export var speed: float = 2
@export var turn_speed: float = 90
@export var turn_in_place: bool = true
## Used if turn_in_place is true. If the angle towards the target is greater than this angle,
## the unit will stay in place and just turn. Otherwise it will both move and turn.
@export var max_move_angle: float = 91

# the unit needs to wait this time before being able to shoot again
var current_cooldown: float

# current value of the unit's hp. If it reaches 0, the unit dies
var current_hp: float

# array of global positions where the unit wants to go
var destinations: Array[Vector2]

# line segments leading between destinations
var line_segments: Array[LineSegment]

# whether the unit listens and reacts to the owner signals
var active: bool = false

# time the unit feels stuck
var stuck_time: float = 0


func _ready() -> void:
	axis_lock_linear_y = true
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	if has_node("Cannon"):
		cannon = $Cannon

	if has_node("SelectionMarker"):
		selection_marker = $SelectionMarker
		for i in range(1, 10):
			selection_marker.set_layer_mask_value(i, false)

	if not movable:
		axis_lock_linear_x = true
		axis_lock_linear_z = true
		axis_lock_angular_y = true

	if range_area_shape != null:
		range_area_shape.shape.radius = attack_range

	current_cooldown = cooldown
	current_hp = hp

	if start_selected:
		activate()

	for child in NodeUtilities.get_all_children(self):
		if child.is_in_group("colorable"):
			var mesh_instance: MeshInstance3D = child as MeshInstance3D
			mesh_instance.mesh = mesh_instance.mesh.duplicate()  # make mesh unique, so it doesn't copy material
			var material = StandardMaterial3D.new()
			material.albedo_color = player.color
			mesh_instance.mesh.material = material


func activate() -> void:
	if active or not selectable:
		return
	active = true
	player.unit_move.connect(on_move)
	player.unit_action.connect(on_action)
	player.unit_secondary.connect(on_secondary)

	player.add_active_unit(self)

	selection_marker.set_layer_mask_value(player.get_normal_visibility_layer(), true)


func deactivate() -> void:
	if not active:
		return
	active = false
	player.unit_move.disconnect(on_move)
	player.unit_action.disconnect(on_action)
	player.unit_secondary.disconnect(on_secondary)

	player.remove_active_unit(self)

	selection_marker.set_layer_mask_value(player.get_normal_visibility_layer(), false)


func add_destination(destination: Vector2) -> void:
	if not movable:
		return

	if destinations.size() > 0:
		var last_destination: Vector2 = destinations[destinations.size() - 1]
		if destination.distance_to(last_destination) < MIN_NEW_DESTINATION_DISTANCE:
			return

	destinations.append(destination)

	var new_segment: LineSegment = LINE_SEGMENT.instantiate()
	for i in range(1, 10):
		new_segment.set_layer_mask_value(i, false)
	new_segment.set_layer_mask_value(player.get_satellite_visibility_layer(), true)

	new_segment.to = Vectors.to_vector3(destinations[destinations.size() - 1])
	if destinations.size() == 1:
		new_segment.from = global_position
	else:
		new_segment.from = Vectors.to_vector3(destinations[destinations.size() - 2])
	get_tree().get_root().add_child(new_segment)
	line_segments.append(new_segment)
	print(new_segment.from, "  ", new_segment.to)


func pop_back_destination() -> void:
	if not movable:
		return
	if destinations.size() == 0:
		return
	destinations.pop_back()
	var segment: LineSegment = line_segments.pop_back()
	segment.queue_free()
	print("poped dest ba")


func pop_front_destination() -> void:
	if destinations.size() == 0:
		return
	destinations.pop_front()
	var segment: LineSegment = line_segments.pop_front()
	segment.queue_free()
	print("poped dest fr")


func clear_destinations() -> void:
	destinations.clear()

	for segment: LineSegment in line_segments:
		segment.queue_free()
	line_segments.clear()

	print("cleard dest")


func update_first_line_segment() -> void:
	if line_segments.size() > 0:
		line_segments[0].from = global_position


func get_enemies_in_range() -> Array[BaseUnit]:
	var enemies: Array[BaseUnit] = []
	for body in range_area.get_overlapping_bodies():
		var unit: BaseUnit = body as BaseUnit
		if unit != null and unit.player != player:
			enemies.append(unit)

	return enemies


func try_shoot(skip_when_no_target: bool = true) -> void:
	if current_cooldown <= 0:
		current_cooldown = cooldown
		var enemies: Array[BaseUnit] = get_enemies_in_range()
		var target: Vector3 = (
			position + Vector3.FORWARD.rotated(Vector3.UP, rotation.y) * attack_range
		)  # shoot where the unit is facing if no target  #global_transform.basis.xform(Vector3.FORWARD)
		if enemies.size() > 0:
			target = enemies.pick_random().position
			_shoot(target)
		elif skip_when_no_target == false:
			_shoot(target)


func _shoot(target: Vector3) -> void:
	if cannon != null:
		cannon.shoot(target)


func take_damage(damage: float) -> void:
	self.current_hp -= damage
	if self.current_hp <= 0:
		die()


func die() -> void:
	while destinations.size() > 0:
		pop_back_destination()
	self.deactivate()
	queue_free()


func on_move(direction: Vector2) -> void:
	if not movable:
		return

	clear_destinations()
	add_destination(Vectors.to_vector2(position) + direction * speed * MANUAL_MOVE_TIME)


func on_action() -> void:
	try_shoot(false)


func on_secondary() -> void:
	print("Secondary!")


func _process(delta: float) -> void:
	current_cooldown -= delta

	if player.current_view != ViewMode.Mode.UNIT or not active:
		if current_cooldown <= -AUTO_FIRE_DELAY * cooldown:
			try_shoot()


func _physics_process(delta: float) -> void:
	if destinations.size() > 0:
		if linear_velocity.length_squared() <= (speed * STUCK_SPEED_FRACTION) ** 2:
			stuck_time += delta
		else:
			stuck_time = 0
		if stuck_time > STUCK_TIME_TO_CANCEL_ORDER:
			stuck_time = 0
			pop_front_destination()
			print("stuck")
			return

		move(delta)
		update_first_line_segment()

	else:
		stuck_time = 0
		linear_velocity = Vector3.ZERO

	angular_velocity = Vector3.ZERO


func move(delta: float) -> void:
	if not movable:
		return

	var next_destination: Vector2 = destinations[0]
	var direction: Vector2 = (next_destination - Vectors.to_vector2(position)).normalized()

	if turn_in_place:
		# position += Vectors.to_vector3(direction) * speed * delta  # phases through other units
		# move_and_collide(Vectors.to_vector3(direction) * speed * delta)  # stops when touching units
		linear_velocity = Vectors.to_vector3(direction) * speed
		look_at(position + linear_velocity)
	else:
		# https://math.stackexchange.com/questions/110080/shortest-way-to-achieve-target-angle
		# I have no idea how it works
		# once again defeated by basic trigonometry
		var target_rotation: float = rad_to_deg(atan2(direction.x, direction.y)) + 180
		var alpha = target_rotation - rotation_degrees.y
		var beta = target_rotation - rotation_degrees.y + 360
		var gamma = target_rotation - rotation_degrees.y - 360
		var a_alpha = abs(alpha)
		var a_beta = abs(beta)
		var a_gamma = abs(gamma)
		var min_value = [a_alpha, a_beta, a_gamma].min()
		var turn_right: bool
		if min_value == a_alpha and alpha > 0:
			turn_right = true
		elif min_value == a_beta and beta > 0:
			turn_right = true
		elif min_value == a_gamma and gamma > 0:
			turn_right = true
		else:
			turn_right = false

		if min_value > 0.1:
			if turn_right:
				rotation_degrees.y += turn_speed * delta
			else:
				rotation_degrees.y -= turn_speed * delta

		if min_value < max_move_angle:
			linear_velocity = -get_global_transform().basis.z * speed
			# translate_object_local(Vector3.FORWARD * speed * delta)

	var squared_distance_to_destination: float = position.distance_squared_to(
		Vectors.to_vector3(next_destination)
	)
	if squared_distance_to_destination <= MIN_NEW_DESTINATION_DISTANCE ** 2:
		pop_front_destination()
