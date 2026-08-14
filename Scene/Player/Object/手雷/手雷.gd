extends RigidBody3D

@export var fuse_time: float = 3.0  # 3秒引爆
@export var explosion_damage: float = 100.0
@export var explosion_radius: float = 8.0

# 标记是否已引爆，防止碰撞时重复触发
var is_exploded: bool = false

@export var explosion_scene = preload("res://Scene/Player/Object/手雷/Explosion.tscn")
@export var explosion_light = preload("res://Scene/Player/Object/fire/omni_light_3d.tscn")

@export var speed: float = 20.0  # 3D中速度单位是米/秒，建议先设小一点

signal bao

func throw(direction: Vector3):
	# 给刚体一个向前的冲量
	linear_velocity = direction.normalized() * speed
	
	# （可选）让抛掷物的正面朝向飞行方向
	#look_at(global_position + direction.normalized(), Vector3.UP)

func _ready():
	var sphere = SphereShape3D.new()
	sphere.radius = explosion_radius
	$Area3D/CollisionShape3D.shape = sphere
	# 启动计时器
	var timer = Timer.new()
	timer.wait_time = fuse_time
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_explode)
	timer.start()

#更多细节
func _on_body_entered(body):
	
	pass

func _on_explode():
	if is_exploded: return
	is_exploded = true
	
	var Explosion_instance = explosion_light.instantiate()
	Explosion_instance.a = 0.1
	get_tree().current_scene.add_child(Explosion_instance)
	Explosion_instance.global_position = global_position
	
	# 实例化爆炸场景
	var explosion_instance = explosion_scene.instantiate()
	# 必须添加到主场景（而不是手雷的子节点），否则手雷一销毁，特效就没了
	get_tree().current_scene.add_child(explosion_instance)
	# 移动到爆炸位置
	explosion_instance.global_position = global_position
	
	# 强制重置并播放（防止某些情况下不播放）
	explosion_instance.restart()
	
	# 【自动清理】等粒子播放完（生命周期+0.5秒缓冲），自动删除特效，防止内存泄漏
	var particle_lifetime = explosion_instance.lifetime
	
	visible = false
	
	var overlapping_bodies = $Area3D.get_overlapping_bodies()
	
	var results = overlapping_bodies
	for result in results:
		var body = result
		if body is CharacterBody3D:
			var direction = (body.global_position - global_position).normalized()
			# 距离越近力越大
			var distance = body.global_position.distance_to(global_position)
			var force = 100.0 / max(distance, 1.0) 
			body.velocity += direction * force
			body._扣血(force)
			
	
	for result in results:
		var body = result
		if body is RigidBody3D:
			var direction = (body.global_position - global_position).normalized()
			# 距离越近力越大
			var distance = body.global_position.distance_to(global_position)
			var force = 50.0 / max(distance, 1.0) 
			body.linear_velocity += direction * force
		
		if body.name == "Player":
			var direction = (body.global_position - global_position).normalized()
			# 距离越近力越大
			var distance = body.global_position.distance_to(global_position)
			var force = 100.0 / max(distance, 1.0) 
			body.velocity += direction * force
			body.camera.抖动(1 / max(distance, 1.0),22.5, 0.05)
	
	await get_tree().create_timer(particle_lifetime + 0.5).timeout
	explosion_instance.queue_free()

	queue_free()
