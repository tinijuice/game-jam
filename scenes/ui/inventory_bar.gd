extends CanvasLayer

@onready var slots: Array = $HBoxContainer.get_children()

var selected_slot: int = 0

@export var campfire_scene: PackedScene


func _ready() -> void:
	Inventory.inventory_changed.connect(update_ui)
	update_ui()
	update_selection()



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("slot_1"):
		select_slot(0)
	elif event.is_action_pressed("slot_2"):
		select_slot(1)
	elif event.is_action_pressed("slot_3"):
		select_slot(2)
	elif event.is_action_pressed("slot_4"):
		select_slot(3)
	elif event.is_action_pressed("slot_5"):
		select_slot(4)
	elif event.is_action_pressed("use_item"):
		use_selected_item()
	
	# Test simple et direct
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.pressed:
			place_selected_item()


func select_slot(index: int) -> void:
	selected_slot = index
	update_selection()


func update_selection() -> void:
	for i in range(slots.size()):
		if i == selected_slot:
			slots[i].set_selected(true)
		else:
			slots[i].set_selected(false)


func use_selected_item() -> void:
	var slot_data = Inventory.get_slot(selected_slot)
	if slot_data["name"] != "":
		use_item(slot_data["name"])


func place_selected_item() -> void:
	print("📦 place_selected_item appelée")
	var slot_data = Inventory.get_slot(selected_slot)
	print("🎯 Slot sélectionné: ", selected_slot, " | Item: ", slot_data["name"])
	if slot_data["name"] != "":
		place_item(slot_data["name"])



func place_item(item_name: String) -> void:
	match item_name:
		"Campfire":
			if campfire_scene and Inventory.has_item("Campfire", 1):
				var campfire = campfire_scene.instantiate()
				
				var player = get_tree().get_first_node_in_group("player")
				if player:
					# Convertir position souris écran → monde
					var camera = get_viewport().get_camera_2d()
					var mouse_world_pos = Vector2.ZERO
					
					if camera:
						var mouse_screen = get_viewport().get_mouse_position()
						var viewport_size = get_viewport().get_visible_rect().size
						mouse_world_pos = camera.global_position + (mouse_screen - viewport_size / 2)
					else:
						mouse_world_pos = get_viewport().get_mouse_position()
					
					# Vérifier la distance avec le joueur
					var max_distance = 200.0  # Rayon en pixels (ajuste selon tes besoins)
					var distance = player.global_position.distance_to(mouse_world_pos)
					
					if distance <= max_distance:
						campfire.global_position = mouse_world_pos
						get_tree().current_scene.add_child(campfire)
						Inventory.remove_item("Campfire", 1)
						print("🔥 Feu de camp placé à: ", campfire.global_position)
					else:
						print("⚠️ Trop loin ! Distance: ", int(distance), " (max: ", max_distance, ")")
						campfire.queue_free()  # Supprime l'instance non utilisée
				else:
					campfire.global_position = Vector2(0, 0)
					get_tree().current_scene.add_child(campfire)
					Inventory.remove_item("Campfire", 1)



func use_item(item_name: String) -> void:
	match item_name:
		"Steak":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.hitpoints += 20
				player.hitpoints = clamp(player.hitpoints, 0, player.hitpoints_max)
				var hud = get_tree().get_root().get_node_or_null("HUD")
				if hud:
					hud.update_health(player.hitpoints)
				Inventory.remove_item("Steak", 1)
				print("🥩 Steak consommé: +20 HP")


func update_ui() -> void:
	for i in range(slots.size()):
		var slot_data = Inventory.get_slot(i)
		slots[i].set_item(slot_data["name"], slot_data["quantity"])
	update_selection()
