extends Area2D
#храним количество урона
@export var damage: int = 1

func enemy_damage(): #возвращает переменную урона
	return damage
