extends Node3D

var EventList

var Pz = 0
var Rx = 0

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Pz += (0 - Pz)  * delta * 20
	Rx += (0 - Rx)  * delta * 20
	$CSGBakedMeshInstance3D.position.x = Pz
	$CSGBakedMeshInstance3D.rotation_degrees.z = Rx
	pass
