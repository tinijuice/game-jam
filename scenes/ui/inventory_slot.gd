extends Panel

@onready var icon: TextureRect = $Icon
@onready var quantity_label: Label = $Quantity

var item_name: String = ""
var item_quantity: int = 0
var is_selected: bool = false

var item_textures: Dictionary = {
	"Steak": preload("res://assets/sprites/loots/Steak.webp"),
	"Campfire": preload("res://assets/sprites/loots/Campfire.png"),
	"Vincent": preload("res://assets/sprites/loots/Vincent.jpeg")
}


func set_item(new_item_name: String, new_quantity: int) -> void:
	item_name = new_item_name
	item_quantity = new_quantity
	
	if item_name != "" and item_quantity > 0:
		if item_textures.has(item_name):
			icon.texture = item_textures[item_name]
		icon.visible = true
		quantity_label.visible = item_quantity > 1
		quantity_label.text = str(item_quantity)
	else:
		clear_slot()


func clear_slot() -> void:
	item_name = ""
	item_quantity = 0
	icon.texture = null
	icon.visible = false
	quantity_label.visible = false
	quantity_label.text = ""


func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		modulate = Color(1.0, 1.0, 0.5)
	else:
		modulate = Color(1.0, 1.0, 1.0)
