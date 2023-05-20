extends Node

var money: int = 10000
var riding_vehicle: Area2D = null

func _ready() -> void:
	set_money(money)

func _process(_delta: float) -> void:
	get_tree().current_scene.get_node("CanvasLayer2/FPS").text = "%d FPS"%Engine.get_frames_per_second()

func set_money(new_money: int) -> void:
	money = new_money
	get_tree().current_scene.get_node("CanvasLayer2/Money").text = "$" + str(money)

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
