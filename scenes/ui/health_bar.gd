extends TextureProgressBar

@export var player_path: NodePath
var player

func _ready():
	player = get_node(player_path)

	min_value = 0
	max_value = player.hitpoints_max
	value = player.hitpoints


func _process(_delta):
	value = player.hitpoints
