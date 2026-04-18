extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var movement_component = $MovementComponent
@onready var attack_timer: Timer = $AttackTimer
@onready var player = null
@onready var blueball_spawner: Node2D = $BlueballSpawner

@export var death_scene: PackedScene
@export var blueball_scene: PackedScene
@export var sprite: CompressedTexture2D #все спрайты имеют наши

enum Phase{ #числовому знач придать наименвание
	Phase_1,
	Phase_2
}

var base_speed
var attack_range = false
var current_phase = Phase.Phase_1


func _ready():
	player = get_tree().get_first_node_in_group("player")
	base_speed = movement_component.max_speed
	health_component.died.connect(on_died)



func _process(delta):
	var direction = movement_component.get_direction()
	movement_component.move_to_player(self) # сам скелетон

	if direction.x != 0 || direction.y != 0: # || значит или
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
	
	var face_sign = sign(direction.x) #sign зивисит от direction
	if face_sign != 0:
		animated_sprite_2d.scale.x = face_sign
	
	
	


func on_died():
	var back_layer = get_tree().get_first_node_in_group("back_layer")
	var death_instance = death_scene.instantiate() as DeathComp
	back_layer.add_child(death_instance)
	death_instance.gpu_particles_2d.texture = sprite
	death_instance.sprite_offset.position.y = animated_sprite_2d.offset.y
	death_instance.global_position = global_position
	if has_node("/root/AutoSave"): 
		AutoSave._on_enemy_killed(true)
	queue_free()
	
func check_phase():
	if health_component.current_health <= health_component.max_health / 2 and current_phase != Phase.Phase_2:
		current_phase = Phase.Phase_2
		base_speed *= 1.5
		attack_timer.wait_time = 2
		scale *= 1.5

func single_shot():
	var front_layer = get_tree().get_first_node_in_group("front_layer")
	var blueball_instance = blueball_scene.instantiate()
	front_layer.add_child(blueball_instance)
	blueball_instance.global_position = blueball_spawner.global_position
	blueball_instance.direction = (player.global_position - global_position).normalized()
	blueball_instance.rotation = blueball_instance.direction.angle()

func burst_shot():
	for i in range(2):
		await get_tree().create_timer(0.1 * i).timeout
		single_shot()


func _on_attack_range_body_entered(body):
	movement_component.max_speed = 0
	attack_range = true
	
	
func _on_attack_range_body_exited(body):
	movement_component.max_speed = base_speed
	attack_range = false

func _on_attack_timer_timeout():
	if not player: return
	if attack_range:
		match current_phase:
			Phase.Phase_1:
				single_shot()
			Phase.Phase_2:
				burst_shot()
	
func _on_health_component_health_decreased():
	check_phase()
