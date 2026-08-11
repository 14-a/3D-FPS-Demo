extends Node3D

var EventList

var Pz = 0
var Rx = 0

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Pz += (0 - Pz) * 0.1
	Rx += (0 - Rx) * 0.1
	$CSGBakedMeshInstance3D.position.x = Pz
	$CSGBakedMeshInstance3D.rotation_degrees.z = Rx
	pass
