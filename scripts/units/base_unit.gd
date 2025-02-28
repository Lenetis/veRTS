class_name BaseUnit

extends Node3D

## The owner of this unit
@export var player: PlayerController

## Whether the unit listens and reacts to the owner signals
@export var active: bool = true

@export_category("Stats")
@export var hp: float = 100
@export var damage: float = 25
@export var cooldown: float = 2
@export var range: float = 5
@export var speed: float = 2
@export var turn_speed: float = 2
@export var turn_in_place: bool = true

# global position where the unit wants to go
var destination: Vector2
var is_moving: bool = false


func _ready() -> void:
	if active:
		activate()


func activate() -> void:
	player.unit_move.connect(on_move)
	player.unit_action.connect(on_action)
	player.unit_secondary.connect(on_secondary)


func deactivate() -> void:
	player.unit_move.disconnect(on_move)
	player.unit_action.disconnect(on_action)
	player.unit_secondary.disconnect(on_secondary)


func on_move(direction: Vector2) -> void:
	is_moving = true
	destination = Vectors.to_vector2(position) + direction * speed
	print(destination)


func on_action() -> void:
	print("Action!")


func on_secondary() -> void:
	print("Secondary!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not is_moving:
		return

	var direction: Vector2 = (destination - Vectors.to_vector2(position)).normalized()

	position += Vectors.to_vector3(direction) * speed * _delta

	if (position - Vectors.to_vector3(destination)).length_squared() < speed ** 2:
		is_moving = false
