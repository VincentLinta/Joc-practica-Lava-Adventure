extends CharacterBody2D

@export var max_health: int = 550
@export var fire_rate: float = 2.0
@export var detection_range: float = 300.0
@export var move_speed: float = 60.0
@export var patrol_distance: float = 100.0
@export var gravity: float = 900.0

# -------------------------------------------------------------
# SCENA PENTRU BOSS-UL ADEVĂRAT
# -------------------------------------------------------------
@export var final_boss_scene: PackedScene

var current_health: int
var fire_timer: float = 0.0
var player: Node2D = null
var is_dead: bool = false
var is_busy: bool = false
var can_move: bool = false

var start_position: Vector2
var move_direction: int = 1
var is_waiting: bool = false

var fire_orb_scene = preload("res://FireOrb.tscn")


func _ready() -> void:
	add_to_group("enemies")

	current_health = max_health
	start_position = global_position

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")
		$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

		if not $AnimatedSprite2D.frame_changed.is_connected(_on_frame_changed):
			$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)

	if has_node("HealthBar"):
		var hb = $HealthBar

		hb.max_value = 100
		hb.value = 100
		hb.show_percentage = false
		hb.position = Vector2(-25, -65)
		hb.size = Vector2(50, 6)

		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color("#e74c3c")
		hb.add_theme_stylebox_override("fill", fill_style)

		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color("#222222")
		hb.add_theme_stylebox_override("background", bg_style)

	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = player.global_position.x < global_position.x

	fire_timer += delta

	if fire_timer >= fire_rate:
		trigger_shoot_sequence()
		fire_timer = 0.0

	if not can_move:
		if distance_to_player <= detection_range:
			can_move = true
		else:
			velocity.x = 0
			move_and_slide()
			return

	if not is_busy and is_on_floor():
		if not is_waiting:
			if has_node("AnimatedSprite2D"):
				$AnimatedSprite2D.play("walk")

			velocity.x = move_direction * move_speed

			if abs(global_position.x - start_position.x) >= patrol_distance or is_on_wall():
				start_edge_pause()
		else:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()


func start_edge_pause() -> void:
	if is_waiting:
		return

	is_waiting = true
	velocity.x = 0

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

	await get_tree().create_timer(1.0).timeout

	if is_dead:
		return

	move_direction *= -1

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = (move_direction < 0)

	is_waiting = false


func trigger_shoot_sequence() -> void:
	if is_dead:
		return

	is_busy = true

	_play_audio("res://sfx/minibossTrage.mp3", 12.0)

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("shoot")


func _on_frame_changed() -> void:
	if not has_node("AnimatedSprite2D"):
		return

	if $AnimatedSprite2D.animation == "shoot":
		if $AnimatedSprite2D.frame == 1:
			spawn_fire_orb()


func spawn_fire_orb() -> void:
	if fire_orb_scene and has_node("Muzzle"):
		var orb = fire_orb_scene.instantiate()
		orb.global_position = $Muzzle.global_position
		get_tree().current_scene.add_child(orb)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	can_move = true
	is_busy = true

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	if has_node("HealthBar"):
		$HealthBar.value = (float(current_health) / float(max_health)) * 100.0

	if current_health <= 0:
		die()
	else:
		if has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("hurt"):
			$AnimatedSprite2D.play("hurt")


func _on_animation_finished() -> void:
	if is_dead:
		return

	if $AnimatedSprite2D.animation in ["shoot", "hurt"]:
		is_busy = false

		if has_node("AnimatedSprite2D"):
			if can_move:
				$AnimatedSprite2D.play("walk")
			else:
				$AnimatedSprite2D.play("idle")


func die() -> void:
	if is_dead:
		return

	is_dead = true

	# ==========================================
	# 1. BONUS SCORE MINI-BOSS
	# ==========================================
	GameState.add_score(3000)

	velocity = Vector2.ZERO

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	# ==========================================
	# 2. DEATH SOUNDS & ANIMAȚII
	# ==========================================
	_play_audio("res://sfx/minibossdeath1.mp3", 8.0)

	if has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("death"):
		$AnimatedSprite2D.play("death")

	await get_tree().create_timer(1.0).timeout
	_play_audio("res://sfx/minibossdeath2.mp3", -1.0)

	# ==========================================
	# 3. AȘTEPTĂM ȘI DĂM BUFF-UL PLAYERULUI
	# ==========================================
	await get_tree().create_timer(2.0).timeout

	var current_player = get_tree().get_first_node_in_group("player")
	if current_player and is_instance_valid(current_player):
		if current_player.has_method("apply_final_boss_buffs"):
			current_player.apply_final_boss_buffs()

	# ==========================================
	# 4. OPRIM MUZICA DE LEVEL 10 ȘI PORNIM MUZICA DE FINAL BOSS
	# ==========================================
	MusicManager.stop()

	if ResourceLoader.exists("res://FINAL_BOSS.mp3"):
		MusicManager.change_music(preload("res://FINAL_BOSS.mp3"), 10.0)
	else:
		print("EROARE: Nu s-a găsit FINAL_BOSS.mp3")

	# ==========================================
	# 5. SPAWN FINAL BOSS ADEVĂRAT
	# ==========================================
	if final_boss_scene:
		var boss_instance = final_boss_scene.instantiate()
		boss_instance.global_position = global_position
		get_tree().current_scene.add_child(boss_instance)
		print("FINAL BOSS A FOST SPAWNAT!")
	else:
		print("EROARE: Nu ai setat 'Final Boss Scene' în Inspector pentru Mini-Boss!")

	if has_node("AnimatedSprite2D") and $AnimatedSprite2D.is_playing():
		await $AnimatedSprite2D.animation_finished

	queue_free()


func _play_audio(
	path: String,
	volume_db: float = 0.0,
	start_offset: float = 0.0
) -> void:
	if not ResourceLoader.exists(path):
		print("EROARE: SUNETUL NU EXISTA: ", path)
		return

	var stream = load(path)
	if stream:
		var asp := AudioStreamPlayer.new()
		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "SFX"

		get_tree().root.add_child(asp)
		asp.play(start_offset)
		asp.finished.connect(asp.queue_free)
