extends TileMap

@export var stand: PackedScene

var selected_structure: int = 4

func _ready() -> void:
	GlobalData.tilemap = self
	update_cursors()

func _input(event: InputEvent) -> void:
	if not $Cursors.visible:
		return
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
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
	
	$Cursors/CursorBuilding.visible = selected_structure < 4
	$Cursors/CursorBuilding.frame = selected_structure % 4
	
	$Cursors/CursorRoof.visible = not $Cursors/CursorBuilding.visible
	$Cursors/CursorRoof.frame_coords = [Vector2i(1, 7), Vector2i(16, 3)][(selected_structure - 4) % 2]
	$Cursors/CursorRoof/CursorRoof2.visible = selected_structure == 4

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	$Cursors/CursorRoof.position = $Cursors/CursorRoof.position.lerp(mouse_pos * 16, delta * 30)
	$Cursors/CursorBuilding.position = $Cursors/CursorRoof.position + Vector2(8, 24)
	
	$Cursors.visible = GlobalData.riding_vehicle != null
	if not $Cursors.visible:
		return
	
	if $Cursors/CursorBuilding.visible:
		if Input.is_action_just_pressed("place"):
			if GlobalData.purchase(100, mouse_pos * 16):
				set_cell(3, mouse_pos, 1, $Cursors/CursorBuilding.frame_coords * 2)
		if Input.is_action_pressed("dig"):
			dig(mouse_pos, 3, 100)
	else:
		var cell_pointed_at: Vector2i = get_cell_atlas_coords(2, mouse_pos)
		var selected_cell: Vector2i = [Vector2i(1, 5), Vector2i(16, 3)][(selected_structure - 4) % 2]
		var cell_duplicate: bool = cell_pointed_at == selected_cell
		if Input.is_action_pressed("place") and not cell_duplicate:
			if GlobalData.purchase(5, mouse_pos * 16):
				dig(mouse_pos, 2, 5)
				set_cell(2, mouse_pos, 0, selected_cell)
		if Input.is_action_pressed("dig"):
			dig(mouse_pos, 2, 5)

func dig(location: Vector2i, layer: int, price: int):
	if get_cell_atlas_coords(layer, location) != Vector2i(-1, -1):
		erase_cell(layer, location)
		GlobalData.change_money_with_pos(price, location * 16)
