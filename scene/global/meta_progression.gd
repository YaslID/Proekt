extends Node
#сохранялка
@onready var gold_text: Label = %GoldText

var save_path = "user://game.save"

var gold: int  

var save_data: Dictionary = {
	"meta_upgrade_currency": 0,
	"meta_upgrades": {}
}


func _ready():
	load_file()
	update_gold()
	

func save_file(): # создали файл и сохранили какую нам надо информацию
	var file = FileAccess.open(save_path,FileAccess.WRITE) # открыв доступ к  файлу
	file.store_var(save_data) 


func load_file():
	if not FileAccess.file_exists(save_path): #чекаем чтоб ошибки не было
		return # ниче не делает ниже если нету файла
	var file = FileAccess.open(save_path,FileAccess.READ)
	save_data = file.get_var() #должны в save_data запихнуть это
	


func add_meta_upgrade(upgrade: MetaUpgrade):#добавил мета апгрейда
	if not save_data["meta_upgrades"].has(upgrade.id):
		save_data["meta_upgrades"][upgrade.id] = { # появл его ключ новый
			"quantity": 0
		}#добавил новый пункт в словарь. новый индекс
	
	save_data["meta_upgrades"][upgrade.id]["quantity"] += 1

func get_upgrade_quantity(upgrade_id: String): #чтобы  быстро количество получать
	if save_data["meta_upgrades"].has(upgrade_id): #есть ли в этом словаре мета апгрейдс с таким элементом id
		return save_data["meta_upgrades"][upgrade_id]["quantity"]
	return 0

func update_gold(): #обновл саму переменную и сохран и также будет обновлять текст голды
	gold = save_data["meta_upgrade_currency"]
	gold_text.text = str(gold)
	save_file()
