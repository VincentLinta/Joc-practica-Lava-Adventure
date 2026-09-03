extends Area2D


# =============================================================
# PORTAL SETTINGS
# =============================================================

@export var boost_duration: float = 5.0
@export var next_level: PackedScene


# =============================================================
# STATE
# =============================================================

var activated: bool = false


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	body_entered.connect(
		_on_body_entered
	)


# =============================================================
# BODY ENTERED
# =============================================================

func _on_body_entered(body: Node) -> void:

	if activated:
		return

	if not body.is_in_group("player"):
		return

	activated = true


	# =========================================================
	# PORTAL BOOST
	# =========================================================

	if body.has_method("start_portal_boost"):

		body.start_portal_boost(
			boost_duration
		)


	# =========================================================
	# LEVEL END SOUND
	# =========================================================

	await get_tree().create_timer(
		max(
			0.1,
			boost_duration - 2.0
		)
	).timeout


	_play_audio(
		"res://sfx/LevelEnd.mp3",
		4.0
	)


	# =========================================================
	# PORTAL SOUND
	# =========================================================

	await get_tree().create_timer(
		1.0
	).timeout

	_play_portal_sound()


	# =========================================================
	# WAIT
	# =========================================================

	await get_tree().create_timer(
		1.0
	).timeout


	# =========================================================
	# LEVEL BONUS
	# =========================================================

	if is_instance_valid(body):

		if body.has_method(
			"award_level_bonus"
		):

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


	# =========================================================
	# COMPLETE LEVEL
	# =========================================================

	GameState.complete_level()


	# =========================================================
	# LEVEL TRANSITION
	# =========================================================

	if next_level:

		GameState.pending_transition_level = (
			GameState.current_level
		)

		GameState.pending_next_level = next_level

		print(
			"GOING TO TRANSITION"
		)

		get_tree().change_scene_to_file(
			"res://LevelTransition.tscn"
		)


# =============================================================
# PORTAL SOUND
# =============================================================

func _play_portal_sound() -> void:

	var path := "res://sfx/portal-phase-jump.wav"

	if not ResourceLoader.exists(path):

		print(
			"EROARE: Nu exista portal-phase-jump.wav"
		)

		return

	var stream = load(path)

	if stream:

		var asp := AudioStreamPlayer.new()

		asp.stream = stream
		asp.volume_db = 6.0
		asp.bus = "SFX"

		get_tree().root.add_child(
			asp
		)

		asp.play()

		asp.finished.connect(
			asp.queue_free
		)


# =============================================================
# GENERIC AUDIO
# =============================================================

func _play_audio(
	path: String,
	volume_db: float = 0.0
) -> void:

	if not ResourceLoader.exists(path):

		print(
			"EROARE PORTAL SFX: Nu exista: ",
			path
		)

		return

	var stream = load(path)

	if stream:

		var asp := AudioStreamPlayer.new()

		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "SFX"

		get_tree().root.add_child(
			asp
		)

		asp.play()

		asp.finished.connect(
			asp.queue_free
		)
