extends Area2D

@export var speed: float = 250.0
@export var damage: int = 25

var direction: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

	visible = true
	z_index = 100


func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	# Ignoră inamicii
	if body.is_in_group("enemies"):
		return

	if body.is_in_group("player"):
		_play_audio("res://sfx/impact_laser.mp3", 8.0)

		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()


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
