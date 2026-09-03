extends CharacterBody2D


const SHIELD_PROJECTILE_SCENE: PackedScene = preload(
	"res://ShieldProjectile.tscn"
)

@export var speed: float = 180.0
@export var jump_velocity: float = -350.0
@export var gravity: float = 900.0

@export var max_health: int = 200
var health: int = 200

# Sistem de buff pentru Final Boss (temporar, nu persistă la restart)
var final_boss_shield: int = 0
var final_boss_damage_multiplier: float = 1.0

@export var attack_damage: int = 25
@export var attack_offset_x: float = 25.0

var is_attacking: bool = false
var is_dead: bool = false
var facing_direction: int = 1

# =============================================================
# KNOCKBACK / STUN
# Folosit în special de Final Boss.
# În celelalte nivele nu are niciun efect dacă nu este apelat.
# =============================================================

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

@export var knockback_duration: float = 0.35
@export var knockback_friction: float = 1200.0

# =============================================================
# DEATH SEQUENCE
# =============================================================

var death_sequence_id: int = 0

# Starea scutului.
var has_shield: bool = false
var shield_in_hand: bool = false
var is_picking_up_shield: bool = false
var is_throwing_shield: bool = false

var active_shield_projectile: Area2D = null

# Multiplicatorul pentru apă.
var movement_speed_multiplier: float = 1.0

# Bonus special pentru apa din Level 8.
var level8_water_jump: bool = false

# Multiplicatorii portalului.
var portal_speed_multiplier: float = 1.0
var portal_jump_multiplier: float = 1.0
var portal_boost_active: bool = false

# --- VARIABILE PENTRU PAȘI ---
var footstep_sounds: Array[AudioStream] = []
@export var step_interval: float = 0.28
var step_timer: float = 0.0
# -----------------------------

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var health_bar: ProgressBar = null

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	Engine.time_scale = 1.0

	if ScreenShake.has_method("stop"):
		ScreenShake.stop()

	add_to_group("player")

	for i in range(1, 9):
		var path := "res://sfx/walk%d.ogg" % i
		if ResourceLoader.exists(path):
			footstep_sounds.append(load(path))

	has_shield = GameState.has_shield
	shield_in_hand = has_shield

	if shield_in_hand:
		anim.play("shield_idle")
	else:
		anim.play("idle")

	max_health = 200
	health = max_health

	attack_area.position.x = attack_offset_x
	attack_shape.disabled = false
	attack_area.monitoring = true

	health_bar = get_tree().root.find_child(
		"HealthBar",
		true,
		false
	) as ProgressBar

	if health_bar:
		health_bar.size = Vector2(250, 36)
		health_bar.position = Vector2(
			(get_viewport_rect().size.x - health_bar.size.x) / 2.0,
			20
		)

		var background_style := StyleBoxFlat.new()
		background_style.bg_color = Color.BLACK
		background_style.border_color = Color.BLACK
		background_style.set_border_width_all(2)

		health_bar.add_theme_stylebox_override(
			"background",
			background_style
		)

		update_health_bar()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var is_level8_water := (
		GameState.current_level == 8
		and movement_speed_multiplier < 1.0
	)

	# =========================================================
	# GRAVITY
	# =========================================================

	if not is_on_floor():
		if is_level8_water:
			velocity.y += gravity * 1.333333 * delta
		else:
			velocity.y += gravity * movement_speed_multiplier * delta

	# =========================================================
	# KNOCKBACK / STUN
	# =========================================================

	if knockback_timer > 0.0:
		knockback_timer -= delta

		velocity.x = move_toward(
			velocity.x,
			0.0,
			knockback_friction * delta
		)

		move_and_slide()

		if knockback_timer <= 0.0:
			knockback_timer = 0.0
			knockback_velocity = Vector2.ZERO

		return

	# =========================================================
	# SHIELD PICKUP
	# =========================================================

	if is_picking_up_shield:
		velocity.x = 0.0
		move_and_slide()
		return

	# =========================================================
	# MOVEMENT INPUT
	# =========================================================

	var direction := Input.get_axis("move_left", "move_right")

	velocity.x = (
		direction
		* speed
		* movement_speed_multiplier
		* portal_speed_multiplier
	)

	# =========================================================
	# JUMP
	# =========================================================

	if Input.is_action_just_pressed("jump") and is_on_floor():
		var current_jump_velocity := jump_velocity

		if is_level8_water:
			current_jump_velocity *= 2.0
			velocity.y = (
				current_jump_velocity
				* portal_jump_multiplier
			)
		else:
			velocity.y = (
				current_jump_velocity
				* movement_speed_multiplier
				* portal_jump_multiplier
			)

		_play_audio("res://sfx/jump.wav")

	# =========================================================
	# FACING
	# =========================================================

	if direction != 0:
		facing_direction = int(sign(direction))
		anim.flip_h = direction < 0
		attack_area.position.x = attack_offset_x * facing_direction

	# =========================================================
	# ATTACK
	# =========================================================

	if Input.is_action_just_pressed("attack"):
		attack()

	# =========================================================
	# SHIELD THROW
	# =========================================================

	if Input.is_action_just_pressed("shield_throw"):
		throw_shield()

	# =========================================================
	# MOVEMENT ANIMATION
	# =========================================================

	if not is_attacking and not is_throwing_shield:
		update_movement_animation(direction)

	# =========================================================
	# FOOTSTEPS
	# =========================================================

	if (
		is_on_floor()
		and direction != 0
		and not is_attacking
		and not is_picking_up_shield
		and not is_throwing_shield
	):
		step_timer -= delta

		if step_timer <= 0.0:
			_play_footstep()
			step_timer = step_interval
	else:
		step_timer = 0.0

	move_and_slide()


