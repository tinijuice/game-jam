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

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	animation_tree.set_active(true)
	await get_tree().process_frame
	
	# Initialiser spawn_point
	if spawn_point == Vector2.ZERO:
		spawn_point = global_position


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	if state == State.ATTACK:
		return
	if distance_to_player() <= attack_range:
		state = State.ATTACK
		attack()
	elif distance_to_player() <= aggro_range:
		state = State.CHASE
		move()
	elif global_position.distance_to(spawn_point) > 32:
		state = State.RETURN
		move()
	elif state != State.IDLE:
		state = State.IDLE
		update_animation()


func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)


func move() -> void:
	if state == State.CHASE:
		nav_agent.target_position = player.global_position
	elif state == State.RETURN:
		nav_agent.target_position = spawn_point
	
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
	var player_pos: Vector2 = player.global_position
	var attack_dir: Vector2 = (player_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()

	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE


func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()


func death() -> void:
	state = State.DEAD
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()
	
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
	
	EnemyRespawner.schedule_respawn(scene_file_path, 15.0)
	
	queue_free()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("take_damage"):
		area.owner.take_damage(attack_damage)