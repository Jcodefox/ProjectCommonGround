extends GridContainer

class_name InventoryUI

signal item_dropped_on(item: Inventory.Item)

func _ready():
	get_parent().hidden.connect(parent_hidden)

func parent_hidden():
	emit_signal("hidden")

func _can_drop_data(position, data):
	return is_instance_valid(data) and data is GUIItem

func _drop_data(position, data):
	if data.get_parent() != self:
		if data.index >= 0 and data.parent_inventory != null:
			data.parent_inventory.remove_at(data.index)
		emit_signal("item_dropped_on", data.item_data)
