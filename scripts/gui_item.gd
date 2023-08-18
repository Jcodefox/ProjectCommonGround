extends TextureRect

class_name GUIItem

var parent_inventory: Inventory = null
var item_data: Inventory.Item = Inventory.Item.new("Item")
var index: int = -1

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(32, 32)

func _get_drag_data(at_position):
	if item_data:
		set_drag_preview(duplicate(0))
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	return self

func _notification(what: int):
	if what == NOTIFICATION_DRAG_END:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		visible = true
