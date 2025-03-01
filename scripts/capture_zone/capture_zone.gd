class_name CaptureZone

extends Area3D

@export var time_to_capture: float = 30

var current_capture_time: float = 0
var capturing_player: PlayerController = null

# dictionary in the form of: {player: [units], player2: [units], ...}
var units: Dictionary = {}


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	if units.size() == 1:
		var player: PlayerController = units.keys()[0]
		if current_capture_time == 0:
			capturing_player = player

		if player == capturing_player:
			current_capture_time += delta
		else:
			current_capture_time -= 2 * delta

	else:
		current_capture_time -= delta

	if current_capture_time < 0:
		current_capture_time = 0

	if current_capture_time != 0:
		print(current_capture_time)

	if current_capture_time >= time_to_capture:
		print("VICTORY!!! ", capturing_player)


func _on_body_entered(body: RigidBody3D) -> void:
	var unit: BaseUnit = body as BaseUnit
	if unit == null:
		return

	if units.get(unit.player):
		units[unit.player].append(unit)
	else:
		units[unit.player] = [unit]


func _on_body_exited(body: RigidBody3D) -> void:
	var unit: BaseUnit = body as BaseUnit
	if unit == null:
		return

	units[unit.player].erase(unit)
	if units[unit.player].size() == 0:
		units.erase(unit.player)
