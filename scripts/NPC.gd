extends CharacterBody2D

const SPEED = 80.0
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var spawn_point: Vector2 = position

var hunger: float = 10.0

enum NEED_TYPE{NONE, FOOD, WATER, ELECTRICITY}

var fullfilling_need: NEED_TYPE = NEED_TYPE.NONE
@export var needs: Dictionary = {
	NEED_TYPE.WATER: {
		"fullfillment_center": "../WaterStand",
		"increase_over_time": 1.0,
		"decrease_over_time": -10.0,
		"critical_value": 4.0,
		"value": 10.0,
		"max_value": 10.0
	},
	NEED_TYPE.FOOD: {
		"fullfillment_center": "../FoodStand",
		"increase_over_time": 1.0,
		"decrease_over_time": -3.0,
		"critical_value": 4.0,
		"value": 10.0,
		"max_value": 10.0
	},
}

func _ready() -> void:
	nav.connect("link_reached", hit_link)
	for need_id in needs:
		needs[need_id]["critical_value"] = randi_range(30, 60)
		needs[need_id]["decrease_over_time"] = randi_range(-10, -2)
		needs[need_id]["max_value"] = randi_range(10, 20)
		needs[need_id]["value"] = needs[need_id]["max_value"]

func _process(_delta: float) -> void:
	$Label.text = ""
	for need_id in needs:
		$Label.text += needs[need_id]["fullfillment_center"].substr(3, len(needs[need_id]["fullfillment_center"]) - 8) + ": "
		$Label.text += "%.1f"%needs[need_id]["value"] + "\n"

func _physics_process(delta: float) -> void:
	if is_dead():
		$Sprite2D.rotation_degrees = -90
		return
	
	for need_id in needs:
		# Go to a need's fullfillment location if it runs low.
		if needs[need_id]["value"] < needs[need_id]["critical_value"]:
			nav.target_position = get_node(needs[need_id]["fullfillment_center"]).position
			fullfilling_need = need_id
		# Do the need logic
		var at_location: bool = get_node(needs[need_id]["fullfillment_center"]).overlaps_body(self)
		needs[need_id]["value"] = clamp(needs[need_id]["value"] + delta / needs[need_id]["increase_over_time" if at_location else "decrease_over_time"], 0, needs[need_id]["max_value"])
		if needs[need_id]["value"] == needs[need_id]["max_value"]:
			fullfilling_need = NEED_TYPE.NONE
		
	# If no needs, go to player
	if fullfilling_need == NEED_TYPE.NONE:
		nav.target_position = spawn_point#Vector2(75, 12)#get_node("../Player").position
	
	# Follow pathfinding
	var direction := (nav.get_next_path_position() - position).normalized()
	if direction.x:
		$Sprite2D.flip_h = direction.x < 0
	if not direction.is_zero_approx() and position.distance_to(nav.get_next_path_position()) > 1:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()

func is_dead():
	for need_id in needs:
		if needs[need_id]["value"] <= 0.0:
			return true
	return false

func hit_link(data: Dictionary):
	position = data["link_exit_position"]
	print($NavigationAgent2D.navigation_layers)
	$NavigationAgent2D.set_navigation_layer_value(2, true)
#	$NavigationAgent2D.set_navigation_layer_value(1, false)
#	$NavigationAgent2D.set_navigation_layer_value(1, true)
