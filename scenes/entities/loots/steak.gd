extends Area2D

@export var item_name: String = "Wood"
@export var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if Inventory.add_item(item_name, quantity):
			queue_free()
