class_name BaseUnit

extends Area3D

## The owner of this unit
@export var player: PlayerController

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
	destinations.append(destination)


func on_move(direction: Vector2) -> void:
	destinations.clear()
	destinations.append(Vectors.to_vector2(position) + direction * speed)
	print(destinations)


func on_action() -> void:
	print("Action!")


func on_secondary() -> void:
	print("Secondary!")


func _process(delta: float) -> void:
	if destinations.size() > 0:
		move(delta)


func move(delta: float) -> void:
	var next_destination: Vector2 = destinations[0]
	var direction: Vector2 = (next_destination - Vectors.to_vector2(position)).normalized()

	position += Vectors.to_vector3(direction) * speed * delta

	if (position - Vectors.to_vector3(next_destination)).length_squared() < speed ** 2:
		destinations.pop_front()
