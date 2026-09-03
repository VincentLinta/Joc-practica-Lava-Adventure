extends Control


# =============================================================
# NODES
# =============================================================

@onready var color_rect: ColorRect = $ColorRect
@onready var win_title: Label = $WinTitle
@onready var subtitle: Label = $Subtitle
@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel

@onready var play_again_button: Button = $PlayAgainButton
@onready var main_menu_button: Button = $MainMenuButton


# =============================================================
# STATE
# =============================================================

var is_open: bool = false
var transition_started: bool = false


# =============================================================
# VIRTUAL DESIGN SIZE
# =============================================================

const DESIGN_SIZE: Vector2 = Vector2(
	1152.0,
	648.0
)


# =============================================================
# ORIGINAL ELEMENT SIZES
# =============================================================

const TITLE_SIZE: Vector2 = Vector2(
	318.0,
	99.0
)

const SUBTITLE_SIZE: Vector2 = Vector2(
	700.0,
	140.0
)

const SCORE_SIZE: Vector2 = Vector2(
	500.0,
	50.0
)

const HIGH_SCORE_SIZE: Vector2 = Vector2(
	500.0,
	50.0
)

const BUTTON_SIZE: Vector2 = Vector2(
	300.0,
	80.0
)


# =============================================================
# ORIGINAL ELEMENT POSITIONS
# =============================================================

const TITLE_POSITION: Vector2 = Vector2(
	417.0,
	70.0
)

const SUBTITLE_POSITION: Vector2 = Vector2(
	226.0,
	140.0
)

const SCORE_POSITION: Vector2 = Vector2(
	326.0,
	315.0
)

const HIGH_SCORE_POSITION: Vector2 = Vector2(
	326.0,
	365.0
)


# =============================================================
# BUTTON LAYOUT
# =============================================================

const BUTTON_GAP: float = 100.0

const MAIN_MENU_BUTTON_POSITION: Vector2 = Vector2(
	180.0,
	500.0
)

const PLAY_AGAIN_BUTTON_POSITION: Vector2 = Vector2(
	680.0,
	500.0
)


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# ---------------------------------------------------------
	# FUNCȚIONEAZĂ CHIAR DACĂ JOCUL AR FI PAUZAT
	# ---------------------------------------------------------

	process_mode = Node.PROCESS_MODE_ALWAYS

	# ---------------------------------------------------------
	# ROOT FULL SCREEN
	# ---------------------------------------------------------

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# ---------------------------------------------------------
	# VIZIBIL IMEDIAT
	# ---------------------------------------------------------

	visible = true
	modulate = Color.WHITE

	# ---------------------------------------------------------
	# INPUT
	# ---------------------------------------------------------

	mouse_filter = Control.MOUSE_FILTER_STOP

	# ---------------------------------------------------------
	# BUTOANE
	# ---------------------------------------------------------

	if play_again_button:
		play_again_button.disabled = false

	if main_menu_button:
		main_menu_button.disabled = false


	# ---------------------------------------------------------
	# CONECTARE BUTOANE
	# ---------------------------------------------------------

	if (
		play_again_button
		and not play_again_button.pressed.is_connected(
			_on_play_again_pressed
		)
	):

		play_again_button.pressed.connect(
			_on_play_again_pressed
		)


	if (
		main_menu_button
		and not main_menu_button.pressed.is_connected(
			_on_main_menu_pressed
		)
	):

		main_menu_button.pressed.connect(
			_on_main_menu_pressed
		)


	# ---------------------------------------------------------
	# RESPONSIVE LAYOUT
	# ---------------------------------------------------------

	_update_responsive_layout()


	if not get_viewport().size_changed.is_connected(
		_update_responsive_layout
	):

		get_viewport().size_changed.connect(
			_update_responsive_layout
	)


	# ---------------------------------------------------------
	# SCORURI
	# ---------------------------------------------------------

	_update_score_labels()


	# ---------------------------------------------------------
	# DESCHIDEM WIN SCREEN
	# ---------------------------------------------------------

	show_win_screen()


