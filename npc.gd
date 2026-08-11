extends CharacterBody3D
class_name NPC

@export var Res : Resource

func _ready() -> void:
	Res.状态 = 0 #待机
	pass

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Res.状态 > 0:
		velocity.x += Res.运动向量.normalized().x * Res.速度 * delta
		velocity.z += Res.运动向量.normalized().z * Res.速度 * delta
	
	velocity.x *= .9
	velocity.z *= .9
	velocity.y *= .99
	move_and_slide()
	pass
