extends Node2D


var pause_menu_instance


func _ready() -> void:
	# În Level2 este permisă aruncarea scutului.
	GameState.shield_throw_unlocked = true
	print("ARUNCAREA SCUTULUI ESTE DEBLOCATA")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		open_pause_menu()


func open_pause_menu() -> void:
	const MAIN_MENU_SCENE: PackedScene = preload("res://MainMenu.tscn")
	pause_menu_instance = MAIN_MENU_SCENE.instantiate()
	pause_menu_instance.opened_from_game = true

	# Îl adăugăm în CanvasLayer ca să rămână fix pe ecran.
	$CanvasLayer.add_child(pause_menu_instance)

	get_tree().paused = true
