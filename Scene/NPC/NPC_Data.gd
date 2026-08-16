
## 用于NPC的一些数据
## 状态为0时时待机，1时是巡逻, 2时是追逐, 3时是攻击
extends Resource

@export var 运动向量 : Vector3 = Vector3()
@export var 血量 = 100
@export var 伤害 = 10
@export var 速度 = 10

## 0是待机
## 1是巡逻
## 2是追逐
## 3是攻击
@export var 状态 = 0
