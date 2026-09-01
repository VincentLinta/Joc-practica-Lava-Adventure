extends CharacterBody2D

@export var gravity: float = 900.0
@export var max_health: int = 60
@export var attack_damage: int = 25
@export var attack_cooldown: float = 2.0

@export var attack_range_x: float = 90.0
@export var attack_range_y: float = 60.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = 0
var cooldown_left: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	anim.play("idle")

	health_bar.position = Vector2(-16, -28)
	health_bar.size = Vector2(32, 5)

	setup_health_bar_style()
	update_health_bar()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = 0.0
	move_and_slide()

	if cooldown_left > 0.0:
		cooldown_left -= delta

	var player_node: Node = get_tree().get_first_node_in_group("player")

	if player_node == null:
		return

	var player: Node2D = player_node as Node2D

	if player == null:
		return

	var distance_x: float = absf(
		player.global_position.x - global_position.x
	)

	var distance_y: float = absf(
		player.global_position.y - global_position.y
	)

	var player_in_range: bool = (
		distance_x <= attack_range_x
		and distance_y <= attack_range_y
	)

	if player_in_range and cooldown_left <= 0.0:
		cooldown_left = attack_cooldown
		attack_player(player)


func attack_player(player: Node2D) -> void:
	if is_dead or not is_instance_valid(player):
		return

	anim.play("attack")
	_play_audio("res://sfx/Enemy Melee Attack.mp3", 12.0)

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
		print(
			"ELECTRIC: atac direct, ",
			attack_damage,
			" damage."
		)
	else:
		print("EROARE: Player nu are take_damage().")

	await get_tree().create_timer(0.45).timeout

	if not is_queued_for_deletion() and not is_dead:
		anim.play("idle")


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	health = clampi(health, 0, max_health)

	print(">>> ELECTRIC LOVIT: ", name, " | HP: ", health, " | POS: ", global_position)

	update_health_bar()

	if health <= 0:
		is_dead = true
		print("!!! ELECTRIC DIED: ", name, " | POS: ", global_position)
		GameState.add_score(50)
		queue_free()


func update_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = health > 0


func setup_health_bar_style() -> void:
	health_bar.show_percentage = false

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.05, 0.05, 0.05)
	background_style.corner_radius_top_left = 2
	background_style.corner_radius_top_right = 2
	background_style.corner_radius_bottom_left = 2
	background_style.corner_radius_bottom_right = 2

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 1.0, 0.2)
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2

	health_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	health_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)


func _play_audio(path: String, volume_db: float = 0.0, start_offset: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
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
