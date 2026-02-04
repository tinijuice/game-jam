extends Area2D

@export var item_name: String = ""
@export var quantity: int = 1

@export var float_height := 8.0
@export var float_speed := 3.0
@export var rotate_speed := 1.5
@export var magnet_speed := 220.0

@onready var sprite: Sprite2D = $item
@onready var shadow: Sprite2D = $Shadow

var start_y: float
var time := 0.0
var player: Node2D = null


func _ready() -> void:
	start_y = sprite.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time += delta

	var offset = sin(time * float_speed) * float_height
	sprite.position.y = start_y + offset

	if player:
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

		if Inventory.add_item(item_name, quantity):
			queue_free()


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
