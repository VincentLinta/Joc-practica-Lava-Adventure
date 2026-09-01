extends Node2D


var pause_menu_instance: Control = null


func _ready() -> void:
	# Level 8 folosește aceleași reguli de bază
	# ca celelalte niveluri.
	#
	# Nu punem aici nimic legat de TutorialUI.
	pass


func _unhandled_input(event: InputEvent) -> void:
	# ESC / ui_cancel deschide meniul de pauză
	# numai atunci când jocul nu este deja paused.
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		open_pause_menu()


func open_pause_menu() -> void:
	# Nu permitem mai multe meniuri simultan.
	if is_instance_valid(pause_menu_instance):
		return


	const MAIN_MENU_SCENE: PackedScene = preload(
		"res://MainMenu.tscn"
	)


	# Instanțiem exact același MainMenu folosit
	# în Level 1 și Level 2.
	pause_menu_instance = MAIN_MENU_SCENE.instantiate() as Control


	if pause_menu_instance == null:
		push_error(
			"Level8.gd: MainMenu.tscn nu a putut fi instanțiat."
		)
		return


	# Spunem MainMenu-ului că a fost deschis
	# din timpul jocului.
	pause_menu_instance.opened_from_game = true


	# =========================================================
	# FOLOSIM CANVASLAYER-UL NORMAL AL LEVEL 8
	# =========================================================
	#
	# Acesta este CanvasLayer-ul care conține HealthBar.
	#
	# NU TutorialUI.
	# =========================================================

	var canvas_layer := get_node_or_null(
		"CanvasLayer"
	) as CanvasLayer


	if canvas_layer == null:
		push_error(
			"Level8.gd: Nu am găsit CanvasLayer-ul HUD în Level8."
		)

		pause_menu_instance.queue_free()
		pause_menu_instance = null

		return


	# Meniul devine copil al CanvasLayer-ului HUD,
	# exact ca în Level1/Level2.
	canvas_layer.add_child(pause_menu_instance)


	# MainMenu.gd are deja:
	#
	# process_mode = Node.PROCESS_MODE_ALWAYS
	#
	# deci poate funcționa și după ce jocul este paused.


	# Punem jocul pe pauză după ce meniul a fost adăugat.
	get_tree().paused = true


	# Consumăm evenimentul ESC aici.
	# Nu îl lăsăm să mai fie procesat de alte noduri.
	get_viewport().set_input_as_handled()
