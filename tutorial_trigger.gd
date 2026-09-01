extends Area2D

@export_multiline var tutorial_text := ""

# Bifează DOAR pentru tutorialul special din Level 8.
@export var special_level8: bool = false

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if triggered:
		return

	if body.name != "Player":
		return

	triggered = true
	set_deferred("monitoring", false)

	# Căutăm TutorialUI oriunde ar fi în scenă, indiferent cât de adânc e îngropat.
	var tutorial_ui = get_tree().current_scene.find_child("TutorialUI", true, false)

	if tutorial_ui == null:
		print("EROARE: TutorialUI nu a fost găsit în scena curentă!")
		return

	# Tutorialele normale rămân exact ca înainte.
	if special_level8:
		tutorial_ui.show_message(tutorial_text, true)
	else:
		tutorial_ui.show_message(tutorial_text, false)
