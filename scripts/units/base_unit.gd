class_name BaseUnit

extends RigidBody3D

## When a new destination is added, that is closer
## to the last destination than this value, it will be skipped
const MIN_NEW_DESTINATION_DISTANCE: float = 0.1

## Manual movement will last for this long after the move key is released. Must be greater than 0!
const MANUAL_MOVE_TIME: float = 0.05

## The unit considers itself stuck if it moves with this fraction of its maximum speed
const STUCK_SPEED_FRACTION: float = 0.125

## The unit cancels its current order after being stuck for this long
const STUCK_TIME_TO_CANCEL_ORDER: float = 1

## The owner of this unit
@export var player: PlayerController

## If true, the unit will start in game as selected
@export var start_selected: bool = false

@export_category("Stats")
@export var hp: float = 100
@export var damage: float = 25
@export var cooldown: float = 2
@export var attack_range: float = 5
@export var speed: float = 2
@export var turn_speed: float = 2
@export var turn_in_place: bool = true

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
	if destinations.size() > 0:
		var last_destination: Vector2 = destinations[destinations.size() - 1]
		if destination.distance_to(last_destination) < MIN_NEW_DESTINATION_DISTANCE:
			return

	destinations.append(destination)


func pop_destination() -> void:
	destinations.pop_back()


func on_move(direction: Vector2) -> void:
	destinations.clear()
	destinations.append(Vectors.to_vector2(position) + direction * speed * MANUAL_MOVE_TIME)


func on_action() -> void:
	print("Action!")


func on_secondary() -> void:
	print("Secondary!")


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
	else:
		stuck_time = 0
		linear_velocity = Vector3.ZERO

	angular_velocity = Vector3.ZERO


func move(_delta: float) -> void:
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
