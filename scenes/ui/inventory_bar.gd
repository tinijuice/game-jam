extends CanvasLayer

@onready var slots: Array = $HBoxContainer.get_children()


func _ready() -> void:
	print("🎒 InventoryBar ready, nombre de slots: ", slots.size())
	Inventory.inventory_changed.connect(update_ui)
	update_ui()


func update_ui() -> void:
	print("🔄 Mise à jour UI inventaire")
	for i in range(slots.size()):
		var slot_data = Inventory.get_slot(i)
		print("Slot ", i, ": ", slot_data)
		slots[i].set_item(slot_data["name"], slot_data["quantity"])
