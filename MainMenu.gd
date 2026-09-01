extends Control


const SETTINGS_PATH := "user://settings.cfg"

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]


var opened_from_game: bool = false


@onready var main_container: CenterContainer = $CenterContainer
@onready var options_container: CenterContainer = $OptionsContainer

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton
@onready var select_level_button: Button = $CenterContainer/VBoxContainer/SelectLevelButton

@onready var level_select_container: CenterContainer = $LevelSelectContainer

@onready var level1_button: Button = $LevelSelectContainer/VBoxContainer/Level1
@onready var level2_button: Button = $LevelSelectContainer/VBoxContainer/Level2
@onready var level3_button: Button = $LevelSelectContainer/VBoxContainer/Level3
@onready var level4_button: Button = $LevelSelectContainer/VBoxContainer/Level4
@onready var level5_button: Button = $LevelSelectContainer/VBoxContainer/Level5
@onready var level6_button: Button = $LevelSelectContainer/VBoxContainer/Level6
@onready var level7_button: Button = $LevelSelectContainer/VBoxContainer/Level7
@onready var level8_button: Button = $LevelSelectContainer/VBoxContainer/Level8
@onready var level9_button: Button = $LevelSelectContainer/VBoxContainer/Level9
@onready var level10_button: Button = $LevelSelectContainer/VBoxContainer/Level10

@onready var level_back_button: Button = $LevelSelectContainer/VBoxContainer/Back
@onready var resolution_option: OptionButton = $OptionsContainer/PanelContainer/VBoxContainer/ResolutionOption
@onready var fullscreen_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/FullscreenButton
@onready var borderless_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/BorderlessButton
@onready var windowed_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/WindowedButton
@onready var back_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/BackButton

# Variabilele pentru butonul și meniul Audio
@onready var audio_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/AudioButton
@onready var audio_menu: Control = $AudioMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Așteptăm un cadru ca să fim siguri că meniul e afișat complet pe ecran înainte de sunet
	await get_tree().process_frame
	SFXManager.play_ui_sound(preload("res://sfx/MenuOpen.mp3"))

	if opened_from_game:
		MusicManager.pause_music()
	else:
		MusicManager.change_music(preload("res://deuslower-dark-fantasy-ambient-dungeon-synthpiano-verse-248214.mp3"))
		
	start_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_start_button_pressed()
	)
	restart_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_restart_button_pressed()
	)
	options_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_options_button_pressed()
	)
	exit_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_exit_button_pressed()
	)
	select_level_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_select_level_pressed()
	)
	level_back_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		_on_level_back_pressed()
	)

	# --- RESETAREA SCORULUI LA FIECARE BUTON DE NIVEL ---
	var level_buttons_array = [
		level1_button, level2_button, level3_button, level4_button, level5_button,
		level6_button, level7_button, level8_button, level9_button, level10_button
	]
	
	for i in range(level_buttons_array.size()):
		var lvl_num = i + 1
		if level_buttons_array[i]:
			level_buttons_array[i].pressed.connect(func():
				SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
				GameState.score = 0
				GameState.start_level(lvl_num)
			)
			# Hover și Focus (săgeți) pe butoanele de nivel
			level_buttons_array[i].mouse_entered.connect(func():
				SFXManager.play_ui_sound(preload("res://sfx/hover.mp3"))
			)
			level_buttons_array[i].focus_entered.connect(func():
				SFXManager.play_ui_sound(preload("res://sfx/hover.mp3"))
			)

	fullscreen_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_fullscreen_button_pressed()
	)
	borderless_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_borderless_button_pressed()
	)
	windowed_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_windowed_button_pressed()
	)
	back_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		_on_back_button_pressed()
	)
	
	audio_button.pressed.connect(func():
		SFXManager.play_ui_sound(preload("res://sfx/click.mp3"))
		_on_audio_button_pressed()
	)

	# Adăugăm sunet de hover / focus (săgeți tastatură) pentru toate butoanele principale
	for btn in [start_button, restart_button, options_button, exit_button, select_level_button, level_back_button, fullscreen_button, borderless_button, windowed_button, back_button, audio_button]:
		if btn:
			btn.mouse_entered.connect(func():
				SFXManager.play_ui_sound(preload("res://sfx/hover.mp3"))
			)
			btn.focus_entered.connect(func():
				SFXManager.play_ui_sound(preload("res://sfx/hover.mp3"))
			)

	setup_resolution_options()
	await load_video_settings()

	main_container.show()
	options_container.hide()
	level_select_container.hide()
	
	if audio_menu:
		audio_menu.hide()

	if opened_from_game:
		start_button.text = "CONTINUE"
		restart_button.show()
	else:
		start_button.text = "START GAME"
		restart_button.hide()

	# Actualizăm starea butoanelor la pornire
	_update_level_buttons_status()

	start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
		
	if audio_menu and audio_menu.visible:
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		audio_menu.hide()
		get_viewport().set_input_as_handled()

	elif level_select_container.visible:
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		_on_level_back_pressed()
		get_viewport().set_input_as_handled()

	elif options_container.visible:
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()

	elif opened_from_game and main_container.visible:
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		get_tree().paused = false
		MusicManager.resume_music()
		queue_free()
		get_viewport().set_input_as_handled()


