extends Node3D

var time: float = 0.0

func _physics_process(delta):
	$Sprite3D.position.y = sin(time) * 0.25 + 0.25
	$Sprite3D.rotate_y(delta)
	time += delta
