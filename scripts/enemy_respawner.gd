extends Node

var respawn_queue: Array = []

func schedule_respawn(enemy_scene_path: String, delay: float, spawn_position: Vector2) -> void:
	respawn_queue.append({
		"scene_path": enemy_scene_path,
		"position": spawn_position,
		"time_left": delay
	})

func _process(delta: float) -> void:
	for i in range(respawn_queue.size() - 1, -1, -1):
		respawn_queue[i].time_left -= delta
		
		if respawn_queue[i].time_left <= 0:
			respawn_enemy(respawn_queue[i].scene_path, respawn_queue[i].position)
			respawn_queue.remove_at(i)

func respawn_enemy(scene_path: String, spawn_position: Vector2) -> void:
	var enemy_scene = load(scene_path)
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.global_position = spawn_position
		enemy_instance.spawn_point = spawn_position
		
		get_tree().current_scene.add_child(enemy_instance)
		print("✅ Ennemi respawn à:", spawn_position)
