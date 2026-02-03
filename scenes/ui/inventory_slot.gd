extends Panel

@onready var icon: TextureRect = $Icon
@onready var quantity_label: Label = $Quantity

var item_name: String = ""
var item_quantity: int = 0


func set_item(new_item_name: String, new_quantity: int) -> void:
	print("📦 Set item: ", new_item_name, " x", new_quantity)
	item_name = new_item_name
	item_quantity = new_quantity
	
	if item_name != "" and item_quantity > 0:
		icon.visible = true
		quantity_label.visible = item_quantity > 1
		quantity_label.text = str(item_quantity)
	else:
		clear_slot()


func clear_slot() -> void:
	item_name = ""
	item_quantity = 0
	icon.visible = false
	quantity_label.visible = false
	quantity_label.text = ""
