extends CharacterBody2D


@export var max_hp: int = 6666

var current_hp: float = 6666.0

var player: Node2D = null
var is_dead: bool = false
var is_attacking: bool = false
var is_active: bool = false


# =============================================================
# VOMIT THRESHOLDS
# 75%, 50%, 25%
# =============================================================

var vomit_thresholds: Array[int] = []
var triggered_vomits: Array[int] = []

var vomit_queue: Array[int] = []


# =============================================================
# BLOOD BALL
# =============================================================

const BLOOD_BALL_SCENE = preload(
	"res://DemonBloodBall.tscn"
)


# =============================================================
# NODES
# =============================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var vomit_area: Area2D = $VomitArea


# =============================================================
# MAP2 / BOSS ARENA
# =============================================================

@onready var arena_map: TileMapLayer = (
	get_parent().get_node_or_null("Map2")
)


# Reținem automat distanța X setată în editor.

var vomit_area_distance_x: float = 0.0


# BossHealthBar este în:
# Level10 -> CanvasLayer -> BossHealthBar

@onready var health_bar = get_node_or_null(
	"../CanvasLayer/BossHealthBar"
)


# =============================================================
# BOSS STATS
# =============================================================

var speed: float = 35.0

@export var gravity: float = 900.0

@export var punch_range: float = 90.0

@export var punch_cooldown: float = 1.5

var punch_timer: float = 0.0


# =============================================================
# ABILITY TIMERS
# =============================================================

var earthquake_timer: float = 0.0
var ranged_attack_timer: float = 0.0

@export var earthquake_interval: float = 10.0

@export var blood_ball_interval: float = 2.0


# =============================================================
# EARTHQUAKE STATE
# =============================================================

var first_earthquake: bool = true


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# =========================================================
	# GRUPURI
	# =========================================================

	add_to_group("boss")
	add_to_group("enemies")


	# =========================================================
	# HP
	# =========================================================

	current_hp = float(max_hp)

	_setup_vomit_thresholds()


	# =========================================================
	# VOMIT AREA DISTANCE
	# =========================================================

	if vomit_area:

		vomit_area_distance_x = abs(
			vomit_area.position.x
		)


	# =========================================================
	# BOSS INACTIV LA START
	# =========================================================

	visible = false

	set_physics_process(false)

	is_active = false
	is_attacking = false


	# =========================================================
	# MAP2 INACTIV LA START
	# =========================================================

	if arena_map:

		arena_map.visible = false
		arena_map.enabled = false
		arena_map.collision_enabled = false
		arena_map.navigation_enabled = false

		print(
			"🧱 MAP2 INACTIVĂ: INVIZIBILĂ + COLLISION OFF!"
		)


	# =========================================================
	# BOSS COLLISION OFF
	# =========================================================

	if collision_shape:

		collision_shape.set_deferred(
			"disabled",
			true
		)


	# =========================================================
	# PLAYER
	# =========================================================

	player = get_tree().get_first_node_in_group(
		"player"
	)


# =============================================================
# SETUP VOMIT THRESHOLDS
# =============================================================

func _setup_vomit_thresholds() -> void:

	vomit_thresholds = [
		int(round(float(max_hp) * 0.75)),
		int(round(float(max_hp) * 0.50)),
		int(round(float(max_hp) * 0.25))
	]


# =============================================================
# START BOSS FIGHT
# =============================================================

func start_boss_fight() -> void:

	if is_dead:
		return

	print(
		"🔥 FINAL BOSS: LUPTA A INCEPUT!"
	)


	# =========================================================
	# RESETARE STARE
	# =========================================================

	current_hp = float(max_hp)

	_setup_vomit_thresholds()

	punch_timer = 0.0
	earthquake_timer = 0.0
	ranged_attack_timer = 0.0

	vomit_queue.clear()
	triggered_vomits.clear()

	first_earthquake = true


	# =========================================================
	# ACTIVATE BOSS
	# =========================================================

	visible = true


	# =========================================================
	# ACTIVATE MAP2 / BOSS ARENA
	# =========================================================

	if arena_map:

		arena_map.enabled = true
		arena_map.visible = true
		arena_map.collision_enabled = true
		arena_map.navigation_enabled = true

		print(
			"🧱 MAP2 ACTIVATĂ: ARENA BOSS PORNITĂ!"
		)


	# =========================================================
	# BOSS SPAWN / LAUGH SOUND
	# =========================================================

	_play_audio(
		"res://sfx/demon_laugh_spawn.mp3",
		28.0
	)


	if collision_shape:

		collision_shape.set_deferred(
			"disabled",
			false
		)

	set_physics_process(true)

	is_active = true
	is_attacking = false


	# =========================================================
	# SHOW BOSS HEALTH BAR
	# =========================================================

	if (
		health_bar
		and health_bar.has_method("show_bar")
	):

		health_bar.show_bar(max_hp)


	# =========================================================
	# BOSS INTRĂ DIRECT ÎN LUPTĂ
	# =========================================================

	trigger_earthquake()