# =============================================================
# MOVEMENT ANIMATION
# =============================================================

func update_movement_animation(direction: float) -> void:
	if has_shield and shield_in_hand:
		if not is_on_floor():
			anim.play("shield_jump")
		elif direction != 0:
			anim.play("shield_run")
		else:
			anim.play("shield_idle")
	else:
		if not is_on_floor():
			anim.play("jump")
		elif direction != 0:
			anim.play("run")
		else:
			anim.play("idle")


# =============================================================
# SHIELD PICKUP
# =============================================================

func collect_shield() -> void:
	if has_shield or is_dead or is_picking_up_shield:
		return

	is_picking_up_shield = true
	has_shield = true
	shield_in_hand = true
	GameState.has_shield = true

	velocity.x = 0.0
	anim.play("shield_pickup")

	await anim.animation_finished

	if is_dead:
		return

	is_picking_up_shield = false

	update_movement_animation(
		Input.get_axis("move_left", "move_right")
	)


# =============================================================
# THROW SHIELD
# =============================================================

func throw_shield() -> void:
	if (
		is_dead
		or not has_shield
		or not shield_in_hand
		or not GameState.shield_throw_unlocked
	):
		return

	if is_attacking or is_throwing_shield or is_picking_up_shield:
		return

	if is_instance_valid(active_shield_projectile):
		return

	is_throwing_shield = true
	anim.play("shield_throw")

	await get_tree().create_timer(0.2).timeout

	if is_dead:
		return

	var projectile := SHIELD_PROJECTILE_SCENE.instantiate() as Area2D

	if projectile == null:
		is_throwing_shield = false
		return

	projectile.global_position = global_position + Vector2(
		22.0 * facing_direction,
		-4.0
	)

	get_tree().current_scene.add_child(projectile)

	active_shield_projectile = projectile
	shield_in_hand = false

	projectile.call("setup", self, facing_direction)

	await anim.animation_finished

	if is_dead:
		return

	is_throwing_shield = false

	update_movement_animation(
		Input.get_axis("move_left", "move_right")
	)


# =============================================================
# SHIELD RETURNED
# =============================================================

func on_shield_returned() -> void:
	active_shield_projectile = null

	if is_dead:
		return

	is_picking_up_shield = true
	velocity.x = 0.0
	anim.play("shield_pickup")

	await anim.animation_finished

	if is_dead:
		return

	shield_in_hand = true
	is_picking_up_shield = false

	update_movement_animation(
		Input.get_axis("move_left", "move_right")
	)


# =============================================================
# PLAYER ATTACK
# =============================================================

func attack() -> void:
	if (
		is_attacking
		or is_dead
		or is_picking_up_shield
		or is_throwing_shield
	):
		return

	is_attacking = true
	anim.play("attack")

	await get_tree().physics_frame
	await get_tree().physics_frame

	var has_hit_enemy: bool = false

	var targets: Array = (
		attack_area.get_overlapping_bodies()
		+ attack_area.get_overlapping_areas()
	)

	for target in targets:
		if not is_instance_valid(target) or target == self:
			continue

		var enemy_node: Node = target

		if (
			not enemy_node.is_in_group("enemies")
			and enemy_node.get_parent() != null
			and enemy_node.get_parent().is_in_group("enemies")
		):
			enemy_node = enemy_node.get_parent()

		if (
			is_instance_valid(enemy_node)
			and enemy_node.is_in_group("enemies")
			and enemy_node.has_method("take_damage")
		):
			var final_damage: int = ceili(
				attack_damage * final_boss_damage_multiplier
			)

			enemy_node.take_damage(final_damage)
			has_hit_enemy = true

	if has_hit_enemy:
		_play_audio(
			"res://sfx/punch.wav",
			10.0,
			0.38
		)
	else:
		_play_audio("res://sfx/swing.wav")

	await anim.animation_finished

	if is_dead:
		return

	is_attacking = false

	update_movement_animation(
		Input.get_axis("move_left", "move_right")
	)


