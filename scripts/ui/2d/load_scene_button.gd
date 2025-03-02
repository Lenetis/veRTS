class_name LoadSceneButton

extends Button

@export var scene_path: String


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(_on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	get_tree().paused = false
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file(scene_path)
