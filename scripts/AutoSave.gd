extends Node
# AutoSave.gd - Полная версия с автосохранением и интеграцией с PostgreSQL

const DB_PROVIDER := "Npgsql"
const DB_CONNECTION_STRING := "Host=localhost;Port=5432;Database=my_game_db;Username=postgres;Password=825P"

var play_time: float = 0
var enemies_killed: int = 0
var bosses_killed: int = 0
var total_deaths: int = 0
var last_save_time = 0

# Ссылки на узлы (для избежания повторного поиска)
var player: Node2D
var health_comp: Node
var exp_manager: Node

func _ready():
	# Ждём появления игрока и настраиваем сигналы
	await _setup_player()
	await load_game() 
	
	# Таймер автосохранения (каждые 10 секунд)
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.timeout.connect(_on_auto_save_timer)
	add_child(timer)
	timer.start()
	
	# Сохранение при выходе из игры (используем tree_exiting)
	get_tree().root.close_requested.connect(_on_quit)
	
	

func _setup_player():
	"""Поиск игрока и подключение сигналов (вызывается при старте и после смерти)"""
	print("⏳ Ожидание игрока...")
	while get_tree().get_first_node_in_group("player") == null:
		await get_tree().process_frame
	print("✅ Игрок появился")
	
	player = get_tree().get_first_node_in_group("player")
	health_comp = player.get_node("HealthComponent") if player else null
	exp_manager = get_tree().get_first_node_in_group("experience_manager")
	
	# Подключаем сигнал смерти (если ещё не подключён)
	if health_comp and not health_comp.died.is_connected(_on_player_died):
		health_comp.died.connect(_on_player_died)

func _process(delta):
	play_time += delta
	if Time.get_ticks_msec() - last_save_time > 1000:  # раз в секунду
		last_save_time = Time.get_ticks_msec()
		

# ------------------------------------------------------------------------------
# СОБЫТИЯ ИГРОКА
# ------------------------------------------------------------------------------

func _on_player_died():
	# Останавливаем музыку (ищем по группе "music" или в /root)
	var music = get_tree().get_first_node_in_group("music")
	if music:
		music.stop()
		print("🎵 Музыка остановлена (через группу)")
	else:
		if has_node("/root/MusicPlayer"):
			$"/root/MusicPlayer".stop()
			print("🎵 Музыка остановлена (через /root)")
		else:
			print("⚠ MusicPlayer не найден")
	
	# Увеличиваем счётчик смертей ДО сохранения статистики
	total_deaths += 1
	var saved = await save_game()
	if saved:
		await save_stats()
	
	print("💀 Смертей: ", total_deaths)
	
	# После смерти игрок обычно исчезает и появляется заново.
	# Ждём появления нового экземпляра и переподключаем сигналы.
	await _setup_player()
	
	if exp_manager:
		exp_manager.current_level = 1
		exp_manager.current_experience = 0
		exp_manager.target_experience = 1
		exp_manager.experience_update.emit(0, 1)
		# Сохраняем сброшенный уровень в БД
		await save_level_progress(1, 1)
		print("🔄 Прогресс уровня сброшен после смерти: уровень=1, target=1")

func _on_enemy_killed(is_boss: bool = false):
	"""Вызывайте этот метод из скриптов врагов при их уничтожении."""
	if is_boss:
		bosses_killed += 1
	else:
		enemies_killed += 1
	
	# Сохраняем статистику после каждого убийства (можно закомментировать,
	# если хотите полагаться только на автосохранение, но так изменения
	# будут видны в pgAdmin почти мгновенно).
	await save_stats()

# ------------------------------------------------------------------------------
# АВТОСОХРАНЕНИЕ ПО ТАЙМЕРУ И ПРИ ВЫХОДЕ
# ------------------------------------------------------------------------------

func _on_auto_save_timer():
	var saved = await save_game()
	if saved:
		await save_stats()
	print("⏱ Автосохранение выполнено")

func _on_quit():
	var saved = await save_game()
	if saved:
		await save_stats()
	print("👋 Сохранено перед выходом")
	get_tree().quit()


# ------------------------------------------------------------------------------
# СОХРАНЕНИЕ В БД
# ------------------------------------------------------------------------------

# func ensure_player_refs():
#	if not player or not is_instance_valid(player):
#		player = get_tree().get_first_node_in_group("player")
#	if player and (not health_comp or not is_instance_valid(health_comp)):
#		health_comp = player.get_node("HealthComponent") if player else null
#		
#		   
# Ищем все ExperienceManager и выбираем тот, у которого наибольший уровень
#
#	var managers = get_tree().get_nodes_in_group("experience_manager")
#	var best_manager = null
#	var max_level = -1
#	for m in managers:
#		if is_instance_valid(m):
#			if m.current_level > max_level:
#				max_level = m.current_level
#				best_manager = m
#				exp_manager = best_manager
#	if managers.size() > 1:
#		print("⚠ Найдено несколько exp_manager, выбран с уровнем ", best_manager.current_level if best_manager else "null")

