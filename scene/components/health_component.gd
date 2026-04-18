extends Node
class_name HealthComponent

signal died
signal health_decreased
signal health_increased

@export var max_health: float = 10 
@export var damage_text_scene: PackedScene
var current_health: float




func _ready():
	current_health = max_health #текущ здоровье к максим приравнивается

func take_damage (damage):#отнимает здоровье
	var front_layer = get_tree().get_first_node_in_group("front_layer") as Node2D
	var damage_text_instance= damage_text_scene.instantiate() as Node2D
	front_layer.add_child(damage_text_instance) #текст не пропадет даже если моб умрет
	damage_text_instance.global_position = owner.global_position #овнер любой обьект кот принадлежит хелтх компоненту
	damage_text_instance.damage_text(damage)
	current_health = max(current_health - damage, 0) #чтоб <0 не было здоровье используем msx
	health_decreased.emit()
	
	if has_node("/root/AutoSave"):
		await AutoSave.save_game()
		
	Callable(check_death).call_deferred() #чтоб ошибок не было
	
	
func take_heal(heal):
	if current_health < max_health:
		var front_layer = get_tree().get_first_node_in_group("front_layer") as Node2D
		var damage_text_instance= damage_text_scene.instantiate() as Node2D
		front_layer.add_child(damage_text_instance) 
		damage_text_instance.global_position = owner.global_position 
		damage_text_instance.modulate = Color("72d6ce")
		damage_text_instance.damage_text(heal)
		current_health = min(current_health + heal, max_health) #не хотим чтоб hp ушло выше макс 
		health_increased.emit()
		
	if has_node("/root/AutoSave"):
			await AutoSave.save_game()
	
func get_health_value():
	return current_health / max_health

func check_death ():
	if current_health == 0:
		died.emit() #чтоб лут выпадал с моба
		
