extends CharacterBody2D

enum State {
	IDLE,
	FLEE,
	DEAD
}

@export_category("Stats")
@export var speed: int = 150
@export var flee_range: float = 400.0
@export var hitpoints: int = 120

@export_category("Related Scenes")
@export var death_packed: PackedScene
@export var item_pickup_scene: PackedScene 

var state: State = State.IDLE
var spawn_point: Vector2

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	animation_tree.set_active(true)
	
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 10.0
	
	call_deferred("actor_setup")


func actor_setup() -> void:
	await get_tree().physics_frame
	
	if spawn_point == Vector2.ZERO:
		spawn_point = global_position


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	
	if distance_to_player() <= flee_range:
		if state != State.FLEE:
			state = State.FLEE
		flee()
	else:
		if state != State.IDLE:
			state = State.IDLE
			velocity = Vector2.ZERO
			update_animation()


func distance_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)


func flee() -> void:
	var flee_direction = (global_position - player.global_position).normalized()
	var flee_target = global_position + flee_direction * 500.0
	
	nav_agent.target_position = flee_target
	
	if not nav_agent.is_navigation_finished():
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		velocity = direction * speed
	else:
		velocity = flee_direction * speed
	
	move_and_slide()
	
	if velocity.x < -0.01:
		$Sprite2D.flip_h = true
	elif velocity.x > 0.01:
		$Sprite2D.flip_h = false
	
	update_animation()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.FLEE:
			animation_playback.travel("run")


func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	state = State.FLEE
	update_animation()
	
	if hitpoints <= 0:
		death()


func death() -> void:
	state = State.DEAD
	
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()
	
	drop_steak()
	
	if death_packed:
		var death_scene: Node2D = death_packed.instantiate()
		var death_position = global_position
		
		var world_effects = get_tree().current_scene.get_node_or_null("Effects")
		
		if not world_effects:
			world_effects = Node2D.new()
			world_effects.name = "Effects"
			get_tree().current_scene.add_child(world_effects)
		
		world_effects.add_child(death_scene)
		death_scene.global_position = death_position
	
	EnemyRespawner.schedule_respawn(scene_file_path, 30.0)
	queue_free()


func drop_steak() -> void:
	if not item_pickup_scene:
		return
	
	var steak_item = item_pickup_scene.instantiate()
	
	steak_item.item_name = "Steak"
	steak_item.quantity = 1
	
	var world = get_tree().current_scene
	world.add_child(steak_item)
	steak_item.global_position = global_position
	
	var steak_texture = load("res://assets/sprites/loots/Steak.webp")
	if steak_texture and steak_item.has_node("item"):
		steak_item.get_node("item").texture = steak_texture