func save_game() -> bool:
	var stack = get_stack()
	print("🔍 save_game вызван из: ", stack[1].source, " строка ", stack[1].line)
	if stack.size() > 2:
		print("   вызвано из: ", stack[2].source, " строка ", stack[2].line)
	var player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		print("⚠ save_game: player не найден")
		return false
		
	if not player_node.has_node("HealthComponent"):
		print("⚠ save_game: HealthComponent не найден")
		return false
		
	var health_comp_node = player_node.get_node("HealthComponent")
	if health_comp_node.current_health == null or health_comp_node.max_health == null:
		print("⚠ save_game: здоровье = null, сохранение отменено")
		return false
		
	await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
        """
        INSERT INTO player_saves (id, health, max_health, pos_x, pos_y, gold, last_save)
        VALUES (1, @health, @max_health, @pos_x, @pos_y, @gold, NOW())
        ON CONFLICT (id) DO UPDATE SET
            health = @health, max_health = @max_health, pos_x = @pos_x, pos_y = @pos_y,
            gold = @gold, last_save = NOW()
		""",
		{
			"@health": health_comp_node.current_health,   # ← локальная переменная
			"@max_health": health_comp_node.max_health,   # ← локальная
			"@pos_x": player_node.global_position.x,      # ← локальная
			"@pos_y": player_node.global_position.y,      # ← локальная
			"@gold": MetaProgression.save_data["meta_upgrade_currency"]
		}
	)
	print("💾 Прогресс сохранён (gold = ", MetaProgression.save_data["meta_upgrade_currency"], ")")
	return true
	
func save_stats():
	await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"""
		INSERT INTO player_stats (player_id, total_kills, total_deaths, play_time_seconds, bosses_defeated, enemies_killed)
		VALUES (1, @kills, @deaths, @play_time, @bosses, @enemies)
		ON CONFLICT (player_id) DO UPDATE SET
			total_kills = @kills, total_deaths = @deaths, play_time_seconds = @play_time,
			bosses_defeated = @bosses, enemies_killed = @enemies
		""",
		{
			"@kills": enemies_killed + bosses_killed,
			"@deaths": total_deaths,
			"@play_time": int(play_time),
			"@bosses": bosses_killed,
			"@enemies": enemies_killed
		}
	)
	print("📊 Статистика сохранена")

func save_level_progress(level: int,  target: int) -> bool:
	await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
        """
        INSERT INTO player_saves (id, level,  target_exp, last_save)
        VALUES (1, @level,  @target, NOW())
        ON CONFLICT (id) DO UPDATE SET
            level = @level,  target_exp = @target, last_save = NOW()
		""",
		{
			"@level": level,
			"@target": target
		}
	)
	print("💾 Прогресс уровня сохранён: уровень=", level,  " до=", target)
	return true

# ------------------------------------------------------------------------------
# АПГРЕЙДЫ
# ------------------------------------------------------------------------------

func save_upgrade(upgrade_id: String, quantity: int = 1):
	var affected = await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"""
		INSERT INTO player_upgrades (player_id, upgrade_id, quantity)
		VALUES (1, @upgrade_id, @quantity)
		ON CONFLICT (player_id, upgrade_id) DO UPDATE SET
			quantity = player_upgrades.quantity + @quantity
		""",
		{
			"@upgrade_id": upgrade_id,
			"@quantity": quantity
		}
	)
	if affected > 0:
		print("🔧 Апгрейд сохранён: ", upgrade_id, " +", quantity)
	else:
		print("❌ Ошибка сохранения апгрейда")

func load_upgrades() -> Dictionary:
	var result = await GDQuery.query_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"SELECT upgrade_id, quantity FROM player_upgrades WHERE player_id = 1",
		{}
	)
	var upgrades = {}
	for row in result:
		upgrades[row.upgrade_id] = row.quantity
	print("🔧 Загружено апгрейдов: ", upgrades.size())
	return upgrades

# ------------------------------------------------------------------------------
# ПОКУПКА АПГРЕЙДА
# ------------------------------------------------------------------------------
func save_gold() -> bool:
	var gold_to_save = MetaProgression.save_data["meta_upgrade_currency"]
	await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
        """
        INSERT INTO player_saves (id, gold, last_save)
        VALUES (1, @gold, NOW())
        ON CONFLICT (id) DO UPDATE SET
            gold = @gold, last_save = NOW()
		""",
		{ "@gold": gold_to_save }
	)
	print("💾 Золото сохранено: ", gold_to_save)
	return true


