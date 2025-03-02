class_name PlayerBase

extends Area3D

@export var player: PlayerController


func _ready():
	for child in NodeUtilities.get_all_children(self):
		if child.is_in_group("colorable"):
			var mesh_instance: MeshInstance3D = child as MeshInstance3D
			mesh_instance.mesh = mesh_instance.mesh.duplicate()  # make mesh unique, so it doesn't copy material
			var material = StandardMaterial3D.new()
			material.albedo_color = player.color
			mesh_instance.mesh.material = material
