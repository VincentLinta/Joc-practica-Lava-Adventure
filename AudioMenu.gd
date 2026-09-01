extends Control

@onready var music_slider: HSlider = $VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXSlider
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	var saved_data = SaveManager.load_game()
	
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		var m_val = saved_data.get("bgm_volume", 1.0)
		music_slider.value = m_val
		AudioServer.set_bus_volume_db(music_idx, -80.0 if m_val <= 0.001 else linear_to_db(m_val))
		
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		var s_val = saved_data.get("sfx_volume", 1.0)
		sfx_slider.value = s_val
		AudioServer.set_bus_volume_db(sfx_idx, -80.0 if s_val <= 0.001 else linear_to_db(s_val))

	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	back_button.pressed.connect(_go_back)

	# --- INTEGRĂRILE PENTRU SUNETE (SFX) ---
	
	if music_slider:
		music_slider.drag_started.connect(SFXManager.start_slider_sound)
		music_slider.drag_ended.connect(func(_value_changed): SFXManager.stop_slider_sound())
		music_slider.mouse_entered.connect(func(): SFXManager.play_ui_sound(preload("res://sfx/hover.mp3")))

	if sfx_slider:
		sfx_slider.drag_started.connect(SFXManager.start_slider_sound)
		sfx_slider.drag_ended.connect(func(_value_changed): SFXManager.stop_slider_sound())
		sfx_slider.mouse_entered.connect(func(): SFXManager.play_ui_sound(preload("res://sfx/hover.mp3")))

	if back_button:
		back_button.mouse_entered.connect(func(): SFXManager.play_ui_sound(preload("res://sfx/hover.mp3")))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
		_go_back()
		get_viewport().set_input_as_handled()


func _on_music_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		if value <= 0.001:
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	
	_save_current_settings()


func _on_sfx_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		if value <= 0.001:
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
			
	_save_current_settings()


func _save_current_settings() -> void:
	var current_data = SaveManager.load_game()
	
	SaveManager.save_game(
		current_data.get("unlocked_level", 1),
		current_data.get("high_score", 0),
		current_data.get("level_high_scores", {}),
		current_data.get("master_volume", 1.0),
		sfx_slider.value,
		music_slider.value
	)


func _go_back() -> void:
	SFXManager.play_ui_sound(preload("res://sfx/cancel_back_esc.mp3"))
	hide()
	
	var current_scene = get_tree().current_scene
	if current_scene:
		var options = current_scene.find_child("OptionsContainer", true, false)
		if options:
			options.show()
