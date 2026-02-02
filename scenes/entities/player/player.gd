extends CharacterBody2D


enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: float = 400.0

var state: State = State.IDLE

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]


func _physics_process(_delta: float) -> void:
	movement_loop()


func movement_loop() -> void:
	var move_direction = Input.get_vector("left", "right", "up", "down")
	
	# DÉBOGAGE - À RETIRER APRÈS
	print("Direction: ", move_direction)
	print("Velocity: ", velocity)
	print("State: ", State.keys()[state])
	
	velocity = move_direction * speed
	move_and_slide()
	
	var new_state = State.RUN if move_direction != Vector2.ZERO else State.IDLE
	if new_state != state:
		state = new_state
		print("Changement d'état vers: ", State.keys()[state])
		update_animation()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")
		State.DEAD:
			animation_playback.travel("dead")
