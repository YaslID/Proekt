extends CanvasLayer
class_name  UpgradeScreen

signal upgrade_selected(upgrade: AbilityUpgrade)
@export var upgrade_card_scene: PackedScene
@onready var animation_player = $AnimationPlayer
@onready var card_container = $MarginContainer/CardContainer

func _ready():#пауза игры
	get_tree().paused = true

func set_ability_upgrades (upgrades: Array[AbilityUpgrade]):
	var delay = 0 #когда заспавн 2 карта делей будет 0.1
	for upgrade in upgrades:
		var upgrade_card_instance = upgrade_card_scene.instantiate() as AbilityUpgrdeCard			
		card_container.add_child(upgrade_card_instance)
		upgrade_card_instance.set_ability_upgrade(upgrade)
		upgrade_card_instance.play_in(delay) # вызывает анимацию повления
		upgrade_card_instance.card_selected.connect(on_upgrade_selected.bind(upgrade)) #дали ему параметр
		delay += 0.1
		#делаем  типо мостик upgrade сигналу

func on_upgrade_selected(upgrade: AbilityUpgrade):
	upgrade_selected.emit(upgrade) # присоединим к upgrade_manager
	animation_player.play("out")
	await  animation_player.animation_finished #чтоб аним успела сработат затухания
	# await AutoSave.save_game()
	get_tree().paused = false
	queue_free()
