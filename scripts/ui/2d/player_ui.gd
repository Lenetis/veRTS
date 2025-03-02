class_name PlayerUI

extends RichTextLabel

@export var player: PlayerController
@export var active_color: Color
@export var inactive_color: Color
@export var selected_color: Color
@export var separator: String = "   -   "
@export var zoom_tooltip: String = "zoom   -   unzoom"
@export var select_tooltip: String = "select unit   -   deselect all"
@export var order_tooltip: String = "add move order   -   cancel last order"
@export var weapon_tooltip: String = "little fire   -   heavy fire"
@export var build_tooltip: String = "TODO"

var opening_active_color_tag: String
var opening_inactive_color_tag: String
var opening_selected_color_tag: String
var closing_color_tag = "[/color]"


func _ready():
	print(active_color)
	print(inactive_color)
	print(selected_color)
	opening_active_color_tag = "[color=" + active_color.to_html(true) + "]"
	opening_inactive_color_tag = "[color=" + inactive_color.to_html(true) + "]"
	opening_selected_color_tag = "[color=" + selected_color.to_html(true) + "]"

	update_text()


func update_text():
	var zoom_text = "Zoom"
	var select_text = "Select"
	var order_text = "Order"
	var weapon_text = "Weapon"
	var build_text = "Build"
	var active_tooltip = ""

	if player.current_view != ViewMode.Mode.SATELLITE:
		text = ""
		return

	var tag_to_use = opening_active_color_tag
	if player.menu_is_open:
		tag_to_use = opening_selected_color_tag

	match player.current_state:
		PlayerController.State.ZOOM:
			zoom_text = add_tag(zoom_text, tag_to_use, closing_color_tag)
			active_tooltip = zoom_tooltip
		PlayerController.State.SELECT:
			select_text = add_tag(select_text, tag_to_use, closing_color_tag)
			active_tooltip = select_tooltip
		PlayerController.State.ORDER:
			order_text = add_tag(order_text, tag_to_use, closing_color_tag)
			active_tooltip = order_tooltip
		PlayerController.State.WEAPON:
			weapon_text = add_tag(weapon_text, tag_to_use, closing_color_tag)
			active_tooltip = weapon_tooltip
		PlayerController.State.BUILD:
			build_text = add_tag(build_text, tag_to_use, closing_color_tag)
			active_tooltip = build_tooltip

	text = (
		zoom_text
		+ separator
		+ select_text
		+ separator
		+ order_text
		+ separator
		+ weapon_text
		+ separator
		+ build_text
	)

	#tooltip_text = add_tag(OS.get_keycode_string(player.key_action), opening_selected_color_tag, closing_color_tag)
	text += "\n\n"
	text += active_tooltip  #(active_tooltip, "[center]", "[/center]")

	if player.menu_is_open:
		text = add_tag(text, opening_active_color_tag, closing_color_tag)
	else:
		text = add_tag(text, opening_inactive_color_tag, closing_color_tag)

	text = add_tag(text, "[center]", "[/center]")


func add_tag(string: String, opening_tag: String, closing_tag: String) -> String:
	return opening_tag + string + closing_tag


func _process(delta):
	update_text()
