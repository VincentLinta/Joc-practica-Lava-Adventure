extends Control

const MUSIC_ACCENT := Color(0.85, 0.6, 0.15)   # auriu — Music
const SFX_ACCENT := Color(0.25, 0.75, 0.85)    # teal/cyan — SFX
const MUSIC_MUTED := Color(0.6, 0.15, 0.12)    # roșu-cărămiziu — Music la 0
const SFX_MUTED := Color(0.45, 0.2, 0.5)       # violet-închis — SFX la 0
const BACK_BG := Color(0.03, 0.12, 0.15)
const BACK_BORDER := Color(0.15, 0.55, 0.65)
const BACK_HOVER_BG := Color(0.05, 0.2, 0.25)
const BACK_HOVER_BORDER := Color(0.25, 0.75, 0.85)

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

	# --- STYLING VIZUAL ---
	_apply_sexy_theme()


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

	_refresh_slider_fill(music_slider, value, MUSIC_ACCENT, MUSIC_MUTED)
	_save_current_settings()

func _on_sfx_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		if value <= 0.001:
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

	_refresh_slider_fill(sfx_slider, value, SFX_ACCENT, SFX_MUTED)
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


# =========================================================
#  STYLING VIZUAL
# =========================================================
func _apply_sexy_theme() -> void:
	var music_label: Label = get_node_or_null("VBoxContainer/Music Volume")
	var sfx_label: Label = get_node_or_null("VBoxContainer/SFX Volume")

	if music_label:
		music_label.add_theme_color_override("font_color", MUSIC_ACCENT)
	if sfx_label:
		sfx_label.add_theme_color_override("font_color", SFX_ACCENT)

	_style_slider(music_slider, MUSIC_ACCENT, MUSIC_MUTED)
	_style_slider(sfx_slider, SFX_ACCENT, SFX_MUTED)
	_style_button(back_button, BACK_BG, BACK_BORDER, BACK_HOVER_BG, BACK_HOVER_BORDER)


func _style_slider(slider: HSlider, accent: Color, muted: Color) -> void:
	if not slider:
		return

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.08, 0.1)
	track.set_corner_radius_all(6)
	track.content_margin_top = 4
	track.content_margin_bottom = 4

	slider.add_theme_stylebox_override("slider", track)

	slider.set_meta("_dragging", false)

	slider.drag_started.connect(func():
		slider.set_meta("_dragging", true)
		slider.add_theme_icon_override("grabber", _make_circle_texture(Color(1, 1, 1), 9))
	)
	slider.drag_ended.connect(func(_value_changed: bool):
		slider.set_meta("_dragging", false)
		var resting_color := muted if slider.value <= 0.001 else accent
		slider.add_theme_icon_override("grabber", _make_circle_texture(resting_color, 8))
	)

	# Setează corect culorile (bară + bulină) chiar de la pornire,
	# inclusiv dacă valoarea a fost salvată pe 0.
	_refresh_slider_fill(slider, slider.value, accent, muted)


func _refresh_slider_fill(slider: HSlider, value: float, accent: Color, muted: Color) -> void:
	if not slider:
		return

	var effective_color: Color = muted if value <= 0.001 else accent

	var fill := StyleBoxFlat.new()
	fill.bg_color = effective_color.darkened(0.35)
	fill.set_corner_radius_all(6)

	var fill_dragging := StyleBoxFlat.new()
	fill_dragging.bg_color = effective_color
	fill_dragging.set_corner_radius_all(6)

	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_dragging)
	slider.add_theme_stylebox_override("grabber_area_disabled", fill)

	# Bulina se recolorează și ea — dar nu în timp ce e trasă (rămâne albă
	# pe durata drag-ului, exact ca înainte; se actualizează la eliberare
	# sau la o schimbare de valoare din tastatură, nu din mouse-drag).
	if not slider.get_meta("_dragging", false):
		var grabber_icon := _make_circle_texture(effective_color, 8)
		slider.add_theme_icon_override("grabber", grabber_icon)
		slider.add_theme_icon_override("grabber_disabled", grabber_icon)


func _style_button(button: Control, bg: Color, border: Color, hover_bg: Color, hover_border: Color) -> void:
	if not button:
		return

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(6)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = hover_bg
	hover.border_color = hover_border

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg.darkened(0.3)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))

	button.resized.connect(func(): button.pivot_offset = button.size / 2)
	button.mouse_entered.connect(func():
		var t := create_tween()
		t.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK)
	)
	button.mouse_exited.connect(func():
		var t := create_tween()
		t.tween_property(button, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	)


func _make_circle_texture(color: Color, radius: int) -> ImageTexture:
	var diameter := radius * 2
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(radius, radius)
	for x in range(diameter):
		for y in range(diameter):
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
