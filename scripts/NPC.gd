extends CharacterBody2D

const SPEED = 80.0
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var spawn_point: Vector2i = Vector2i(INF, INF)
@onready var sqrt_path_max_distance: float = sqrt(nav.path_max_distance)

class Need:
	var value: float
	var max_value: float
	var critical_value: float
	var seconds_to_increase: float
	var seconds_to_decrease: float
	var stand: String
	func _init(val, max_val, crit_val, sec_inc, sec_dec, stand):
		value = val
		max_value = max_val
		critical_value = crit_val
		seconds_to_increase = sec_inc
		seconds_to_decrease = sec_dec
		self.stand = stand

var fullfilling_need: bool = false
var already_died: bool = false
var needs: Array[Need] = [
	Need.new(10.0, 10.0, 4.0, 1.0, 10.0, "water"),
	Need.new(10.0, 10.0, 4.0, 1.0, 10.0, "food"),
]

func check_for_bed():
	if get_node("../Tilemap").get_cell_atlas_coords(3, spawn_point) != Vector2i(0, 0):
		var beds: Array[Vector2i] = GlobalData.get_available_beds()
		if beds.size() > 0:
			spawn_point = beds.pick_random()
			get_node("../Tilemap").bed_data[spawn_point] = self
		else:
			spawn_point = Vector2i(INF, INF)
	get_tree().create_timer(1).timeout.connect(check_for_bed)

func _ready() -> void:
	get_tree().create_timer(1).timeout.connect(check_for_bed)
	nav.connect("link_reached", hit_link)
	for need in needs:
		need.value = need.max_value
		need.max_value = randi_range(10, 15)
		need.critical_value = randi_range(3, 6)
		need.seconds_to_decrease = randi_range(10, 6)

func _process(_delta: float) -> void:
	$Label.text = ""
	for need in needs:
		$Label.text += need.stand + ": "
		$Label.text += "%.1f"%need.value + "\n"

func _physics_process(delta: float) -> void:
	if already_died:
		return
	if is_dead():
		$Sprite2D.rotation_degrees = -90
		GlobalData.change_money_with_pos(-1000, position)
		already_died = true
		return
	do_need_logic(delta)
	calculate_movement()

func do_need_logic(delta: float):
	for need in needs:
		var stands: Array[Vector2i] = GlobalData.get_stands_of_type(need.stand)
		# Go to a need's fullfillment location if it runs low.
		if need.value < need.critical_value:
			var target_stand: Vector2 = Vector2.INF
			var lowest_dist: float = INF
			for stand in stands:
				if position.distance_squared_to(stand) < lowest_dist:
					lowest_dist = position.distance_squared_to(stand)
					target_stand = stand
			
			if target_stand != null:
				set_target(target_stand)
				fullfilling_need = true
		
		# Do the need logic
		var at_location: bool = false
		for stand in stands:
			at_location = at_location or position.distance_squared_to(stand) < 64
		need.value = need.value + delta / (need.seconds_to_increase if at_location else -need.seconds_to_decrease)
		need.value = clamp(need.value, 0, need.max_value)
		if need.value == need.max_value:
			fullfilling_need = false
	
	if spawn_point == Vector2i(INF, INF):
		set_target(get_node("../Bulldozer").position - Vector2(5, 14))
		return
	if not fullfilling_need:
		set_target(spawn_point * 16 + Vector2i(8, 8))

func calculate_movement():
	# Follow pathfinding
	var direction := (nav.get_next_path_position() - position).normalized()
	if direction.x:
		$Sprite2D.flip_h = direction.x < 0
	if not direction.is_zero_approx() and position.distance_squared_to(nav.get_next_path_position()) > 1:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	if not velocity.is_zero_approx():
		move_and_slide()

func is_dead():
	for need in needs:
		if need.value <= 0.0:
			return true
	return false

func hit_link(data: Dictionary) -> void:
	position = data["link_exit_position"]

func set_target(target: Vector2):
	if nav.target_position != target:
		nav.target_position = target

func _on_mouse_entered() -> void:
	$Label.visible = true
func _on_mouse_exited() -> void:
	$Label.visible = false
