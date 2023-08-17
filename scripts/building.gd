extends CSGShape3D

var is_placeholder: bool = true
var height: float = 3.0
var mouse_down_pos: Vector3 = Vector3.ZERO
var was_mouse_pressed: bool = false

var place_mode: bool = false
var cursor: Node3D
var door_prefab := preload("res://prefabs/door.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = not is_placeholder
	if is_placeholder:
		cursor = $"../Cursor"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not is_placeholder:
		if Input.is_action_just_pressed("dig"):
			var result := raycast(was_mouse_pressed, 8)
#			print(result)
#			if result.has("collider"):
#				result["collider"].queue_free()
		return
	if Input.is_action_just_pressed("interact"):
		place_mode = not place_mode
	if not place_mode:
		return
	
	var tmp_result := raycast(was_mouse_pressed, 4 if was_mouse_pressed else 2)
	if tmp_result.has("position"):
		cursor.position = tmp_result["position"]
		if tmp_result["normal"] != Vector3.UP and tmp_result["normal"] != Vector3.DOWN:
			#cursor.look_at(cursor.position + tmp_result["normal"])
			pass
		else:
			cursor.look_at(cursor.position + tmp_result["normal"], Vector3.FORWARD)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		visible = true
		if Input.is_action_just_pressed("scroll_up"):
			height += 1.0
		if Input.is_action_just_pressed("scroll_down"):
			height -= 1.0
			height = max(height, 1.0)
		var result := raycast(was_mouse_pressed, 4 if was_mouse_pressed else 2)
		if result.has("position"):
			if not was_mouse_pressed:
				mouse_down_pos = result["position"]
			var corner_a: Vector3 = mouse_down_pos
			var corner_b: Vector3 = result["position"]
			corner_a.y = 0.0
			corner_b.y = 0.0
			$CSGBox3D.size = abs(corner_b - corner_a) * Vector3(1, 0, 1)
			position.x = (corner_a.x + corner_b.x) * 0.5
			position.z = (corner_a.z + corner_b.z) * 0.5
			$CSGBox3D.size += Vector3(0, height, 0)
			$CSGBox3D2.size = $CSGBox3D.size - Vector3(0.1, 0.1, 0.1)
			position.y = abs(mouse_down_pos.y + $CSGBox3D.size.y * 0.5)
			$PlacementArea.global_position.y = mouse_down_pos.y
			$PlacementArea/CollisionShape3D.shape.size = abs(Vector3($CSGBox3D.size.x * 2, 0.01, $CSGBox3D.size.z * 2)) + Vector3(10.0, 0.0, 10.0)
		was_mouse_pressed = true
	else:
		if was_mouse_pressed:
			var new_building := duplicate(7)
			new_building.get_node("PlacementArea").queue_free()
			new_building.is_placeholder = false
			new_building.use_collision = true
			get_node("../").add_child(new_building)
			visible = false
		was_mouse_pressed = false
	if Input.is_action_just_pressed("dig"):
		var result := raycast(was_mouse_pressed, 4 if was_mouse_pressed else 2)
		if result.has("position") and result["collider"].is_in_group("building"):
			var new_door := door_prefab.instantiate()
			result["collider"].add_child(new_door)
			new_door.global_position = result["position"]
			if tmp_result["normal"] != Vector3.UP and tmp_result["normal"] != Vector3.DOWN:
				new_door.look_at(cursor.position + tmp_result["normal"])
			else:
				new_door.look_at(cursor.position + tmp_result["normal"], Vector3.FORWARD)

func raycast(collide_with_areas: bool, mask: int) -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_pos)
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_parameters: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_parameters.from = ray_origin
	ray_parameters.to = ray_origin + ray_normal * 100
	ray_parameters.collide_with_areas = collide_with_areas
	ray_parameters.collision_mask = mask
	return space.intersect_ray(ray_parameters)
