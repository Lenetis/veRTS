class_name BaseProjectile

extends Area3D

@export var speed: float = 10
@export var damage: float = 10
@export var lifetime: float = 5
@export var die_on_hit: bool = true

var current_lifetime: float

var player: PlayerController


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	current_lifetime = lifetime


func _process(delta: float) -> void:
	translate_object_local(Vector3.FORWARD * speed * delta)
	current_lifetime -= delta

	if current_lifetime <= 0:
		queue_free()


func initialize(owner_player: PlayerController) -> void:
	player = owner_player


func _on_body_entered(body: RigidBody3D) -> void:
	var unit: BaseUnit = body as BaseUnit
	if unit.player != player:
		unit.take_damage(damage)

		if die_on_hit:
			queue_free()
