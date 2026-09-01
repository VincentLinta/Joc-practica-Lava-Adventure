extends Area2D

@export var float_height: float = 6.0
@export var float_speed: float = 2.5

var start_y: float
var time_passed: float = 0.0
var collected: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Dacă scutul a fost deja colectat, nu mai apare
	# după reîncărcarea nivelului.
	if GameState.has_shield:
		queue_free()
		return

	start_y = position.y
	animated_sprite.play("default")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return

	time_passed += delta
	position.y = (
		start_y
		+ sin(time_passed * float_speed) * float_height
	)


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	if not body.has_method("collect_shield"):
		return

	collected = true
	set_process(false)
	visible = false

	# Sunetul de colectare / deblocare scut
	_play_audio("res://sfx/Shield_pickup.mp3", 4.0)

	# Pornește animația de prindere pe Player.
	body.call("collect_shield")

	# Elimină obiectul de pe teren.
	queue_free()


func _play_audio(path: String, volume_db: float = 0.0) -> void:
	if not FileAccess.file_exists(path):
		print("EROARE: SUNETUL NU EXISTA: ", path)
		return

	var stream = load(path)
	if stream:
		var asp := AudioStreamPlayer.new()
		asp.stream = stream
		asp.volume_db = volume_db
		asp.bus = "Master"
		# Îl adăugăm în root ca să continue să cânte și după queue_free()
		get_tree().root.add_child(asp)
		asp.play()
		asp.finished.connect(asp.queue_free)
