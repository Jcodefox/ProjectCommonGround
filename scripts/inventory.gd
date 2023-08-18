extends Node

class_name Inventory

signal updated_items

class Item:
	var name: String = ""
	var icon: Texture = null
	func _init(new_item_name: String, new_item_icon: Texture = null):
		name = new_item_name
		icon = new_item_icon
	func _to_string():
		return name

var items: Array[Item] = []
var attached_ui: InventoryUI = null

func add_item(new_item: Item):
	items.push_back(new_item)
	emit_signal("updated_items")
	update_ui()

func remove_at(index: int):
	items.remove_at(index)
	emit_signal("updated_items")
	update_ui()

func clear():
	items.clear()
	emit_signal("inventory_updated")
	update_ui()

func get_item_names() -> Array[String]:
	var result: Array[String] = []
	for item in items:
		result.push_back(str(item))
	return result

func attach_ui(inventory_ui: InventoryUI):
	attached_ui = inventory_ui
	attached_ui.item_dropped_on.connect(add_item)
	attached_ui.hidden.connect(dettach_ui)
	update_ui()

func dettach_ui():
	if attached_ui:
		attached_ui.item_dropped_on.disconnect(add_item)
		attached_ui.hidden.disconnect(dettach_ui)
	attached_ui = null

func update_ui():
	if not attached_ui:
		return
	for child in attached_ui.get_children():
		child.queue_free()
	for item_index in range(items.size()):
		var new_item: GUIItem = GUIItem.new()
		new_item.item_data = items[item_index]
		new_item.index = item_index
		new_item.texture = items[item_index].icon
		new_item.parent_inventory = self
		attached_ui.add_child(new_item)
