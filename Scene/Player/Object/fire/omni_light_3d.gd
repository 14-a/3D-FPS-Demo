extends OmniLight3D

var a = 0.5

var b = 50

var c = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light_energy = b
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	light_energy += (0 - light_energy) * delta * a * 100
	if light_energy < 0.01: 
		queue_free()
	pass
