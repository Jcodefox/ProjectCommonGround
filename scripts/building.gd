extends CSGShape3D

@onready var original_size: Vector3 = $CSGBox3D.size
var time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta
	$CSGBox3D.size = original_size + Vector3(1, 0, 1) * abs(sin(time * 0.1)) * 200
	$CSGBox3D2.size = $CSGBox3D.size - Vector3(0.1, 0.2, 0.1)
	$Door.position.z = $CSGBox3D.size.z / 2
