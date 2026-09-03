extends Control


const SETTINGS_PATH := "user://settings.cfg"

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]


# =========================================================
# PALETĂ DE CULORI — MENIU "LAVA ADVENTURE"
# =========================================================

const TITLE_COLOR := Color(1.0, 0.45, 0.1)
const TITLE_SHADOW := Color(0.6, 0.05, 0.0, 0.9)

const BUTTON_FONT := Color(1, 1, 1)

const MAIN_BG := Color(0.25, 0.03, 0.03)
const MAIN_BORDER := Color(0.8, 0.1, 0.1)
const MAIN_HOVER_BG := Color(0.4, 0.05, 0.05)
const MAIN_HOVER_BORDER := Color(1.0, 0.25, 0.2)

const LEVEL_BG := Color(0.35, 0.22, 0.02)
const LEVEL_BORDER := Color(0.85, 0.6, 0.15)
const LEVEL_HOVER_BG := Color(0.5, 0.32, 0.03)
const LEVEL_HOVER_BORDER := Color(1.0, 0.75, 0.2)

const OPTIONS_BG := Color(0.03, 0.12, 0.15)
const OPTIONS_BORDER := Color(0.15, 0.55, 0.65)
const OPTIONS_HOVER_BG := Color(0.05, 0.2, 0.25)
const OPTIONS_HOVER_BORDER := Color(0.25, 0.75, 0.85)


var opened_from_game: bool = false

# =========================================================
# PAUSE INPUT SAFETY
# =========================================================

var ignore_first_cancel: bool = false

# =========================================================
# ORIGINAL LEVEL BUTTON TEXT
# =========================================================

var original_level_button_texts: Dictionary = {}


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

@onready var apply_resolution_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/ApplyResolutionButton

@onready var fullscreen_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/FullscreenButton
@onready var borderless_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/BorderlessButton
@onready var windowed_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/WindowedButton
@onready var back_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/BackButton

