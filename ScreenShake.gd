extends Node

var camera: Camera2D = null
var shake_strength: float = 0.0
var shake_decay: float = 10.0
var original_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
		if camera != null:
			original_offset = camera.offset

	if camera == null:
		return

	if shake_strength > 0.1:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		camera.offset = original_offset + Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength
	else:
		shake_strength = 0.0
		camera.offset = original_offset


func shake(amount: float, decay: float = 10.0) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
		if camera != null:
			original_offset = camera.offset

	shake_strength = max(shake_strength, amount)
	shake_decay = decay


func stop() -> void:
	shake_strength = 0.0
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()

	if camera != null and is_instance_valid(camera):
		camera.offset = original_offset
