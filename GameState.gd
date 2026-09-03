extends Node


var score: int = 0
var total_score: int = 0
var high_score: int = 0

var last_level_delta: int = 0
var is_new_level_record: bool = false


# =============================================================
# SCORURI PE NIVEL
# =============================================================

# Scorul din run-ul curent pentru fiecare nivel.
# Îl păstrăm pentru compatibilitate cu sistemul actual.
var level_scores: Dictionary = {}

# Recordul PERMANENT pentru fiecare nivel.
var level_high_scores: Dictionary = {}


# =============================================================
# SHIELD
# =============================================================

var has_shield: bool = false
var shield_throw_unlocked: bool = false


# =============================================================
# LEVEL STATE
# =============================================================

var current_level: int = 1
var unlocked_level: int = 1


# =============================================================
# DEVELOPER MODE
# =============================================================
#
# FALSE = progresie reală.
#
# Nivelurile se deblochează numai după completarea nivelului
# precedent și rămân salvate în save.cfg.
# =============================================================

var developer_mode: bool = false


# =============================================================
# LEVEL TRANSITION
# =============================================================

var pending_transition_level: int = 1
var pending_next_level: PackedScene


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# ---------------------------------------------------------
	# RESETAREA ESTE DEZACTIVATA DEFINITIV AICI
	# ---------------------------------------------------------

	# reset_all_data()

	load_saved_data()


# =============================================================
# RESET ALL DATA
# =============================================================

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

	print(
		"--- SALVAREA A FOST RESETATA LA 0! ---"
	)


# =============================================================
# LOAD SAVED DATA
# =============================================================

func load_saved_data() -> void:

	var data: Dictionary = SaveManager.load_game()


	# ---------------------------------------------------------
	# UNLOCKED LEVEL
	# ---------------------------------------------------------

	var saved_level: int = int(
		data.get(
			"unlocked_level",
			1
		)
	)


	# ---------------------------------------------------------
	# GLOBAL HIGH SCORE
	# ---------------------------------------------------------

	high_score = int(
		data.get(
			"high_score",
			0
		)
	)


	# ---------------------------------------------------------
	# LEVEL HIGH SCORES
	# ---------------------------------------------------------

	var raw_highs = data.get(
		"level_high_scores",
		{}
	)

	level_high_scores.clear()


	for key in raw_highs:

		level_high_scores[int(key)] = int(
			raw_highs[key]
		)


	# ---------------------------------------------------------
	# RECONSTRUIRE TOTAL SCORE
	# ---------------------------------------------------------

	recalculate_total_score()


	# ---------------------------------------------------------
	# SINCRONIZARE LEVEL SCORES
	# ---------------------------------------------------------

	level_scores.clear()


	for level in level_high_scores:

		level_scores[level] = level_high_scores[level]


	# ---------------------------------------------------------
	# DEVELOPER MODE OFF
	# ---------------------------------------------------------

	if developer_mode:

		unlocked_level = 10

	else:

		unlocked_level = saved_level


# =============================================================
# SAVE PROGRESS
# =============================================================

func save_progress() -> void:

	# NU modificăm SaveManager.
	# El continuă să păstreze și setările audio.

	SaveManager.save_game(
		unlocked_level,
		high_score,
		level_high_scores
	)


# =============================================================
# ADD SCORE
# =============================================================

func add_score(amount: int) -> void:

	score += amount


# =============================================================
# LEVEL BONUS
# =============================================================

func award_level_bonus(
	current_hp: int,
	max_hp: int
) -> int:

	var bonus := 0


	if current_hp >= max_hp:

		bonus = 1000

	elif float(current_hp) > (
		float(max_hp) / 2.0
	):

		bonus = 500


	if bonus > 0:

		add_score(bonus)


	return bonus


# =============================================================
# COMPLETE LEVEL
# =============================================================

