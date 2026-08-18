extends Node3D

var speed = 50

var Player : CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position -= transform.basis.z * delta *speed
	
	if $RayCast3D.is_colliding():
		if $RayCast3D.get_collider().name == "Player":
			if not Player.die:
				Player._扣血(10)
		queue_free()
	pass