# =============================================================
# ORIENTARE VOMIT SPRE PLAYER
# =============================================================

func orient_vomit_toward_player() -> void:

	if not player:
		return

	if not is_instance_valid(player):
		return


	# =========================================================
	# DEMON_VOMIT ARE JETUL ORIGINAL SPRE STÂNGA
	# =========================================================

	if player.global_position.x < global_position.x:

		# -----------------------------------------------------
		# PLAYER ÎN STÂNGA
		# -----------------------------------------------------

		animated_sprite.flip_h = false

		if vomit_area:
			vomit_area.position.x = (
				-vomit_area_distance_x
			)

	else:

		# -----------------------------------------------------
		# PLAYER ÎN DREAPTA
		# -----------------------------------------------------

		animated_sprite.flip_h = true

		if vomit_area:
			vomit_area.position.x = (
				vomit_area_distance_x
			)


# =============================================================
# PHYSICS PROCESS
# =============================================================

func _physics_process(delta: float) -> void:

	if is_dead or not is_active:
		return


	# =========================================================
	# PLAYER VALIDATION
	# =========================================================

	if not player or not is_instance_valid(player):

		player = get_tree().get_first_node_in_group(
			"player"
		)


	# =========================================================
	# GRAVITY
	# =========================================================

	if not is_on_floor():

		velocity.y += gravity * delta

	else:

		velocity.y = 0.0


	# =========================================================
	# PUNCH COOLDOWN
	# =========================================================

	punch_timer = max(
		punch_timer - delta,
		0.0
	)


	# =========================================================
	# DACĂ FACE O ABILITATE
	# =========================================================

	if is_attacking:

		move_and_slide()

		return


	# =========================================================
	# VOMIT ARE PRIORITATE
	# =========================================================

	if vomit_queue.size() > 0:

		start_next_vomit()

		return


	# =========================================================
	# DISTANȚA LA PLAYER
	# =========================================================

	var distance_to_player: float = INF

	if player:

		distance_to_player = global_position.distance_to(
			player.global_position
		)


	# =========================================================
	# PUNCH
	# =========================================================

	if (
		player
		and distance_to_player <= punch_range
		and punch_timer <= 0.0
	):

		execute_punch(player)

		return


	# =========================================================
	# TIMERE ABILITĂȚI
	# =========================================================

	earthquake_timer += delta
	ranged_attack_timer += delta


	# =========================================================
	# EARTHQUAKE
	# =========================================================

	if earthquake_timer >= earthquake_interval:

		earthquake_timer = 0.0

		trigger_earthquake()

		return


	# =========================================================
	# BLOOD BALL
	# =========================================================

	if ranged_attack_timer >= blood_ball_interval:

		ranged_attack_timer = 0.0

		shoot_blood_ball()

		return


	# =========================================================
	# MOVEMENT
	# =========================================================

	if player:

		# =====================================================
		# FLIP SPRITE + VOMIT AREA PENTRU MOVEMENT
		# =====================================================

		if player.global_position.x < global_position.x:

			# PLAYER ESTE ÎN STÂNGA
			# Sprite-ul original privește spre STÂNGA.
			animated_sprite.flip_h = false

			if vomit_area:
				vomit_area.position.x = (
					-vomit_area_distance_x
				)

		else:

			# PLAYER ESTE ÎN DREAPTA
			# Îl întoarcem spre DREAPTA.
			animated_sprite.flip_h = true

			if vomit_area:
				vomit_area.position.x = (
					vomit_area_distance_x
				)


		# =====================================================
		# MOVEMENT DIRECTION
		# =====================================================

		var horizontal_difference: float = (
			player.global_position.x
			- global_position.x
		)

		var horizontal_direction: float = sign(
			horizontal_difference
		)

		velocity.x = horizontal_direction * speed

		move_and_slide()


		# =====================================================
		# ANIMATION
		# =====================================================

		if abs(velocity.x) > 0.1:

			animated_sprite.play("walk")

		else:

			animated_sprite.play("idle")


# =============================================================
# EARTHQUAKE
# =============================================================

