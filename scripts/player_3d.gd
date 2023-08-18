extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var building_types: Array[PackedScene] = []
var held_item: int = 0
var build_mode: bool = false

@export var world_item_prefab: PackedScene

@onready var inventory_ui: CanvasLayer = get_node("../InventoryUI")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var held_items: Array[Node3D] = []

func _ready():
	$Inventory.updated_items.connect(inventory_updated)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.x < 0:
		$Sprite3D.flip_h = true
	if direction.x > 0:
		$Sprite3D.flip_h = false
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("build_mode"):
		build_mode = not build_mode
	
	if Input.is_action_just_pressed("drop"):
		if held_items.size() > 0:
			$FloorLocator.force_raycast_update()
			var dropped_item: Node3D = held_items.pop_back()
			if $FloorLocator.is_colliding():
				dropped_item.position = $FloorLocator.get_collision_point() + Vector3(0.0, 0.4, 0.0)
			dropped_item.get_node("NoGrabCooldown").start(1)
			refresh_inventory()

	if Input.is_action_just_pressed("interact"):
		inventory_ui.visible = not inventory_ui.visible
		refresh_inventory()
		if inventory_ui.visible:
			$Inventory.attach_ui(inventory_ui.get_node("PlayerInventory/List"))
			attach_nearby_inventory()
		else:
			$Inventory.dettach_ui()
	
	for i in range(held_items.size()):
		held_items[i].position = position + Vector3(0, 1.2 + 0.8 * i, 0)

	for area in $ItemCollector.get_overlapping_areas():
		handle_area(area)

func attach_nearby_inventory():
	var other_inventory_ui: InventoryUI = inventory_ui.get_node("OtherInventory/List")
	other_inventory_ui.get_parent().visible = false
	for area in $ItemCollector.get_overlapping_bodies():
		if area == self:
			continue
		var inventory_to_attach: Node = area.find_child("Inventory")
		if inventory_to_attach and inventory_to_attach is Inventory:
			other_inventory_ui.get_parent().visible = true
			inventory_to_attach.attach_ui(other_inventory_ui)
			return

func handle_area(area: Area3D):
	if area.is_in_group("item") and not area in held_items:
		if not area.get_node("NoGrabCooldown").is_stopped():
			return
		held_items.push_back(area)
		refresh_inventory()

func refresh_inventory():
	var new_items: Array[Inventory.Item] = []
	for item in held_items:
		new_items.push_back(Inventory.Item.new(item.get_meta("item_type", "Item"), item.get_node("Sprite3D").texture))
	$Inventory.items = new_items
	$Inventory.update_ui()

func inventory_updated():
	for item in held_items:
		item.queue_free()
	held_items.clear()
	for item in $Inventory.items:
		var new_world_item: Node3D = world_item_prefab.instantiate()
		new_world_item.set_meta("item_type", item.name)
		new_world_item.get_node("Sprite3D").texture = item.icon
		get_parent().add_child(new_world_item)
		held_items.push_back(new_world_item)

func _notification(what: int):
	if what == NOTIFICATION_DRAG_END:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
