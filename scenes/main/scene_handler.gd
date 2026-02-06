extends Node

@export var main_menu_packed: PackedScene
@export var game_scene_packed: PackedScene

func _ready() -> void:
	load_main_menu("game_start")


func load_main_menu(origin: String) -> void:
	print("🏠 Chargement du menu, origine:", origin)
	
	cleanup_all_scenes()
	
	await get_tree().process_frame

	var main_menu: Control = main_menu_packed.instantiate()
	main_menu.new_game_pressed.connect(new_game)
	main_menu.settings_pressed.connect(settings_open)
	main_menu.about_pressed.connect(about_open)
	main_menu.exit_pressed.connect(exit_game)

	add_child(main_menu)


func new_game(origin: String) -> void:
	print("🎮 Nouvelle partie, origine:", origin)
	
	cleanup_all_scenes()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var game_scene: Node2D = game_scene_packed.instantiate()
	add_child(game_scene)
	print("✅ GameScene créée")


func cleanup_all_scenes() -> void:
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		main_menu.queue_free()
	
	var game_scene = get_node_or_null("GameScene")
	if game_scene:
		game_scene.queue_free()
	
	for child in get_children():
		if child is CanvasLayer:
			child.queue_free()


func settings_open(_origin: String) -> void:
	pass


func about_open(_origin: String) -> void:
	pass


func exit_game(_origin: String) -> void:
	get_tree().quit()
