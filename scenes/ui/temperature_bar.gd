extends Control

# Variable température actuelle
var temperature: float = 0

# Référence aux nodes enfants
@onready var bar: ProgressBar = $Bar
@onready var label: Label = $Label

# Intervalle de mise à jour (en secondes)
const INTERVAL: float = 3.0

func _ready():
	# Initialiser la barre et le label
	bar.value = temperature
	label.text = str(temperature) + "°C"

	# Lancer le timer pour faire descendre la température
	start_temperature_loop()

# Fonction pour mettre à jour la température toutes les 3 secondes
func start_temperature_loop() -> void:
	# Utilisation d'un timer intégré
	async_func()

# Fonction asynchrone qui boucle
async func async_func() -> void:
	while true:
		await get_tree().create_timer(INTERVAL).timeout
		change_temperature(-1)

# Fonction qui change la température et met à jour barre + label
func change_temperature(delta: float) -> void:
	temperature += delta
	temperature = clamp(temperature, -40, 40)
	bar.value = temperature
	label.text = str(temperature) + "°C"
