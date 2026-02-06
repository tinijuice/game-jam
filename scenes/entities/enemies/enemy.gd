extends CharacterBody2D


enum State {
	IDLE,
	CHASE,
	RETURN,
	RUN,
	ATTACK,
	DEAD
}


@export_category("Stats")
@export var speed: int = 128
@export var attack_damage: int = 10
@export var attack_speed: float = 1.0
@export var aggro_range: float = 256.0
@export var attack_range: float = 80.0
@export var hitpoints: int = 180
@export_category("Related Scenes")
@export var death_packed: PackedScene

var state: State = State.IDLE
var spawn_point: Vector2
var has_chased: bool = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var idle_sounds: Array[AudioStreamPlayer2D] = []  

var sound_timer: float = 0.0
var sound_interval: float = 0.0

var player: CharacterBody2D = null

var wander_timer: float = 0.0
var wander_interval: float = 3.0
var wander_radius: float = 100.0
var wander_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	animation_tree.set_active(true)
	await get_tree().process_frame
	
	if spawn_point == Vector2.ZERO:
		spawn_point = global_position
	
	load_idle_sounds()
	
	sound_interval = randf_range(3.0, 15.0)
	sound_timer = randf_range(0.0, sound_interval)
	
	wander_interval = randf_range(2.0, 5.0)
	wander_timer = randf_range(0.0, wander_interval)


func load_idle_sounds() -> void:
	var sound_mob = get_node_or_null("SoundMob")
	
	if not sound_mob:
		push_warning("Aucun node 'SoundMob' trouvé pour %s" % name)
		return
	
	for child in sound_mob.get_children():
		if child is AudioStreamPlayer2D:
			idle_sounds.append(child)
	
	if idle_sounds.is_empty():
		push_warning("Aucun AudioStreamPlayer2D trouvé dans SoundMob de %s" % name)


func get_player() -> CharacterBody2D:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	return player


func _physics_process(delta: float) -> void:
	if state != State.DEAD:
		sound_timer += delta
		if sound_timer >= sound_interval:
			play_random_idle_sound()
			sound_timer = 0.0
		
		wander_timer += delta
		if wander_timer >= wander_interval and state == State.IDLE:
			set_new_wander_target()
			wander_timer = 0.0
			wander_interval = randf_range(2.0, 5.0)
	
	var current_player = get_player()
	
	if not is_instance_valid(current_player):
		if state != State.IDLE and state != State.DEAD:
			state = State.IDLE
			velocity = Vector2.ZERO
			var walk_sound = get_node_or_null("Walk")
			if walk_sound and walk_sound is AudioStreamPlayer2D:
				walk_sound.stop()
			update_animation()
		return
	
	if state == State.DEAD:
		return
	if state == State.ATTACK:
		var walk_sound = get_node_or_null("Walk")
		if walk_sound and walk_sound is AudioStreamPlayer2D:
			walk_sound.stop()
		return
	
	if distance_to_player() <= attack_range:
		state = State.ATTACK
		var walk_sound = get_node_or_null("Walk")
		if walk_sound and walk_sound is AudioStreamPlayer2D:
			walk_sound.stop()
		attack()
	elif distance_to_player() <= aggro_range:
		state = State.CHASE
		has_chased = true
		move()
	elif global_position.distance_to(spawn_point) > 32 and has_chased:
		state = State.RETURN
		move()
	elif state == State.IDLE and wander_target != Vector2.ZERO:
		if global_position.distance_to(wander_target) > 10:
			move()
		else:
			wander_target = Vector2.ZERO
			velocity = Vector2.ZERO
			var walk_sound = get_node_or_null("Walk")
			if walk_sound and walk_sound is AudioStreamPlayer2D:
				walk_sound.stop()
			update_animation()
	elif state != State.IDLE:
		state = State.IDLE
		velocity = Vector2.ZERO
		wander_target = Vector2.ZERO
		var walk_sound = get_node_or_null("Walk")
		if walk_sound and walk_sound is AudioStreamPlayer2D:
			walk_sound.stop()
		update_animation()


func distance_to_player() -> float:
	var current_player = get_player()
	if not is_instance_valid(current_player):
		return INF
	return global_position.distance_to(current_player.global_position)



func set_new_wander_target() -> void:
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	wander_target = spawn_point + random_offset


func move() -> void:
	var current_player = get_player()
	if not is_instance_valid(current_player):
		return
	
	if state == State.CHASE:
		nav_agent.target_position = current_player.global_position
	elif state == State.RETURN:
		nav_agent.target_position = spawn_point
	elif state == State.IDLE and wander_target != Vector2.ZERO:
		nav_agent.target_position = wander_target
	
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	velocity = global_position.direction_to(next_path_position) * speed

	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)
	move_and_slide()

	if state == State.IDLE or State.CHASE:
		if velocity.x < -0.01:
			$Sprite2D.flip_h = true
		elif velocity.x > 0.01:
			$Sprite2D.flip_h = false
	
	var walk_sound = get_node_or_null("Walk")
	if walk_sound and walk_sound is AudioStreamPlayer2D:
		if velocity != Vector2.ZERO:
			if not walk_sound.playing:
				walk_sound.play()
		else:
			walk_sound.stop()
	
	update_animation()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	nav_agent.velocity = safe_velocity


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.CHASE:
			animation_playback.travel("run")
		State.RETURN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")


func attack() -> void:
	var current_player = get_player()
	if not is_instance_valid(current_player):
		state = State.IDLE
		return
	
	var player_pos: Vector2 = current_player.global_position
	var attack_dir: Vector2 = (player_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()
	
	var attack_sound = get_node_or_null("AttackSound")
	if attack_sound and attack_sound is AudioStreamPlayer2D and not attack_sound.playing:
		attack_sound.play()

	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE


func play_random_idle_sound() -> void:
	if idle_sounds.is_empty():
		return
	
	var random_sound = idle_sounds.pick_random()
	if random_sound and not random_sound.playing:
		random_sound.play()
	
	sound_interval = randf_range(3.0, 15.0)


func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()


func death() -> void:
	state = State.DEAD
	
	var current_player = get_player()
	if is_instance_valid(current_player) and current_player.has_method("on_enemy_killed"):
		current_player.on_enemy_killed()
	
	if death_packed:
		var death_scene: Node2D = death_packed.instantiate()
		var death_position = global_position + Vector2(0.0, -32.0)
		
		var world_effects = get_tree().current_scene.get_node_or_null("Effects")
		
		if not world_effects:
			world_effects = Node2D.new()
			world_effects.name = "Effects"
			get_tree().current_scene.add_child(world_effects)
		
		world_effects.add_child(death_scene)
		death_scene.global_position = death_position
	
	EnemyRespawner.schedule_respawn(scene_file_path, 45.0, spawn_point)
	
	queue_free()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("take_damage"):
		area.owner.take_damage(attack_damage)
