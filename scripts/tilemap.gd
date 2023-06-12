extends TileMap

@export var stand: PackedScene

class Tile:
	var tileset_location: Vector2i
	var tileset_src_id: int
	var render_offset: Vector2i
	func _init(set_location, set_src_id, rndr_offset = Vector2i.ZERO):
		tileset_location = set_location
		tileset_src_id = set_src_id
		render_offset = rndr_offset

var placeable_tiles: Array[Tile] = [
	Tile.new(Vector2i(16, 3), 0), # Walkable
	Tile.new(Vector2i(1, 5), 0, Vector2i(0, -1)), # Wall
	Tile.new(Vector2i(0, 0), 1), # Battery
	Tile.new(Vector2i(2, 0), 1), # Windup
	Tile.new(Vector2i(0, 2), 1), # Water
	Tile.new(Vector2i(2, 2), 1), # Bread
]

var selected_structure: int = 0

func _ready() -> void:
	GlobalData.tilemap = self
	update_Cursor()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if Input.is_key_pressed(KEY_SHIFT) or not $Cursor.visible:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		selected_structure += 1
		update_Cursor()
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		selected_structure -= 1
		update_Cursor()

func update_Cursor():
	if selected_structure < 0:
		selected_structure = placeable_tiles.size() - 1
	selected_structure = selected_structure % placeable_tiles.size()
	var selected_tile: Tile = placeable_tiles[selected_structure]
	var tileset_src: TileSetSource = tile_set.get_source(selected_tile.tileset_src_id)
	$Cursor.texture = tileset_src.texture
	$Cursor.region_rect = tileset_src.get_tile_texture_region(selected_tile.tileset_location)
	

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	$Cursor.position = $Cursor.position.lerp((mouse_pos + placeable_tiles[selected_structure].render_offset) * 16, delta * 30)
	
	$Cursor.visible = GlobalData.riding_vehicle != null
	if not $Cursor.visible:
		return
	
	var selected_tile: Tile = placeable_tiles[selected_structure]
	var tile_data: TileData = tile_set.get_source(selected_tile.tileset_src_id).get_tile_data(selected_tile.tileset_location, 0)
	var layer: int = tile_data.get_custom_data("place_layer")
	var cell_pointed_at: Vector2i = get_cell_atlas_coords(layer, mouse_pos)
	var cell_duplicate: bool = cell_pointed_at == selected_tile.tileset_location
	if Input.is_action_pressed("place") and not cell_duplicate:
		var price: int = tile_data.get_custom_data("price")
		if GlobalData.purchase(price, mouse_pos * 16):
			dig(mouse_pos, layer)
			set_cell(layer, mouse_pos, selected_tile.tileset_src_id, selected_tile.tileset_location)
	if Input.is_action_pressed("dig"):
		dig(mouse_pos, layer)

func dig(location: Vector2i, layer: int):
	var checked_cell: Vector2i = get_cell_atlas_coords(layer, location)
	if checked_cell != Vector2i(-1, -1):
		GlobalData.change_money_with_pos(get_cell_tile_data(layer, location).get_custom_data("price"), location * 16)
		erase_cell(layer, location)
