class_name EnemyPool

#словарь кот будет содержать все разновидности мобов и их вес
var mobs: Array[Dictionary] = []
var weight_sum = 0

func add_mob(mob, weight: int):
	mobs.append({"mob": mob, "weight": weight}) # добавляем эелемент в массив
	weight_sum += weight # сумма  скелета и гоблина
	
	# к  примеру гоблин 20 а скелет 10. получается 30
func pick_mob(): # чем больше вес тем больше шанс спавна
	var random_weight = randi_range(1, weight_sum) # от 1 до 30 числа
	for mob in mobs: #цикл для выбора моба. получилось 30 к примеру
		random_weight -= mob["weight"] # первым скелет к примеру и от к примеру 30-10 получили 200
		if random_weight <= 0: # сравниваем и потом заново цикл и там к примеру гоблин и от оставшихся 20-20
			return mob["mob"] # и потом спавним
			
