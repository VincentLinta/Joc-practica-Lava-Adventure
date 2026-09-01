extends Area2D

@export var speed_multiplier: float = 0.5

# Distanțe pentru volumul ambiental
@export var ambient_start_distance: float = 600.0
@export var ambient_max_distance: float = 50.0

# Volum maxim (dB) pentru ambient (mărit)
@export var ambient1_max_vol_db: float = 6.0
@export var ambient2_max_vol_db: float = 3.0

var player: CharacterBody2D = null
var player_inside: CharacterBody2D = null

var ambient1_audio: AudioStreamPlayer
var ambient2_audio: AudioStreamPlayer
var walk_audio: AudioStreamPlayer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_audio()


func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if player != null and is_instance_valid(player):
		_update_ambient_audio()

	_update_walk_audio()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = body as CharacterBody2D

		if body.has_method("set_water_slow"):
			body.set_water_slow(speed_multiplier)

		_play_splash_sound("res://sfx/water_splash.mp3", 5.0)


func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		if player_inside.has_method("set_water_slow"):
			player_inside.set_water_slow(1.0)
		player_inside = null


func _setup_audio() -> void:
	# Ambient 1
	var amb1_stream = load("res://sfx/water_ambient1.mp3")
	if amb1_stream:
		ambient1_audio = AudioStreamPlayer.new()
		ambient1_audio.stream = amb1_stream
		ambient1_audio.bus = "Master"
		ambient1_audio.volume_db = -80.0
		add_child(ambient1_audio)
		_make_audio_loop(amb1_stream)

	# Ambient 2
	var amb2_stream = load("res://sfx/water_ambient2.mp3")
	if amb2_stream:
		ambient2_audio = AudioStreamPlayer.new()
		ambient2_audio.stream = amb2_stream
		ambient2_audio.bus = "Master"
		ambient2_audio.volume_db = -80.0
		add_child(ambient2_audio)
		_make_audio_loop(amb2_stream)

	# Mers prin apă
	var walk_stream = load("res://sfx/walking_in_water.mp3")
	if walk_stream:
		walk_audio = AudioStreamPlayer.new()
		walk_audio.stream = walk_stream
		walk_audio.bus = "Master"
		walk_audio.volume_db = 12.0
		add_child(walk_audio)
		_make_audio_loop(walk_stream)


func _make_audio_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif "loop" in stream:
		stream.set("loop", true)


func _update_ambient_audio() -> void:
	var distance := _get_distance_to_player()

	var target_vol1 := _calculate_volume(distance, ambient1_max_vol_db)
	var target_vol2 := _calculate_volume(distance, ambient2_max_vol_db)

	if ambient1_audio:
		ambient1_audio.volume_db = target_vol1
		if target_vol1 > -70.0 and not ambient1_audio.playing:
			ambient1_audio.play()
		elif target_vol1 <= -70.0 and ambient1_audio.playing:
			ambient1_audio.stop()

	if ambient2_audio:
		ambient2_audio.volume_db = target_vol2
		if target_vol2 > -70.0 and not ambient2_audio.playing:
			ambient2_audio.play()
		elif target_vol2 <= -70.0 and ambient2_audio.playing:
			ambient2_audio.stop()


func _update_walk_audio() -> void:
	if walk_audio == null:
		return

	if player_inside != null and is_instance_valid(player_inside):
		# Verificăm dacă playerul se mișcă efectiv în 2D
		var is_moving: bool = player_inside.velocity.length() > 5.0
		if is_moving:
			if not walk_audio.playing:
				walk_audio.play()
		else:
			if walk_audio.playing:
				walk_audio.stop()
	else:
		if walk_audio.playing:
			walk_audio.stop()


func _calculate_volume(distance: float, max_vol: float) -> float:
	if player_inside != null:
		return max_vol

	if distance >= ambient_start_distance:
		return -80.0

	if distance <= ambient_max_distance:
		return max_vol

	var percentage := inverse_lerp(ambient_start_distance, ambient_max_distance, distance)
	percentage = clampf(percentage, 0.0, 1.0)
	return lerp(-25.0, max_vol, percentage)


func _get_distance_to_player() -> float:
	if player_inside != null:
		return 0.0

	if player == null or not is_instance_valid(player):
		return 99999.0

	var min_dist := global_position.distance_to(player.global_position)

	for child in get_children():
		if child is CollisionShape2D and child.shape:
			var shape_pos: Vector2 = child.global_position
			if child.shape is RectangleShape2D:
				var rect_size: Vector2 = child.shape.size * child.global_scale
				var half_size := rect_size / 2.0
				var rect_min := shape_pos - half_size
				var rect_max := shape_pos + half_size

				var px: float = clampf(player.global_position.x, rect_min.x, rect_max.x)
				var py: float = clampf(player.global_position.y, rect_min.y, rect_max.y)

				var closest_point := Vector2(px, py)
				var d := closest_point.distance_to(player.global_position)
				if d < min_dist:
					min_dist = d
			else:
				var d := shape_pos.distance_to(player.global_position)
				if d < min_dist:
					min_dist = d

	return min_dist


func _play_splash_sound(path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
		return

	var stream = load(path)
	if stream:
		var asp := AudioStreamPlayer.new()
		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"
		get_tree().root.add_child(asp)
		asp.play()
		asp.finished.connect(asp.queue_free)
