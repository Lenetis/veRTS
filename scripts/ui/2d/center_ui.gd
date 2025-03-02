class_name Crosshair

extends TextureRect

@export var player: PlayerController


func _ready():
	update_text()


func update_text():
	if player.current_view != ViewMode.Mode.SATELLITE:
		visible = false
	else:
		visible = true


func _process(delta):
	update_text()
