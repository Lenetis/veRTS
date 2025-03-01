class_name PlayerController

extends Node

## Controls everything that has to do with the player - captures key inputs
## and performs all appropriate actions.

enum State { ZOOM, SELECT, ORDER, WEAPON }

const SATELLITE_STATES: Array[State] = [State.ZOOM, State.SELECT, State.ORDER, State.WEAPON]

var state_action_dict: Dictionary = {
	State.ZOOM: satellite_zoom,
	State.SELECT: satellite_select,
	State.ORDER: satellite_order,
	State.WEAPON: satellite_weapon,
}
var state_secondary_dict: Dictionary = {
	State.ZOOM: satellite_unzoom,
	State.SELECT: satellite_deselect,
	State.ORDER: satellite_cancel_order,
	State.WEAPON: satellite_weapon2,
}

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
@export var view_toggle_hold_time: float = 0.75
var view_hold_timer: float = 0

var current_view: ViewMode.Mode = ViewMode.Mode.UNIT
var current_state: State = State.ZOOM

# array of units that are currently selected
var active_units: Array[BaseUnit] = []

var menu_is_open: bool = false

var key_action_just_pressed: bool = false
var key_secondary_just_pressed: bool = false

var move_vector: Vector2 = Vector2.ZERO

signal view_toggled(new_view: ViewMode.Mode)

signal unit_move(direction: Vector2)
signal unit_action
signal unit_secondary

signal satellite_move(direction: Vector2)

signal satellite_zoom
signal satellite_unzoom

signal satellite_order
signal satellite_cancel_order

signal satellite_select
signal satellite_deselect

signal satellite_weapon
signal satellite_weapon2


func add_active_unit(unit: BaseUnit) -> void:
	active_units.append(unit)


func remove_active_unit(unit: BaseUnit) -> void:
	active_units.erase(unit)


## Toggles between unit and satellite view mode
func toggle_view() -> void:
	menu_is_open = false
	print("Toggle! From: ", current_view)
	if current_view == ViewMode.Mode.UNIT:
		current_view = ViewMode.Mode.SATELLITE
	else:
		current_view = ViewMode.Mode.UNIT
	print("To: ", current_view)
	view_toggled.emit(current_view)


## Switches state in satellite mode, by the given offset
func switch_state(offset: int) -> void:
	print("switch satellite state. From: ", current_state)
	var current_state_index: int = SATELLITE_STATES.find(current_state)
	var new_state_index: int = (current_state_index + offset) % SATELLITE_STATES.size()
	current_state = SATELLITE_STATES[new_state_index]
	print("To: ", current_state)


func _unhandled_key_input(event: InputEvent) -> void:
	event = event as InputEventKey  # should always cast correctly
	if event.is_released() and event.keycode == key_option:
		if view_hold_timer > 0 and view_hold_timer < 0.5 * view_toggle_hold_time:
			menu_is_open = not menu_is_open
			print("Menu is open: ", menu_is_open)

	elif event.is_pressed():
		if event.keycode == key_action:
			key_action_just_pressed = true
		elif event.keycode == key_secondary:
			key_secondary_just_pressed = true


func _process(delta: float) -> void:
	if menu_is_open:
		_menu_process(delta)

	_calculate_move_vector()

	match current_view:
		ViewMode.Mode.UNIT:
			_unit_process(delta)
		ViewMode.Mode.SATELLITE:
			_satellite_process(delta)

	if Input.is_key_pressed(key_option):
		view_hold_timer += delta
	else:
		view_hold_timer = 0

	if view_hold_timer >= view_toggle_hold_time:
		toggle_view()
		view_hold_timer = -1000000  # spaghetti TODO

	key_action_just_pressed = false
	key_secondary_just_pressed = false


func _calculate_move_vector() -> void:
	move_vector = Vector2.ZERO
	if Input.is_key_pressed(key_up):
		move_vector += Vector2(0, -1)
	if Input.is_key_pressed(key_down):
		move_vector += Vector2(0, 1)
	if Input.is_key_pressed(key_left):
		move_vector += Vector2(-1, 0)
	if Input.is_key_pressed(key_right):
		move_vector += Vector2(1, 0)


func _menu_process(_delta: float) -> void:
	if key_action_just_pressed:
		switch_state(-1)
	if key_secondary_just_pressed:
		switch_state(1)


func _unit_process(_delta: float) -> void:
	if move_vector != Vector2.ZERO:
		unit_move.emit(move_vector)

	if key_action_just_pressed:
		unit_action.emit()

	if key_secondary_just_pressed:
		unit_secondary.emit()


func _satellite_process(_delta: float) -> void:
	if move_vector != Vector2.ZERO:
		satellite_move.emit(move_vector)

	if not menu_is_open:
		# these states should send continous signals (every frame)
		if current_state in [State.ZOOM, State.SELECT]:
			if Input.is_key_pressed(key_action):
				var action_signal: Signal = state_action_dict[current_state]
				action_signal.emit()

			if Input.is_key_pressed(key_secondary):
				var action_signal: Signal = state_secondary_dict[current_state]
				action_signal.emit()

		# other states should send signals on press only
		else:
			if key_action_just_pressed:
				var action_signal: Signal = state_action_dict[current_state]
				action_signal.emit()

			if key_secondary_just_pressed:
				var action_signal: Signal = state_secondary_dict[current_state]
				action_signal.emit()
