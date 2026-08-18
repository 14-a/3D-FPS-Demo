
extends CharacterBody3D
class_name NPC

@export var Path : Array[Node3D]

@export var Res : Resource
@export var 锁敌范围 = 20

@export var 开火距离 = 3

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

enum 总状态 {
	待机 = 0,
	巡逻 = 1,
	追逐 = 2,
	攻击 = 3
}

const 地面摩擦力 = .9
const 空气阻力 = .99
const 前往下一个路径点间隔的时间 = 2
const 开枪间隔时间 = 0.25

func _ready() -> void:
	状态 = 总状态.巡逻
	
	## 检测玩家的范围
	var CheskPlayerSphere = SphereShape3D.new()
	CheskPlayerSphere.radius = 锁敌范围
	var CheskCollision = CollisionShape3D.new()
	CheskCollision.shape = CheskPlayerSphere
	$Area3D.add_child(CheskCollision)
	
	ViewInWorld.target_position = Vector3(0,0,-100)
	
	timer.wait_time = 开枪间隔时间
	add_child(timer)
	timer.timeout.connect(_Fire)
	timer.start()
	
	PaTimer.wait_time = 前往下一个路径点间隔的时间
	add_child(PaTimer)
	PaTimer.timeout.connect(_ChangePath)
	PaTimer.start()
	pass

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		阻力 = 空气阻力
	else:
		阻力 = 地面摩擦力
		
	_NPC_Event(delta)
	
	velocity *= 阻力
	move_and_slide()

func _NPC_Event(delta) -> void:
	_CheskPlayerInNearby()
	
	$MeshInstance3D3.scale.x = 血量 / 100.0
	$MeshInstance3D2.scale.x += ((血量 / 100.0) - $MeshInstance3D2.scale.x) * 5 * delta 
	
	if 血量 <= 0: queue_free()
	
	if 状态 == 总状态.待机: _待机(delta)
	if 状态 == 总状态.巡逻: _巡逻(delta)
	if 状态 == 总状态.追逐: _追逐(delta)
	if 状态 == 总状态.攻击: _攻击(delta)


func _扣血(伤害, 来源 = 0, NODE = 0) -> void:
	血量 -= 伤害
	if 来源 is String:
		if 来源 == "player":
			状态 = 总状态.追逐
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
				Player._扣血(5)
	pass

func _ChangePath() -> void:
	if not OnRaod :  NowPathIndex += 1
	pass

func _缓动函数(x) -> float:
	return 1 - pow(x, 10)

func _待机(delta) -> void:
	if PlayerInNearby == 1:
		状态 = 总状态.追逐

func _巡逻(delta) -> void:
	if PlayerInNearby == 1:
		状态 = 总状态.追逐
		
	if Path:
		NowPath = Path[NowPathIndex % Path.size()]
		look_at(NowPath.position)
		rotation_degrees.x = 0
		if (NowPath.position - position).length() > 1:
			velocity -= transform.basis.z * delta * 10
			OnRaod = true
		else : OnRaod = false

func _追逐(delta) -> void:
	if Player:
			look_at(Player.position)
			rotation_degrees.x = 0
			if (Player.position - position).length() > 2:
				if not Player.die:
					velocity -= transform.basis.z * delta * 10
				if (Player.position - position).length() < 开火距离 : 状态 = 3
			else:
				状态 = 总状态.攻击
	pass

func _攻击(delta) -> void:
	look_at(Player.position)
	rotation_degrees.x = 0
	if (Player.position - position).length() > 开火距离:
		状态 = 总状态.追逐