func trigger_earthquake() -> void:

	if is_dead or is_attacking:
		return

	is_attacking = true


	# =========================================================
	# BOSS BAR EFFECT
	# =========================================================

	if (
		health_bar
		and health_bar.has_method("earthquake_effect")
	):

		health_bar.earthquake_effect()


	# =========================================================
	# SOUND - EARTHQUAKE
	# =========================================================

	_play_audio(
		"res://sfx/HARDEarthquake.wav",
		8.0
	)

	earthquake_secondary_sound()


	# =========================================================
	# ANIMATION
	# =========================================================

	animated_sprite.play("earthquake")


	# =========================================================
	# DAMAGE PLAYER
	# =========================================================

	if has_node("EarthquakeArea"):

		for body in $EarthquakeArea.get_overlapping_bodies():

			if (
				body.is_in_group("player")
				and body.has_method("take_damage")
			):

				body.take_damage(
					100,
					"final_boss"
				)


	# =========================================================
	# CAMERA SHAKE
	# =========================================================

	if first_earthquake:

		apply_screen_shake(
			2.0,
			25.0
		)

		first_earthquake = false

	else:

		apply_screen_shake(
			2.0,
			15.0
		)


	await animated_sprite.animation_finished

	if is_dead:
		return


	is_attacking = false

	earthquake_timer = 0.0

	start_next_vomit()


# =============================================================
# EARTHQUAKE SECONDARY SOUND
# =============================================================

func earthquake_secondary_sound() -> void:

	await get_tree().create_timer(
		0.20
	).timeout

	if is_dead:
		return

	_play_audio(
		"res://sfx/miniEarthquake.mp3",
		5.0
	)


# =============================================================
# BLOOD BALL
# =============================================================

func shoot_blood_ball() -> void:

	if is_dead or is_attacking:
		return

	if not player:
		return

	if not is_instance_valid(player):
		return

	if not has_node("BloodBallSpawn"):
		print(
			"❌ FINAL BOSS: BloodBallSpawn NU EXISTĂ!"
		)
		return

	is_attacking = true


	# =========================================================
	# CAPTURĂM POZIȚIA PLAYERULUI EXACT LA LANSARE
	# =========================================================

	var spawn_position: Vector2 = (
		$BloodBallSpawn.global_position
	)

	var player_position_at_shot: Vector2 = (
		player.global_position
	)

	var shot_direction: Vector2 = (
		spawn_position.direction_to(
			player_position_at_shot
		)
	).normalized()


	# =========================================================
	# ANIMATION
	# =========================================================

	animated_sprite.play(
		"demon_blood_ball"
	)


	# =========================================================
	# SPAWN PROJECTILE
	# =========================================================

	var ball = BLOOD_BALL_SCENE.instantiate()

	if not ball:

		is_attacking = false
		return


	# =========================================================
	# ADAUGĂM PROIECTILUL ÎN SCENA CURENTĂ
	# =========================================================

	get_tree().current_scene.add_child(
		ball
	)


	# =========================================================
	# POZIȚIE PROIECTIL
	# =========================================================

	ball.global_position = spawn_position


	# =========================================================
	# DIRECȚIE FIXATĂ LA LANSARE
	# =============================================================
	#
	# Playerul poate fugi după aceea.
	# Blood Ball NU își schimbă direcția.
	#
	# =============================================================

	ball.direction = shot_direction


	print(
		"🩸 BLOOD BALL LANSATĂ!"
	)

	print(
		"   Spawn: ",
		spawn_position
	)

	print(
		"   Player la momentul lansării: ",
		player_position_at_shot
	)

	print(
		"   Direcție fixată: ",
		shot_direction
	)


	# =========================================================
	# AȘTEPTĂM ANIMAȚIA
	# =========================================================

	await animated_sprite.animation_finished

	if is_dead:
		return


	is_attacking = false

	start_next_vomit()


# =============================================================
# CHECK VOMIT TRIGGERS
# =============================================================

func check_vomit_triggers() -> void:

	if is_dead:
		return


	for threshold in vomit_thresholds:

		if (
			current_hp <= threshold
			and not threshold in triggered_vomits
			and not threshold in vomit_queue
		):

			triggered_vomits.append(
				threshold
			)

			vomit_queue.append(
				threshold
			)


	if not is_attacking:

		start_next_vomit()


# =============================================================
# START NEXT VOMIT
# =============================================================

func start_next_vomit() -> void:

	if is_dead:
		return

	if is_attacking:
		return

	if vomit_queue.is_empty():
		return


	vomit_queue.pop_front()

	execute_vomit_attack()


# =============================================================
# VOMIT ATTACK
# =============================================================

