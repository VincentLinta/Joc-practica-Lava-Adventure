extends Area2D


# =============================================================
# CONFIGURARE
# =============================================================

var speed: float = 250.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 50

var blood_ball_audio: AudioStreamPlayer = null
var is_destroyed: bool = false


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# =========================================================
	# SCALE
	# =========================================================

	scale = Vector2(0.6, 0.6)


	# =========================================================
	# COLLISION
	# =========================================================

	monitoring = true
	monitorable = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


	# =========================================================
	# ANIMATION
	# =========================================================

	$AnimatedSprite2D.play("demon_blood_ball")


	# =========================================================
	# BLOOD BALL SOUND
	# =========================================================

	var blood_ball_stream := load(
		"res://sfx/blood_ball_sound.mp3"
	) as AudioStreamMP3

	if blood_ball_stream:

		# Facem o copie ca sa nu modificam resursa originala.
		blood_ball_stream = blood_ball_stream.duplicate()

		# Sunetul se repeta cat timp bila zboara.
		blood_ball_stream.loop = true

		blood_ball_audio = AudioStreamPlayer.new()

		blood_ball_audio.stream = blood_ball_stream
		blood_ball_audio.volume_db = 5.0
		blood_ball_audio.bus = "SFX"

		add_child(blood_ball_audio)

		blood_ball_audio.play()


	# =========================================================
	# TIMEOUT - 4 SECUNDE
	# =========================================================

	await get_tree().create_timer(4.0).timeout

	if is_destroyed:
		return

	_destroy_blood_ball()


# =============================================================
# MOVEMENT
# =============================================================

func _physics_process(delta: float) -> void:

	if is_destroyed:
		return

	# Folosim global_position ca proiectilul sa nu fie
	# influentat de miscarea boss-ului daca este copilul lui.
	global_position += direction * speed * delta


# =============================================================
# COLLISION
# =============================================================

func _on_body_entered(body: Node2D) -> void:

	if is_destroyed:
		return


	# =========================================================
	# PLAYER
	# =========================================================

	if body.is_in_group("player"):

		if body.has_method("take_damage"):

			body.take_damage(
				damage,
				"final_boss"
			)

		_destroy_blood_ball()
		return


	# =========================================================
	# PERETE / OBSTACOL
	# =========================================================

	if body is StaticBody2D \
	or body is TileMap \
	or body is TileMapLayer:

		_destroy_blood_ball()
		return


# =============================================================
# DESTROY PROJECTILE
# =============================================================

func _destroy_blood_ball() -> void:

	if is_destroyed:
		return

	is_destroyed = true

	# Oprim miscarea.
	set_physics_process(false)

	# Oprim sunetul.
	_stop_blood_ball_sound()

	# Stergem proiectilul.
	queue_free()


# =============================================================
# STOP SOUND
# =============================================================

func _stop_blood_ball_sound() -> void:

	if blood_ball_audio:

		blood_ball_audio.stop()
		blood_ball_audio.queue_free()

		blood_ball_audio = null
