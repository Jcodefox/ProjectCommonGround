extends TileMap

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	$Sprite2D.position = $Sprite2D.position.lerp(mouse_pos * 16, delta * 30)
	if Input.is_action_pressed("place"):
		set_cell(3, mouse_pos, 3, Vector2i.ZERO)
	if Input.is_action_pressed("dig"):
		set_cell(3, mouse_pos)
