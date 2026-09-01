extends Area2D

@export var speed: float = 520.0
@export var return_speed: float = 650.0
@export var damage: int = 100

@export var hit_distance: float = 18.0
@export var catch_distance: float = 18.0
@export var max_no_target_distance: float = 280.0
@export var spin_speed: float = 12.0

var player: Node2D
var target: Node2D

var returning: bool = false
var has_hit: bool = false

var start_position: Vector2
var forward_direction: Vector2 = Vector2.RIGHT


func setup(owner_player: Node2D, facing_direction: int) -> void:
	player = owner_player
	forward_direction = Vector2(float(facing_direction), 0.0)
	start_position = global_position

	# Sunet la lansare/aruncare
	_play_audio("res://sfx/ScutAruncat.mp3", 2.0)

	target = find_closest_visible_enemy()

	if target:
		print("SCUTUL URMARESTE: ", target.name)
	else:
		print("NICIUN INAMIC VIZIBIL - SCUTUL ZBOARA INAINTE")


func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta

	if not is_instance_valid(player):
		queue_free()
		return

	if returning:
		return_to_player(delta)
		return

	if is_instance_valid(target) and target.is_inside_tree():
		global_position = global_position.move_toward(
			target.global_position,
			speed * delta
		)

		if global_position.distance_to(target.global_position) <= hit_distance:
			hit_target()
	else:
		target = find_closest_visible_enemy()

		if target:
			return

		global_position += forward_direction * speed * delta

		if global_position.distance_to(start_position) >= max_no_target_distance:
			returning = true


func hit_target() -> void:
	if has_hit:
		return

	has_hit = true

	if is_instance_valid(target) and target.has_method("take_damage"):
		var damage_multiplier: float = 1.0

		if is_instance_valid(player):
			var multiplier_value = player.get("final_boss_damage_multiplier")
			if multiplier_value != null:
				damage_multiplier = multiplier_value

		var final_damage: int = roundi(damage * damage_multiplier)

		var is_oneshot := false
		if "health" in target and target.health <= final_damage:
			is_oneshot = true

		target.call("take_damage", final_damage)

		if is_oneshot:
			# Ajustat la 2.0 dB (sweet spot)
			_play_audio("res://sfx/Shield_hitONESHOT.mp3", 1.0)
		else:
			_play_audio("res://sfx/Shield_hit.mp3", 3.0)

		print("SCUT HIT: ", target.name, " - DAMAGE: ", final_damage)

	target = null
	returning = true


func return_to_player(delta: float) -> void:
	var catch_position := player.global_position + Vector2(0.0, -4.0)

	global_position = global_position.move_toward(
		catch_position,
		return_speed * delta
	)

	if global_position.distance_to(catch_position) <= catch_distance:
		_play_audio("res://sfx/Shield_return.mp3", 8.0)

		if player.has_method("on_shield_returned"):
			player.call("on_shield_returned")

		queue_free()


func find_closest_visible_enemy() -> Node2D:
	var closest_enemy: Node2D = null
	var closest_distance_squared: float = INF

	var camera := get_viewport().get_camera_2d()
	var camera_rect := Rect2()

	if camera:
		camera_rect = get_camera_world_rect(camera)

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D

		if enemy == null:
			continue

		if not enemy.is_inside_tree():
			continue

		if not enemy.is_visible_in_tree():
			continue

		if camera and not camera_rect.has_point(enemy.global_position):
			continue

		var distance_squared := global_position.distance_squared_to(
			enemy.global_position
		)

		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_enemy = enemy

	return closest_enemy


func get_camera_world_rect(camera: Camera2D) -> Rect2:
	var viewport_size := get_viewport_rect().size

	var half_visible_size := Vector2(
		viewport_size.x / camera.zoom.x,
		viewport_size.y / camera.zoom.y
	) * 0.5

	var screen_center := camera.get_screen_center_position()

	return Rect2(
		screen_center - half_visible_size,
		half_visible_size * 2.0
	).grow(24.0)


func _play_audio(path: String, volume_db: float = 0.0, start_offset: float = 0.0) -> void:
	if not FileAccess.file_exists(path):
		print("EROARE: SUNETUL NU EXISTA: ", path)
		return

	var stream = load(path)
	if stream:
		var asp := AudioStreamPlayer.new()
		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"
		get_tree().root.add_child(asp)
		asp.play(start_offset)
		asp.finished.connect(asp.queue_free)