func _update_level_buttons_status() -> void:
	var level_buttons = [
		level1_button, level2_button, level3_button, level4_button, level5_button,
		level6_button, level7_button, level8_button, level9_button, level10_button
	]
	
	for i in range(level_buttons.size()):
		var level_num := i + 1
		if level_buttons[i]:
			level_buttons[i].disabled = not GameState.is_level_unlocked(level_num)


func _on_start_button_pressed() -> void:
	if opened_from_game:
		get_tree().paused = false
		MusicManager.resume_music()
		queue_free()
	else:
		get_tree().paused = false
		GameState.score = 0
		GameState.start_level(1)


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameState.score = 0
	GameState.start_level(GameState.current_level)
	queue_free()


func _on_options_button_pressed() -> void:
	main_container.hide()
	options_container.show()
	resolution_option.grab_focus()


func _on_audio_button_pressed() -> void:
	options_container.hide()
	audio_menu.show()


func _on_back_button_pressed() -> void:
	options_container.hide()
	main_container.show()
	options_button.grab_focus()


func _on_select_level_pressed() -> void:
	_update_level_buttons_status()
	main_container.hide()
	level_select_container.show()
	level1_button.grab_focus()


func _on_level_back_pressed() -> void:
	level_select_container.hide()
	main_container.show()
	select_level_button.grab_focus()


func _on_fullscreen_button_pressed() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	save_video_settings()


func _on_borderless_button_pressed() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	save_video_settings()


func _on_windowed_button_pressed() -> void:
	await apply_selected_resolution()


func _on_apply_resolution_button_pressed() -> void:
	await apply_selected_resolution()


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func setup_resolution_options() -> void:
	resolution_option.clear()

	for resolution in RESOLUTIONS:
		var resolution_text := (
			str(resolution.x)
			+ " x "
			+ str(resolution.y)
		)
		resolution_option.add_item(resolution_text)

	select_resolution_in_menu(
		DisplayServer.window_get_size()
	)


func select_resolution_in_menu(resolution: Vector2i) -> void:
	for index in range(RESOLUTIONS.size()):
		if RESOLUTIONS[index] == resolution:
			resolution_option.select(index)
			return

	resolution_option.select(0)


func get_selected_resolution() -> Vector2i:
	var selected_index: int = resolution_option.selected

	if selected_index < 0:
		return RESOLUTIONS[0]

	if selected_index >= RESOLUTIONS.size():
		return RESOLUTIONS[0]

	return RESOLUTIONS[selected_index]


func apply_selected_resolution() -> void:
	var selected_resolution: Vector2i = get_selected_resolution()

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
	)

	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		false
	)

	await get_tree().process_frame

	DisplayServer.window_set_size(
		selected_resolution
	)

	await get_tree().process_frame

	center_game_window()
	save_video_settings()


func center_game_window() -> void:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var window_size: Vector2i = DisplayServer.window_get_size()

	var centered_position := Vector2i(
		screen_rect.position.x
		+ int((screen_rect.size.x - window_size.x) / 2.0),

		screen_rect.position.y
		+ int((screen_rect.size.y - window_size.y) / 2.0)
	)

	DisplayServer.window_set_position(
		centered_position
	)


func save_video_settings() -> void:
	var config := ConfigFile.new()
	var selected_resolution: Vector2i = get_selected_resolution()

	config.set_value(
		"video",
		"width",
		selected_resolution.x
	)

	config.set_value(
		"video",
		"height",
		selected_resolution.y
	)

	config.set_value(
		"video",
		"window_mode",
		DisplayServer.window_get_mode()
	)

	config.save(SETTINGS_PATH)


func load_video_settings() -> void:
	var config := ConfigFile.new()
	var load_error: Error = config.load(SETTINGS_PATH)

	if load_error != OK:
		return

	var saved_width: int = int(
		config.get_value(
			"video",
			"width",
			1280
		)
	)

	var saved_height: int = int(
		config.get_value(
			"video",
			"height",
			720
		)
	)

	var saved_mode: int = int(
		config.get_value(
			"video",
			"window_mode",
			DisplayServer.WINDOW_MODE_WINDOWED
		)
	)

	var saved_resolution := Vector2i(
		saved_width,
		saved_height
	)

	select_resolution_in_menu(saved_resolution)

	DisplayServer.window_set_mode(saved_mode)

	if saved_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(
			DisplayServer.WINDOW_FLAG_BORDERLESS,
			false
		)

		await get_tree().process_frame

		DisplayServer.window_set_size(
			saved_resolution
		)

		await get_tree().process_frame

		center_game_window()