func execute_vomit_attack() -> void:

	if is_dead or is_attacking:
		return

	is_attacking = true


	# =========================================================
	# ORIENTARE CORECTĂ A VOMITULUI
	# =========================================================

	orient_vomit_toward_player()


	# =========================================================
	# BOSS BAR EFFECT
	# =========================================================

	if (
		health_bar
		and health_bar.has_method("vomit_effect")
	):

		health_bar.vomit_effect()


	# =========================================================
	# SOUND - VOMIT
	# =========================================================

	_play_audio(
		"res://sfx/demon_vomit.mp3",
		6.0
	)


	# =========================================================
	# ANIMATION
	# =========================================================

	animated_sprite.play(
		"demon_vomit"
	)


	# =========================================================
	# DAMAGE PLAYER
	# =========================================================

	if vomit_area:

		for body in vomit_area.get_overlapping_bodies():

			if (
				body.is_in_group("player")
				and body.has_method("take_damage")
			):

				body.take_damage(
					50,
					"final_boss"
				)


	await animated_sprite.animation_finished

	if is_dead:
		return


	is_attacking = false

	start_next_vomit()


# =============================================================
# ATTACK AREA
# =============================================================

func _on_attack_area_body_entered(
	_body: Node2D
) -> void:

	return


# =============================================================
# PUNCH
# =============================================================

func execute_punch(target: Node2D) -> void:

	if is_dead or is_attacking:
		return

	if not is_instance_valid(target):
		return

	is_attacking = true

	punch_timer = punch_cooldown


	# =========================================================
	# SOUND - PUNCH
	# =========================================================

	_play_audio(
		"res://sfx/demon_punch.mp3",
		7.0
	)


	# =========================================================
	# ANIMATION
	# =========================================================

	animated_sprite.play(
		"demon_punch"
	)


	# =========================================================
	# DAMAGE
	# =========================================================

	if target.has_method("take_damage"):

		target.take_damage(
			75,
			"final_boss"
		)


	# =========================================================
	# KNOCKBACK
	# =========================================================

	if target.has_method("apply_knockback"):

		var knockback_dir := (
			target.global_position
			- global_position
		).normalized()

		target.apply_knockback(
			knockback_dir * 800.0
		)


	await animated_sprite.animation_finished

	if is_dead:
		return


	is_attacking = false

	start_next_vomit()


# =============================================================
# BOSS TAKE DAMAGE
# =============================================================

func take_damage(amount: int) -> void:

	if is_dead or not is_active:
		return


	# =========================================================
	# REDUCE HP
	# =========================================================

	current_hp -= amount

	current_hp = clamp(
		current_hp,
		0.0,
		float(max_hp)
	)


	# =========================================================
	# UPDATE BOSS HEALTH BAR
	# =========================================================

	if (
		health_bar
		and health_bar.has_method("update_hp")
	):

		health_bar.update_hp(
			current_hp,
			amount
		)


	# =========================================================
	# BOSS HURT SOUND
	# =========================================================

	_play_audio(
		"res://sfx/demon_hurt.mp3",
		5.0
	)


	# =========================================================
	# CHECK VOMIT
	# =========================================================

	check_vomit_triggers()


	# =========================================================
	# HIT EFFECTS
	# =========================================================

	play_hit_effects(
		amount
	)


	# =========================================================
	# DEATH
	# =========================================================

	if current_hp <= 0:

		die()

	elif not is_attacking:

		animated_sprite.play(
			"take_damage"
		)


# =============================================================
# HIT EFFECTS
# =============================================================

func play_hit_effects(amount: int) -> void:

	apply_screen_shake(
		0.2,
		4.0
	)


	# =========================================================
	# RED FLASH
	# =========================================================

	if animated_sprite:

		var original_modulate = (
			animated_sprite.modulate
		)

		animated_sprite.modulate = Color(
			2.0,
			0.5,
			0.5,
			1.0
		)


		await get_tree().create_timer(
			0.1
		).timeout


		if (
			animated_sprite
			and is_instance_valid(
				animated_sprite
			)
		):

			animated_sprite.modulate = (
				original_modulate
			)


	# =========================================================
	# DAMAGE NUMBER
	# =========================================================

	spawn_floating_damage(
		amount
	)


# =============================================================
# FLOATING DAMAGE NUMBER
# =============================================================

func spawn_floating_damage(amount: int) -> void:

	var label = Label.new()

	label.text = "-" + str(amount)

	label.add_theme_font_size_override(
		"font_size",
		22
	)

	label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.2,
			0.2
		)
	)

	label.global_position = (
		global_position
		+ Vector2(
			randf_range(-20, 20),
			-50
		)
	)

	get_tree().current_scene.add_child(
		label
	)


	var tween = create_tween().set_parallel(
		true
	)

	tween.tween_property(
		label,
		"global_position:y",
		label.global_position.y - 40,
		0.6
	)

	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		0.6
	)

	tween.chain().tween_callback(
		label.queue_free
	)


