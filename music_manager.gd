extends AudioStreamPlayer


# =============================================================
# NODES
# =============================================================

@onready var pause_player: AudioStreamPlayer = $PausePlayer


# =============================================================
# VICTORY MUSIC
# =============================================================

const VICTORY_MUSIC_PATH: String = "res://VICTORYSONG.mp3"

var victory_music_active: bool = false
var victory_stream: AudioStreamMP3 = null


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	if not get_tree().scene_changed.is_connected(
		_on_scene_changed
	):
		get_tree().scene_changed.connect(
			_on_scene_changed
	)


# =============================================================
# NORMAL MUSIC
# =============================================================

func change_music(
	new_stream: AudioStream,
	custom_volume_db: float = 6
) -> void:

	if new_stream == null:
		return


	# ---------------------------------------------------------
	# DACĂ VICTORY MUSIC ESTE ACTIVĂ
	# ---------------------------------------------------------

	if victory_music_active:

		var current_scene := get_tree().current_scene

		if current_scene:

			var scene_path: String = (
				current_scene.scene_file_path
			)

			# -------------------------------------------------
			# WIN SCREEN / MAIN MENU
			#
			# Nu lăsăm muzica normală să înlocuiască
			# VICTORYSONG.
			# -------------------------------------------------

			if (
				scene_path == "res://WinScreen.tscn"
				or scene_path == "res://MainMenu.tscn"
			):

				return

			# -------------------------------------------------
			# ORICE ALTĂ SCENĂ
			#
			# Inclusiv Level 1-10.
			# -------------------------------------------------

			stop_victory_music()


	# =========================================================
	# MUZICA NORMALĂ EXISTENTĂ
	# =========================================================

	if pause_player and pause_player.playing:
		pause_player.stop()

	stream_paused = false

	volume_db = custom_volume_db

	if stream != new_stream or not playing:
		stream = new_stream
		play()


# =============================================================
# START VICTORY MUSIC
# =============================================================

func start_victory_music() -> void:

	if victory_music_active:
		return


	if not ResourceLoader.exists(
		VICTORY_MUSIC_PATH
	):
		print(
			"❌ NU EXISTĂ VICTORYSONG.mp3!"
		)
		return


	var loaded_stream = load(
		VICTORY_MUSIC_PATH
	)


	if loaded_stream == null:
		print(
			"❌ VICTORYSONG NU S-A PUTUT ÎNCĂRCA!"
		)
		return


	if loaded_stream is not AudioStreamMP3:
		print(
			"❌ VICTORYSONG.mp3 NU ESTE AudioStreamMP3!"
		)
		return


	victory_stream = loaded_stream
	victory_stream.loop = true


	# ---------------------------------------------------------
	# OPRIM PAUSE MUSIC
	# ---------------------------------------------------------

	if pause_player and pause_player.playing:
		pause_player.stop()


	# ---------------------------------------------------------
	# PORNIM VICTORY MUSIC
	# ---------------------------------------------------------

	stream_paused = false
	bus = "Music"
	volume_db = 6.0

	victory_music_active = true

	stream = victory_stream
	play()


	print(
		"🏆 VICTORY MUSIC PORNIT!"
	)


# =============================================================
# STOP VICTORY MUSIC
# =============================================================

func stop_victory_music() -> void:

	if not victory_music_active:
		return

	victory_music_active = false

	stop()

	victory_stream = null

	print(
		"🎵 VICTORY MUSIC OPRIT!"
	)


# =============================================================
# SCENE CHANGED
# =============================================================

func _on_scene_changed() -> void:

	if not victory_music_active:
		return

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	var scene_path: String = (
		current_scene.scene_file_path
	)


	# ---------------------------------------------------------
	# VICTORY MUSIC RĂMÂNE
	# ---------------------------------------------------------

	if (
		scene_path == "res://WinScreen.tscn"
		or scene_path == "res://MainMenu.tscn"
	):

		return


	# ---------------------------------------------------------
	# ORICE ALTĂ SCENĂ = STOP
	# ---------------------------------------------------------

	stop_victory_music()


# =============================================================
# PAUSE MUSIC
# =============================================================

func pause_music() -> void:

	stream_paused = true

	if pause_player and not pause_player.playing:
		pause_player.play()


# =============================================================
# RESUME MUSIC
# =============================================================

func resume_music() -> void:

	if pause_player:
		pause_player.stop()

	stream_paused = false
