extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var held_items: Array[Node3D] = []

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
	
	for i in range(held_items.size()):
		held_items[i].position = position + Vector3(0, 1.2 + 0.8 * i, 0)
	if Input.is_action_just_pressed("interact"):
		if held_items.size() > 0:
			$FloorLocator.force_raycast_update()
			var dropped_item: Node3D = held_items.pop_back()
			if $FloorLocator.is_colliding():
				dropped_item.position = $FloorLocator.get_collision_point() + Vector3(0.0, 0.4, 0.0)
			dropped_item.get_node("NoGrabCooldown").start(1)
	for area in $ItemCollector.get_overlapping_areas():
		collect(area)

func collect(area: Area3D):
	if area.is_in_group("item") and not area in held_items:
		if not area.get_node("NoGrabCooldown").is_stopped():
			return
		held_items.push_back(area)
