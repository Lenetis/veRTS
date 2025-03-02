class_name CaptureZone

extends Area3D

const CAPTURE_INDICATOR = preload("res://scenes/capture_zone/capture_indicator.tscn")

@export var time_to_capture: float = 30
@export var indicator_distance: float = 5

var current_capture_time: float = 0
var capturing_player: PlayerController = null

# dictionary in the form of: {player: [units], player2: [units], ...}
var units: Dictionary = {}

var capture_indicators: Array[MeshInstance3D] = []
var last_update_time: float = 0

var over: bool = false


func update_indicators() -> void:
	if abs(last_update_time - current_capture_time) < 0.25:
		return
	last_update_time = current_capture_time

	for indicator in capture_indicators:
		indicator.queue_free()
	capture_indicators.clear()

	for i in range(int(current_capture_time)):
		var new_indicator: MeshInstance3D = CAPTURE_INDICATOR.instantiate()
		var pos = indicator_distance * Vector3.FORWARD

		pos = pos.rotated(Vector3.UP, (deg_to_rad(360) / time_to_capture) * i)
		new_indicator.position = pos + global_position
		new_indicator.rotation_degrees.y = (360 / time_to_capture) * i

		new_indicator.mesh = new_indicator.mesh.duplicate()  # make mesh unique, so it doesn't copy material
		var material = StandardMaterial3D.new()
		material.albedo_color = capturing_player.color
		new_indicator.mesh.material = material

		get_tree().get_root().get_children()[0].add_child(new_indicator)

		capture_indicators.append(new_indicator)


func win():
	over = true

	var root_node = get_tree().get_root() as Node
	var all_nodes = NodeUtilities.get_all_children(root_node)
	for node in all_nodes:
		if node.name == "Victory":
			print("victory")
			node.visible = true
		if node.name == "VictoryText":
			print("text")
			node.text = (
				"[center][color="
				+ capturing_player.color.to_html(true)
				+ "][b]ONE TOOK,\n"
				+ "THE REST LEFT[/b][/color][/center]"
			)
	#var new_indicator: MeshInstance3D = CAPTURE_INDICATOR.instantiate()

	#new_indicator.mesh = new_indicator.mesh.duplicate()  # make mesh unique, so it doesn't copy material
	#var material = StandardMaterial3D.new()
	#material.albedo_color = capturing_player.color
	#new_indicator.mesh.material = material

	#new_indicator.scale = Vector3(10000, 5, 10000)

	#get_tree().get_root().get_children()[0].add_child(new_indicator)
	get_tree().paused = true


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	if over:
		return
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
		update_indicators()

	if current_capture_time >= time_to_capture:
		print("VICTORY!!! ", capturing_player)
		win()


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
