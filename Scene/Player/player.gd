extends CharacterBody3D

@onready var 镜头轴承 = $Node3D
@onready var ViewRay = $RayCast3D
@onready var camera: Camera3D = $Node3D/Camera3D
@onready var gun = $Node3D/HandObject/gun
@onready var throw_origin = $Node3D/Marker3D
@onready var rope_mesh : CSGCylinder3D = $GrappleRope          # 新增：绳索绘制节点
@onready var Health = $Control/MeshInstance2D4
@onready var _Health = $Control/MeshInstance2D3
@onready var Fuck = $Control/Fuck
@onready var GameOverText = $Control/Label2

@export var 鼠标灵敏度 = 0.1
@export var head_bob_speed: float = 1.5
@export var head_bob_intensity: float = 0.1
@export var head_bob_sway_intensity: float = 0.05

@export var 武器列表 : Array[Node3D]
var 当前武器 : Node
var 当前武器索引 = 0

var 血量 = 100

var PlayerRes = preload("res://Scene/Player/PlayerRes.tres")
var fireLight = preload("res://Scene/Player/Object/fire/omni_light_3d.tscn")
var grenade_scene = preload("res://Scene/Player/Object/手雷/手雷.tscn")

var head_bob_timer: float = 0.0
var is_moving: bool = false

var speed = 1

var is_grappling: bool = false
var grapple_point: Vector3 = Vector3.ZERO

var die = false

var OverStart = 0

const 满血基准 = 100.0
const 默认射程 = 30.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const 黑屏初始位置 = 14979.0
const 黑屏重启位置 = 1000
const 黑屏静止前位置 = -3000
const 倾斜最大角 = -15

enum HandObject {
	手枪 = 0,
	小刀 = 1
}

func _ready() -> void:
	ViewRay.target_position = Vector3(0,0,-默认射程)
	ViewRay.add_exception($PlayerCollision)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$Node3D/HandObject/gun.EventList = PlayerRes.EventList
	
	rope_mesh.visible = false

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.y -= event.relative.x * 鼠标灵敏度
		镜头轴承.rotation_degrees.x -= event.relative.y * 鼠标灵敏度
		if 镜头轴承.rotation_degrees.x > 89: 镜头轴承.rotation_degrees.x = 89
		if 镜头轴承.rotation_degrees.x < -89: 镜头轴承.rotation_degrees.x = -89
		ViewRay.rotation_degrees.x = 镜头轴承.rotation_degrees.x
		
	if Input.is_action_just_pressed("退出") and not die:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else : 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	
	#重力和跳跃
	if not is_on_floor(): velocity += get_gravity() * delta
	if Input.is_action_just_pressed("跳") and is_on_floor() and not die:
		velocity.y = JUMP_VELOCITY
	
	#处理水平面上的运动
	var input_dir := Input.get_vector("左", "右", "前", "后")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * speed
		velocity.z = direction.z * SPEED * speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed)
		velocity.z = move_toward(velocity.z, 0, SPEED * speed)
	
	if Input.is_action_pressed("疾跑") and not die: _疾跑()
	else : _步行()
	
	if Input.is_action_pressed("聚焦") and not die: $Node3D/Camera3D.fov += (0 - $Node3D/Camera3D.fov) * .1
	if Input.is_action_pressed("蹲下") and not die: _蹲下(delta)
	else : _站立(delta)
	
	if not die:
		move_and_slide()
		camera.偏移vec.z += ((input_dir.x * 倾斜最大角)- camera.偏移vec.z) * 2 *delta
	
	_Player_Event(delta)

