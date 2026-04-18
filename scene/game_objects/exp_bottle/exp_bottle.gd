extends Node2D

@onready var collision_shape_2d = $Area2D/CollisionShape2D

var bottle_experience = 1

func tween_exp_bottle(percent: float, start_position: Vector2): # от нач позиц в сторону игрока
	var player = get_tree().get_first_node_in_group("player") as Node2D#делаем координаты
	if player == null:
		return

	global_position = start_position.lerp(player.global_position, percent) #постепенно ускор будет
	
	var direction = player.global_position - start_position #вращалка
	var direction_degrees = rad_to_deg(direction.angle()) # перевод в градусы
	
	rotation = lerp_angle(rotation, direction_degrees, 0.05) #плавное изменение. инетрполяция


func exp_collected():
	print("🍾 Бутылка собрана, опыт = ", bottle_experience)
	Global.experience_bottle_collected.emit(bottle_experience)
	queue_free() #самоуничтожение

func disable_collision():
	collision_shape_2d.disabled = true



func _on_area_2d_area_entered(area): # сигнал триггерить собтия арена2д(маски)
	Callable(disable_collision).call_deferred() # чтоб не ломалась анимка
	var rng = randi_range(20,40)
	var player = get_tree().get_first_node_in_group("player") as Node2D#делаем координаты
	if player == null:
		return
	var away_point = global_position + (global_position - player.global_position)\
	.normalized() * rng #rng это расст на кот бутылек будет отлетать в противоп сторону от игрока
	var tween_out = create_tween()
	#себя, параметр кот анимировать будем, конечная, скорость 0.4м
	tween_out.tween_property(self, "global_position", away_point, .4)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_CUBIC)
	await tween_out.finished
	var tween = create_tween()
	tween.tween_method(tween_exp_bottle.bind(global_position), 0.0, 1.0, 0.3)\
	.set_ease(Tween.EASE_IN)\
	.set_trans(Tween.TRANS_CUBIC) #делаем bind для второго аргумента
	$AudioStreamPlayer2D.play()
	tween.tween_callback(exp_collected) # когда анимка кнчится выше вызовем ее
	#set_ease и далее это плавность анимки бутылки. easings.net
