extends TextureProgressBar

@export var min_temp := -40
@export var max_temp := 40
@export var start_temp := 20

@export var decrease_every := 2
@export var cold_damage_start := 0
@export var extreme_cold_temp := -40
@export var extreme_cold_damage := 2 
@export var extreme_cold_damage_interval := 1.0

@export var player_path: NodePath

var current_temp: int
var player: Node = null
var is_near_fire: bool = false
var extreme_cold_timer: float = 0.0  # Timer pour les dégâts extrêmes

func _ready():
	min_value = min_temp
	max_value = max_temp

	current_temp = start_temp
	value = current_temp

	if player_path != null:
		player = get_node(player_path)

	start_cooling()


func _process(delta: float) -> void:
	# Infliger des dégâts continus à -40°
	if current_temp <= extreme_cold_temp and player:
		extreme_cold_timer += delta
		if extreme_cold_timer >= extreme_cold_damage_interval:
			player.take_damage(extreme_cold_damage)
			extreme_cold_timer = 0.0


func start_cooling() -> void:
	while true:
		await get_tree().create_timer(decrease_every).timeout
		if not is_near_fire:
			change_temperature(-1)


func change_temperature(amount: int) -> void:
	if not player:
		return

	var old_temp = current_temp
	current_temp = clamp(current_temp + amount, min_temp, max_temp)
	value = current_temp

	# Dégâts progressifs entre cold_damage_start et extreme_cold_temp
	if current_temp <= cold_damage_start and current_temp > extreme_cold_temp:
		var damage = abs(current_temp - old_temp)
		if damage > 0:
			player.take_damage(damage)


func reset_temperature() -> void:
	current_temp = start_temp
	value = current_temp
	extreme_cold_timer = 0.0