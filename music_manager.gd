extends AudioStreamPlayer

@onready var pause_player: AudioStreamPlayer = $PausePlayer


func change_music(new_stream: AudioStream, custom_volume_db: float = 6):
	if pause_player and pause_player.playing:
		pause_player.stop()

	stream_paused = false
	volume_db = custom_volume_db

	if stream != new_stream or not playing:
		stream = new_stream
		play()


func pause_music():
	stream_paused = true
	if pause_player and not pause_player.playing:
		pause_player.play()


func resume_music():
	if pause_player:
		pause_player.stop()
	stream_paused = false
