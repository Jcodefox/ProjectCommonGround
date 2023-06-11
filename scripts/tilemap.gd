extends TileMap

@export var stand: PackedScene

class Tile:
	var render_src: Texture2D
	var tileset_location: Vector2i
	var tileset_src_id: int
	var tilemap_layer: int
	var price: int
	var render_offset: Vector2i
	func _init(rndr_src, set_location, set_src_id, map_layer, prc, rndr_offset = Vector2i.ZERO):
		tileset_location = set_location
		tileset_src_id = set_src_id
		tilemap_layer = map_layer
		price = prc
		render_src = rndr_src
		render_offset = rndr_offset

const GROUND_TILESET: Texture2D = preload("res://sprites/tiles_packed_1.png")
const STANDS_TILESET: Texture2D = preload("res://sprites/tiles_packed_1.png")

var placeable_tiles: Array[Tile] = [
	Tile.new(GROUND_TILESET, Vector2i(16, 3), 0, 2, 5), # Walkable
	Tile.new(GROUND_TILESET, Vector2i(1, 5), 0, 2, 5, Vector2i(0, -1)), # Wall
	Tile.new(STANDS_TILESET, Vector2i(0, 0), 1, 3, 100), # Battery
	Tile.new(STANDS_TILESET, Vector2i(2, 0), 1, 3, 100), # Windup
	Tile.new(STANDS_TILESET, Vector2i(0, 2), 1, 3, 100), # Water
	Tile.new(STANDS_TILESET, Vector2i(2, 2), 1, 3, 100), # Bread
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
	$Cursor.texture = placeable_tiles[selected_structure].render_src
	$Cursor.region_rect = tile_set.get_source(placeable_tiles[selected_structure].tileset_src_id).get_tile_texture_region(placeable_tiles[selected_structure].tileset_location)

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
	var cell_pointed_at: Vector2i = get_cell_atlas_coords(selected_tile.tilemap_layer, mouse_pos)
	var cell_duplicate: bool = cell_pointed_at == selected_tile.tileset_location
	if Input.is_action_pressed("place") and not cell_duplicate:
		if GlobalData.purchase(selected_tile.price, mouse_pos * 16):
			dig(mouse_pos, selected_tile.tilemap_layer, 5)
			set_cell(selected_tile.tilemap_layer, mouse_pos, selected_tile.tileset_src_id, selected_tile.tileset_location)
	if Input.is_action_pressed("dig"):
		dig(mouse_pos, selected_tile.tilemap_layer, 5)

func dig(location: Vector2i, layer: int, price: int):
	if get_cell_atlas_coords(layer, location) != Vector2i(-1, -1):
		erase_cell(layer, location)
		GlobalData.change_money_with_pos(price, location * 16)