@onready var audio_button: Button = $OptionsContainer/PanelContainer/VBoxContainer/AudioButton
@onready var audio_menu: Control = $AudioMenu


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# =========================================================
	# PAUSE MENU SAFETY
	# =========================================================

	if opened_from_game:
		Engine.time_scale = 1.0
		ignore_first_cancel = true

	await get_tree().process_frame

	SFXManager.play_ui_sound(
		preload("res://sfx/MenuOpen.mp3")
	)

	if opened_from_game:
		MusicManager.pause_music()
	else:
		MusicManager.change_music(
			preload(
				"res://deuslower-dark-fantasy-ambient-dungeon-synthpiano-verse-248214.mp3"
			)
		)

	# =========================================================
	# BUTOANE PRINCIPALE
	# =========================================================

	start_button.pressed.connect(_on_start_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	select_level_button.pressed.connect(_on_select_level_pressed)

	# =========================================================
	# LEVEL BUTTONS
	# =========================================================

	var level_buttons_array: Array[Button] = [
		level1_button,
		level2_button,
		level3_button,
		level4_button,
		level5_button,
		level6_button,
		level7_button,
		level8_button,
		level9_button,
		level10_button
	]

	# ---------------------------------------------------------
	# MEMORĂM TEXTELE ORIGINALE
	# ---------------------------------------------------------

	for button in level_buttons_array:
		if button:
			original_level_button_texts[button] = button.text

	# ---------------------------------------------------------
	# CONECTĂM BUTOANELE
	# ---------------------------------------------------------

	for i in range(level_buttons_array.size()):
		var lvl_num: int = i + 1
		var button: Button = level_buttons_array[i]

		if button:
			button.pressed.connect(
				_handle_level_button_pressed.bind(
					button,
					lvl_num
				)
			)

	level_back_button.pressed.connect(_on_level_back_pressed)

	# =========================================================
	# OPTIONS
	# =========================================================

	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	borderless_button.pressed.connect(_on_borderless_button_pressed)
	windowed_button.pressed.connect(_on_windowed_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	audio_button.pressed.connect(_on_audio_button_pressed)

	# =========================================================
	# HOVER / FOCUS
	# =========================================================

	var hover_buttons: Array[Control] = [
		start_button,
		restart_button,
		options_button,
		exit_button,
		select_level_button,
		level1_button,
		level2_button,
		level3_button,
		level4_button,
		level5_button,
		level6_button,
		level7_button,
		level8_button,
		level9_button,
		level10_button,
		level_back_button,
		apply_resolution_button,
		fullscreen_button,
		borderless_button,
		windowed_button,
		back_button,
		audio_button
	]

	for btn in hover_buttons:
		if btn:
			btn.mouse_entered.connect(
				_on_button_mouse_entered
			)

			btn.focus_entered.connect(
				_on_button_focus_entered
			)

	# =========================================================
	# CLICK SOUNDS
	# =========================================================

	start_button.pressed.connect(_play_click_sound)
	restart_button.pressed.connect(_play_click_sound)
	options_button.pressed.connect(_play_click_sound)
	exit_button.pressed.connect(_play_click_sound)
	select_level_button.pressed.connect(_play_click_sound)

	level_back_button.pressed.connect(_play_back_sound)
	fullscreen_button.pressed.connect(_play_click_sound)
	borderless_button.pressed.connect(_play_click_sound)
	windowed_button.pressed.connect(_play_click_sound)
	apply_resolution_button.pressed.connect(_play_click_sound)
	back_button.pressed.connect(_play_back_sound)
	audio_button.pressed.connect(_play_click_sound)

	# =========================================================
	# RESOLUTION
	# =========================================================

	setup_resolution_options()

	await load_video_settings()

	# =========================================================
	# VISIBILITY
	# =========================================================

	main_container.show()
	options_container.hide()
	level_select_container.hide()

	if audio_menu:
		audio_menu.hide()

	# =========================================================
	# START / CONTINUE
	# =========================================================

	if opened_from_game:
		start_button.text = "CONTINUE"
		restart_button.show()
	else:
		start_button.text = "START GAME"
		restart_button.hide()

	# =========================================================
	# LEVEL STATUS
	# =========================================================

	_update_level_buttons_status()

	# =========================================================
	# VISUAL
	# =========================================================

	_apply_sexy_theme()
	_fade_in()

	start_button.grab_focus()


# =========================================================
# AUDIO HELPERS
# =========================================================

func _play_click_sound() -> void:
	SFXManager.play_ui_sound(
		preload("res://sfx/click.mp3")
	)


func _play_back_sound() -> void:
	SFXManager.play_ui_sound(
		preload("res://sfx/cancel_back_esc.mp3")
	)


func _play_hover_sound() -> void:
	SFXManager.play_ui_sound(
		preload("res://sfx/hover.mp3")
	)


func _on_button_mouse_entered() -> void:
	_play_hover_sound()


func _on_button_focus_entered() -> void:
	_play_hover_sound()


# =========================================================
# INPUT BACK / ESC
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	# =========================================================
	# IGNORĂM ESC-UL CARE A DESCHIS MENIUL
	# =========================================================

	if ignore_first_cancel:
		ignore_first_cancel = false
		get_viewport().set_input_as_handled()
		return

	if audio_menu and audio_menu.visible:
		_play_back_sound()

		audio_menu.hide()

		get_viewport().set_input_as_handled()

	elif level_select_container.visible:
		_play_back_sound()

		_on_level_back_pressed()

		get_viewport().set_input_as_handled()

	elif options_container.visible:
		_play_back_sound()

		_on_back_button_pressed()

		get_viewport().set_input_as_handled()

	elif opened_from_game and main_container.visible:
		_play_back_sound()

		Engine.time_scale = 1.0
		get_tree().paused = false

		MusicManager.resume_music()

		queue_free()

		get_viewport().set_input_as_handled()


# =========================================================
# LEVEL STATUS
# =========================================================

func _update_level_buttons_status() -> void:
	var level_buttons: Array[Button] = [
		level1_button,
		level2_button,
		level3_button,
		level4_button,
		level5_button,
		level6_button,
		level7_button,
		level8_button,
	level9_button,
		level10_button
	]

	for i in range(level_buttons.size()):
		var level_num: int = i + 1
		var button: Button = level_buttons[i]

		if not button:
			continue

		var unlocked: bool = GameState.is_level_unlocked(level_num)

		# -----------------------------------------------------
		# IMPORTANT:
		# Nu dezactivăm butonul locked.
		# -----------------------------------------------------

		button.disabled = false

		# -----------------------------------------------------
		# TEXT LOCK / UNLOCK
		# -----------------------------------------------------

		if unlocked:
			if original_level_button_texts.has(button):
				button.text = str(
					original_level_button_texts[button]
				)
		else:
			button.text = (
				"🔒 "
				+ str(level_num)
			)

		# -----------------------------------------------------
		# KEYBOARD FOCUS
		# -----------------------------------------------------

		if unlocked:
			button.focus_mode = Control.FOCUS_ALL
		else:
			button.focus_mode = Control.FOCUS_NONE


# =========================================================
# LEVEL BUTTON CLICK
# =========================================================

func _handle_level_button_pressed(
	button: Button,
	level_number: int
) -> void:

	# ---------------------------------------------------------
	# LOCKED LEVEL
	# ---------------------------------------------------------

	if not GameState.is_level_unlocked(level_number):
		_play_back_sound()

		print(
			"🔒 LEVEL %d ESTE BLOCAT!"
			% level_number
		)

		button.release_focus()

		return

	# ---------------------------------------------------------
	# UNLOCKED LEVEL
	# ---------------------------------------------------------

	_play_click_sound()

	GameState.score = 0

	GameState.start_level(
		level_number
	)


# =========================================================
# START GAME / CONTINUE
# =========================================================

func _on_start_button_pressed() -> void:

	if opened_from_game:

		# -----------------------------------------------------
		# IMPORTANT:
		# Invalidăm death sequence cât timp jocul este încă paused.
		# Astfel secvența veche nu poate face reload imediat.
		# -----------------------------------------------------

		var player := get_tree().get_first_node_in_group("player")

		if (
			player
			and player.has_method("resume_death_after_pause")
		):
			player.resume_death_after_pause()

		Engine.time_scale = 1.0
		get_tree().paused = false

		MusicManager.resume_music()

		queue_free()

	else:

		Engine.time_scale = 1.0
		get_tree().paused = false

		GameState.score = 0
		GameState.start_level(1)


# =========================================================
# RESTART
# =========================================================

func _on_restart_button_pressed() -> void:

	get_tree().paused = false
	Engine.time_scale = 1.0

	GameState.score = 0

	GameState.start_level(
		GameState.current_level
	)

	queue_free()


# =========================================================
# OPTIONS
# =========================================================

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


# =========================================================
# LEVEL SELECT
# =========================================================

func _on_select_level_pressed() -> void:

	_update_level_buttons_status()

	main_container.hide()
	level_select_container.show()

	var level_buttons: Array[Button] = [
		level1_button,
		level2_button,
		level3_button,
		level4_button,
	level5_button,
		level6_button,
		level7_button,
		level8_button,
		level9_button,
		level10_button
	]

	for button in level_buttons:
		if (
			button
			and not button.disabled
			and button.focus_mode != Control.FOCUS_NONE
		):
			button.grab_focus()
			break


func _on_level_back_pressed() -> void:

	level_select_container.hide()
	main_container.show()

	select_level_button.grab_focus()


# =========================================================
# VIDEO MODE
# =========================================================

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


# =========================================================
# EXIT
# =========================================================

func _on_exit_button_pressed() -> void:

	get_tree().quit()


# =========================================================
# RESOLUTION OPTIONS
# =========================================================

func setup_resolution_options() -> void:

	resolution_option.clear()

	for resolution in RESOLUTIONS:

		var resolution_text := (
			str(resolution.x)
			+ " x "
			+ str(resolution.y)
		)

		resolution_option.add_item(
			resolution_text
		)

	select_resolution_in_menu(
		DisplayServer.window_get_size()
	)


func select_resolution_in_menu(
	resolution: Vector2i
) -> void:

	for index in range(
		RESOLUTIONS.size()
	):

		if RESOLUTIONS[index] == resolution:

			resolution_option.select(
				index
			)

			return

	resolution_option.select(0)


func get_selected_resolution() -> Vector2i:

	var selected_index: int = (
		resolution_option.selected
	)

	if selected_index < 0:
		return RESOLUTIONS[0]

	if selected_index >= RESOLUTIONS.size():
		return RESOLUTIONS[0]

	return RESOLUTIONS[selected_index]


# =========================================================
# APPLY RESOLUTION
# =========================================================

func apply_selected_resolution() -> void:

	var selected_resolution: Vector2i = (
		get_selected_resolution()
	)

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

	var screen_index: int = (
		DisplayServer.window_get_current_screen()
	)

	var screen_rect: Rect2i = (
		DisplayServer.screen_get_usable_rect(
			screen_index
		)
	)

	var window_size: Vector2i = (
		DisplayServer.window_get_size()
	)

	var centered_position := Vector2i(
		screen_rect.position.x
		+ int(
			(
				screen_rect.size.x
				- window_size.x
			) / 2.0
		),

		screen_rect.position.y
		+ int(
			(
				screen_rect.size.y
				- window_size.y
			) / 2.0
		)
	)

	DisplayServer.window_set_position(
		centered_position
	)


# =========================================================
# SAVE VIDEO SETTINGS
# =========================================================

func save_video_settings() -> void:

	var config := ConfigFile.new()

	var selected_resolution: Vector2i = (
		get_selected_resolution()
	)

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

	config.save(
		SETTINGS_PATH
	)


# =========================================================
# LOAD VIDEO SETTINGS
# =========================================================

func load_video_settings() -> void:

	var config := ConfigFile.new()

	var load_error: Error = (
		config.load(SETTINGS_PATH)
	)

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

	select_resolution_in_menu(
		saved_resolution
	)

	DisplayServer.window_set_mode(
		saved_mode
	)

	if saved_mode == (
		DisplayServer.WINDOW_MODE_WINDOWED
	):

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


# =========================================================
# STYLING
# =========================================================

func _apply_sexy_theme() -> void:

	if has_node("Background"):

		$Background.color = Color(
			0.05,
			0.02,
			0.03
		)

	_style_title()

	# -------------------------------------------------------
	# MAIN BUTTONS
	# -------------------------------------------------------

	_style_button_group(
		[
			start_button,
			restart_button,
			options_button,
			exit_button,
			select_level_button
		],
		MAIN_BG,
		MAIN_BORDER,
		MAIN_HOVER_BG,
		MAIN_HOVER_BORDER
	)

	# -------------------------------------------------------
	# LEVEL BUTTONS
	# -------------------------------------------------------

	_style_button_group(
		[
			level1_button,
			level2_button,
			level3_button,
			level4_button,
			level5_button,
			level6_button,
			level7_button,
			level8_button,
			level9_button,
			level10_button,
			level_back_button
		],
		LEVEL_BG,
		LEVEL_BORDER,
		LEVEL_HOVER_BG,
		LEVEL_HOVER_BORDER
	)

	# -------------------------------------------------------
	# OPTIONS
	# -------------------------------------------------------

	_style_button_group(
		[
			resolution_option,
			apply_resolution_button,
			fullscreen_button,
			borderless_button,
			windowed_button,
			back_button,
			audio_button
		],
		OPTIONS_BG,
		OPTIONS_BORDER,
		OPTIONS_HOVER_BG,
		OPTIONS_HOVER_BORDER
	)

	# -------------------------------------------------------
	# OPTIONS PANEL
	# -------------------------------------------------------

	if options_container.has_node(
		"PanelContainer"
	):

		var panel: PanelContainer = (
			$OptionsContainer/PanelContainer
		)

		var panel_style := StyleBoxFlat.new()

		panel_style.bg_color = Color(
			OPTIONS_BG.r,
			OPTIONS_BG.g,
			OPTIONS_BG.b,
			0.9
		)

		panel_style.border_color = (
			OPTIONS_BORDER
		)

		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(10)
		panel_style.set_content_margin_all(16)

		panel.add_theme_stylebox_override(
			"panel",
			panel_style
		)


# =========================================================
# TITLE
# =========================================================

func _style_title() -> void:

	if not $CenterContainer/VBoxContainer.has_node(
		"TitleLabel"
	):
		return

	var title: Label = (
		$CenterContainer/VBoxContainer/TitleLabel
	)

	title.add_theme_font_size_override(
		"font_size",
		64
	)

	title.add_theme_color_override(
		"font_color",
		TITLE_COLOR
	)

	title.add_theme_color_override(
		"font_shadow_color",
		TITLE_SHADOW
	)

	title.add_theme_constant_override(
		"shadow_offset_x",
		0
	)

	title.add_theme_constant_override(
		"shadow_offset_y",
		0
	)

	title.add_theme_constant_override(
		"shadow_outline_size",
		14
	)

	_pulse_title(title)


func _pulse_title(title: Label) -> void:

	var tween := create_tween().set_loops()

	tween.tween_property(
		title,
		"modulate",
		Color(
			1,
			0.65,
			0.3
		),
		1.2
	).set_trans(
		Tween.TRANS_SINE
	)

	tween.tween_property(
		title,
		"modulate",
		Color(
			1,
			1,
			1
		),
		1.2
	).set_trans(
		Tween.TRANS_SINE
	)


# =========================================================
# BUTTON GROUP
# =========================================================

func _style_button_group(
	buttons: Array,
	bg: Color,
	border: Color,
	hover_bg: Color,
	hover_border: Color
) -> void:

	for button in buttons:

		if button:

			_style_button(
				button,
				bg,
				border,
				hover_bg,
				hover_border
			)


# =========================================================
# BUTTON STYLE
# =========================================================

func _style_button(
	button: Control,
	bg: Color,
	border: Color,
	hover_bg: Color,
	hover_border: Color
) -> void:

	var normal := StyleBoxFlat.new()

	normal.bg_color = bg
	normal.border_color = border

	normal.set_border_width_all(3)
	normal.set_corner_radius_all(6)

	var hover: StyleBoxFlat = (
		normal.duplicate()
	)

	hover.bg_color = hover_bg
	hover.border_color = hover_border

	var pressed: StyleBoxFlat = (
		normal.duplicate()
	)

	pressed.bg_color = (
		bg.darkened(0.3)
	)

	var disabled: StyleBoxFlat = (
		normal.duplicate()
	)

	disabled.bg_color = (
		bg.darkened(0.5)
	)

	disabled.border_color = (
		border.darkened(0.5)
	)

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	button.add_theme_color_override(
		"font_color",
		BUTTON_FONT
	)

	button.add_theme_color_override(
		"font_hover_color",
		BUTTON_FONT
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color(
			1,
			1,
			1,
			0.4
		)
	)

	if not button.resized.is_connected(_on_button_resized.bind(button)):
		button.resized.connect(
			_on_button_resized.bind(button)
		)

	if button.size != Vector2.ZERO:
		button.pivot_offset = (
			button.size / 2
		)


# =========================================================
# BUTTON RESIZE
# =========================================================

func _on_button_resized(button: Control) -> void:

	button.pivot_offset = (
		button.size / 2
	)


# =========================================================
# BUTTON HOVER SCALE
# =========================================================

func _on_button_hover(
	button: Control,
	is_hovering: bool
) -> void:

	var target_scale := (
		Vector2(1.05, 1.05)
		if is_hovering
		else Vector2.ONE
	)

	var tween := create_tween()

	tween.tween_property(
		button,
		"scale",
		target_scale,
		0.15
	).set_trans(
		Tween.TRANS_BACK
	)


# =========================================================
# FADE IN
# =========================================================

func _fade_in() -> void:

	modulate.a = 0.0

	var tween := create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.6
	).set_trans(
		Tween.TRANS_SINE
	)
