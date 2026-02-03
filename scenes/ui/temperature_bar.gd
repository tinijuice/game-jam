extends TextureProgressBar

@export var min_temp := -40
@export var max_temp := 40
@export var start_temp := 0

@export var decrease_every := 3
@export var cold_damage_start := -30
@export var extreme_cold_temp := -40
@export var extreme_cold_damage := 5

@export var player_path: NodePath

var current_temp: int
var player: Node = null

func _ready():
	min_value = min_temp
	max_value = max_temp

	current_temp = start_temp
	value = current_temp

	if player_path != null:
		player = get_node(player_path)
	if not player:
		print("⚠️ Player non assigné dans TemperatureBar !")

	start_cooling()


func start_cooling() -> void:
	while true:
		await get_tree().create_timer(decrease_every).timeout
		change_temperature(-1)


func change_temperature(amount: int) -> void:
	if not player:
		return

	var old_temp = current_temp
	current_temp = clamp(current_temp + amount, min_temp, max_temp)
	value = current_temp

	if current_temp <= cold_damage_start and current_temp > extreme_cold_temp:
		var damage = abs(current_temp - old_temp)
		if damage > 0:
			player.take_damage(damage)
	elif current_temp <= extreme_cold_temp:
		player.take_damage(extreme_cold_damage)


func reset_temperature() -> void:
	current_temp = start_temp
	value = current_temp
	print("🌡️ Température réinitialisée à: ", start_temp)