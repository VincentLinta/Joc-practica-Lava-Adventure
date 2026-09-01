extends Node


var panel: Panel
var label: Label

var waiting_for_input := false
var can_continue := false
var current_text := ""
var tutorial_open := false


# =========================================================
# LEVEL 8 SETTINGS
# =========================================================

@export var level8_font_size: int = 30
@export var level8_panel_size: Vector2 = Vector2(720, 300)


func _ready() -> void:
	# IMPORTANT:
	# TutorialUI funcționează și când jocul este paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ---------------------------------------------------------
	# Găsim Panel-ul copil al TutorialUI.
	#
	# Structura:
	#
	# TutorialUI
	# └── Panel
	#     └── Label
	# ---------------------------------------------------------

	panel = get_node_or_null("Panel") as Panel

	if panel == null:
		push_warning("TutorialUI.gd: Panel nu a fost găsit.")
		return

	label = panel.get_node_or_null("Label") as Label

	if label == null:
		push_warning("TutorialUI.gd: Panel/Label nu a fost găsit.")
		panel = null
		return

	# Textul este mereu centrat.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Tutorialul este ascuns la început.
	panel.hide()

	tutorial_open = false
	waiting_for_input = false
	can_continue = false


# =========================================================
# SHOW TUTORIAL
# =========================================================

func show_message(text: String, special_level8: bool = false) -> void:
	if panel == null or label == null:
		return

	# Nu permitem două tutoriale simultan.
	if tutorial_open:
		return

	tutorial_open = true
	waiting_for_input = false
	can_continue = false

	current_text = text


	# =========================================================
	# RESETĂM STILUL
	# =========================================================

	label.remove_theme_font_size_override("font_size")
	label.remove_theme_color_override("font_color")

	panel.remove_theme_stylebox_override("panel")

	panel.custom_minimum_size = Vector2.ZERO


	# =========================================================
	# LEVEL 8 SPECIAL STYLE
	# =========================================================

	if special_level8:

		# Text mai mare.
		label.add_theme_font_size_override(
			"font_size",
			level8_font_size
		)

		# Text alb.
		label.add_theme_color_override(
			"font_color",
			Color("#FFFFFF")
		)

		# Text centrat.
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


		# -----------------------------------------------------
		# PANEL LEVEL 8
		# Albastru + margine galbenă.
		# -----------------------------------------------------

		var level8_style := StyleBoxFlat.new()

		level8_style.bg_color = Color("#102A43", 0.95)

		level8_style.border_color = Color("#FFD43B")
		level8_style.set_border_width_all(3)

		level8_style.corner_radius_top_left = 12
		level8_style.corner_radius_top_right = 12
		level8_style.corner_radius_bottom_left = 12
		level8_style.corner_radius_bottom_right = 12

		level8_style.content_margin_left = 35.0
		level8_style.content_margin_right = 35.0
		level8_style.content_margin_top = 25.0
		level8_style.content_margin_bottom = 25.0

		panel.add_theme_stylebox_override(
			"panel",
			level8_style
		)

		# Panel mai mare pentru Level 8.
		panel.custom_minimum_size = level8_panel_size


	# =========================================================
	# AFIȘĂM TUTORIALUL
	# =========================================================

	label.text = current_text + "\n\nPlease read..."

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.90, 0.90)

	panel.show()

	await get_tree().process_frame


	# =========================================================
	# ANIMAȚIE DE APARIȚIE
	# =========================================================

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.45
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished


	# =========================================================
	# AȘTEPTĂM ÎNAINTE DE A PERMITE ÎNCHIDEREA
	# =========================================================

	waiting_for_input = true
	can_continue = false

	await get_tree().create_timer(2.0).timeout

	# Dacă tutorialul a fost deja închis, nu mai continuăm.
	if not tutorial_open:
		return

	can_continue = true

	label.text = current_text + "\n\nPress any key to continue..."


# =========================================================
# INPUT PENTRU ÎNCHIDEREA TUTORIALULUI
# =========================================================
#
# FOARTE IMPORTANT:
#
# NU folosim _unhandled_input().
#
# ESC este verificat PRIMUL și este ignorat complet.
#
# TutorialUI NU apelează niciodată:
#
#     set_input_as_handled()
#
# pentru ESC.
#
# Astfel, sistemul principal al jocului poate primi ESC.
# =========================================================

func _input(event: InputEvent) -> void:

	# =====================================================
	# ESC = NU ESTE TREABA TUTORIALULUI
	# =====================================================

	if event.is_action_pressed("ui_cancel"):
		return


	# =====================================================
	# Dacă tutorialul nu este deschis, ieșim.
	# =====================================================

	if not tutorial_open:
		return

	if not waiting_for_input:
		return

	if not can_continue:
		return


	# =====================================================
	# INPUT VALID PENTRU ÎNCHIDEREA TUTORIALULUI
	# =====================================================

	var valid_input := false

	if event is InputEventKey:
		if event.pressed:
			valid_input = true

	elif event is InputEventMouseButton:
		if event.pressed:
			valid_input = true


	if not valid_input:
		return


	# =====================================================
	# ÎNCHIDEM TUTORIALUL
	# =====================================================

	close_tutorial()


# =========================================================
# CLOSE TUTORIAL
# =========================================================

func close_tutorial() -> void:

	if not tutorial_open:
		return

	tutorial_open = false
	waiting_for_input = false
	can_continue = false


	# =====================================================
	# ANIMAȚIE DE DISPARIȚIE
	# =====================================================

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.30
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	tween.tween_property(
		panel,
		"scale",
		Vector2(0.90, 0.90),
		0.30
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	await tween.finished

	panel.hide()


	# =====================================================
	# Consumăm DOAR input-ul care a închis tutorialul.
	#
	# ESC NU AJUNGE NICIODATĂ AICI.
	# =====================================================

	get_viewport().set_input_as_handled()