# =============================================================
# KNOCKBACK
# =============================================================

func apply_knockback(force: Vector2) -> void:
	if is_dead:
		return

	is_attacking = false
	is_throwing_shield = false
	is_picking_up_shield = false

	knockback_velocity = force
	knockback_timer = knockback_duration
	velocity = force

	if anim.sprite_frames.has_animation("hurt"):
		anim.play("hurt")


# =============================================================
# AUDIO
# =============================================================

func _play_audio(
	path: String,
	volume_db: float = 0.0,
	start_offset: float = 0.0
) -> void:
	if not ResourceLoader.exists(path):
		print(
			"EROARE SFX: Nu s-a gasit fisierul audio la calea: ",
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
		asp.finished.connect(asp.queue_free)


# =============================================================
# TAKE DAMAGE
# =============================================================

func take_damage(
	amount: int,
	source: String = "enemy"
) -> void:
	if is_dead:
		return

	var remaining_damage: int = amount

	if final_boss_shield > 0:
		var absorbed_damage: int = min(
			final_boss_shield,
			remaining_damage
		)

		final_boss_shield -= absorbed_damage
		remaining_damage -= absorbed_damage

	if remaining_damage > 0:
		health -= remaining_damage
		health = clamp(
			health,
			0,
			max_health
		)

	ScreenShake.shake(
		3.0,
		15.0
	)

	_play_audio(
		"res://sfx/hurt-sound.mp3"
	)

	update_health_bar(true)

	if health <= 0:
		die(source)


# =============================================================
# FINAL BOSS BUFFS
# =============================================================

func apply_final_boss_buffs() -> void:
	if is_dead:
		return

	health = max_health
	final_boss_shield = int(round(max_health * 3.885))
	final_boss_damage_multiplier = 2

	update_health_bar(false)

	print(
		"FINAL BOSS BUFF ACTIVAT | HP: ",
		health,
		" | Shield: ",
		final_boss_shield,
		" | Damage Multiplier: ",
		final_boss_damage_multiplier
	)


# =============================================================
# UPDATE HEALTH BAR
# =============================================================

func update_health_bar(animate_text: bool = false) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

		var hp_fill := StyleBoxFlat.new()
		hp_fill.bg_color = Color.RED
		hp_fill.border_color = Color.BLACK
		hp_fill.set_border_width_all(2)

		health_bar.add_theme_stylebox_override(
			"fill",
			hp_fill
		)

		var parent_node := health_bar.get_parent()

		if parent_node:
			var shield_bar := parent_node.find_child(
				"ShieldBarUI",
				false,
				false
			) as ProgressBar

			var shield_label := parent_node.find_child(
				"ShieldLabelUI",
				false,
				false
			) as Label

			if final_boss_shield > 0:
				if shield_bar == null:
					shield_bar = ProgressBar.new()
					shield_bar.name = "ShieldBarUI"
					parent_node.add_child(shield_bar)

				shield_bar.visible = true
				shield_bar.show_percentage = false
				shield_bar.max_value = max_health * 2
				shield_bar.value = final_boss_shield

				shield_bar.size = Vector2(
					250,
					health_bar.size.y
				)

				shield_bar.position = Vector2(
					health_bar.position.x
					+ health_bar.size.x
					+ 4.0,
					health_bar.position.y
				)

				var shield_fill := StyleBoxFlat.new()
				shield_fill.bg_color = Color("#00d2ff")
				shield_fill.border_color = Color.BLACK
				shield_fill.set_border_width_all(2)

				shield_bar.add_theme_stylebox_override(
					"fill",
					shield_fill
				)

				var shield_bg := StyleBoxFlat.new()
				shield_bg.bg_color = Color.BLACK
				shield_bg.border_color = Color.BLACK
				shield_bg.set_border_width_all(2)

				shield_bar.add_theme_stylebox_override(
					"background",
					shield_bg
				)

				if shield_label == null:
					shield_label = Label.new()
					shield_label.name = "ShieldLabelUI"
					parent_node.add_child(shield_label)

				shield_label.visible = true
				shield_label.text = "+%d SHIELD" % final_boss_shield

				shield_label.add_theme_color_override(
					"font_color",
					Color.YELLOW
				)

				shield_label.horizontal_alignment = (
					HORIZONTAL_ALIGNMENT_CENTER
				)

				shield_label.vertical_alignment = (
					VERTICAL_ALIGNMENT_CENTER
				)

				shield_label.size = shield_bar.size
				shield_label.position = shield_bar.position

			else:
				if shield_bar:
					shield_bar.visible = false

				if shield_label:
					shield_label.visible = false

	update_hp_ui(animate_text)


# =============================================================
# UPDATE HP TEXT
# =============================================================

func update_hp_ui(animate: bool = false) -> void:
	var hp_label: Label = get_tree().root.find_child(
		"HPLabel",
		true,
		false
	) as Label

	if hp_label:
		hp_label.text = "HP %d" % health

		if animate:
			var tween := create_tween()

			hp_label.modulate = Color(
				1.0,
				0.25,
				0.25
			)

			tween.tween_property(
				hp_label,
				"modulate",
				Color.WHITE,
				0.25
			)


# =============================================================
# PLAYER DEATH
# =============================================================

func die(source: String = "enemy") -> void:
	if is_dead:
		return

	is_dead = true

	set_physics_process(false)

	Engine.time_scale = 0.2

	ScreenShake.shake(
		28.0,
		2.5
	)

	var cam := get_viewport().get_camera_2d()

	if cam:
		var tween := create_tween()

		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_property(
			cam,
			"zoom",
			cam.zoom * 1.25,
			0.3
		)

	anim.modulate = Color(
		2.5,
		0.2,
		0.2
	)

	var death_sound := "res://sfx/moarte_enemy.wav"
	var sound_volume: float = 12.0

	# =========================================================
	# SUNET SPECIAL FINAL BOSS - DOAR LEVEL 10
	# =========================================================

	if (
		GameState.current_level == 10
		and source == "final_boss"
	):
		death_sound = "res://sfx/whenTheBossKillsYou.mp3"
		sound_volume = 12.0

	elif (
		source == "lava"
		or source == "spike"
		or source == "hazard"
	):
		death_sound = "res://sfx/moarte_oricealtcv.wav"
		sound_volume = 20.0

	else:
		sound_volume = 12.0

	_play_audio(
		death_sound,
		sound_volume
	)

	# Pornim prima secvență de moarte.
	death_sequence_id += 1
	_run_death_sequence(death_sequence_id)


# =============================================================
# DEATH SEQUENCE
# =============================================================

func _run_death_sequence(sequence_id: int) -> void:
	# process_always = false:
	# timerul se OPREȘTE atunci când jocul este paused.
	await get_tree().create_timer(
		0.25,
		false
	).timeout

	if not is_dead:
		return

	if sequence_id != death_sequence_id:
		return

	_reload_level()


# =============================================================
# RESUME DEATH AFTER PAUSE
# =============================================================

func resume_death_after_pause() -> void:
	if not is_dead:
		return

	# Invalidăm secvența veche.
	death_sequence_id += 1

	# Refacem efectul vizual de moarte.
	anim.modulate = Color(
		2.5,
		0.2,
		0.2
	)

	# Repornim screen shake.
	ScreenShake.shake(
		28.0,
		2.5
	)

	# Pornim o secvență nouă.
	_run_death_sequence(death_sequence_id)


# =============================================================
# RELOAD LEVEL
# =============================================================

func _reload_level() -> void:
	Engine.time_scale = 1.0

	if ScreenShake.has_method("stop"):
		ScreenShake.stop()

	if GameState.has_method("reset_level_score"):
		GameState.reset_level_score()

	get_tree().reload_current_scene()


# =============================================================
# WATER SLOW
# =============================================================

func set_water_slow(multiplier: float) -> void:
	if multiplier < 1.0 and movement_speed_multiplier == 1.0:
		velocity.x *= multiplier

	velocity.y *= multiplier

	movement_speed_multiplier = multiplier


# =============================================================
# LEVEL 8 WATER JUMP
# =============================================================

func set_level8_water_jump(enabled: bool) -> void:
	level8_water_jump = enabled


# =============================================================
# PORTAL BOOST
# =============================================================

func start_portal_boost(duration: float = 5.0) -> void:
	if portal_boost_active or is_dead:
		return

	portal_boost_active = true
	portal_speed_multiplier = 3.0
	portal_jump_multiplier = 5.0

	await get_tree().create_timer(duration).timeout

	portal_speed_multiplier = 1.0
	portal_jump_multiplier = 1.0
	portal_boost_active = false


# =============================================================
# FOOTSTEP
# =============================================================

func _play_footstep() -> void:
	if footstep_sounds.is_empty():
		return

	var random_stream: AudioStream = footstep_sounds.pick_random()

	if random_stream:
		var asp := AudioStreamPlayer.new()

		asp.stream = random_stream
		asp.volume_db = randf_range(2.0, 5.0)
		asp.pitch_scale = randf_range(0.93, 1.07)
		asp.bus = "Master"

		get_tree().root.add_child(asp)

		asp.play()
		asp.finished.connect(asp.queue_free)
