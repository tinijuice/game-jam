extends Area2D



@export_multiline var chest_content: String = ""

@export var is_open: bool = false
var player_nearby: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accepte"):
		open_chest()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		print("💬 Appuie sur E pour ouvrir")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false


func open_chest() -> void:
	if is_open:
		print("📦 Coffre déjà ouvert")
		return
	
	is_open = true
	print("📦 Coffre ouvert !")
	
	var items = chest_content.split(",")
	for item_str in items:
		item_str = item_str.strip_edges()
		if item_str == "":
			continue
		
		var parts = item_str.split(":")
		if parts.size() == 2:
			var item_name = parts[0].strip_edges()
			var quantity = int(parts[1].strip_edges())
			Inventory.add_item(item_name, quantity)
			print("  ➜ Ajouté:", item_name, "x", quantity)
		else:
			print("⚠️ Format invalide:", item_str)
	
	modulate = Color(0.7, 0.7, 0.7)
