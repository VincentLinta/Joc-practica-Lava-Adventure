extends CanvasLayer

@onready var timer_label: Label = get_node_or_null("TimerLabel")
@onready var score_label: Label = get_node_or_null("ScoreLabel")

# Referințe pentru caseta de Level
@onready var panel: PanelContainer = get_node_or_null("PanelContainer")
@onready var level_label: RichTextLabel = get_node_or_null("PanelContainer/LevelLabel") as RichTextLabel

var level_time: float = 0.0
var _regex := RegEx.new() # Instanțiat o singură dată pentru performanță


func _ready() -> void:
	level_time = 0.0
	var _err := _regex.compile("\\d+") # Fix pentru avertismentul din Debugger
	_setup_styles()
	_setup_layout()
	_update_level_text()


func _setup_styles() -> void:
	# 1. Stil Panel Level (Dark Glass cu bordură aurie)
	if panel:
		var level_style := StyleBoxFlat.new()
		level_style.bg_color = Color(0.08, 0.09, 0.13, 0.85)
		level_style.border_color = Color(1.0, 0.78, 0.18, 0.9)
		level_style.set_border_width_all(2)
		level_style.set_corner_radius_all(8)
		level_style.content_margin_left = 16
		level_style.content_margin_right = 16
		level_style.content_margin_top = 6
		level_style.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", level_style)

	# 2. Stil Timer Box (Dark Glass cu bordură Cyan Neon)
	if timer_label:
		var timer_style := StyleBoxFlat.new()
		timer_style.bg_color = Color(0.08, 0.09, 0.13, 0.85)
		timer_style.border_color = Color(0.0, 0.85, 1.0, 0.8)
		timer_style.set_border_width_all(2)
		timer_style.set_corner_radius_all(8)
		timer_style.content_margin_left = 14
		timer_style.content_margin_right = 14
		timer_style.content_margin_top = 6
		timer_style.content_margin_bottom = 6
		timer_label.add_theme_stylebox_override("normal", timer_style)

	# 3. Stil Score Box (Dark Glass cu bordură Emerald Green)
	if score_label:
		var score_style := StyleBoxFlat.new()
		score_style.bg_color = Color(0.08, 0.09, 0.13, 0.85)
		score_style.border_color = Color(0.2, 0.9, 0.4, 0.8)
		score_style.set_border_width_all(2)
		score_style.set_corner_radius_all(8)
		score_style.content_margin_left = 16
		score_style.content_margin_right = 16
		score_style.content_margin_top = 6
		score_style.content_margin_bottom = 6
		score_label.add_theme_stylebox_override("normal", score_style)


func _setup_layout() -> void:
	# Pozitionare si dimensiune font Timer
	if timer_label:
		timer_label.position = Vector2(25, 20)
		timer_label.add_theme_font_size_override("font_size", 16)

	# Pozitionare Level Panel
	if panel:
		panel.custom_minimum_size = Vector2(160, 44)
		panel.anchors_preset = Control.PRESET_CENTER_TOP
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		
		var viewport_width := get_viewport().get_visible_rect().size.x
		panel.position.x = (viewport_width - panel.size.x) / 2.0
		panel.position.y = 65

	# Pozitionare si dimensiune font Score
	if score_label:
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.anchors_preset = Control.PRESET_TOP_RIGHT
		score_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		score_label.offset_right = -25
		score_label.offset_left = -175
		score_label.offset_top = 20
		score_label.offset_bottom = 56
		score_label.add_theme_font_size_override("font_size", 16)


func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	var is_in_game := not players.is_empty()

	visible = is_in_game

	if is_in_game:
		level_time += delta
		_update_timer_text()
		_update_score_text()
		_update_level_text()


func _update_timer_text() -> void:
	if timer_label:
		@warning_ignore("integer_division")
		var minutes := int(level_time) / 60
		var seconds := int(level_time) % 60
		timer_label.text = "TIME %02d:%02d" % [minutes, seconds]


func _update_level_text() -> void:
	if level_label == null:
		return

	var level_num_str := "1"

	if "current_level" in GameState and GameState.current_level != 0:
		level_num_str = str(GameState.current_level)
	elif get_tree().current_scene != null:
		var current_scene := get_tree().current_scene
		var scene_identifier := current_scene.scene_file_path + " " + current_scene.name
		
		var match_res := _regex.search(scene_identifier)
		if match_res:
			level_num_str = match_res.get_string()

	level_label.bbcode_enabled = true
	level_label.fit_content = true
	level_label.scroll_active = false
	level_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Text "LEVEL" mărit la font 18 cu Cyan (#00E5FF) și cifră boldată auriu (#FFCC00)
	level_label.text = "[center][font_size=18][b][color=#00e5ff]LEVEL[/color][/b][/font_size]  [font_size=22][b][color=#ffcc00]%s[/color][/b][/font_size][/center]" % level_num_str


func _update_score_text() -> void:
	if score_label:
		if "score" in GameState:
			score_label.text = "SCORE %d" % GameState.score
		elif "coins" in GameState:
			score_label.text = "COINS %d" % GameState.coins
		else:
			score_label.text = "SCORE 0"