# =============================================================
# RESPONSIVE LAYOUT
# =============================================================

func _update_responsive_layout() -> void:

	if not is_inside_tree():
		return

	var viewport_size: Vector2 = (
		get_viewport_rect().size
	)

	if viewport_size.x <= 0.0:
		return

	if viewport_size.y <= 0.0:
		return


	# =========================================================
	# SCALE UNIFORM
	# =========================================================

	var scale_x: float = (
		viewport_size.x
		/ DESIGN_SIZE.x
	)

	var scale_y: float = (
		viewport_size.y
		/ DESIGN_SIZE.y
	)

	var ui_scale: float = min(
		scale_x,
		scale_y
	)


	# =========================================================
	# SCALED DESIGN SIZE
	# =========================================================

	var scaled_design_size: Vector2 = (
		DESIGN_SIZE
		* ui_scale
	)


	# =========================================================
	# CENTER DESIGN
	# =========================================================

	var design_offset: Vector2 = (
		viewport_size
		- scaled_design_size
	) * 0.5


	# =========================================================
	# COLOR RECT
	# =========================================================

	if color_rect:

		color_rect.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		color_rect.position = Vector2.ZERO
		color_rect.size = viewport_size
		color_rect.scale = Vector2.ONE


	# =========================================================
	# WIN TITLE
	# =========================================================

	if win_title:

		win_title.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		win_title.size = TITLE_SIZE

		win_title.scale = Vector2(
			ui_scale,
			ui_scale
		)

		win_title.position = (
			design_offset
			+ (
				TITLE_POSITION
				* ui_scale
			)
		)


	# =========================================================
	# SUBTITLE
	# =========================================================

	if subtitle:

		subtitle.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		subtitle.size = SUBTITLE_SIZE

		subtitle.scale = Vector2(
			ui_scale,
			ui_scale
		)

		subtitle.position = (
			design_offset
			+ (
				SUBTITLE_POSITION
				* ui_scale
			)
		)


	# =========================================================
	# SCORE
	# =========================================================

	if score_label:

		score_label.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		score_label.size = SCORE_SIZE

		score_label.scale = Vector2(
			ui_scale,
			ui_scale
		)

		score_label.position = (
			design_offset
			+ (
				SCORE_POSITION
				* ui_scale
			)
		)


	# =========================================================
	# HIGH SCORE
	# =========================================================

	if high_score_label:

		high_score_label.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		high_score_label.size = HIGH_SCORE_SIZE

		high_score_label.scale = Vector2(
			ui_scale,
			ui_scale
		)

		high_score_label.position = (
			design_offset
			+ (
				HIGH_SCORE_POSITION
				* ui_scale
			)
		)


	# =========================================================
	# MAIN MENU BUTTON
	# =========================================================

	if main_menu_button:

		main_menu_button.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		main_menu_button.size = BUTTON_SIZE

		main_menu_button.scale = Vector2(
			ui_scale,
			ui_scale
		)

		main_menu_button.position = (
			design_offset
			+ (
				MAIN_MENU_BUTTON_POSITION
				* ui_scale
			)
		)


	# =========================================================
	# PLAY AGAIN BUTTON
	# =========================================================

	if play_again_button:

		play_again_button.set_anchors_and_offsets_preset(
			Control.PRESET_TOP_LEFT
		)

		play_again_button.size = BUTTON_SIZE

		play_again_button.scale = Vector2(
			ui_scale,
			ui_scale
		)

		play_again_button.position = (
			design_offset
			+ (
				PLAY_AGAIN_BUTTON_POSITION
				* ui_scale
			)
		)


# =============================================================
# SHOW WIN SCREEN
# =============================================================

