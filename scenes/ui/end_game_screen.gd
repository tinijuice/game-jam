extends Control

signal repeat_level(origin: String)
signal main_menu(origin: String)

var victorious: bool 

func _on_replay_pressed() -> void:
	# ⭐ Émet le signal AVANT de supprimer
	repeat_level.emit("end_game_screen")
	await get_tree().process_frame
	get_parent().queue_free()  # Supprime le CanvasLayer après


func _on_main_menu_pressed() -> void:
	# ⭐ Émet le signal AVANT de supprimer
	main_menu.emit("end_game_screen")
	await get_tree().process_frame
	get_parent().queue_free()  # Supprime le CanvasLayer après