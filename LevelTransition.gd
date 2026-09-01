extends CanvasLayer

@onready var complete_label: Label = $Label
@onready var loading_label: Label = $Label2
@onready var score_label: Control = get_node_or_null("ScoreLabel")

var dots_tween_running := true

func _ready() -> void:
	print("TRANSITION OPENED")
	var completed: int = GameState.pending_transition_level
	complete_label.text = "LEVEL %d COMPLETE" % completed
	
	var level_high: int = GameState.get_current_level_high_score()
	var is_record: bool = GameState.is_new_level_record
	
	if score_label:
		if score_label is RichTextLabel:
			var rtl := score_label as RichTextLabel
			rtl.bbcode_enabled = true
			
			var high_color := "#FFD700" if is_record else "#FF7700"
			var new_badge := " [pulse freq=2.5 color=#FFD700]★ NEW RECORD![/pulse]" if is_record else ""
			
			var score_diff = GameState.get_level_score_delta()
			var total_bonus_str = " [color=#00FFAA](+%d)[/color]" % score_diff if score_diff > 0 else ""
			
			# Ordinea fixă cerută:
			# 1. LEVEL SCORE (sus)
			# 2. HIGH SCORE specific nivelului curent (mijloc - ex: 1500)
			# 3. TOTAL SCORE din tot run-ul adunat (jos - ex: 2700 +1500)
			rtl.text = "[center]" \
				+ "[color=#FFAA00][font_size=22]LEVEL SCORE: %d[/font_size][/color]\n" % GameState.score \
				+ "[pulse freq=2.0 color=#FFD700][color=%s][font_size=22]HIGH SCORE: %d[/font_size][/color][/pulse]%s\n" % [high_color, level_high, new_badge] \
				+ "[color=#00FF99][font_size=24][b]TOTAL SCORE: %d%s[/b][/font_size][/color]" % [GameState.total_score, total_bonus_str] \
				+ "[/center]"
		elif score_label is Label:
			var lbl := score_label as Label
			lbl.text = "LEVEL SCORE: %d\nHIGH SCORE: %d\nTOTAL SCORE: %d" % [
				GameState.score,
				level_high,
				GameState.total_score
			]
	
	var next_text := "Loading Level %d" % (completed + 1)
	loading_label.text = next_text
	
	complete_label.scale = Vector2(0.5, 0.5)
	complete_label.pivot_offset = complete_label.size / 2.0
	var pop_tween := create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK)
	pop_tween.set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(complete_label, "scale", Vector2(1.0, 1.0), 0.3)
	
	_animate_dots(next_text)
	
	await get_tree().create_timer(3.0).timeout
	dots_tween_running = false
	
	if GameState.pending_next_level:
		GameState.current_level = GameState.pending_transition_level + 1
		GameState.score = 0
		get_tree().change_scene_to_packed(GameState.pending_next_level)

func _animate_dots(base_text: String) -> void:
	var dot_count := 0
	while dots_tween_running:
		if loading_label:
			loading_label.text = base_text + ".".repeat(dot_count)
		dot_count = (dot_count + 1) % 4
		await get_tree().create_timer(0.4).timeout
