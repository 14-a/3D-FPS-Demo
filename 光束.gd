@tool
extends Node3D
class_name 光束

@export var 最大长度 = 10.0
@export var 光束内焰颜色 : Color
@export var 光束外焰颜色 : Color
@export var 亮度 : float = 10

@onready var Ray = $RayCast3D

var 光束内焰 = MeshInstance3D.new()
var 光束外焰 = MeshInstance3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Ray.target_position = Vector3(0,0,-最大长度)
	
	var 内焰材质 = StandardMaterial3D.new()
	内焰材质.albedo_color = 光束内焰颜色
	内焰材质.emission_enabled = true
	内焰材质.emission = 光束内焰颜色
	内焰材质.emission_energy_multiplier = 亮度
	
	var 外焰材质 = StandardMaterial3D.new()
	外焰材质.albedo_color = 光束外焰颜色
	外焰材质.emission_enabled = true
	外焰材质.emission = 光束外焰颜色
	外焰材质.emission_energy_multiplier = 亮度 / 2.0
	外焰材质.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var box = BoxMesh.new()
	box.size *= .25
	box.size.z = 1
	光束内焰.mesh = box
	光束内焰.material_overlay = 内焰材质
	
	add_child(光束内焰)
	
	var box_ = BoxMesh.new()
	box_.size.x = .5
	box_.size.y = .5
	box_.size.z = 1
	光束外焰.mesh = box_
	光束外焰.set_surface_override_material(0, 外焰材质)
	add_child(光束外焰)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Ray.is_colliding():
		光束内焰.scale.z = (Ray.get_collision_point() - position).length()
		光束外焰.scale.z = (Ray.get_collision_point() - position).length()
		光束内焰.position.z = -(Ray.get_collision_point() - position).length() /2
		光束外焰.position.z = -(Ray.get_collision_point() - position).length() /2
	else:
		光束内焰.scale.z = Ray.target_position.length() * 10
		光束内焰.position.z = (Ray.target_position.z / 2.0)
		光束外焰.scale.z = Ray.target_position.length() * 10
		光束外焰.position.z = (Ray.target_position.z / 2.0)
	pass
