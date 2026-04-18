extends Camera2D

@onready var player = %Player as Node2D


func _process(delta):
	if player == null: #чтоб ошибки не было
		return
	global_position = player.global_position
