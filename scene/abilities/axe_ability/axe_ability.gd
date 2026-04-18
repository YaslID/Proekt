extends Node2D
class_name AxeAbility

@onready var hit_box_component = $HitBoxComponent


var axe_max_radius = 100 #100 пикс от персонажа
var base_direction = Vector2.RIGHT #отвеч за изнач напр топора

func _ready(): #твин это анимация через код. гибче чем анимка обычная
	base_direction= base_direction.rotated(randf_range(0, TAU)) #смещение
	var tween = create_tween()
	tween.tween_method(rotation_animation, 0.0, 2.0, 3) #мы можем создать интерполяцию от 0 до 100 и указать время
	tween.tween_callback(queue_free)

func rotation_animation(rotations): # ротатионс будет интерполяцией. она не статична
	var percent = rotations / 2 # плавный переход
	var axe_current_radius = percent * axe_max_radius # от 0 до 100
	var axe_current_direction = base_direction.rotated(rotations * TAU)# тау это 360%
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	global_position = player.global_position + (axe_current_direction * axe_current_radius)
	
	
