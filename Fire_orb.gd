extends Area2D

@export var speed: float = 300.0
@export var damage: int = 35
@export var flyby_range: float = 500.0
@export var flyby_volume_db: float = 0.0

var target_position: Vector2
var direction: Vector2
var has_played_flyby: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var player = get_tree().get_first_node_in_group("player")

	if player:
		# Memorăm EXACT poziția playerului când se trage.
		target_position = player.global_position
		direction = global_position.direction_to(target_position)
	else:
		queue_free()
		return

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("spin")

	visible = true
	z_index = 100


func _physics_process(delta: float) -> void:
	# Merge în linie dreaptă către poziția memorată.
	# NU urmărește playerul.
	global_position += direction * speed * delta

	# Flyby:
	# se aude o singură dată când proiectilul intră
	# la maximum 500 px de player.
	if not has_played_flyby:
		var player = get_tree().get_first_node_in_group("player")

		if player:
			if global_position.distance_to(player.global_position) <= flyby_range:
				has_played_flyby = true

				_play_audio(
					"res://sfx/minibossProiectil.mp3",
					flyby_volume_db
				)

	# Dacă ajunge la poziția memorată, dispare.
	if global_position.distance_to(target_position) <= (speed * delta) + 5.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

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
