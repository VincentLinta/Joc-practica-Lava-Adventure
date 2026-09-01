extends Area2D

@export var boost_duration: float = 5.0
@export var next_level: PackedScene

var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if activated:
		return

	if not body.is_in_group("player"):
		return

	activated = true

	if body.has_method("start_portal_boost"):
		body.start_portal_boost(boost_duration)

	# 1. Așteptăm până aproape de finalul animației/boost-ului.
	await get_tree().create_timer(
		max(0.1, boost_duration - 2.0)
	).timeout

	# 2. Cântă LevelEnd fix înainte de portal.
	_play_audio(
		"res://sfx/LevelEnd.mp3",
		4.0
	)

	# 3. Pauză de 1 secundă între LevelEnd și sunetul de teleportare.
	await get_tree().create_timer(1.0).timeout

	# 4. Pornește sunetul de portal.
	_play_portal_sound()

	# 5. Ultimele secunde de efect, apoi schimbarea de scenă.
	await get_tree().create_timer(1.0).timeout

	# ---------------------------------------------------------
	# BONUS HP & SALVARE PROGRES (COMPLETARE NIVEL)
	# ---------------------------------------------------------
	if is_instance_valid(body):
		if body.has_method("award_level_bonus"):
			body.call(
				"award_level_bonus",
				body.health,
				body.max_health
			)
		else:
			GameState.award_level_bonus(
				body.health,
				body.max_health
			)

	# SALVARE AUTOMATĂ ȘI ACTUALIZARE SCOR / HIGH SCORE
	GameState.complete_level()

	# ---------------------------------------------------------
	# TRANZIȚIE
	# ---------------------------------------------------------
	if next_level:
		GameState.pending_transition_level = GameState.current_level
		GameState.pending_next_level = next_level

		print("GOING TO TRANSITION")

		get_tree().change_scene_to_file(
			"res://LevelTransition.tscn"
		)


func _play_portal_sound() -> void:
	_play_audio(
		"res://sfx/portal-phase-jump.wav",
		16.0
	)


func _play_audio(
	path: String,
	volume_db: float = 0.0
) -> void:
	if not FileAccess.file_exists(path):
		print(
			"EROARE: SUNETUL NU EXISTA: ",
			path
		)
		return

	var stream = load(path)

	if stream:
		var asp := AudioStreamPlayer.new()

		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"

		get_tree().root.add_child(asp)

		asp.play()

		asp.finished.connect(
			asp.queue_free
		)
