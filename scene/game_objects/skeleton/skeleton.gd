extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var movement_component = $MovementComponent

@export var death_scene: PackedScene
@export var sprite: CompressedTexture2D #все спрайты имеют наши



func _ready():
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
		AutoSave._on_enemy_killed(false) 
	queue_free()
	
	
	
