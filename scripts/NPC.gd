extends CharacterBody2D

const SPEED = 80.0
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var spawn_point: Vector2 = position

var hunger: float = 10.0

enum NEED_TYPE{NONE, FOOD, WATER, ELECTRICITY}

var fullfilling_need: NEED_TYPE = NEED_TYPE.NONE
@export var needs: Dictionary = {
	NEED_TYPE.WATER: {
		"fullfillment_center": "water",
		"increase_over_time": 1.0,
		"decrease_over_time": -10.0,
		"critical_value": 4.0,
		"value": 10.0,
		"max_value": 10.0
	},
	NEED_TYPE.FOOD: {
		"fullfillment_center": "food",
		"increase_over_time": 1.0,
		"decrease_over_time": -3.0,
		"critical_value": 4.0,
		"value": 10.0,
		"max_value": 10.0
	},
}

func _ready() -> void:
	nav.connect("link_reached", hit_link)
	nav.connect("velocity_computed", velocity_computed)
	for need_id in needs:
		needs[need_id]["critical_value"] = randi_range(3, 6)
		needs[need_id]["decrease_over_time"] = randi_range(-10, -6)
		needs[need_id]["max_value"] = randi_range(10, 15)
		needs[need_id]["value"] = needs[need_id]["max_value"]

func _process(_delta: float) -> void:
	$Label.text = ""
	for need_id in needs:
		$Label.text += needs[need_id]["fullfillment_center"] + ": "
		$Label.text += "%.1f"%needs[need_id]["value"] + "\n"

func _physics_process(delta: float) -> void:
	if is_dead():
		$Sprite2D.rotation_degrees = -90
		return
	
	if position.distance_to(nav.get_next_path_position()) > nav.path_max_distance:
		nav.target_position = nav.target_position
	
	for need_id in needs:
		var stands := get_tree().get_nodes_in_group(needs[need_id]["fullfillment_center"])
		# Go to a need's fullfillment location if it runs low.
		if needs[need_id]["value"] < needs[need_id]["critical_value"]:
			var target_stand: Node2D = null
			var lowest_dist: float = 0
			for stand in stands:
				if target_stand == null:
					target_stand = stand
					lowest_dist = position.distance_to(stand.position)
					continue
				if position.distance_to(stand.position) < lowest_dist:
					lowest_dist = position.distance_to(stand.position)
					target_stand = stand
				
			if target_stand != null:
				set_target(target_stand.position)
				fullfilling_need = need_id
		# Do the need logic
		var at_location: bool = false
		for stand in stands:
			at_location = at_location or stand.overlaps_body(self)
		needs[need_id]["value"] = clamp(needs[need_id]["value"] + delta / needs[need_id]["increase_over_time" if at_location else "decrease_over_time"], 0, needs[need_id]["max_value"])
		if needs[need_id]["value"] == needs[need_id]["max_value"]:
			fullfilling_need = NEED_TYPE.NONE
		
	# If no needs, go to player
	if fullfilling_need == NEED_TYPE.NONE:
		set_target(spawn_point)
	
	# Follow pathfinding
	var direction := (nav.get_next_path_position() - position).normalized()
	if direction.x:
		$Sprite2D.flip_h = direction.x < 0
	if not direction.is_zero_approx() and position.distance_to(nav.get_next_path_position()) > 1:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	nav.set_velocity(velocity)

func is_dead():
	for need_id in needs:
		if needs[need_id]["value"] <= 0.0:
			return true
	return false

func hit_link(data: Dictionary):
	position = data["link_exit_position"]

func velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func set_target(target: Vector2):
	if nav.target_position != target:
		nav.target_position = target

func _on_mouse_entered() -> void:
	$Label.visible = true

func _on_mouse_exited() -> void:
	$Label.visible = false
