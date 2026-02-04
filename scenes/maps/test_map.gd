extends Node2D  # ← IMPORTANT : doit correspondre au type de node

func _ready():
	# Enregistrer les zones de spawn
	await get_tree().process_frame
	EnemyRespawner.register_spawn_zones()
