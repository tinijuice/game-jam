extends Area2D

@export var heal_amount: int = 1
@export var heal_interval: float = 2.0
@export var temperature_gain: int = 2

var players_nearby: Array = []
var is_healing: bool = false

var animation_player: AnimationPlayer


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	animation_player = find_child("AnimationPlayer", true, false)
	if animation_player and animation_player.has_animation("fire"):
		animation_player.play("fire")
	else:
		print("⚠️ AnimationPlayer ou animation 'fire' non trouvé")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if body not in players_nearby:
		players_nearby.append(body)
		print("🔥 Player près du feu")
		if not is_healing:
			start_healing()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if body in players_nearby:
		players_nearby.erase(body)
		print("❄️ Player éloigné du feu")
		if players_nearby.is_empty():
			is_healing = false


func start_healing() -> void:
	is_healing = true
	while is_healing and not players_nearby.is_empty():
		await get_tree().create_timer(heal_interval).timeout
		
		if not is_healing or players_nearby.is_empty():
			break
			
		for player in players_nearby:
			if is_instance_valid(player):
				heal_player(player)
				print("💚 +", heal_amount, " HP | 🌡️ +", temperature_gain, "°")


func heal_player(player: Node) -> void:
	if player.hitpoints < player.hitpoints_max:
		player.hitpoints += heal_amount
		player.hitpoints = clamp(player.hitpoints, 0, player.hitpoints_max)
		
		var hud = get_tree().get_root().get_node_or_null("HUD")
		if hud and hud.has_method("update_health"):
			hud.update_health(player.hitpoints)
	
	var temp_bar = get_tree().current_scene.find_child("TemperatureBar", true, false)
	if temp_bar and temp_bar.has_method("change_temperature"):
		temp_bar.change_temperature(temperature_gain)
