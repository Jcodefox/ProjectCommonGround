extends Node3D

@onready var spawn_point: Vector2i = Vector2i(INF, INF)

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

func _physics_process(delta: float) -> void:
	if already_died:
		return
	if is_dead():
		already_died = true
		return
	do_need_logic(delta)
	calculate_movement()

func do_need_logic(delta: float):
	for need in needs:
		var stands: Array[Vector3] # TODO: Get stands for need
		# Go to a need's fullfillment location if it runs low.
		if need.value < need.critical_value:
			var target_stand: Vector3 = Vector3.INF
			var lowest_dist: float = INF
			# TODO: check what the closest fullfilling stand is
			#       and set target_stand and lowest_dist accordingly
			
			if target_stand != null:
				#TODO: set target to target_stand
				fullfilling_need = true
		
		# Do the need logic
		var at_location: bool = false
		for stand in stands:
			# TODO: Check if at a stand and set at_location accordingly
			pass
		need.value = need.value + delta / (need.seconds_to_increase if at_location else -need.seconds_to_decrease)
		need.value = clamp(need.value, 0, need.max_value)
		if need.value == need.max_value:
			fullfilling_need = false
	
	if not fullfilling_need:
		# TODO: Go home
		pass

func calculate_movement():
	# TODO: Pathfind to target
	pass

func is_dead():
	for need in needs:
		if need.value <= 0.0:
			return true
	return false
