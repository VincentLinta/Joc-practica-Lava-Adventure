extends Area2D

@export var damage_per_tick: int = 15
@export var tick_time: float = 0.25

# =========================
# AUDIO LAVA
# =========================
@export var away_start_distance: float = 1000.0
@export var away_max_distance: float = 200.0

@export var close_start_distance: float = 500.0
@export var close_max_distance: float = 50.0

@export var away_max_volume_db: float = 8.0
@export var close_max_volume_db: float = 12.0

var player: Node = null
var player_inside: Node = null
var damage_timer: float = 0.0

var away_audio: AudioStreamPlayer
var close_audio: AudioStreamPlayer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_lava_audio()


func _physics_process(delta: float) -> void:
	# DAMAGE (Doar pentru Player)
	if player_inside != null and is_instance_valid(player_inside):
		damage_timer += delta

		if damage_timer >= tick_time:
			damage_timer -= tick_time

			if player_inside.has_method("take_damage"):
				player_inside.take_damage(damage_per_tick, "lava")
	else:
		player_inside = null

	# GĂSEȘTE PLAYER
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	# ACTUALIZARE AUDIO
	if player != null and is_instance_valid(player):
		_update_lava_audio()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		player_inside = body
		damage_timer = tick_time


func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null
		damage_timer = 0.0


func _setup_lava_audio() -> void:
	var away_stream = load("res://sfx/LavaAway.wav")
	if away_stream:
		away_audio = AudioStreamPlayer.new()
		away_audio.stream = away_stream
		away_audio.bus = "Master"
		away_audio.volume_db = -80.0
		add_child(away_audio)
		_make_audio_loop(away_stream)
	else:
		print("EROARE: Nu s-a putut incarca LavaAway.wav!")

	var close_stream = load("res://sfx/LavaClose.wav")
	if close_stream:
		close_audio = AudioStreamPlayer.new()
		close_audio.stream = close_stream
		close_audio.bus = "Master"
		close_audio.volume_db = -80.0
		add_child(close_audio)
		_make_audio_loop(close_stream)
	else:
		print("EROARE: Nu s-a putut incarca LavaClose.wav!")


func _make_audio_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end == 0:
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)


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


func _update_lava_audio() -> void:
	var distance: float = _get_distance_to_player()

	# LAVA AWAY
	if away_audio:
		if distance >= away_start_distance:
			if away_audio.playing:
				away_audio.stop()
				away_audio.volume_db = -80.0
		else:
			var volume := _calculate_volume(
				distance,
				away_start_distance,
				away_max_distance,
				away_max_volume_db
			)
			away_audio.volume_db = volume
			if not away_audio.playing:
				away_audio.play()

	# LAVA CLOSE
	if close_audio:
		if distance >= close_start_distance:
			if close_audio.playing:
				close_audio.stop()
				close_audio.volume_db = -80.0
		else:
			var volume := _calculate_volume(
				distance,
				close_start_distance,
				close_max_distance,
				close_max_volume_db
			)
			close_audio.volume_db = volume
			if not close_audio.playing:
				close_audio.play()


func _calculate_volume(
	distance: float,
	start_distance: float,
	max_distance: float,
	max_volume_db: float
) -> float:
	if distance >= start_distance:
		return -80.0

	if distance <= max_distance:
		return max_volume_db

	var percentage := inverse_lerp(start_distance, max_distance, distance)
	percentage = clampf(percentage, 0.0, 1.0)

	return lerp(-8.0, max_volume_db, percentage)
