extends Node
class_name ExperienceManager

signal level_up(current_level) #вылет карт при апргейде
signal experience_update (current_experience:float, target_experience:float)

var current_experience = 0
var target_experience = 1 #чтоб апнуться стоко надо
var target_after_lvlup = 5
var current_level = 1



func _ready():
	Global.experience_bottle_collected.connect(on_experience_bottle_collected)

func  on_experience_bottle_collected (experience): #триггер для изменения опыта
	current_experience = min(current_experience + experience, target_experience) # логика прокачки
	experience_update.emit(current_experience,target_experience)
	
	if current_experience == target_experience: #отвечает за повыш уровня
		current_level += 1
		current_experience = 0
		target_experience += target_after_lvlup
		print("🔥 Повышение уровня! Новый уровень: ", current_level)
		experience_update.emit(current_experience,target_experience)
		level_up.emit(current_level) #передача
		if has_node("/root/AutoSave"):
			print("ExperienceManager: вызываю save_level_progress")
			AutoSave.save_level_progress(current_level,  target_experience)
	
	
