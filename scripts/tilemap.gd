extends TileMap

@export var stand: PackedScene

var selected_structure: int = 4

func _ready() -> void:
	update_cursors()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if Input.is_key_pressed(KEY_SHIFT):
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		selected_structure += 1
		update_cursors()
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		selected_structure -= 1
		update_cursors()

func update_cursors():
	if selected_structure < 0:
		selected_structure = 5
	selected_structure = selected_structure % 6
	
	$CursorBuilding.visible = selected_structure < 4
	$CursorBuilding.frame = selected_structure % 4
	
	$CursorRoof.visible = not $CursorBuilding.visible
	$CursorRoof.frame_coords = [Vector2i(1, 7), Vector2i(16, 3)][(selected_structure - 4) % 2]
	$CursorRoof/CursorRoof2.visible = selected_structure == 4

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	$CursorRoof.position = $CursorRoof.position.lerp(mouse_pos * 16, delta * 30)
	$CursorBuilding.position = $CursorRoof.position + Vector2(8, 24)
	if $CursorBuilding.visible:
		if Input.is_action_just_pressed("place"):
			var new_stand: Node2D = stand.instantiate()
			new_stand.position = mouse_pos * 16 + Vector2i(8, 8)
			new_stand.add_to_group(["battery", "windup", "water", "food"][$CursorBuilding.frame])
			new_stand.get_node("Icon").frame = $CursorBuilding.frame
			new_stand.connect("input_event", stand_input_event.bind(new_stand))
			get_parent().add_child(new_stand)
	else:
		if Input.is_action_pressed("place"):
			set_cell(2, mouse_pos, 0, [Vector2i(1, 5), Vector2i(16, 3)][(selected_structure - 4) % 2])
		if Input.is_action_pressed("dig"):
			erase_cell(2, mouse_pos)

func stand_input_event(viewport: Node, event: InputEvent, shape_idx: int, stand: Node2D):
	if not event is InputEventMouseButton or not $CursorBuilding.visible:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		stand.queue_free()
