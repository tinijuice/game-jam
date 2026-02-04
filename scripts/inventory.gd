extends Node

signal inventory_changed
signal item_added(item_name: String, quantity: int)

const MAX_SLOTS: int = 5

var items: Array = []


func _ready() -> void:
	for i in range(MAX_SLOTS):
		items.append({"name": "", "quantity": 0})


func add_item(item_name: String, quantity: int = 1) -> bool:
	for slot in items:
		if slot["name"] == item_name:
			slot["quantity"] += quantity
			item_added.emit(item_name, quantity)
			inventory_changed.emit()
			print("✅ Ajouté: ", quantity, "x ", item_name)
			return true
	
	for slot in items:
		if slot["name"] == "":
			slot["name"] = item_name
			slot["quantity"] = quantity
			item_added.emit(item_name, quantity)
			inventory_changed.emit()
			print("✅ Ajouté: ", quantity, "x ", item_name)
			return true
	
	print("⚠️ Inventaire plein !")
	return false


func remove_item(item_name: String, quantity: int = 1) -> bool:
	for slot in items:
		if slot["name"] == item_name:
			slot["quantity"] -= quantity
			if slot["quantity"] <= 0:
				slot["name"] = ""
				slot["quantity"] = 0
			inventory_changed.emit()
			return true
	return false


func has_item(item_name: String, quantity: int = 1) -> bool:
	for slot in items:
		if slot["name"] == item_name and slot["quantity"] >= quantity:
			return true
	return false


func get_slot(index: int) -> Dictionary:
	if index >= 0 and index < items.size():
		return items[index]
	return {"name": "", "quantity": 0}


func clear_inventory() -> void:
	for slot in items:
		slot["name"] = ""
		slot["quantity"] = 0
	inventory_changed.emit()
