extends CanvasLayer

@onready var window_mode_button: Button = %WindowModeButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

func _ready():
	await load_and_apply_settings()   # загружаем настройки из БД
	update_options()

func load_and_apply_settings():
	var settings = await AutoSave.load_settings()
	
	# Применяем полноэкранный режим
	if settings.has("fullscreen"):
		var is_fullscreen = settings["fullscreen"] == "true"
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Применяем громкость музыки
	if settings.has("music_volume"):
		var vol = float(settings["music_volume"])
		music_slider.value = vol
		AudioServer.set_bus_volume_db(1, linear_to_db(vol))
	
	# Применяем громкость SFX
	if settings.has("sfx_volume"):
		var vol = float(settings["sfx_volume"])
		sfx_slider.value = vol
		AudioServer.set_bus_volume_db(2, linear_to_db(vol))

func update_options():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		window_mode_button.text = "Fullscreen"
	else:
		window_mode_button.text = "Windowed"
	
	sfx_slider.value = get_volume_percent(2)
	music_slider.value = get_volume_percent(1)

func get_volume_percent(bus_index: int):
	var volume_db = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(volume_db)

func _on_window_mode_button_pressed():
	var mode = DisplayServer.window_get_mode()
	if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		AutoSave.save_setting("fullscreen", "true")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		AutoSave.save_setting("fullscreen", "false")
	update_options()

func _on_sfx_slider_value_changed(value: float):
	var volume_db = linear_to_db(value)
	AudioServer.set_bus_volume_db(2, volume_db)
	AutoSave.save_setting("sfx_volume", value)

func _on_music_slider_value_changed(value: float):
	var volume_db = linear_to_db(value)
	AudioServer.set_bus_volume_db(1, volume_db)
	AutoSave.save_setting("music_volume", value)

func _on_back_button_pressed():
	queue_free()
