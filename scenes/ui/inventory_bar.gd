extends CanvasLayer

@onready var slots: Array = $HBoxContainer.get_children()

var selected_slot: int = 0

@export var campfire_scene: PackedScene


var poison_timer: float = 0.0
var is_poisoned: bool = false
var poison_duration: float = 8.0
var poison_damage: int = 5


func _ready() -> void:
	Inventory.inventory_changed.connect(update_ui)
	update_ui()
	update_selection()


func _process(delta: float) -> void:
	if is_poisoned:
		poison_timer += delta
		if poison_timer >= 1.0:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.take_damage(poison_damage)
			poison_timer = 0.0
			poison_duration -= 1.0
			
			if poison_duration <= 0:
				is_poisoned = false
				poison_duration = 10.0


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
	var slot_data = Inventory.get_slot(selected_slot)
	if slot_data["name"] != "":
		place_item(slot_data["name"])


func place_item(item_name: String) -> void:
	match item_name:
		"Campfire":
			if campfire_scene and Inventory.has_item("Campfire", 1):
				var campfire = campfire_scene.instantiate()
				
				var player = get_tree().get_first_node_in_group("player")
				if player:
					var mouse_world_pos = player.get_global_mouse_position()
					
					var max_distance = 200.0
					var distance = player.global_position.distance_to(mouse_world_pos)
					
					if distance <= max_distance:
						get_tree().current_scene.add_child(campfire)
						campfire.global_position = mouse_world_pos
						
						Inventory.remove_item("Campfire", 1)
					else:
						campfire.queue_free()


func use_item(item_name: String) -> void:
	match item_name:
		"Steak":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				if player.has_node("EatSound"):
					player.get_node("EatSound").play()
				
				player.hitpoints += 20
				player.hitpoints = clamp(player.hitpoints, 0, player.hitpoints_max)
				var hud = get_tree().get_root().get_node_or_null("HUD")
				if hud:
					hud.update_health(player.hitpoints)
				Inventory.remove_item("Steak", 1)
		
		"Spider":
			is_poisoned = true
			poison_timer = 0.0
			poison_duration = 10.0
			Inventory.remove_item("Spider", 1)

		"Vincent":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.hitpoints = 0
				var hud = get_tree().get_root().get_node_or_null("HUD")
				if hud:
					hud.update_health(player.hitpoints)
				
				if player.has_method("death"):
					player.death()
				
				Inventory.remove_item("Vincent", 1)
				print("💀 Vincent consommé... RIP")


func update_ui() -> void:
	for i in range(slots.size()):
		var slot_data = Inventory.get_slot(i)
		slots[i].set_item(slot_data["name"], slot_data["quantity"])
	update_selection()