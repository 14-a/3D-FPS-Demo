extends Node3D

@export var Player : CharacterBody3D 

@onready var Find = $RayCast3D
@onready var gun = $Node3D3

var Bullet = preload("res://Scene/NPC/不可移动NPC/塔台/子弹/node_3d.tscn")

var timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Find.target_position = Vector3(0,0,-100)
	
	timer.wait_time = 0.1
	add_child(timer)
	timer.timeout.connect(_Fire)
	timer.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if _FindPlayer():
		gun.rotation = Find.rotation
		pass
	$Node3D2.P = gun.rotation
	
	pass

#寻找玩家
func _FindPlayer() -> bool:
	#Find.target_position = (Player.position - position)
	Find.look_at(Vector3(Player.position.x, Player.position.y + 1,Player.position.z))
	if Find.is_colliding():
		var body = Find.get_collider()
		if body.name == "Player":
			return true
		else:
			return false
	else:
		return false

func _Fire() -> void:
	if _FindPlayer():
		if not Player.die:
			var BulletInstance = Bullet.instantiate()
			BulletInstance.Player = Player
			BulletInstance.rotation = Find.rotation
			BulletInstance.position.y = 2
			add_child(BulletInstance)
	pass
