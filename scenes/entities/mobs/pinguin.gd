extends CharacterBody2D

enum State {
	IDLE,
	WANDER,
	DEAD
}

@export_category("Stats")
@export var speed: int = 80
@export var hitpoints: int = 120

@export_category("Wander Settings")
@export var wander_time_min: float = 2.0
@export var wander_time_max: float = 5.0
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0
@export var wander_radius: float = 300.0

@export_category("Related Scenes")
@export var death_packed: PackedScene
@export var item_pickup_scene: PackedScene 

var state: State = State.IDLE
var spawn_point: Vector2
var wander_target: Vector2
var state_timer: float = 0.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
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
	
	start_idle()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	state_timer -= delta
	
	match state:
		State.IDLE:
			if state_timer <= 0:
				start_wander()
		
		State.WANDER:
			wander()
			if state_timer <= 0 or nav_agent.is_navigation_finished():
				start_idle()


func start_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	state_timer = randf_range(idle_time_min, idle_time_max)
	update_animation()


func start_wander() -> void:
	state = State.WANDER
	state_timer = randf_range(wander_time_min, wander_time_max)
	
	var random_angle = randf() * TAU
	var random_distance = randf_range(50.0, wander_radius)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	wander_target = spawn_point + offset
	nav_agent.target_position = wander_target
	
	update_animation()


func wander() -> void:
	if nav_agent.is_navigation_finished():
		return
	
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	velocity = direction * speed
	
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
		State.WANDER:
			animation_playback.travel("run")


func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	
	if hitpoints <= 0:
		death()


func death() -> void:
	state = State.DEAD
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()
	
	drop_vincent()  # ← Changé ici
	
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


func drop_vincent() -> void:  # ← Renommé
	if not item_pickup_scene:
		return
	
	var vincent_item = item_pickup_scene.instantiate()  # ← Renommé
	
	vincent_item.item_name = "Vincent"
	vincent_item.quantity = 1
	
	var world = get_tree().current_scene
	world.add_child(vincent_item)
	vincent_item.global_position = global_position
	
	var vincent_texture = load("res://assets/sprites/loots/Vincent.jpeg")  # ← Renommé
	if vincent_texture and vincent_item.has_node("item"):
		vincent_item.get_node("item").texture = vincent_texture
	
	print("Vincent créé à: ", vincent_item.global_position)
