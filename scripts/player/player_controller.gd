class_name PlayerController

extends Node

## Controls everything that has to do with the player - captures key inputs
## and performs all appropriate actions.

enum ViewMode { UNIT, SATELLITE }

# Keys responsible for movement
@export var key_up: Key
@export var key_down: Key
@export var key_left: Key
@export var key_right: Key

# Action and secondary action, for example: select/deselect, add/remove selection, shoot/switch unit
@export var key_action: Key
@export var key_secondary: Key

# For opening menus and switching the current mode of action/secondary keys
# Holding this key toggles between satellite view and unit view
@export var key_option: Key
@export var view_toggle_hold_time: float = 1

var current_view: ViewMode = ViewMode.UNIT

signal unit_move(direction: Vector2)
signal unit_action
signal unit_secondary


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


func _process(delta: float) -> void:
	match current_view:
		ViewMode.UNIT:
			_unit_process(delta)
		ViewMode.SATELLITE:
			_satellite_process(delta)


func _unit_process(_delta: float) -> void:
	var move_vector: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(key_up):
		move_vector += Vector2(0, -1)
	if Input.is_key_pressed(key_down):
		move_vector += Vector2(0, 1)
	if Input.is_key_pressed(key_left):
		move_vector += Vector2(-1, 0)
	if Input.is_key_pressed(key_right):
		move_vector += Vector2(1, 0)

	if move_vector != Vector2.ZERO:
		unit_move.emit(move_vector)

	if Input.is_key_pressed(key_action):
		unit_action.emit()

	if Input.is_key_pressed(key_secondary):
		unit_secondary.emit()


func _satellite_process(_delta: float) -> void:
	pass
