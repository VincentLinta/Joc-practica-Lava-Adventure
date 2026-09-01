extends Node

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Player dedicat pentru sunetul continuu de slider (cărămizile)
var slider_player: AudioStreamPlayer = null

# Preîncărcăm sunetul de slider din folderul tău
var slider_sound = preload("res://sfx/slider_medieval.mp3")

func _ready() -> void:
	sfx_player.bus = "SFX"
	# Prinde orice AudioStreamPlayer nou apărut oriunde în joc (Player, Enemy, Lava, etc.)
	# și îl trece automat pe bus-ul SFX, fără să mai umblăm prin fiecare script de gameplay.
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if not (node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D):
		return

	# Nu atingem playerul/playerele folosite de MusicManager pentru muzica de fundal
	if MusicManager and MusicManager.is_ancestor_of(node):
		return

	node.bus = "SFX"


# Funcția ta originală pentru sunete rapide / gameplay
func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	sfx_player.stream = sound
	sfx_player.play()

# Funcție pentru sunete UI care se pot suprapune (click, hover, etc.)
func play_ui_sound(sound: AudioStream) -> void:
	if sound == null:
		return
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = sound
	temp_player.bus = "SFX"
	add_child(temp_player)
	temp_player.play()
	temp_player.finished.connect(temp_player.queue_free)

# --- CONTROLOARE PENTRU SLIDER (CĂRĂMIZI) ---
func start_slider_sound() -> void:
	if slider_player != null and slider_player.playing:
		return
	
	slider_player = AudioStreamPlayer.new()
	slider_player.stream = slider_sound
	slider_player.bus = "SFX"
	add_child(slider_player)
	slider_player.play()

func stop_slider_sound() -> void:
	if slider_player != null and slider_player.playing:
		slider_player.stop()
		slider_player.queue_free()
		slider_player = null
