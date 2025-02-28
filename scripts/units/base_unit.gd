class_name BaseUnit

extends Node3D

## The owner of this unit
@export var player: PlayerController

## Whether the unit listens and reacts to the owner signals
@export var active: bool = true

## Global position where the unit wants to go
@export var destination: Vector2

@export_category("Stats")
@export var hp: float = 100
@export var damage: float = 25
@export var cooldown: float = 2
@export var speed: float = 2
@export var turn_speed: float = 2
@export var turn_in_place: bool = true

var is_moving: bool = false


func _ready() -> void:
	if active:
		activate()


func activate() -> void:
	player.unit_move.connect(move)
	player.unit_action.connect(action)
	player.unit_secondary.connect(secondary)


func deactivate() -> void:
	player.unit_move.disconnect(move)
	player.unit_action.disconnect(action)
	player.unit_secondary.disconnect(secondary)


func move(direction: Vector2) -> void:
	is_moving = true
	destination = Vectors.to_vector2(position) + direction * speed
	print(destination)


func action() -> void:
	print("Action!")


func secondary() -> void:
	print("Secondary!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not is_moving:
		return

	var direction: Vector2 = (destination - Vectors.to_vector2(position)).normalized()

	position += Vectors.to_vector3(direction) * speed * _delta

	if (position - Vectors.to_vector3(destination)).length_squared() < speed ** 2:
		is_moving = false
