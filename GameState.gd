extends Node

var score: int = 0
var total_score: int = 0
var high_score: int = 0

var last_level_delta: int = 0
var is_new_level_record: bool = false

# Scorul din run-ul curent pentru fiecare nivel.
# Îl păstrăm pentru compatibilitate cu sistemul actual.
var level_scores: Dictionary = {}

# Recordul PERMANENT pentru fiecare nivel.
var level_high_scores: Dictionary = {}

var has_shield: bool = false
var shield_throw_unlocked: bool = false

var current_level: int = 1
var unlocked_level: int = 1
var developer_mode: bool = true

var pending_transition_level: int = 1
var pending_next_level: PackedScene


func _ready() -> void:
	# RESETAREA ESTE DEZACTIVATA DEFINITIV AICI:
	# reset_all_data()

	load_saved_data()


func reset_all_data() -> void:
	score = 0
	total_score = 0
	high_score = 0

	last_level_delta = 0
	is_new_level_record = false

	level_scores.clear()
	level_high_scores.clear()

	unlocked_level = 1

	save_progress()

	print("--- SALVAREA A FOST RESETATA LA 0! ---")


func load_saved_data() -> void:
	var data: Dictionary = SaveManager.load_game()

	var saved_level: int = int(
		data.get("unlocked_level", 1)
	)

	high_score = int(
		data.get("high_score", 0)
	)

	var raw_highs = data.get(
		"level_high_scores",
		{}
	)

	level_high_scores.clear()

	for key in raw_highs:
		level_high_scores[int(key)] = int(raw_highs[key])

	# Reconstruim TOTAL SCORE din recordul fiecărui nivel.
	recalculate_total_score()

	# Păstrăm level_scores sincronizat cu recordurile
	# pentru compatibilitatea sistemului existent.
	level_scores.clear()

	for level in level_high_scores:
		level_scores[level] = level_high_scores[level]

	if developer_mode:
		unlocked_level = 10
	else:
		unlocked_level = saved_level


func save_progress() -> void:
	# NU modificăm SaveManager.
	# El continuă să păstreze și setările audio.
	SaveManager.save_game(
		unlocked_level,
		high_score,
		level_high_scores
	)


func add_score(amount: int) -> void:
	score += amount


func award_level_bonus(current_hp: int, max_hp: int) -> int:
	var bonus := 0

	if current_hp >= max_hp:
		bonus = 1000
	elif float(current_hp) > (float(max_hp) / 2.0):
		bonus = 500

	if bonus > 0:
		add_score(bonus)

	return bonus


func complete_level() -> void:
	# Scorul obținut în run-ul actual.
	var current_run_score: int = score

	# RECORDUL PERMANENT al nivelului.
	var previous_best: int = get_current_level_high_score()

	# Verificăm dacă avem record nou.
	if current_run_score > previous_best:
		level_high_scores[current_level] = current_run_score
		level_scores[current_level] = current_run_score

		last_level_delta = current_run_score - previous_best
		is_new_level_record = true
	else:
		# Recordul vechi rămâne neatins.
		level_scores[current_level] = previous_best

		last_level_delta = 0
		is_new_level_record = false

	# TOTAL = suma recordurilor unui singur nivel pentru fiecare nivel.
	recalculate_total_score()

	# High Score global = Total Score.
	high_score = total_score

	# Deblocăm următorul nivel.
	var next_level := current_level + 1

	if next_level > unlocked_level:
		unlocked_level = next_level

	# Salvăm recordurile permanente.
	save_progress()


func get_level_score_delta() -> int:
	return last_level_delta


func get_current_level_high_score() -> int:
	var key = current_level

	if level_high_scores.has(key):
		return int(
			level_high_scores[key]
		)

	if level_high_scores.has(str(key)):
		return int(
			level_high_scores[str(key)]
		)

	return 0


func recalculate_total_score() -> void:
	total_score = 0

	# Adunăm O SINGURĂ DATĂ recordul fiecărui nivel.
	for lvl in level_high_scores:
		total_score += int(
			level_high_scores[lvl]
		)

	# High Score global reprezintă totalul
	# recordurilor tuturor nivelurilor.
	high_score = total_score


func is_level_unlocked(level: int) -> bool:
	if developer_mode:
		return true

	return level <= unlocked_level


func start_level(level: int) -> void:
	if not is_level_unlocked(level):
		print(
			"NIVEL BLOCAT! Nu poti accesa Level %d"
			% level
		)
		return

	get_tree().paused = false

	current_level = level

	# RESETAM DOAR RUN-UL CURENT.
	score = 0
	last_level_delta = 0
	is_new_level_record = false

	# IMPORTANT:
	# NU resetăm:
	# total_score
	# high_score
	# level_high_scores
	#
	# Astfel restartul sau selectarea unui nivel
	# nu distruge recordurile existente.

	if level == 1:
		has_shield = false
		shield_throw_unlocked = false
	else:
		has_shield = true
		shield_throw_unlocked = true

	# MUZICA PE NIVELE
	if level >= 1 and level <= 3:
		MusicManager.change_music(
			preload(
				"res://alex-morgan-video-game-pixel-chiptune-music-583271.mp3"
			)
		)
	elif level >= 4 and level <= 6:
		MusicManager.change_music(
			preload(
				"res://viacheslavstarostin-gaming-game-video-game-music-474517.mp3"
			)
		)
	elif level >= 7 and level <= 9:
		MusicManager.change_music(
			preload(
				"res://8059346-chiptune-grooving-142242.mp3"
			)
		)
	elif level == 10:
		MusicManager.change_music(
			preload(
				"res://LEVEL10.mp3"
			)
		)

	var path := "res://Level%d.tscn" % level

	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error(
			"Level does not exist: " + path
		)
