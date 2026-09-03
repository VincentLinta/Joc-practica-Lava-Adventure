extends Area2D


# =============================================================
# STATE
# =============================================================

var activated: bool = false
var player_entered: bool = false
var win_screen_opened: bool = false


# =============================================================
# NEXT SCENE
# =============================================================

const NEXT_SCENE_PATH: String = "res://WinScreen.tscn"


# =============================================================
# NODES
# =============================================================

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# ---------------------------------------------------------
	# PORTAL INACTIV LA START
	# ---------------------------------------------------------

	activated = false
	player_entered = false
	win_screen_opened = false

	visible = false
	monitoring = false

	if collision_shape:
		collision_shape.set_deferred(
			"disabled",
			true
		)


	# ---------------------------------------------------------
	# DETECTARE PLAYER
	# ---------------------------------------------------------

	if not body_entered.is_connected(
		_on_body_entered
	):

		body_entered.connect(
			_on_body_entered
		)


	# ---------------------------------------------------------
	# GRUP FINAL PORTAL
	# ---------------------------------------------------------

	add_to_group(
		"final_portal"
	)


# =============================================================
# BODY ENTERED
# =============================================================

func _on_body_entered(body: Node) -> void:

	if not activated:
		return

	if player_entered:
		return

	if win_screen_opened:
		return

	if not is_instance_valid(body):
		return

	if not body.is_in_group("player"):
		return


	# ---------------------------------------------------------
	# PLAYER A INTRAT ÎN PORTAL
	# ---------------------------------------------------------

	player_entered = true

	print(
		"🔥 PLAYER A INTRAT ÎN FINAL PORTAL!"
	)


	_open_win_screen()


# =============================================================
# ACTIVATE
# =============================================================

func activate() -> void:

	if activated:
		return

	activated = true
	player_entered = false
	win_screen_opened = false


	# ---------------------------------------------------------
	# PORTAL DEVINE VIZIBIL
	# ---------------------------------------------------------

	visible = true
	monitoring = true


	# ---------------------------------------------------------
	# COLLISION ON
	# ---------------------------------------------------------

	if collision_shape:

		collision_shape.set_deferred(
			"disabled",
			false
		)


	print(
		"🌀 FINAL PORTAL ACTIVAT!"
	)


# =============================================================
# OPEN WIN SCREEN
# =============================================================

func _open_win_screen() -> void:

	if win_screen_opened:
		return

	win_screen_opened = true


	# =========================================================
	# 1 SECUNDĂ DUPĂ INTRAREA ÎN PORTAL
	# =========================================================

	print(
		"⏳ FINAL PORTAL SOUND ÎN 1 SECUNDĂ..."
	)

	await get_tree().create_timer(
		1.0
	).timeout


	if not is_inside_tree():
		return


	# =========================================================
	# FINAL PORTAL SOUND
	# =========================================================
	#
	# Se redă o singură dată.
	# finalportalsound.mp3 are Loop OFF în Import.
	# =========================================================

	if SFXManager.has_method(
		"play_ui_sound"
	):

		SFXManager.play_ui_sound(
			preload(
				"res://sfx/finalportalsound.mp3"
			)
		)

		print(
			"🌀 FINAL PORTAL SOUND!"
		)

	else:

		print(
			"❌ SFXManager NU ARE play_ui_sound()!"
		)


	# =========================================================
	# ÎNCĂ 1 SECUNDĂ
	# =========================================================
	#
	# PLAYER ENTER
	# -> 1 sec
	# -> PORTAL SOUND
	# -> 1 sec
	# -> WIN SCREEN
	# =========================================================

	await get_tree().create_timer(
		1.0
	).timeout


	# =========================================================
	# VERIFICARE
	# =========================================================

	if not is_inside_tree():
		return


	# =========================================================
	# RESET TIMP
	# =========================================================

	Engine.time_scale = 1.0


	# =========================================================
	# STOP SCREEN SHAKE
	# =========================================================

	if ScreenShake.has_method(
		"stop"
	):

		ScreenShake.stop()


	# =========================================================
	# TRANZIȚIE DIRECTĂ LA WIN SCREEN
	# =========================================================

	print(
		"🏆 MERGEM DIRECT LA WIN SCREEN!"
	)

	get_tree().change_scene_to_file(
		NEXT_SCENE_PATH
	)
