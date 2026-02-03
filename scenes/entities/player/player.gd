extends CharacterBody2D

enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: int = 400
@export var attack_speed: float = 0.6
@export var attack_damage: int = 60
@export var hitpoints: int = 120
@export var hitpoints_max: int = 150
@export_category("Related Scenes")
@export var death_packed: PackedScene


var state: State = State.IDLE
var move_direction: Vector2 = Vector2(0, 0)

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	update_health_bar()
	$HitBox.monitoring = false
	animation_tree.set_active(true)
	health_bar.min_value = 0
	health_bar.max_value = hitpoints_max
	health_bar.value = hitpoints


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()


var last_monitoring_state: bool = false

func _physics_process(_delta: float) -> void:
	# Print seulement quand le monitoring change
	if $HitBox.monitoring != last_monitoring_state:
		print("⚡ Monitoring changé: ", $HitBox.monitoring)
		last_monitoring_state = $HitBox.monitoring
	
	if not state == State.ATTACK:
		movement_loop()


func movement_loop() -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()

	
	if state == State.IDLE or state == State.RUN:
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		if move_direction.x > 0.01:
			$Sprite2D.flip_h = false

	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif motion == Vector2.ZERO and state == State.RUN:
		state = State.IDLE
		update_animation()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")
	

func attack() -> void:
	if state == State.ATTACK:
		return
	state = State.ATTACK

	var mouse_pos: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()

	await get_tree().create_timer(attack_speed).timeout
	
	if move_direction != Vector2.ZERO:
		state = State.RUN
	else:
		state = State.IDLE
	update_animation()


func take_damage(damage_taken: int) -> void:
	hitpoints -= damage_taken
	hitpoints = clamp(hitpoints, 0, hitpoints_max)
	update_health_bar()
	if hitpoints <= 0 and state != State.DEAD:
		death()


func update_health_bar() -> void:
	if is_instance_valid(health_bar):
		health_bar.value = hitpoints
	if is_instance_valid(health_label):
		health_label.text = str(hitpoints)


func death() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD

	# Stoppe complètement le player
	velocity = Vector2.ZERO
	$HitBox.monitoring = false

	# Instancie la scène de mort
	if death_packed != null:
		var death_scene: Node2D = death_packed.instantiate()
		death_scene.position = global_position + Vector2(0, -32)
		%Effects.add_child(death_scene)

	# Masque le player
	$Sprite2D.visible = false
	$HealthBar.visible = false

	# Timer avant respawn
	await get_tree().create_timer(2.0).timeout

	# Respawn
	hitpoints = hitpoints_max
	update_health_bar()

	global_position = spawn_point.global_position
	state = State.IDLE
	
	$HitBox.monitoring = true
	$Sprite2D.visible = true
	$HealthBar.visible = true


func _on_hit_box_area_entered(area: Area2D) -> void:
	area.owner.take_damage(attack_damage)
