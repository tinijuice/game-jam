extends Node

var spawn_zones: Array = []

func register_spawn_zones() -> void:
	spawn_zones.clear()
	
	# Récupérer toutes les zones de spawn
	var zones = get_tree().get_nodes_in_group("spawn_zones")
	
	for zone in zones:
		spawn_zones.append(zone)
	
	print("🎯 Zones de spawn enregistrées : ", spawn_zones.size())

func get_random_spawn_position() -> Vector2:
	if spawn_zones.is_empty():
		print("⚠️ Aucune zone de spawn, position par défaut")
		return Vector2(500, 500)
	
	# Choisir une zone aléatoire
	var random_zone = spawn_zones.pick_random()
	
	# Obtenir un point aléatoire dans cette zone
	return random_zone.get_random_point_inside()

func schedule_respawn(enemy_scene_path: String, delay: float = 90.0) -> void:
	print("🔄 Respawn programmé")
	
	await get_tree().create_timer(delay).timeout
	
	var world = get_tree().current_scene
	if not is_instance_valid(world):
		return
	
	var enemies_container = world.get_node_or_null("Enemies")
	if not enemies_container:
		enemies_container = world
	
	var new_enemy = load(enemy_scene_path).instantiate()
	enemies_container.call_deferred("add_child", new_enemy)
	
	await get_tree().process_frame
	
	# Obtenir une position dans une zone de spawn
	var random_pos = get_random_spawn_position()
	
	new_enemy.global_position = random_pos
	new_enemy.spawn_point = random_pos
	
	print("✅ Ennemi respawné à : ", random_pos)