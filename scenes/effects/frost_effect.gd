extends CanvasLayer

@onready var frost_overlay: ColorRect = $FrostOverlay
@onready var frost_texture: TextureRect = $FrostTexture

var max_frost_opacity: float = 0.8


func _ready() -> void:
	# TEST : force l'affichage au démarrage
	frost_overlay.modulate.a = 0.5
	print("FrostEffect ready - Alpha:", frost_overlay.modulate.a)
	
	if frost_texture:
		frost_texture.modulate.a = 0.5


func update_frost_effect(current_temp: float) -> void:
	print("Température reçue:", current_temp)
	
	if current_temp >= -30.0:
		frost_overlay.modulate.a = 0.0
		if frost_texture:
			frost_texture.modulate.a = 0.0
	elif current_temp <= -40.0:
		frost_overlay.modulate.a = max_frost_opacity
		if frost_texture:
			frost_texture.modulate.a = max_frost_opacity
	else:
		var frost_progress = (-30.0 - current_temp) / 10.0
		frost_overlay.modulate.a = frost_progress * max_frost_opacity
		if frost_texture:
			frost_texture.modulate.a = frost_progress * max_frost_opacity
	
	print("Alpha après calcul:", frost_overlay.modulate.a)
