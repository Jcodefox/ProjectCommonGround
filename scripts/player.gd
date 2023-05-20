extends CharacterBody2D

const SPEED = 80.0

func _ready() -> void:
	GlobalData.riding_vehicle = get_node("../Bulldozer")

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.x:
		$Sprite2D.flip_h = direction.x < 0
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	if Input.is_action_just_pressed("interact") and get_node("../Bulldozer").overlaps_body(self):
		if GlobalData.riding_vehicle:
			GlobalData.riding_vehicle = null
		else:
			GlobalData.riding_vehicle = get_node("../Bulldozer")
			position = GlobalData.riding_vehicle.position
	
	move_and_slide()
	
	if GlobalData.riding_vehicle:
		GlobalData.riding_vehicle.position = position

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not Input.is_key_pressed(KEY_SHIFT):
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		$Camera2D.zoom += Vector2(0.1, 0.1)
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		if $Camera2D.zoom.x > 0.1:
			$Camera2D.zoom -= Vector2(0.1, 0.1)