func _Player_Event(delta) -> void: 
	当前武器索引 = 当前武器索引 % 武器列表.size()
	当前武器 = 武器列表[当前武器索引]
	当前武器.visible = true
	
	Health.scale.x += ((血量 / 满血基准) - Health.scale.x) * 5 * delta
	_Health.scale.x = 血量 / 满血基准
	Fuck.modulate.a += (0 - Fuck.modulate.a) * 5 * delta
	
	血量 = max(血量, 0)
	
	if 血量 <= 0: _die(delta)
	
	if die: return
	
	GameOverText.visible = false
	
	if Input.is_action_just_pressed("射击"):
		if 当前武器索引 == HandObject.手枪: _fire()
		if 当前武器索引 == HandObject.小刀: _chop()
	
	if Input.is_action_just_pressed("投手雷"): throw_grenade()
	if Input.is_action_just_pressed("切换武器"): _切换武器()

func throw_grenade():
	var grenade = grenade_scene.instantiate()
	grenade.global_position = throw_origin.global_position
	grenade.throw(-camera.global_transform.basis.z)
	get_tree().current_scene.add_child(grenade)

func _扣血(伤害) -> void:
	血量 -= 伤害
	Fuck.modulate.a = 1
	camera.偏移vec.x = 伤害 / 10.0
	pass

## 重启游戏之前的过场
func _OVERSTART(delta) -> void:
	$Control/MeshInstance2D5.position.x += (0 - $Control/MeshInstance2D5.position.x) * 2 * delta
	if abs(0 - $Control/MeshInstance2D5.position.x) < 黑屏重启位置: get_tree().reload_current_scene()
	if $Control/MeshInstance2D5.position.x > 黑屏静止前位置:
		$Control/MeshInstance2D5.position.x = 0
		$Control/MeshInstance2D5.position.x += (黑屏初始位置 - $Control/MeshInstance2D5.position.x) * 2 * delta
	pass

func _Over_Start() -> void:
	OverStart = 1
	pass

## 手枪的攻击逻辑
func _fire() -> void:
	gun.Pz = -1
	gun.Rx = 45
	var l = fireLight.instantiate()
	l.position = Vector3(0.35, 0,-1.91)
	l.light_energy = 12
	$Node3D.add_child(l)
	camera.偏移vec.x = 5
	if ViewRay.is_colliding():
		var body = ViewRay.get_collider()
		if body is RigidBody3D:
			body.linear_velocity += -camera.global_transform.basis.z * 5
		if body is CharacterBody3D:
			body.velocity += -camera.global_transform.basis.z * 2
			if "NPC" in body.name:
				body._扣血(10, "player", 镜头轴承.global_position)

## 小刀的攻击逻辑
func _chop() -> void:
	
	pass

func _切换武器() -> void:
	当前武器.visible = false
	当前武器索引 += 1

func _die(delta) -> void:
	die = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Fuck.modulate.a = 1
	gun.visible = false
	$Control/MeshInstance2D.visible = false
	$Control/MeshInstance2D2.visible = false
	GameOverText.visible = true
	
	if OverStart == 1:
		_OVERSTART(delta)
	pass

func _蹲下(delta) -> void:
	$Node3D.position.y += (1 - $Node3D.position.y) * .1
	$RayCast3D.position.y += (1 - $RayCast3D.position.y) * .1
	$MeshInstance3D.scale.y += (0.5 - $MeshInstance3D.scale.y) * .1
	$PlayerCollision.scale.y += (0.5 - $PlayerCollision.scale.y) * .1

func _站立(delta) -> void:
	$Node3D.position.y += (1.694 - $Node3D.position.y) * .1
	$RayCast3D.position.y += (1.694 - $RayCast3D.position.y) * .1
	$MeshInstance3D.scale.y += (1 - $MeshInstance3D.scale.y) * .1
	$PlayerCollision.scale.y += (1 - $PlayerCollision.scale.y) * .1

func _疾跑() -> void:
	speed = 1.5
	$Node3D/Camera3D.fov += (100 - $Node3D/Camera3D.fov) * .1

func _步行() -> void:
	speed = 1
	$Node3D/Camera3D.fov += (90 - $Node3D/Camera3D.fov) * .1
