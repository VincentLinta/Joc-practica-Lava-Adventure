extends CharacterBody2D

const PROJECTILE := preload("res://EnemyProjectile.tscn")

@export var speed: float = 40.0
@export var patrol_distance: float = 80.0
@export var max_health: int = 150
@export var shoot_interval: float = 3.0
@export var detection_range: float = 450.0

@export var edge_check_distance: float = 12.0
@export var ground_check_distance: float = 8.0

var health: int
var direction: int = 1
var aim_direction: int = 1
var start_position: Vector2

var shoot_timer: float = 0.0
var turn_cooldown: float = 0.0
@export var turn_cooldown_duration: float = 0.20

var dead := false
var is_shooting := false
var is_hurt := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	add_to_group("enemies")

	start_position = global_position
	health = max_health
	shoot_timer = shoot_interval

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.BLACK
	health_bar.add_theme_stylebox_override("fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.35, 0.35, 0.35)
	health_bar.add_theme_stylebox_override("background", background)

	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if dead:
		return

	turn_cooldown = max(turn_cooldown - delta, 0.0)

	# =========================================================
	# GRAVITY
	# =========================================================
	# ShooterEnemy este CharacterBody2D, deci îl ținem pe sol
	# și împiedicăm deplasarea accidentală în aer.
	# =========================================================

	if not is_on_floor():
		velocity.y += 900.0 * delta
	else:
		velocity.y = 0.0


	# =========================================================
	# HURT / SHOOTING
	# =========================================================

	if is_hurt or is_shooting:
		velocity.x = 0
		move_and_slide()
		return


	# =========================================================
	# WALL / EDGE CHECK
	# =========================================================

	if (
		(is_on_wall() or not has_ground_ahead())
		and turn_cooldown <= 0.0
	):
		direction *= -1
		sprite.flip_h = direction < 0
		turn_cooldown = turn_cooldown_duration


	# =========================================================
	# PATROL MOVEMENT
	# =========================================================

	velocity.x = direction * speed

	move_and_slide()


	# =========================================================
	# PATROL LIMITS
	# =========================================================

	if global_position.x >= start_position.x + patrol_distance:
		direction = -1
		sprite.flip_h = true

	elif global_position.x <= start_position.x - patrol_distance:
		direction = 1
		sprite.flip_h = false


	# =========================================================
	# SHOOT TIMER
	# =========================================================

	shoot_timer -= delta

	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval

		if can_see_player():
			shoot()


func has_ground_ahead() -> bool:
	var space_state := get_world_2d().direct_space_state

	var ray_start := global_position + Vector2(
		direction * 8.0,
		10.0
	)

	var ray_end := ray_start + Vector2(
		0,
		35.0
	)

	var query := PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_end
	)

	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	return not result.is_empty()


func can_see_player() -> bool:
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return false

	var distance = global_position.distance_to(
		player.global_position
	)

	return distance <= detection_range


func shoot() -> void:
	if dead or is_shooting:
		return


	# =========================================================
	# AIM
	# =========================================================

	var player = get_tree().get_first_node_in_group("player")

	if player and GameState.current_level >= 6:

		var horizontal_difference: float = (
			player.global_position.x
			- global_position.x
		)

		# Dacă player-ul este aproape direct deasupra/dedesubt,
		# păstrăm direcția actuală.
		if abs(horizontal_difference) < 20.0:
			aim_direction = direction
		else:
			aim_direction = (
				1
				if horizontal_difference > 0.0
				else -1
			)

		sprite.flip_h = aim_direction < 0

	else:
		aim_direction = direction


	# =========================================================
	# SHOOTING
	# =========================================================

	is_shooting = true
	print("TRAGE")

	sprite.play("shoot")
	_play_double_laser()

	await get_tree().create_timer(0.18).timeout

	if dead:
		return


	# =========================================================
	# PROJECTILE
	# =========================================================

	var projectile = PROJECTILE.instantiate()

	projectile.global_position = (
		muzzle.global_position
		+ Vector2(
			aim_direction * 15,
			0
		)
	)

	projectile.direction = aim_direction

	get_tree().current_scene.add_child(projectile)


	# =========================================================
	# WAIT SHOOT ANIMATION
	# =========================================================

	await sprite.animation_finished

	if dead:
		return

	sprite.play("walk")

	# Revenim la orientarea de patrol.
	sprite.flip_h = direction < 0

	is_shooting = false


func take_damage(amount: int) -> void:
	if dead:
		return

	health -= amount

	health = clamp(
		health,
		0,
		max_health
	)

	print(
		">>> SHOOTER LOVIT: ",
		name,
		" | HP: ",
		health,
		" | POS: ",
		global_position
	)

	var tween = create_tween()

	tween.tween_property(
		health_bar,
		"value",
		health,
		0.2
	)

	if health <= 0:
		die()
		return

	is_hurt = true

	sprite.play("hurt")

	modulate = Color(
		1,
		0.6,
		0.6
	)

	await get_tree().create_timer(
		0.08
	).timeout

	modulate = Color.WHITE

	await sprite.animation_finished

	if dead:
		return

	is_hurt = false

	sprite.play("walk")


func die() -> void:
	if dead:
		return

	dead = true

	print(
		"!!! SHOOTER DIED: ",
		name,
		" | POS: ",
		global_position
	)

	GameState.add_score(250)

	is_hurt = false
	is_shooting = false

	velocity = Vector2.ZERO

	$CollisionShape2D.set_deferred(
		"disabled",
		true
	)

	sprite.play("death")

	await sprite.animation_finished

	queue_free()


func _play_double_laser() -> void:
	_play_audio(
		"res://sfx/laser.mp3",
		4.0
	)

	await get_tree().create_timer(
		0.15
	).timeout

	_play_audio(
		"res://sfx/laser.mp3",
		4.0
	)


func _play_audio(
	path: String,
	volume_db: float = 0.0,
	start_offset: float = 0.0
) -> void:

	if not ResourceLoader.exists(path):

		print(
			"EROARE: SUNETUL NU EXISTĂ: ",
			path
		)

		return

	var stream = load(path)

	if stream:

		var asp := AudioStreamPlayer.new()

		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"

		get_tree().root.add_child(asp)

		asp.play(start_offset)

		asp.finished.connect(
			asp.queue_free
		)
