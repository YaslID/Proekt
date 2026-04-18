extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var panel_container: PanelContainer = $MarginContainer/PanelContainer

var options_menu_scene = preload("res://scene/ui/options_menu.tscn")

var is_closing = false #делаем красиво попаут окошко

func _ready():
	panel_container.pivot_offset = panel_container.size / 2 #чтоб прыжок норм был окна
	get_tree().paused = true
	animation_player.play("in")
	
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.3)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) #выпрыгивание окна аним


func close():
	if is_closing: #избегаем многократ нажатие
		return
		
	is_closing = true
	
	animation_player.play_backwards("in")
	
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0)
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.3)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	get_tree().paused = false
	
	queue_free()

func _input(event): # фиксим повторное нажатие esc и p
	if event.is_action_pressed("pause"):
		close()
		
	
	
func _on_resume_button_pressed(): #делаем как выше но наоборот
	close()

func _on_options_button_pressed():
	add_child(options_menu_scene.instantiate())

func _on_quit_button_pressed():
	get_tree().paused = false #чтоб пауза не перекинулось в другое место пишем это
	MusicPlayer.stop() #чтоб не игралась она в паузе
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
