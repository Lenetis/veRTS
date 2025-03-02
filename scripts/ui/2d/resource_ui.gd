class_name ResourceUI

extends RichTextLabel

@export var player: PlayerController


func update_text():
	text = (
		"[center]"
		+ str(round(player.money))
		+ "\n"
		+ "(+"
		+ str(player.base_income)
		+ ")\n"
		+ "[color="
		+ player.color.to_html(true)
		+ "]════════════════════[/color]"
		+ "[/center]"
	)


func _ready():
	update_text()


func _process(delta):
	update_text()
