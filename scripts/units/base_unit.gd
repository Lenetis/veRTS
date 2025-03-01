class_name BaseUnit

extends RigidBody3D

## WARNING, UNIT NEEDS A CANNON AS ITS DIRECT CHILD

@onready var range_area = $RangeArea3D
@onready var range_area_shape = $RangeArea3D/CollisionShape3D

@onready var cannon = $Cannon

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

@export_category("Stats")
@export var hp: float = 100
@export var cooldown: float = 2
@export var attack_range: float = 25
@export var speed: float = 2
@export var turn_speed: float = 2
@export var turn_in_place: bool = true

# the unit needs to wait this time before being able to shoot again
var current_cooldown: float

# current value of the unit's hp. If it reaches 0, the unit dies
var current_hp: float

# array of global positions where the unit wants to go
var destinations: Array[Vector2]

# whether the unit listens and reacts to the owner signals
var active: bool = false

# time the unit feels stuck
var stuck_time: float = 0


func _ready() -> void:
	axis_lock_linear_y = true
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	if not movable:
		axis_lock_linear_x = true
		axis_lock_linear_z = true
		axis_lock_angular_y = true

	range_area_shape.shape.radius = attack_range

	current_cooldown = cooldown
	current_hp = hp

	if start_selected:
		activate()


func activate() -> void:
	if active:
		return
	active = true
	player.unit_move.connect(on_move)
	player.unit_action.connect(on_action)
	player.unit_secondary.connect(on_secondary)

	player.add_active_unit(self)


func deactivate() -> void:
	if not active:
		return
	active = false
	player.unit_move.disconnect(on_move)
	player.unit_action.disconnect(on_action)
	player.unit_secondary.disconnect(on_secondary)

	player.remove_active_unit(self)


func add_destination(destination: Vector2) -> void:
	if not movable:
		return

	if destinations.size() > 0:
		var last_destination: Vector2 = destinations[destinations.size() - 1]
		if destination.distance_to(last_destination) < MIN_NEW_DESTINATION_DISTANCE:
			return

	destinations.append(destination)


func pop_destination() -> void:
	if not movable:
		return
	destinations.pop_back()


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
	cannon.shoot(target)


func take_damage(damage: float) -> void:
	self.current_hp -= damage
	if self.current_hp <= 0:
		die()


func die() -> void:
	self.deactivate()
	queue_free()


func on_move(direction: Vector2) -> void:
	if not movable:
		return

	destinations.clear()
	destinations.append(Vectors.to_vector2(position) + direction * speed * MANUAL_MOVE_TIME)


func on_action() -> void:
	try_shoot(false)


func on_secondary() -> void:
	print("Secondary!")
	die()


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
			destinations.pop_front()
			return

		move(delta)

		look_at(position + linear_velocity)
	else:
		stuck_time = 0
		linear_velocity = Vector3.ZERO

	angular_velocity = Vector3.ZERO


func move(_delta: float) -> void:
	if not movable:
		return

	var next_destination: Vector2 = destinations[0]
	var direction: Vector2 = (next_destination - Vectors.to_vector2(position)).normalized()

	# position += Vectors.to_vector3(direction) * speed * delta  # phases through other units
	# move_and_collide(Vectors.to_vector3(direction) * speed * delta)  # stops when touching units
	linear_velocity = Vectors.to_vector3(direction) * speed

	var squared_distance_to_destination: float = position.distance_squared_to(
		Vectors.to_vector3(next_destination)
	)
	if squared_distance_to_destination <= MIN_NEW_DESTINATION_DISTANCE ** 2:
		destinations.pop_front()
