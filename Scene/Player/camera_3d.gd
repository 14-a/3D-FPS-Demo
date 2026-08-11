extends Camera3D

var 偏移 = 0

var 偏移vec = Vector3.ZERO

var 偏移最大角度 = 45

var 衰减速度 = 0.1

func _process(delta: float) -> void:
	偏移 += (0 - 偏移) * 衰减速度
	rotation_degrees.x = 偏移 * 偏移最大角度 * (1 - (randf() * 2)) + 偏移vec.x
	rotation_degrees.y = 偏移 * 偏移最大角度 * (1 - (randf() * 2)) + 偏移vec.y
	rotation_degrees.z = 偏移 * 偏移最大角度 * (1 - (randf() * 2)) + 偏移vec.z
	偏移vec += (Vector3(0,0,0) - 偏移vec) * 衰减速度
	pass

## 给镜头添加抖动效果
func 抖动(幅度, 最大角度,衰减 = 0.1) -> void:
	偏移 = 幅度
	偏移最大角度 = 最大角度
	衰减速度 = 衰减
	pass 
