class_name UpgradePool

#словарь кот будет содержать все разновидности мобов и их вес
var upgrades: Array[Dictionary] = []
var weight_sum = 0

func add_upgrade(upgrade, weight: int):
	upgrades.append({"upgrade": upgrade, "weight": weight}) # добавляем эелемент в массив
	weight_sum += weight # сумма  скелета и гоблина


func remove_upgrade(applied_upgrade):
	upgrades = upgrades.filter(func(upgrade): return upgrade["upgrade"] !=  applied_upgrade)
	weight_sum = 0
	for upgrade in upgrades: #берет обновл массив без топора и плюсует вес кот мы обнули. пресчет веса
		weight_sum += upgrade["weight"]

	# к  примеру гоблин 20 а скелет 10. получается 30
func pick_upgrade(chosen_upgrades: Array): # чем больше вес тем больше шанс спавна
	var updated_upgrades: Array[Dictionary] = upgrades
	var updated_weight_sum = weight_sum
	
	if chosen_upgrades.size() > 0:
		updated_upgrades = []
		updated_weight_sum = 0
		for upgrade in upgrades:
			if upgrade["upgrade"] in chosen_upgrades:
				continue # перейди к след эелементу в этом аррее
			updated_upgrades.append(upgrade) #добавляем в пул апгрейдов
			updated_weight_sum += upgrade["weight"] # пересобираем из оставшихся апгрейдов
			
			
	var random_weight = randi_range(1, updated_weight_sum) # от 1 до 30 числа
	for upgrade in updated_upgrades: #цикл для выбора моба. получилось 30 к примеру
		random_weight -= upgrade["weight"] # первым скелет к примеру и от к примеру 30-10 получили 200
		if random_weight <= 0: # сравниваем и потом заново цикл и там к примеру гоблин и от оставшихся 20-20
			return upgrade["upgrade"] # и потом спавним
			
