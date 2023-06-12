extends Node

var money: int = 10000
var riding_vehicle: Area2D = null

var tilemap: TileMap

func _ready() -> void:
	set_money(money)

func _process(_delta: float) -> void:
	get_tree().current_scene.get_node("CanvasLayer/FPS").text = "%d FPS"%Engine.get_frames_per_second()

func set_money(new_money: int) -> void:
	money = new_money
	get_tree().current_scene.get_node("CanvasLayer/Money").text = "$" + str(money)

func purchase(change_amount: int, pos: Vector2=Vector2(-500000,-500000)) -> bool:
	if money < change_amount:
		return false
	change_money_with_pos(-change_amount, pos)
	return true

func change_money_with_pos(change_amount: int, pos: Vector2=Vector2(-500000,-500000)):
	set_money(money + change_amount)
	if pos.x > -49999 and pos.y > -49999:
		var money_sub: Label = Label.new()
		money_sub.text = ("+$" if change_amount > 0 else "-$") + str(abs(change_amount))
		get_tree().current_scene.add_child(money_sub)
		money_sub.position = pos
		money_sub.z_index = 500
		money_sub.scale = Vector2(0.5, 0.5)
		money_sub.add_theme_color_override("font_color", Color.GREEN if change_amount > 0 else Color.RED)
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(money_sub, "position", money_sub.position - Vector2(0, 32), 0.5)
		tween.tween_callback(money_sub.queue_free)

func get_beds() -> Array[Vector2i]:
	var beds: Array[Vector2i] = tilemap.get_used_cells_by_id(3, 4, Vector2i.ZERO)
	for i in range(beds.size()):
		beds[i] = beds[i] * 16 + Vector2i(8, 8)
	return beds

func get_stands_of_type(type: String) -> Array[Vector2i]:
	const type_to_coords: Dictionary = {
		"battery": Vector2i(0, 0),
		"windup": Vector2i(2, 0),
		"water": Vector2i(0, 2),
		"food": Vector2i(2, 2),
	}
	var stands: Array[Vector2i] = tilemap.get_used_cells_by_id(3, 1, type_to_coords[type])
	for i in range(stands.size()):
		stands[i] = stands[i] * 16 + Vector2i(8, 8)
	return stands
