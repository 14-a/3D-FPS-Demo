extends CharacterBody3D
class_name NPC

@export var Path : Array[Node3D]

@export var Res : Resource
@export var 锁敌范围 = 20

@export var 开火距离 = 10

var 血量 = 100

var 阻力 = 0.9

var PlayerInNearby = 0
var Player : CharacterBody3D

var 状态 = 0

var NowPath : Node3D
var NowPathIndex = 0
var OnRaod = false

var FireLight = preload("res://Scene/Player/Object/fire/omni_light_3d.tscn")

## 判定玩家是否可见
@onready var CheskPlayerVisible = $RayCast3D

## npc的全局坐标系下的视线向量
@onready var ViewInWorld = $RayCast3D2

## 枪
@onready var gun = $Node3D/gun

var timer = Timer.new()
var PaTimer = Timer.new()

func _ready() -> void:
	状态 = 1 #巡逻
	
	## 检测玩家的范围
	var CheskPlayerSphere = SphereShape3D.new()
	CheskPlayerSphere.radius = 锁敌范围
	var CheskCollision = CollisionShape3D.new()
	CheskCollision.shape = CheskPlayerSphere
	$Area3D.add_child(CheskCollision)
	
	ViewInWorld.target_position = Vector3(0,0,-100)
	
	timer.wait_time = 1
	add_child(timer)
	timer.timeout.connect(_Fire)
	timer.start()
	
	PaTimer.wait_time = 2
	add_child(PaTimer)
	PaTimer.timeout.connect(_ChangePath)
	PaTimer.start()
	
	pass

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		阻力 = 0.99
	else:
		阻力 = .9
	
	if Res.状态 > 0:
		velocity.x += Res.运动向量.normalized().x * Res.速度 * delta
		velocity.z += Res.运动向量.normalized().z * Res.速度 * delta
	
	velocity.x *= 阻力
	velocity.z *= 阻力
	velocity.y *= 阻力
	move_and_slide()
	
	_NPC_Event(delta)
	
	pass

func _NPC_Event(delta) -> void:
	_CheskPlayerInNearby()
	
	$MeshInstance3D3.scale.x = 血量 / 100.0
	$MeshInstance3D2.scale.x += ((血量 / 100.0) - $MeshInstance3D2.scale.x) * 0.5 * delta * 10
	
	if 血量 <= 0:
		queue_free()
	
	if 状态 == 0:
		if PlayerInNearby == 1:
			状态 = 2
	
	if 状态 == 1:
		if PlayerInNearby == 1:
			状态 = 2
		
		if Path:
			NowPath = Path[NowPathIndex % Path.size()]
			look_at(NowPath.position)
			rotation_degrees.x = 0
			if (NowPath.position - position).length() > 1:
				velocity -= transform.basis.z * delta * 10
				OnRaod = true
			else : OnRaod = false
			pass
		pass
	if 状态 == 2:
		#if PlayerInNearby == 0:
			#状态 = 1
		
		if Player:
			look_at(Player.position)
			rotation_degrees.x = 0
			if (Player.position - position).length() > 2:
				if not Player.die:
					velocity -= transform.basis.z * delta * 10
				if (Player.position - position).length() < 开火距离 : 状态 = 3
			else:
				状态 = 3
	if 状态 == 3:
		look_at(Player.position)
		rotation_degrees.x = 0
		if (Player.position - position).length() > 开火距离:
			状态 = 2
	pass

func _扣血(伤害, 来源 = 0, NODE = 0) -> void:
	血量 -= 伤害
	if 来源 is String:
		if 来源 == "player":
			状态 = 2
			look_at(NODE)
			rotation_degrees.x = 0

#检测玩家是否在附近
func _CheskPlayerInNearby() -> void:
	PlayerInNearby = 0
	var Nearbybody = $Area3D.get_overlapping_bodies()
	for i in Nearbybody:
		if i is CharacterBody3D:
			#在附近
			if i.name == "Player":
				var npcToPlayerVec : Vector3 = (i.global_position - global_position).normalized()
				var View : Vector3 = (ViewInWorld.get_collision_point()).normalized()
				CheskPlayerVisible.target_position = npcToPlayerVec * 锁敌范围
				CheskPlayerVisible.rotation = -rotation
				#检测是否被遮挡
				if CheskPlayerVisible.is_colliding():
					var body = CheskPlayerVisible.get_collider()
					if body is CharacterBody3D:
						#是否在视野范围内
						if View.dot(npcToPlayerVec) > 0:
							PlayerInNearby = 1
							Player = i
	pass

func _Fire() -> void:
	if 状态 == 3:
		if not Player.die:
			var 命中概率 = 5 / (Player.position - position).length()
			
			gun.Pz = -1
			gun.Rx = 45
			var l = FireLight.instantiate()
			l.position = Vector3(0, 0,-.91)
			l.light_energy = 12
			$Node3D.add_child(l)
			#有概率击中玩家
			if (randi() % 100 + 1) > ((1 - 命中概率) * 100):
				Player._扣血(10)
	pass

func _ChangePath() -> void:
	if not OnRaod :  NowPathIndex += 1
	pass

func _缓动函数(x) -> float:
	return 1 - pow(x, 10)
