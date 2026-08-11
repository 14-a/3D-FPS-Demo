extends CharacterBody3D

@onready var 镜头轴承 = $Node3D
@onready var ViewRay = $RayCast3D
@onready var camera: Camera3D = $Node3D/Camera3D
@onready var gun = $Node3D/gun
@onready var throw_origin = $Node3D/Marker3D
@onready var rope_mesh : CSGCylinder3D = $GrappleRope          # 新增：绳索绘制节点

@export var 鼠标灵敏度 = 0.1
@export var head_bob_speed: float = 1.5
@export var head_bob_intensity: float = 0.1
@export var head_bob_sway_intensity: float = 0.05

# -------- 钩爪参数 ----------
@export var grapple_range: float = 30.0          # 最大钩爪距离（与射线长度一致）
@export var grapple_force: float = 15.0         # 拉向锚点的力度
@export var max_rope_length: float = 25.0       # 绳索最大拉伸长度（超过则拉回）
@export var rope_stiffness: float = 0.9         # 弹性系数（0~1），1为刚性
# -----------------------------

var 血量 = 100

var PlayerRes = preload("res://Scene/Player/PlayerRes.tres")
var fireLight = preload("res://Scene/Player/Object/fire/omni_light_3d.tscn")
var grenade_scene = preload("res://Scene/Player/Object/手雷/手雷.tscn")

var head_bob_timer: float = 0.0
var is_moving: bool = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var speed = 1

signal Event(type)

var is_grappling: bool = false
var grapple_point: Vector3 = Vector3.ZERO
# 也可保留原有字典，但推荐使用单独变量
# var playerStudeLits = {"point" : Vector3.ZERO, "hooked" : false}
# --------------------------------

func _ready() -> void:
	ViewRay.target_position = Vector3(0,0,-30)
	ViewRay.add_exception($PlayerCollision)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$Node3D/gun.EventList = PlayerRes.EventList
	
	rope_mesh.visible = false

	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.y -= event.relative.x * 鼠标灵敏度
		镜头轴承.rotation_degrees.x -= event.relative.y * 鼠标灵敏度
		if 镜头轴承.rotation_degrees.x > 89: 镜头轴承.rotation_degrees.x = 89
		if 镜头轴承.rotation_degrees.x < -89: 镜头轴承.rotation_degrees.x = -89
		ViewRay.rotation_degrees.x = 镜头轴承.rotation_degrees.x
		
	if Input.is_action_just_pressed("退出"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else : 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor(): velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("跳") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("疾跑"):
		speed = 1.5
		$Node3D/Camera3D.fov += (100 - $Node3D/Camera3D.fov) * .1
	else :
		speed = 1
		$Node3D/Camera3D.fov += (90 - $Node3D/Camera3D.fov) * .1
	
	if Input.is_action_pressed("聚焦"): $Node3D/Camera3D.fov += (0 - $Node3D/Camera3D.fov) * .1
	
	if Input.is_action_pressed("蹲下"):
		$Node3D.position.y += (1 - $Node3D.position.y) * .1
		$RayCast3D.position.y += (1 - $RayCast3D.position.y) * .1
		$MeshInstance3D.scale.y += (0.5 - $MeshInstance3D.scale.y) * .1
		$PlayerCollision.scale.y += (0.5 - $PlayerCollision.scale.y) * .1
	else : 
		$Node3D.position.y += (1.694 - $Node3D.position.y) * .1
		$RayCast3D.position.y += (1.694 - $RayCast3D.position.y) * .1
		$MeshInstance3D.scale.y += (1 - $MeshInstance3D.scale.y) * .1
		$PlayerCollision.scale.y += (1 - $PlayerCollision.scale.y) * .1
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("左", "右", "前", "后")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * speed
		velocity.z = direction.z * SPEED * speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed)
		velocity.z = move_toward(velocity.z, 0, SPEED * speed)

	move_and_slide()
	
	is_moving = velocity.length() > 0.1
	
	#_apply_head_bob(delta)
	
	_Player_Event()
	
	if is_grappling:
		_update_rope_visual() 
		_apply_grapple_force(delta)
	
	if Input.is_action_just_released("发射钩爪") and is_grappling:
		_release_grapple()

func _Player_Event() -> void: 
	if Input.is_action_just_pressed("射击"):
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
	
	if Input.is_action_just_pressed("投手雷"):
		throw_grenade()
	
	# ---------- 钩爪发射（按下时） ----------
	if Input.is_action_just_pressed("发射钩爪"):
		_attempt_grapple()
	# ----------------------------------------
	pass

func _attempt_grapple():
	if is_grappling:
		_release_grapple()
		return
	
	ViewRay.force_raycast_update()
	
	if ViewRay.is_colliding():
		var collider = ViewRay.get_collider()
		if collider == self:
			return
		
		grapple_point = ViewRay.get_collision_point()
		is_grappling = true
		rope_mesh.visible = false
		#更多效果

func _release_grapple():
	is_grappling = false
	rope_mesh.visible = false

func _update_rope_visual():
	var start = global_position
	var end = grapple_point
	var midpoint = (start + end) / 2
	var length = start.distance_to(end)
	
	rope_mesh.global_position = midpoint
	
	rope_mesh.look_at(end, Vector3.UP)
	
	rope_mesh.height = length

func _apply_grapple_force(delta):
	var direction_to_anchor = (grapple_point - global_position).normalized()
	var distance = global_position.distance_to(grapple_point)
	
	var force_magnitude = grapple_force
	velocity += direction_to_anchor * force_magnitude * delta
	
	if distance < 0.5:
		_release_grapple()

func _apply_head_bob(delta):
	if is_moving:
		var current_speed = velocity.length()
		var speed_factor = clamp(current_speed / 5.0, 0.5, 2.0) 
		head_bob_timer += delta * head_bob_speed * speed_factor
		var vertical_bob = sin(head_bob_timer) * head_bob_intensity
		var horizontal_sway = sin(head_bob_timer * 0.5) * head_bob_sway_intensity 
		camera.position.y = vertical_bob
		camera.position.x = horizontal_sway
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, 10.0 * delta)

func throw_grenade():
	var grenade = grenade_scene.instantiate()
	grenade.global_position = throw_origin.global_position
	grenade.throw(-camera.global_transform.basis.z)
	get_tree().current_scene.add_child(grenade)
