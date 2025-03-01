class_name Cannon

extends Node3D

@export var projectile: PackedScene

## Lerp weight with which the cannon returns to its original position
@export var look_back_lerp_weight: float = 2.5

var player: PlayerController


func _ready() -> void:
	player = get_parent().player


func shoot(target: Vector3) -> void:
	look_at(target)
	var new_projectile: BaseProjectile = projectile.instantiate()
	new_projectile.initialize(player)
	new_projectile.transform = global_transform
	get_tree().get_root().add_child(new_projectile)


func _process(delta: float) -> void:
	rotation_degrees = rotation_degrees.lerp(Vector3.ZERO, look_back_lerp_weight * delta)
