extends Area2D

@export var player_prefabs: Array[PackedScene] = []
var amount: int = 4

func _ready() -> void:
	get_node("../CanvasLayer2/Citizens").text = "%d citizens"%amount
	get_tree().create_timer(0.1).timeout.connect(spawn_citizen)

func spawn_citizen() -> void:
	if player_prefabs.size() <= 0:
		return
	amount += 1
	get_node("../CanvasLayer2/Citizens").text = "%d citizens"%amount
	var new_player: Node2D = player_prefabs.pick_random().instantiate()
	get_parent().add_child(new_player)
	new_player.get_node("Sprite2D").frame = [0, 1, 2, 3].pick_random()
	new_player.position = position
	get_tree().create_timer(0.1).timeout.connect(spawn_citizen)
