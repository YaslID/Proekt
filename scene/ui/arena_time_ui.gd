extends CanvasLayer

@export var arena_time_manager: Node #привязка arena_manager
@onready var label = %Label #ссылка на нод всегда рабочей будет изза процента



func _process(delta):
	if arena_time_manager == null:
		return
		
	var time_elapsed = arena_time_manager.get_time_elapsed ()
	label.text = format_timer(time_elapsed)
	
func format_timer (seconds: float):
	var minutes = floor(seconds/60)
	var remaining_seconds = seconds - (minutes * 60) # никогда не будет больше 60
	return str(int(minutes)) + ":" + "%02d"  %  floor(remaining_seconds) #записываем  переменные в текст. что в ковычках будет тест в чистом виде
