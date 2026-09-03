extends CharacterBody2D


@export var max_health: int = 50
@export var gravity: float = 900.0

@export var explosion_damage: int = 30
@export var explosion_radius: float = 150.0

var health: int
var is_dead := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	anim.play("idle")
	setup_health_bar_style()
	update_health_bar()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount

	print(
		">>> EXPLOSIVE LOVIT: ",
		name,
		" | HP: ",
		health,
		" | POS: ",
		global_position
	)

	if health < 0:
		health = 0

	update_health_bar()

	if health <= 0:
		die()
	else:
		flash_red()


func update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = health


func setup_health_bar_style() -> void:
	health_bar.show_percentage = false

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(
		0.12,
		0.12,
		0.12
	)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(
		0.65,
		0.0,
		1.0
	)

	health_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	health_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)


func explode_damage() -> void:
	var player = get_tree().get_first_node_in_group(
		"player"
	)

	if player == null:
		print("No player found in group")
		return

	var distance_to_player = global_position.distance_to(
		player.global_position
	)

	print(
		"Explosion distance:",
		distance_to_player
	)

	if distance_to_player <= explosion_radius:

		if player.has_method("take_damage"):

			player.take_damage(
				explosion_damage
			)

			print(
				"Explosion hit player for",
				explosion_damage,
				"damage"
			)


func die() -> void:
	if is_dead:
		return

	is_dead = true

	print(
		"!!! EXPLOSIVE DIED: ",
		name,
		" | POS: ",
		global_position
	)

	# SHAKE MULT MAI MARE SI PERSISTENT PENTRU EXPLOZIE
	ScreenShake.shake(
		22.0,
		6.0
	)

	body_collision.set_deferred(
		"disabled",
		true
	)

	hurtbox_collision.set_deferred(
		"disabled",
		true
	)

	GameState.add_score(100)

	_play_audio(
		"res://sfx/EXPLOZIE.mp3",
		20.0
	)

	explode_damage()

	health_bar.visible = false

	anim.modulate = Color.WHITE
	anim.play("death")

	await anim.animation_finished

	queue_free()


func flash_red() -> void:
	anim.modulate = Color.RED

	await get_tree().create_timer(
		0.1
	).timeout

	if not is_dead:
		anim.modulate = Color.WHITE


func _play_audio(
	path: String,
	volume_db: float = 0.0,
	start_offset: float = 0.0
) -> void:

	var exists := ResourceLoader.exists(path)

	_log_audio(
		"[ENEMY] path=%s exists=%s" % [
			path,
			exists
		]
	)

	if not exists:

		print(
			"EROARE: SUNETUL NU EXISTA: ",
			path
		)

		_log_audio(
			"[ENEMY] ABORT (ResourceLoader.exists=false): %s" % path
		)

		return

	var stream = load(path)

	if stream == null:

		_log_audio(
			"[ENEMY] ABORT (load() null): %s" % path
		)

		return

	var asp := AudioStreamPlayer.new()

	asp.stream = stream
	asp.volume_db = volume_db
	asp.bus = "Master"

	get_tree().root.add_child(
		asp
	)

	asp.play(
		start_offset
	)

	asp.finished.connect(
		asp.queue_free
	)

	_log_audio(
		"[ENEMY] OK path=%s playing=%s bus=%s vol=%s" % [
			path,
			asp.playing,
			asp.bus,
			asp.volume_db
		]
	)


func _log_audio(line: String) -> void:
	var f := FileAccess.open(
		"user://audio_debug.log",
		FileAccess.READ_WRITE
		if FileAccess.file_exists("user://audio_debug.log")
		else FileAccess.WRITE
	)

	if f:
		f.seek_end()

		f.store_line(
			"[%s] %s" % [
				Time.get_ticks_msec(),
				line
			]
		)

		f.close()