func complete_level() -> void:

	# ---------------------------------------------------------
	# SCORUL DIN RUN-UL ACTUAL
	# ---------------------------------------------------------

	var current_run_score: int = score


	# ---------------------------------------------------------
	# RECORDUL PERMANENT
	# ---------------------------------------------------------

	var previous_best: int = (
		get_current_level_high_score()
	)


	# ---------------------------------------------------------
	# RECORD NOU
	# ---------------------------------------------------------

	if current_run_score > previous_best:

		level_high_scores[current_level] = (
			current_run_score
		)

		level_scores[current_level] = (
			current_run_score
		)

		last_level_delta = (
			current_run_score
			- previous_best
		)

		is_new_level_record = true


	else:

		# Recordul vechi rămâne neatins.

		level_scores[current_level] = (
			previous_best
		)

		last_level_delta = 0
		is_new_level_record = false


	# ---------------------------------------------------------
	# TOTAL SCORE
	# ---------------------------------------------------------

	recalculate_total_score()


	# ---------------------------------------------------------
	# GLOBAL HIGH SCORE
	# ---------------------------------------------------------

	high_score = total_score


	# ---------------------------------------------------------
	# DEBLOCARE URMĂTOR NIVEL
	# ---------------------------------------------------------
	#
	# Level 10 este ultimul nivel.
	# Nu permitem niciodată deblocarea Level 11.
	# ---------------------------------------------------------

	if current_level < 10:

		var next_level: int = current_level + 1

		if next_level > unlocked_level:

			unlocked_level = next_level

	else:

		unlocked_level = min(
			unlocked_level,
			10
		)


	# ---------------------------------------------------------
	# SAVE
	# ---------------------------------------------------------

	save_progress()


# =============================================================
# GET LEVEL SCORE DELTA
# =============================================================

func get_level_score_delta() -> int:

	return last_level_delta


# =============================================================
# GET CURRENT LEVEL HIGH SCORE
# =============================================================

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


# =============================================================
# RECALCULATE TOTAL SCORE
# =============================================================

func recalculate_total_score() -> void:

	total_score = 0


	# ---------------------------------------------------------
	# ADUNĂM O SINGURĂ DATĂ RECORDUL FIECĂRUI NIVEL
	# ---------------------------------------------------------

	for lvl in level_high_scores:

		total_score += int(
			level_high_scores[lvl]
		)


	# ---------------------------------------------------------
	# GLOBAL HIGH SCORE
	# ---------------------------------------------------------

	high_score = total_score


# =============================================================
# IS LEVEL UNLOCKED
# =============================================================

func is_level_unlocked(level: int) -> bool:

	if developer_mode:

		return true


	return level <= unlocked_level


# =============================================================
# START LEVEL
# =============================================================

func start_level(level: int) -> void:

	# ---------------------------------------------------------
	# VERIFICARE LEVEL LOCKED
	# ---------------------------------------------------------

	if not is_level_unlocked(level):

		print(
			"NIVEL BLOCAT! Nu poti accesa Level %d"
			% level
		)

		return


	# ---------------------------------------------------------
	# RESET PAUSE
	# ---------------------------------------------------------

	get_tree().paused = false


	# ---------------------------------------------------------
	# CURRENT LEVEL
	# ---------------------------------------------------------

	current_level = level


	# ---------------------------------------------------------
	# RESET RUN SCORE
	# ---------------------------------------------------------

	score = 0

	last_level_delta = 0
	is_new_level_record = false


	# ---------------------------------------------------------
	# NU RESETĂM RECORDURILE PERMANENTE
	# ---------------------------------------------------------
	#
	# NU resetăm:
	# total_score
	# high_score
	# level_high_scores
	#
	# Astfel restartul sau selectarea unui nivel
	# nu distruge recordurile existente.
	# ---------------------------------------------------------


	# ---------------------------------------------------------
	# SHIELD
	# ---------------------------------------------------------

	if level == 1:

		has_shield = false
		shield_throw_unlocked = false

	else:

		has_shield = true
		shield_throw_unlocked = true


	# =========================================================
	# MUZICA PE NIVELE
	# =========================================================

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


	# =========================================================
	# LOAD SCENE
	# =========================================================

	var path := (
		"res://Level%d.tscn"
		% level
	)


	if ResourceLoader.exists(path):

		get_tree().change_scene_to_file(
			path
		)

	else:

		push_error(
			"Level does not exist: "
			+ path
		)
