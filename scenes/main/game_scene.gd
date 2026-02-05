extends Node2D

@export var end_game_screen_packed: PackedScene

var player: CharacterBody2D = null
var death_handled: bool = false

func _ready() -> void:
	death_handled = false
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.game_over.connect(display_end_game_screen)


func display_end_game_screen(victorious: bool) -> void:
	
	if death_handled:
		return
	
	death_handled = true
	
	if end_game_screen_packed == null:
		return
	
	var end_game_screen_scene: Control = end_game_screen_packed.instantiate()
	end_game_screen_scene.victorious = victorious

	var scene_handler: Node = get_node("/root/SceneHandler")
	end_game_screen_scene.repeat_level.connect(scene_handler.new_game)
	end_game_screen_scene.main_menu.connect(scene_handler.load_main_menu)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	canvas_layer.add_child(end_game_screen_scene)
	
