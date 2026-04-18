extends Node

@onready var timer = $Timer

@export var arena_time_manager: ArenaTimeManager
@export var skeleton_scene: PackedScene
@export var goblin_scene: PackedScene
@export var wolf_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var mini_boss_2scene: PackedScene

var base_spawn_time
var min_spawn_time = 0.2
var difficulty_multiplier = 0.01
var enemy_pool = EnemyPool.new()


func _ready():
	enemy_pool.add_mob(skeleton_scene, 30)
	base_spawn_time = timer.wait_time
	arena_time_manager.difficulty_increased.connect(on_difficulty_incrased)

func get_spawn_position(): # могу не делать это
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var spawn_position = Vector2.ZERO
	var random_direction = Vector2.RIGHT.rotated(randf_range(0,TAU)) # напр вправо это 0 градусов и идет по кругу потом тау это 2pP
	var random_distance = randi_range(380,500)
	
	for i in 24: # могу не делать это
		spawn_position = player.global_position + (random_direction * random_distance)
		var ray_extender = random_direction * 20 #чтоб в стенах мобы не застревали(стен нету у меня)
		var raycast = PhysicsRayQueryParameters2D.create\
		(player.global_position,  spawn_position + ray_extender, 1)
		var intersection = get_tree().root.world_2d.direct_space_state.intersect_ray(raycast)
		
		if intersection.is_empty(): # могу не делать это
			break
			
		else:
			random_direction = random_direction.rotated(deg_to_rad(15)) # могу не делать это
			
			
			
	return spawn_position # могу не делать это
	
func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var chosen_mob = enemy_pool.pick_mob()
	var enemy = chosen_mob.instantiate() as Node2D
	var back_layer = get_tree().get_first_node_in_group("back_layer") #мобы будут спавнится в бэк лэере
	back_layer.add_child(enemy)
	
	enemy.global_position = get_spawn_position()
	
	
func on_difficulty_incrased(difficulty_level: int ):
	var new_spawn_time = max(min_spawn_time, (base_spawn_time - (difficulty_level * difficulty_multiplier)))
	timer.wait_time = new_spawn_time
	
	if difficulty_level == 2:
		enemy_pool.add_mob(goblin_scene, 70)
	elif  difficulty_level == 4:
		enemy_pool.add_mob(wolf_scene, 20)
	elif difficulty_level == 6:
		enemy_pool.add_mob(mini_boss_scene, 10)
	elif difficulty_level == 8:
		enemy_pool.add_mob(mini_boss_2scene, 5)
	
	
