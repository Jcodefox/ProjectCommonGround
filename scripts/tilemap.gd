extends TileMap

@export var stand: PackedScene
var cursor: Sprite2D = Sprite2D.new()

class Tile:
	var tileset_location: Vector2i
	var tileset_src_id: int
	func _init(set_location, set_src_id):
		tileset_location = set_location
		tileset_src_id = set_src_id

var placeable_tiles: Array[Tile] = [
	Tile.new(Vector2i(16, 3), 0), # Walkable
	Tile.new(Vector2i(1, 5), 0), # Wall
	Tile.new(Vector2i(0, 2), 1), # Water
	Tile.new(Vector2i(2, 2), 1), # Bread
	Tile.new(Vector2i(0, 0), 1), # Battery
	Tile.new(Vector2i(2, 0), 1), # Windup
	Tile.new(Vector2i(0, 0), 4), # Bed
	Tile.new(Vector2i(0, 0), 3), # Landing pad
	Tile.new(Vector2i(0, 0), 5), # Plant
]

var bed_data: Dictionary = {}

var selected_structure: int = 0

@export var npc_prefabs: Array[PackedScene] = []
var npc_amount: int = 0

func _ready() -> void:
	add_child(cursor)
	cursor.name = "Cursor"
	cursor.visible = false
	cursor.region_enabled =true
	cursor.offset = Vector2i(8, 8)
	GlobalData.tilemap = self
	update_Cursor()
	get_node("../CanvasLayer/Citizens").text = "%d citizens"%npc_amount
	get_tree().create_timer(5).timeout.connect(spawn_citizen)

func spawn_citizen() -> void:
	var landing_pads: Array[Vector2i] = get_used_cells_by_id(3, 3, Vector2i.ZERO)
	get_tree().create_timer(max(1, 10 - landing_pads.size())).timeout.connect(spawn_citizen)
	if npc_prefabs.size() <= 0:
		return
	if landing_pads.size() <= 0:
		return
	npc_amount += 1
	get_node("../CanvasLayer/Citizens").text = "%d citizens"%npc_amount
	var new_npc: Node2D = npc_prefabs.pick_random().instantiate()
	get_parent().add_child(new_npc)
	new_npc.get_node("Sprite2D").frame = [0, 1, 2, 3].pick_random()
	if new_npc.get_node("Sprite2D").frame == 2:
		new_npc.needs[0].stand = "battery"
		new_npc.needs[1].stand = "windup"
	new_npc.position = landing_pads.pick_random() * 16

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if Input.is_key_pressed(KEY_SHIFT) or not cursor.visible:
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
	cursor.texture = tileset_src.texture
	cursor.region_rect = tileset_src.get_tile_texture_region(selected_tile.tileset_location)
	

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	
	var selected_tile: Tile = placeable_tiles[selected_structure]
	var tile_data: TileData = tile_set.get_source(selected_tile.tileset_src_id).get_tile_data(selected_tile.tileset_location, 0)
	
	cursor.position = cursor.position.lerp((mouse_pos * 16) - tile_data.texture_origin, delta * 30)
	
	cursor.visible = GlobalData.riding_vehicle != null
	if not cursor.visible:
		return
	
	var layer: int = tile_data.get_custom_data("place_layer")
	var cell_pointed_at: Vector2i = get_cell_atlas_coords(layer, mouse_pos)
	var cell_duplicate: bool = cell_pointed_at == selected_tile.tileset_location
	if Input.is_action_pressed("place") and not cell_duplicate:
		var price: int = tile_data.get_custom_data("price")
		if GlobalData.purchase(price, mouse_pos * 16):
			dig(mouse_pos, layer)
			set_cell(layer, mouse_pos, selected_tile.tileset_src_id, selected_tile.tileset_location)
			if selected_structure == 6:
				bed_data[mouse_pos] = null
	if Input.is_action_pressed("dig"):
		dig(mouse_pos, layer)

func dig(location: Vector2i, layer: int):
	var checked_cell: Vector2i = get_cell_atlas_coords(layer, location)
	if checked_cell == placeable_tiles[6].tileset_location and get_cell_source_id(layer, location) == placeable_tiles[6].tileset_src_id:
		bed_data.erase(location)
	if checked_cell != Vector2i(-1, -1):
		GlobalData.change_money_with_pos(get_cell_tile_data(layer, location).get_custom_data("price"), location * 16)
		erase_cell(layer, location)