# =============================================================
# BOSS DEATH
# =============================================================

func die() -> void:

	if is_dead:
		return


	# =========================================================
	# DEATH STATE
	# =========================================================

	is_dead = true
	is_active = false
	is_attacking = false

	velocity = Vector2.ZERO

	set_physics_process(false)


	# =========================================================
	# STOP LEVEL 10 MUSIC
	# =========================================================

	MusicManager.stop()

	print(
		"🎵 LEVEL MUSIC OPRITĂ PENTRU DEATH SEQUENCE!"
	)


	# =========================================================
	# FINAL BOSS SCORE
	# =========================================================

	GameState.add_score(
		666666
	)


	print(
		"🔥 FINAL BOSS UCIS! +666666 SCORE"
	)

	print(
		"SCOR CURENT: ",
		GameState.score
	)


	# =========================================================
	# COLLISION OFF
	# =========================================================

	if collision_shape:

		collision_shape.set_deferred(
			"disabled",
			true
		)


	# =========================================================
	# HIDE BOSS BAR
	# =========================================================

	if (
		health_bar
		and health_bar.has_method("hide_bar")
	):

		health_bar.hide_bar()


	# =========================================================
	# EXISTING DEATH SOUNDS
	# =========================================================

	_play_audio(
		"res://sfx/SATANICNOOODEATH.mp3",
		8.0
	)

	_play_audio(
		"res://sfx/DemonicDeath.mp3",
		8.0
	)

	_play_audio(
		"res://sfx/satanicDeath.mp3",
		8.0
	)


	# =========================================================
	# DEATH ANIMATION
	# =========================================================

	animated_sprite.play(
		"demon_death"
	)


	# =========================================================
	# FINAL SCREEN SHAKE
	# =========================================================

	apply_screen_shake(
		1.0,
		10.0
	)


	# =========================================================
	# WAIT 4 SECONDS
	# =========================================================

	print(
		"⏳ BOSS DEFEAT + PORTAL ÎN 4 SECUNDE..."
	)


	await get_tree().create_timer(
		4.0
	).timeout


	if not is_instance_valid(self):
		return


	# =========================================================
	# BOSS DEFEAT SOUNDS
	# =========================================================

	_play_audio(
		"res://sfx/bossdefeat.mp3",
		12.0
	)

	_play_audio(
		"res://sfx/bossdefeat2.mp3",
		12.0
	)


	# =========================================================
	# ACTIVATE FINAL PORTAL
	# =========================================================

	var final_portal = (
		get_tree().get_first_node_in_group(
			"final_portal"
		)
	)


	if (
		final_portal
		and is_instance_valid(final_portal)
		and final_portal.has_method("activate")
	):

		final_portal.activate()

		print(
			"🌀 FINAL PORTAL ACTIVAT DUPĂ 4 SECUNDE!"
		)

	else:

		print(
			"❌ NU AM GĂSIT FINAL PORTAL!"
		)


	# =========================================================
	# REMOVE BOSS
	# =========================================================

	queue_free()


# =============================================================
# SCREEN SHAKE
# =============================================================

func apply_screen_shake(
	duration: float,
	intensity: float
) -> void:

	if not ScreenShake.has_method("shake"):
		return


	var decay: float = 6.0


	if duration <= 0.25:

		decay = 15.0

	elif duration <= 1.0:

		decay = 7.0

	else:

		decay = 3.0


	ScreenShake.shake(
		intensity,
		decay,
		duration
	)


# =============================================================
# AUDIO
# =============================================================

func _play_audio(
	path: String,
	volume_db: float = 0.0,
	start_offset: float = 0.0
) -> void:

	var exists := ResourceLoader.exists(path)

	_log_audio(
		"[BOSS] path=%s exists=%s" % [
			path,
			exists
		]
	)

	if not exists:

		print(
			"EROARE BOSS SFX: Nu exista: ",
			path
		)

		_log_audio(
			"[BOSS] ABORT (ResourceLoader.exists=false): %s" % path
		)

		return


	var stream = load(path)

	if stream == null:

		_log_audio(
			"[BOSS] ABORT (load() null): %s" % path
		)

		return

	var asp := AudioStreamPlayer.new()

	asp.stream = stream
	asp.volume_db = volume_db
	asp.bus = "SFX"

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
		"[BOSS] OK path=%s playing=%s bus=%s vol=%s" % [
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
