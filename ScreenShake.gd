extends Node


var camera: Camera2D = null

var shake_strength: float = 0.0
var shake_decay: float = 10.0

var original_offset: Vector2 = Vector2.ZERO


# =============================================================
# TIMED SHAKE
# =============================================================
#
# -1.0 = shake normal, bazat doar pe decay
# > 0  = shake cu durată controlată
#
# IMPORTANT:
# Shake-urile vechi din Player.gd nu vor anula un shake
# temporizat al Final Boss-ului.
# =============================================================

var shake_duration: float = -1.0
var shake_time_left: float = 0.0


# =============================================================
# PROCESS
# =============================================================

func _process(delta: float) -> void:

	# =========================================================
	# GĂSEȘTE CAMERA
	# =========================================================

	if camera == null or not is_instance_valid(camera):

		camera = get_viewport().get_camera_2d()

		if camera != null:
			original_offset = camera.offset


	if camera == null:
		return


	# =========================================================
	# SHAKE ACTIV
	# =========================================================

	if shake_strength > 0.1:

		# =====================================================
		# TIMED SHAKE
		# =====================================================

		if shake_time_left > 0.0:

			shake_time_left -= delta

			if shake_time_left <= 0.0:

				shake_strength = 0.0
				shake_time_left = 0.0
				shake_duration = -1.0

				camera.offset = original_offset

				return


		# =====================================================
		# DECAY
		# =====================================================

		var decay_amount := shake_decay * delta

		decay_amount = clamp(
			decay_amount,
			0.0,
			1.0
		)

		shake_strength = lerp(
			shake_strength,
			0.0,
			decay_amount
		)


		# =====================================================
		# RANDOM CAMERA OFFSET
		# =====================================================

		camera.offset = (
			original_offset
			+ Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			) * shake_strength
		)


	# =========================================================
	# SHAKE TERMINAT
	# =========================================================

	else:

		shake_strength = 0.0
		shake_time_left = 0.0
		shake_duration = -1.0

		camera.offset = original_offset


# =============================================================
# SHAKE
# =============================================================
#
# amount   = intensitatea shake-ului
# decay    = cât de repede se stinge
# duration = durata maximă
#
# Exemple vechi:
# ScreenShake.shake(3.0, 15.0)
#
# Exemplu Final Boss:
# ScreenShake.shake(25.0, 3.0, 2.0)
# =============================================================

func shake(
	amount: float,
	decay: float = 10.0,
	duration: float = -1.0
) -> void:

	# =========================================================
	# CAMERA
	# =========================================================

	if camera == null or not is_instance_valid(camera):

		camera = get_viewport().get_camera_2d()

		if camera != null:
			original_offset = camera.offset


	if camera == null:
		return


	# =========================================================
	# EXISTĂ DEJA UN SHAKE TEMPORIZAT?
	# =========================================================

	var timed_shake_active := shake_time_left > 0.0


	# =========================================================
	# INTENSITATE
	# =========================================================
	#
	# Păstrăm întotdeauna cea mai mare intensitate.
	# =========================================================

	if amount > shake_strength:

		shake_strength = amount

		# Dacă NU avem deja un shake temporizat mai important,
		# putem actualiza decay-ul.
		if not timed_shake_active:
			shake_decay = decay


	# =========================================================
	# DECAY PENTRU SHAKE NOU
	# =========================================================

	# Dacă nu avem un shake temporizat activ,
	# folosim decay-ul primit normal.
	if not timed_shake_active:

		shake_decay = decay


	# =========================================================
	# DURATION
	# =========================================================
	#
	# duration > 0:
	# -> pornim / prelungim un shake temporizat.
	#
	# duration <= 0:
	# -> NU anulăm un shake temporizat deja activ.
	# =========================================================

	if duration > 0.0:

		shake_duration = duration

		shake_time_left = max(
			shake_time_left,
			duration
		)


# =============================================================
# STOP
# =============================================================

func stop() -> void:

	shake_strength = 0.0
	shake_duration = -1.0
	shake_time_left = 0.0


	if camera == null or not is_instance_valid(camera):

		camera = get_viewport().get_camera_2d()


	if camera != null and is_instance_valid(camera):

		camera.offset = original_offset