func purchase_upgrade(upgrade_id: String, cost: int) -> bool:
	if MetaProgression.save_data["meta_upgrade_currency"] < cost:
		print("❌ Недостаточно монет для апгрейда ", upgrade_id)
		return false
	
	MetaProgression.save_data["meta_upgrade_currency"] -= cost
	MetaProgression.update_gold()
	
	await save_upgrade(upgrade_id, 1)
	if not MetaProgression.save_data["meta_upgrades"].has(upgrade_id):
		MetaProgression.save_data["meta_upgrades"][upgrade_id] = {"quantity": 0}
	MetaProgression.save_data["meta_upgrades"][upgrade_id]["quantity"] += 1
	MetaProgression.update_gold()
	await save_gold()   # обновляем gold в player_saves
	
	print("✅ Апгрейд куплен: ", upgrade_id, ", осталось монет: ", MetaProgression.save_data["meta_upgrade_currency"])
	return true
	
func save_setting(key: String, value: Variant):
	var str_value = str(value)
	await GDQuery.execute_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"""
		INSERT INTO game_settings (setting_key, setting_value, updated_at)
		VALUES (@key, @value, NOW())
		ON CONFLICT (setting_key) DO UPDATE SET
			setting_value = @value,
			updated_at = NOW()
		""",
		{
			"@key": key,
			"@value": str_value
		}
	)
	print("💾 Настройка сохранена: ", key, " = ", str_value)
	
func load_settings() -> Dictionary:
	var result = await GDQuery.query_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"SELECT setting_key, setting_value FROM game_settings",
		{}
	)
	var settings = {}
	for row in result:
		settings[row.setting_key] = row.setting_value
	print("📦 Загружено настроек: ", settings.size())
	return settings
# ------------------------------------------------------------------------------
# ЗАГРУЗКА
# ------------------------------------------------------------------------------

func load_game():
	await _setup_player()
	
	# Ждём ExperienceManager (если нужен)
	var wait_count = 0
	while exp_manager == null and wait_count < 50:
		exp_manager = get_tree().get_first_node_in_group("experience_manager")
		if exp_manager == null:
			await get_tree().process_frame
			wait_count += 1
	
	if not player:
		return
	
	# Пытаемся загрузить существующее сохранение
	var progress = await GDQuery.query_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"SELECT id, health, max_health, pos_x, pos_y, gold, level, target_exp FROM player_saves WHERE id = 1",
		{}
	)
	
	if progress.size() == 0:
		print("🆕 Новая игра")
		MetaProgression.save_data["meta_upgrade_currency"] = 0
		if exp_manager:
			exp_manager.current_level = 1
			exp_manager.current_experience = 0
			exp_manager.target_experience = 1
			exp_manager.experience_update.emit(0, 1)
		if player and health_comp:
			health_comp.max_health = 10
			health_comp.current_health = 10
			health_comp.health_increased.emit()
		await save_game()
		await save_stats()
		return
	
	var data = progress[0]
	print("📦 Загружено золото: ", data["gold"])
	
	# Загружаем здоровье
	if health_comp:
		health_comp.max_health = data["max_health"]
		health_comp.current_health = data["health"]
		if health_comp.current_health <= 0:
			health_comp.current_health = health_comp.max_health
		health_comp.health_increased.emit()
	
	# Загружаем позицию (важно!)
	player.global_position = Vector2(data["pos_x"], data["pos_y"])
	
	# Загружаем золото
	MetaProgression.save_data["meta_upgrade_currency"] = data["gold"]
	MetaProgression.update_gold()
	
	# Уровень принудительно ставим 1 (игнорируем сохранённый)
	if exp_manager:
		exp_manager.current_level = 1
		exp_manager.current_experience = 0
		# target_exp загружаем из БД (чтобы прогресс опыта не сбрасывался, если не хотите)
		exp_manager.target_experience = 1
		exp_manager.experience_update.emit(0, 1)
	else:
		print("⚠ exp_manager не найден")
	
	# Статистика (опционально)
	var stats = await GDQuery.query_async(
		DB_PROVIDER,
		DB_CONNECTION_STRING,
		"SELECT * FROM player_stats WHERE player_id = 1",
		{}
	)
	if stats.size() > 0:
		var s = stats[0]
		enemies_killed = s["enemies_killed"]
		bosses_killed = s["bosses_defeated"]
		play_time = s["play_time_seconds"]
		total_deaths = s["total_deaths"]
		
	var upgrades = await load_upgrades()
	MetaProgression.save_data["meta_upgrades"] = {}
	for upgrade_id in upgrades:
		MetaProgression.save_data["meta_upgrades"][upgrade_id] = {
			"quantity": upgrades[upgrade_id]
		}
		
	print("🔧 Апгрейды загружены в MetaProgression")
	if exp_manager:
		exp_manager.current_level = 1
		exp_manager.current_experience = 0
		exp_manager.target_experience = 1   # ← дополнительно сбрасываем
		exp_manager.experience_update.emit(0, 1)
		print("🔧 ФИНАЛЬНАЯ УСТАНОВКА: уровень=1, target=1")
		await save_level_progress(1, 1)
		print("🔧 Сохранили уровень 1 в БД")
	
	print("📦 Загружено: здоровье, позиция, золото. Уровень принудительно 1.")