func show_win_screen() -> void:

	if is_open:
		return

	is_open = true


	# ---------------------------------------------------------
	# RESET TIME SCALE
	# ---------------------------------------------------------

	Engine.time_scale = 1.0


	# ---------------------------------------------------------
	# PORNIM VICTORY MUSIC
	# ---------------------------------------------------------

	if MusicManager.has_method(
		"start_victory_music"
	):

		MusicManager.start_victory_music()


	# ---------------------------------------------------------
	# SALVĂM LEVEL 10
	# ---------------------------------------------------------

	_save_level_10_result()


	# ---------------------------------------------------------
	# SCORURI
	# ---------------------------------------------------------

	_update_score_labels()


	# ---------------------------------------------------------
	# VIZIBIL INSTANT
	# ---------------------------------------------------------

	visible = true
	modulate = Color.WHITE


	# ---------------------------------------------------------
	# BUTOANE
	# ---------------------------------------------------------

	if play_again_button:
		play_again_button.disabled = false

	if main_menu_button:
		main_menu_button.disabled = false


	# ---------------------------------------------------------
	# FOCUS PE PLAY AGAIN
	# ---------------------------------------------------------

	if play_again_button:
		play_again_button.grab_focus()


	print(
		"🏆 WIN SCREEN AFIȘAT!"
	)


# =============================================================
# SCORE LABELS
# =============================================================

func _update_score_labels() -> void:

	if score_label:

		score_label.text = (
			"SCORE: %d"
			% GameState.score
		)

	if high_score_label:

		high_score_label.text = (
			"HIGH SCORE: %d"
			% GameState.high_score
		)


# =============================================================
# LEVEL 10 SAVE
# =============================================================

func _save_level_10_result() -> void:

	if GameState.current_level != 10:
		return

	var current_run_score: int = GameState.score

	var previous_best: int = (
		GameState.get_current_level_high_score()
	)


	# ---------------------------------------------------------
	# RECORD NOU
	# ---------------------------------------------------------

	if current_run_score > previous_best:

		GameState.level_high_scores[10] = (
			current_run_score
		)

		GameState.level_scores[10] = (
			current_run_score
		)

		GameState.last_level_delta = (
			current_run_score
			- previous_best
		)

		GameState.is_new_level_record = true

	else:

		GameState.level_scores[10] = (
			previous_best
		)

		GameState.last_level_delta = 0
		GameState.is_new_level_record = false


	# ---------------------------------------------------------
	# TOTAL SCORE
	# ---------------------------------------------------------

	GameState.recalculate_total_score()

	GameState.high_score = (
		GameState.total_score
	)


	# ---------------------------------------------------------
	# SALVARE
	# ---------------------------------------------------------

	GameState.save_progress()


	print(
		"🏆 LEVEL 10 FINALIZAT!"
	)

	print(
		"🏆 SCORE: ",
		GameState.score
	)

	print(
		"🏆 LEVEL 10 BEST: ",
		GameState.get_current_level_high_score()
	)

	print(
		"🏆 GLOBAL HIGH SCORE: ",
		GameState.high_score
	)

	print(
		"🏆 UNLOCKED LEVEL: ",
		GameState.unlocked_level
	)


# =============================================================
# PLAY AGAIN
# =============================================================

func _on_play_again_pressed() -> void:

	if transition_started:
		return

	transition_started = true


	# ---------------------------------------------------------
	# RESETĂM TOT CE POATE AFECTA RESTARTUL
	# ---------------------------------------------------------

	get_tree().paused = false

	Engine.time_scale = 1.0


	if ScreenShake.has_method("stop"):
		ScreenShake.stop()


	# ---------------------------------------------------------
	# PLAY AGAIN = LEVEL 1
	# ---------------------------------------------------------

	GameState.start_level(1)


# =============================================================
# MAIN MENU
# =============================================================

func _on_main_menu_pressed() -> void:

	if transition_started:
		return

	transition_started = true


	# ---------------------------------------------------------
	# RESET
	# ---------------------------------------------------------

	get_tree().paused = false

	Engine.time_scale = 1.0


	if ScreenShake.has_method("stop"):
		ScreenShake.stop()


	# ---------------------------------------------------------
	# MAIN MENU
	# ---------------------------------------------------------

	get_tree().change_scene_to_file(
		"res://MainMenu.tscn"
	)
