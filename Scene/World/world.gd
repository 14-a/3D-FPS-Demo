extends Node

var BAO = preload("res://Scene/Player/Object/手雷/手雷.tscn")

var a = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	a.x = -sin(deg_to_rad($Player.rotation.y)) * cos(deg_to_rad($Player.镜头轴承.rotation.x))
	a.y = sin(deg_to_rad($Player.镜头轴承.rotation.x))
	a.z = -cos(deg_to_rad($Player.rotation.y)) * cos(deg_to_rad($Player.镜头轴承.rotation.x))
	pass


func _on_player_event(type: Variant) -> void:
	if type == "投手雷":
		var s = BAO.instantiate()
		s.position = $Player.position
		s.position.y += 1
		add_child(s)
		s.linear_velocity = a * 10
	pass # Replace with function body.
