extends GutTest


# =============================================================
# MOCK PLAYER
# Folosit pentru verificarea damage / knockback.
# =============================================================

class MockPlayer extends Node2D:

	var damages: Array = []
	var knockbacks: Array = []

	func take_damage(
		amount: int,
		source: String = ""
	) -> void:

		damages.append({
			"amount": amount,
			"source": source
		})

	func apply_knockback(
		force: Vector2
	) -> void:

		knockbacks.append(force)


# =============================================================
# MOCK BUFF PLAYER
# Folosit strict pentru integrarea:
# TurretGuardian death -> apply_final_boss_buffs()
# =============================================================

class MockBuffPlayer extends Node2D:

	var max_health: int = 200
	var health: int = 200
	var final_boss_shield: int = 0
	var final_boss_damage_multiplier: float = 1.0
	var buff_called: bool = false

	func apply_final_boss_buffs() -> void:

		buff_called = true
		health = max_health
		final_boss_shield = 777
		final_boss_damage_multiplier = 2.0


# =============================================================
# MOCK PHYSICS PLAYER
# CharacterBody2D real pentru get_overlapping_bodies().
# =============================================================

class MockPhysicsPlayer extends CharacterBody2D:

	var health: int = 200
	var damages: Array = []
	var knockbacks: Array = []

	func take_damage(
		amount: int,
		source: String = ""
	) -> void:

		health = max(
			health - amount,
			0
		)

		damages.append({
			"amount": amount,
			"source": source
		})

	func apply_knockback(
		force: Vector2
	) -> void:

		knockbacks.append(force)


# =============================================================
# MOCK BOSS
# Nu porneste BossFinal-ul real.
# =============================================================

class MockBoss extends Node:

	var start_called: bool = false

	func start_boss_fight() -> void:
		start_called = true


# =============================================================
# SAVE BACKUP
# =============================================================

var original_save_exists: bool = false
var original_save_data: PackedByteArray


# =============================================================
# SETUP
# =============================================================

func before_each() -> void:

	# ---------------------------------------------------------
	# GAME STATE
	# ---------------------------------------------------------

	GameState.developer_mode = false
	GameState.current_level = 1
	GameState.unlocked_level = 1

	GameState.score = 0
	GameState.total_score = 0
	GameState.high_score = 0

	GameState.last_level_delta = 0
	GameState.is_new_level_record = false

	GameState.level_scores.clear()
	GameState.level_high_scores.clear()

	GameState.has_shield = false
	GameState.shield_throw_unlocked = false

	# ---------------------------------------------------------
	# SAVE BACKUP
	# ---------------------------------------------------------

	original_save_exists = FileAccess.file_exists(
		SaveManager.SAVE_PATH
	)

	original_save_data = PackedByteArray()

	if original_save_exists:

		var file := FileAccess.open(
			SaveManager.SAVE_PATH,
			FileAccess.READ
		)

		assert_not_null(
			file,
			"Save-ul existent trebuie sa poata fi deschis."
		)

		if file != null:

			original_save_data = file.get_buffer(
				file.get_length()
			)

			file.close()

	# ---------------------------------------------------------
	# AUDIO CLEANUP
	# ---------------------------------------------------------

	if SFXManager.slider_player != null:
		SFXManager.stop_slider_sound()

	if SFXManager.sfx_player != null:
		SFXManager.sfx_player.stop()

	# ---------------------------------------------------------
	# TIME SCALE
	# ---------------------------------------------------------

	Engine.time_scale = 1.0


# =============================================================
# RESTAURARE DUPA FIECARE TEST
# =============================================================

func after_each() -> void:

	Engine.time_scale = 1.0

	# ---------------------------------------------------------
	# RESTORE SAVE
	# ---------------------------------------------------------

	var global_path := ProjectSettings.globalize_path(
		SaveManager.SAVE_PATH
	)

	if original_save_exists:

		var file := FileAccess.open(
			SaveManager.SAVE_PATH,
			FileAccess.WRITE
		)

		assert_not_null(
			file,
			"Save-ul original trebuie sa poata fi restaurat."
		)

		if file != null:

			file.store_buffer(
				original_save_data
			)

			file.close()

	else:

		if FileAccess.file_exists(
			SaveManager.SAVE_PATH
		):

			DirAccess.remove_absolute(
				global_path
			)

	# ---------------------------------------------------------
	# AUDIO CLEANUP
	# ---------------------------------------------------------

	if SFXManager.slider_player != null:
		SFXManager.stop_slider_sound()

	if SFXManager.sfx_player != null:
		SFXManager.sfx_player.stop()

	if MusicManager:
		MusicManager.stop()


# =============================================================
# 1. GAME STATE
# LOCK / UNLOCK / DEVELOPER MODE / LIMITE
# =============================================================

func test_game_state_unlock_and_boundaries() -> void:

	# ---------------------------------------------------------
	# NORMAL MODE
	# ---------------------------------------------------------

	GameState.developer_mode = false
	GameState.unlocked_level = 1

	assert_true(
		GameState.is_level_unlocked(1),
		"Level 1 trebuie sa fie unlocked."
	)

	for level in range(2, 11):

		assert_false(
			GameState.is_level_unlocked(level),
			"Level %d trebuie sa fie locked la progres 1."
			% level
		)

	GameState.unlocked_level = 5

	assert_true(
		GameState.is_level_unlocked(5),
		"Level-ul exact egal cu unlocked_level trebuie sa fie unlocked."
	)

	assert_true(
		GameState.is_level_unlocked(3),
		"Level-urile mai mici trebuie sa fie unlocked."
	)

	assert_false(
		GameState.is_level_unlocked(6),
		"Level-ul imediat urmator trebuie sa ramana locked."
	)

	GameState.unlocked_level = 10

	assert_true(
		GameState.is_level_unlocked(10),
		"Level 10 trebuie sa fie unlocked."
	)

	assert_false(
		GameState.is_level_unlocked(11),
		"Level 11 nu trebuie sa fie unlocked."
	)

	# ---------------------------------------------------------
	# DEVELOPER MODE
	# ---------------------------------------------------------

	GameState.developer_mode = true
	GameState.unlocked_level = 1

	for level in range(1, 11):

		assert_true(
			GameState.is_level_unlocked(level),
			"Developer mode trebuie sa permita Level %d."
			% level
		)

	assert_true(
		GameState.is_level_unlocked(11),
		"Developer mode permite acces numeric la Level 11 conform logicii actuale."
	)

	GameState.developer_mode = false
	GameState.unlocked_level = 1

	assert_true(
		GameState.is_level_unlocked(1),
		"Level 1 trebuie sa ramana accesibil."
	)

	assert_false(
		GameState.is_level_unlocked(10),
		"Level 10 trebuie sa fie locked fara progres."
	)


# =============================================================
# 2. SCORE + BONUSURI
# ADD SCORE + EDGE CASE + LEVEL BONUS
# =============================================================

func test_score_and_bonus_rules() -> void:

	# ---------------------------------------------------------
	# ADD SCORE
	# ---------------------------------------------------------

	GameState.score = 0

	GameState.add_score(100)
	GameState.add_score(250)
	GameState.add_score(50)

	assert_eq(
		GameState.score,
		400,
		"add_score trebuie sa cumuleze corect scorurile."
	)

	GameState.add_score(0)

	assert_eq(
		GameState.score,
		400,
		"add_score(0) nu trebuie sa modifice scorul."
	)

	# ---------------------------------------------------------
	# BONUS FULL HP
	# ---------------------------------------------------------

	GameState.score = 0

	var full_bonus := GameState.award_level_bonus(
		200,
		200
	)

	assert_eq(
		full_bonus,
		1000,
		"Full HP trebuie sa ofere bonus 1000."
	)

	assert_eq(
		GameState.score,
		1000,
		"Bonusul 1000 trebuie adaugat la score."
	)

	# ---------------------------------------------------------
	# BONUS > 50%
	# ---------------------------------------------------------

	GameState.score = 0

	var above_half_bonus := GameState.award_level_bonus(
		150,
		200
	)

	assert_eq(
		above_half_bonus,
		500,
		"Mai mult de 50% HP trebuie sa ofere bonus 500."
	)

	assert_eq(
		GameState.score,
		500,
		"Bonusul 500 trebuie adaugat la score."
	)

	# ---------------------------------------------------------
	# EXACT 50% + SUB 50%
	# ---------------------------------------------------------

	GameState.score = 0

	var half_bonus := GameState.award_level_bonus(
		100,
		200
	)

	assert_eq(
		half_bonus,
		0,
		"La exact 50% HP nu trebuie oferit bonus."
	)

	var low_bonus := GameState.award_level_bonus(
		50,
		200
	)

	assert_eq(
		low_bonus,
		0,
		"Sub 50% HP nu trebuie oferit bonus."
	)

	assert_eq(
		GameState.score,
		0,
		"Scorul nu trebuie modificat sub pragul de bonus."
	)


# =============================================================
# 3. HIGH SCORE + TOTAL SCORE + DELTA
# =============================================================

func test_high_score_total_and_delta() -> void:

	# ---------------------------------------------------------
	# LOOKUP
	# ---------------------------------------------------------

	GameState.current_level = 3
	GameState.level_high_scores.clear()

	GameState.level_high_scores[3] = 750

	assert_eq(
		GameState.get_current_level_high_score(),
		750,
		"Trebuie returnat high score-ul nivelului curent."
	)

	GameState.level_high_scores.clear()
	GameState.level_high_scores["3"] = 900

	assert_eq(
		GameState.get_current_level_high_score(),
		900,
		"Trebuie suportata si cheia string."
	)

	GameState.current_level = 5
	GameState.level_high_scores.clear()

	assert_eq(
		GameState.get_current_level_high_score(),
		0,
		"Un nivel fara record trebuie sa returneze 0."
	)

	# ---------------------------------------------------------
	# TOTAL
	# ---------------------------------------------------------

	GameState.level_high_scores[1] = 100
	GameState.level_high_scores[2] = 250
	GameState.level_high_scores[3] = 500
	GameState.level_high_scores[4] = 1250

	GameState.recalculate_total_score()

	assert_eq(
		GameState.total_score,
		2100,
		"Total score trebuie sa fie suma recordurilor."
	)

	assert_eq(
		GameState.high_score,
		2100,
		"High score global trebuie sa urmeze total score."
	)

	GameState.level_high_scores[2] = 600

	GameState.recalculate_total_score()

	assert_eq(
		GameState.total_score,
		2450,
		"Total score trebuie recalculat corect."
	)

	assert_eq(
		GameState.high_score,
		2450,
		"High score trebuie recalculat corect."
	)

	# ---------------------------------------------------------
	# DELTA
	# ---------------------------------------------------------

	GameState.last_level_delta = 375

	assert_eq(
		GameState.get_level_score_delta(),
		375,
		"get_level_score_delta() trebuie sa returneze delta."
	)

	GameState.last_level_delta = 0

	assert_eq(
		GameState.get_level_score_delta(),
		0,
		"Delta 0 trebuie returnata corect."
	)


# =============================================================
# 4. COMPLETE LEVEL
# RECORD NOU + RECORD EGAL + RECORD MAI MIC
# + UNLOCK + LEVEL 10
# =============================================================

func test_complete_level_all_score_cases() -> void:

	# ---------------------------------------------------------
	# RECORD NOU + UNLOCK
	# ---------------------------------------------------------

	GameState.current_level = 3
	GameState.score = 1200
	GameState.unlocked_level = 3

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.complete_level()

	assert_eq(
		GameState.level_high_scores[3],
		1200,
		"Scorul nou trebuie salvat ca record."
	)

	assert_eq(
		GameState.level_scores[3],
		1200,
		"level_scores trebuie actualizat."
	)

	assert_eq(
		GameState.last_level_delta,
		1200,
		"Primul record trebuie sa aiba delta 1200."
	)

	assert_true(
		GameState.is_new_level_record,
		"Primul record trebuie marcat ca record nou."
	)

	assert_eq(
		GameState.total_score,
		1200,
		"Total score trebuie sa includa noul record."
	)

	assert_eq(
		GameState.high_score,
		1200,
		"High score trebuie actualizat."
	)

	assert_eq(
		GameState.unlocked_level,
		4,
		"Level 3 trebuie sa deblocheze Level 4."
	)

	# ---------------------------------------------------------
	# RECORD EGAL
	# ---------------------------------------------------------

	GameState.current_level = 5
	GameState.score = 2000
	GameState.unlocked_level = 5

	GameState.level_high_scores.clear()
	GameState.level_high_scores[5] = 2000

	GameState.complete_level()

	assert_eq(
		GameState.level_high_scores[5],
		2000,
		"Scorul egal nu trebuie sa schimbe recordul."
	)

	assert_eq(
		GameState.last_level_delta,
		0,
		"Scorul egal trebuie sa aiba delta 0."
	)

	assert_false(
		GameState.is_new_level_record,
		"Scorul egal nu este record nou."
	)

	# ---------------------------------------------------------
	# RECORD MAI MIC
	# ---------------------------------------------------------

	GameState.current_level = 6
	GameState.score = 700
	GameState.unlocked_level = 6

	GameState.level_high_scores.clear()
	GameState.level_high_scores[6] = 1000

	GameState.complete_level()

	assert_eq(
		GameState.level_high_scores[6],
		1000,
		"Recordul vechi trebuie pastrat."
	)

	assert_eq(
		GameState.last_level_delta,
		0,
		"Scorul mai mic trebuie sa aiba delta 0."
	)

	assert_false(
		GameState.is_new_level_record,
		"Scorul mai mic nu este record nou."
	)

	# ---------------------------------------------------------
	# TOTAL + DELTA
	# ---------------------------------------------------------

	GameState.current_level = 7
	GameState.score = 900
	GameState.unlocked_level = 7

	GameState.level_high_scores.clear()

	GameState.level_high_scores[1] = 100
	GameState.level_high_scores[2] = 200
	GameState.level_high_scores[3] = 300

	GameState.complete_level()

	assert_eq(
		GameState.total_score,
		1500,
		"Totalul trebuie sa fie 100+200+300+900."
	)

	assert_eq(
		GameState.high_score,
		1500,
		"High score trebuie sa fie 1500."
	)

	GameState.current_level = 8
	GameState.score = 1800
	GameState.unlocked_level = 8

	GameState.level_high_scores.clear()
	GameState.level_high_scores[8] = 1200

	GameState.complete_level()

	assert_eq(
		GameState.get_level_score_delta(),
		600,
		"Delta trebuie sa fie 600 cand recordul creste."

	)

	# ---------------------------------------------------------
	# LEVEL 10
	# ---------------------------------------------------------

	GameState.current_level = 10
	GameState.unlocked_level = 10
	GameState.score = 6666

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.complete_level()

	assert_eq(
		GameState.current_level,
		10,
		"Completarea Level 10 nu trebuie sa schimbe current_level."
	)

	assert_eq(
		GameState.unlocked_level,
		10,
		"Level 10 nu trebuie sa deblocheze Level 11."
	)

	assert_true(
		GameState.level_high_scores.has(10),
		"Recordul Level 10 trebuie inregistrat."
	)

	assert_eq(
		GameState.level_high_scores[10],
		6666,
		"Recordul Level 10 trebuie sa fie 6666."
	)


# =============================================================
# 5. LOAD / RESET / LOCKED START / SHIELD STATE
# =============================================================

func test_game_state_load_reset_and_level_rules() -> void:

	# ---------------------------------------------------------
	# LOAD DATA
	# ---------------------------------------------------------

	GameState.load_saved_data()

	assert_eq(
		typeof(GameState.unlocked_level),
		TYPE_INT,
		"unlocked_level trebuie sa fie int."
	)

	assert_eq(
		typeof(GameState.high_score),
		TYPE_INT,
		"high_score trebuie sa fie int."
	)

	assert_eq(
		typeof(GameState.total_score),
		TYPE_INT,
		"total_score trebuie sa fie int."
	)

	assert_eq(
		typeof(GameState.level_high_scores),
		TYPE_DICTIONARY,
		"level_high_scores trebuie sa fie Dictionary."
	)

	assert_eq(
		typeof(GameState.level_scores),
		TYPE_DICTIONARY,
		"level_scores trebuie sa fie Dictionary."
	)

	# ---------------------------------------------------------
	# RESET
	# ---------------------------------------------------------

	GameState.score = 9999
	GameState.total_score = 9999
	GameState.high_score = 9999
	GameState.unlocked_level = 10

	GameState.level_scores[1] = 500
	GameState.level_high_scores[1] = 1000

	GameState.reset_all_data()

	assert_eq(
		GameState.score,
		0,
		"reset_all_data() trebuie sa reseteze score."
	)

	assert_eq(
		GameState.total_score,
		0,
		"reset_all_data() trebuie sa reseteze total score."
	)

	assert_eq(
		GameState.high_score,
		0,
		"reset_all_data() trebuie sa reseteze high score."
	)

	assert_eq(
		GameState.unlocked_level,
		1,
		"reset_all_data() trebuie sa revina la Level 1."
	)

	assert_true(
		GameState.level_scores.is_empty(),
		"level_scores trebuie golit."
	)

	assert_true(
		GameState.level_high_scores.is_empty(),
		"level_high_scores trebuie golit."
	)

	# ---------------------------------------------------------
	# LOCKED START
	# ---------------------------------------------------------

	GameState.developer_mode = false
	GameState.unlocked_level = 2
	GameState.current_level = 2
	GameState.score = 500
	GameState.last_level_delta = 100
	GameState.is_new_level_record = true

	GameState.start_level(5)

	assert_eq(
		GameState.current_level,
		2,
		"Level locked nu trebuie sa schimbe current_level."
	)

	assert_eq(
		GameState.score,
		500,
		"Level locked nu trebuie sa schimbe score."
	)

	assert_eq(
		GameState.last_level_delta,
		100,
		"Level locked nu trebuie sa schimbe delta."
	)

	assert_true(
		GameState.is_new_level_record,
		"Level locked nu trebuie sa schimbe flag-ul."
	)

	# ---------------------------------------------------------
	# SHIELD RULES
	# ---------------------------------------------------------

	GameState.current_level = 1
	GameState.has_shield = false
	GameState.shield_throw_unlocked = false

	assert_false(
		GameState.has_shield,
		"Level 1 nu trebuie sa porneasca cu shield."
	)

	assert_false(
		GameState.shield_throw_unlocked,
		"Shield throw nu trebuie sa fie unlocked pe Level 1."
	)

	GameState.current_level = 2
	GameState.has_shield = true
	GameState.shield_throw_unlocked = true

	assert_true(
		GameState.has_shield,
		"Level 2 trebuie sa aiba shield."
	)

	assert_true(
		GameState.shield_throw_unlocked,
		"Shield throw trebuie sa fie unlocked din Level 2."
	)

	GameState.current_level = 10
	GameState.has_shield = true
	GameState.shield_throw_unlocked = true

	assert_true(
		GameState.has_shield,
		"Level 10 trebuie sa aiba shield."
	)

	assert_true(
		GameState.shield_throw_unlocked,
		"Shield throw trebuie sa fie unlocked pe Level 10."
	)


# =============================================================
# 6. PLAYER
# INITIAL STATE + DAMAGE + DEAD STATE
# =============================================================

func test_player_core_behaviour() -> void:

	var player_scene := load(
		"res://Player.tscn"
	)

	assert_not_null(
		player_scene,
		"Player.tscn trebuie sa existe."
	)

	var player = player_scene.instantiate()
	add_child_autofree(player)

	# ---------------------------------------------------------
	# INITIAL
	# ---------------------------------------------------------

	assert_eq(
		player.max_health,
		200,
		"Player max_health trebuie sa fie 200."
	)

	assert_eq(
		player.health,
		200,
		"Player health initial trebuie sa fie 200."
	)

	assert_eq(
		player.attack_damage,
		25,
		"Player attack_damage trebuie sa fie 25."
	)

	assert_true(
		player.is_in_group("player"),
		"Player-ul trebuie sa fie in group-ul player."
	)

	# ---------------------------------------------------------
	# NORMAL DAMAGE + ZERO
	# ---------------------------------------------------------

	player.health = 200
	player.is_dead = false
	GameState.has_shield = false

	player.take_damage(25)

	assert_eq(
		player.health,
		175,
		"25 damage trebuie sa lase 175 HP."
	)

	player.take_damage(50)

	assert_eq(
		player.health,
		125,
		"Damage-ul consecutiv trebuie sa se acumuleze."
	)

	player.take_damage(0)

	assert_eq(
		player.health,
		125,
		"0 damage nu trebuie sa schimbe HP."
	)

	# ---------------------------------------------------------
	# DEAD PLAYER
	# ---------------------------------------------------------

	player.health = 100
	player.is_dead = true
	GameState.has_shield = false

	player.take_damage(9999)

	assert_eq(
		player.health,
		100,
		"Player-ul mort nu trebuie sa mai primeasca damage."
	)


# =============================================================
# 7. PLAYER FINAL BOSS BUFF
# + REAPLICARE
# =============================================================

func test_player_final_boss_buff_behaviour() -> void:

	var player_scene := load(
		"res://Player.tscn"
	)

	assert_not_null(
		player_scene,
		"Player.tscn trebuie sa existe."
	)

	var player = player_scene.instantiate()
	add_child_autofree(player)

	# ---------------------------------------------------------
	# FIRST APPLICATION
	# ---------------------------------------------------------

	player.health = 50
	player.final_boss_shield = 0
	player.final_boss_damage_multiplier = 1.0

	player.apply_final_boss_buffs()

	assert_eq(
		player.health,
		player.max_health,
		"Buff-ul Final Boss trebuie sa refaca HP-ul la maxim."
	)

	assert_eq(
		player.final_boss_shield,
		777,
		"Final Boss shield trebuie sa fie 777."
	)

	assert_eq(
		player.final_boss_damage_multiplier,
		2.0,
		"Final Boss damage multiplier trebuie sa fie 2.0."
	)

	# ---------------------------------------------------------
	# REAPPLICATION
	# ---------------------------------------------------------

	var first_shield := int(
		player.final_boss_shield
	)

	var first_multiplier := float(
		player.final_boss_damage_multiplier
	)

	player.health = 25

	player.apply_final_boss_buffs()

	assert_eq(
		player.final_boss_shield,
		first_shield,
		"Reaplicarea nu trebuie sa schimbe shield-ul."
	)

	assert_eq(
		player.final_boss_damage_multiplier,
		first_multiplier,
		"Reaplicarea nu trebuie sa schimbe multiplier-ul."
	)

	assert_eq(
		player.health,
		player.max_health,
		"Reaplicarea trebuie sa refaca HP-ul."
	)


# =============================================================
# 8. SAVE / LOAD
# DEFAULT + PROGRESS + MULTIPLE SCORES + OVERWRITE
# =============================================================

func test_save_load_progress_and_edge_cases() -> void:

	# ---------------------------------------------------------
	# DEFAULT / MISSING SAVE
	# ---------------------------------------------------------

	if FileAccess.file_exists(
		SaveManager.SAVE_PATH
	):

		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				SaveManager.SAVE_PATH
			)
		)

	var default_data: Dictionary = (
		SaveManager.load_game()
	)

	assert_eq(
		default_data["unlocked_level"],
		1,
		"Fara save, unlocked_level trebuie sa fie 1."
	)

	assert_eq(
		default_data["high_score"],
		0,
		"Fara save, high_score trebuie sa fie 0."
	)

	assert_true(
		default_data["level_high_scores"] is Dictionary,
		"Default level_high_scores trebuie sa fie Dictionary."
	)

	assert_eq(
		default_data["master_volume"],
		1.0,
		"Master volume default trebuie sa fie 1.0."
	)

	assert_eq(
		default_data["sfx_volume"],
		1.0,
		"SFX volume default trebuie sa fie 1.0."
	)

	assert_eq(
		default_data["bgm_volume"],
		1.0,
		"BGM volume default trebuie sa fie 1.0."
	)

	# ---------------------------------------------------------
	# SAVE + LOAD
	# ---------------------------------------------------------

	var level_scores := {
		1: 100,
		2: 500,
		5: 3000
	}

	SaveManager.save_game(
		5,
		3600,
		level_scores
	)

	var data: Dictionary = (
		SaveManager.load_game()
	)

	assert_eq(
		data["unlocked_level"],
		5,
		"Unlocked level trebuie pastrat."
	)

	assert_eq(
		data["high_score"],
		3600,
		"High score trebuie pastrat."
	)

	assert_eq(
		int(data["level_high_scores"][1]),
		100,
		"Level 1 score trebuie pastrat."
	)

	assert_eq(
		int(data["level_high_scores"][2]),
		500,
		"Level 2 score trebuie pastrat."
	)

	assert_eq(
		int(data["level_high_scores"][5]),
		3000,
		"Level 5 score trebuie pastrat."
	)

	# ---------------------------------------------------------
	# MULTIPLE LEVEL SCORES
	# ---------------------------------------------------------

	var many_scores := {
		1: 100,
		2: 250,
		3: 900,
		7: 4500,
		10: 10000
	}

	SaveManager.save_game(
		10,
		15750,
		many_scores
	)

	var many_data: Dictionary = (
		SaveManager.load_game()
	)

	var loaded_scores: Dictionary = (
		many_data["level_high_scores"]
	)

	assert_eq(
		loaded_scores.size(),
		5,
		"Trebuie pastrate toate cele 5 level scores."
	)

	assert_eq(
		int(loaded_scores[3]),
		900,
		"Level 3 score trebuie pastrat."
	)

	assert_eq(
		int(loaded_scores[7]),
		4500,
		"Level 7 score trebuie pastrat."
	)

	assert_eq(
		int(loaded_scores[10]),
		10000,
		"Level 10 score trebuie pastrat."
	)

	# ---------------------------------------------------------
	# OVERWRITE
	# ---------------------------------------------------------

	SaveManager.save_game(
		3,
		1000,
		{
			1: 100,
			3: 900
		}
	)

	SaveManager.save_game(
		7,
		5000,
		{
			1: 500,
			7: 4500
		}
	)

	var overwrite_data: Dictionary = (
		SaveManager.load_game()
	)

	assert_eq(
		overwrite_data["unlocked_level"],
		7,
		"A doua salvare trebuie sa inlocuiasca unlocked_level."
	)

	assert_eq(
		overwrite_data["high_score"],
		5000,
		"A doua salvare trebuie sa inlocuiasca high_score."
	)

	var overwrite_scores: Dictionary = (
		overwrite_data["level_high_scores"]
	)

	assert_eq(
		int(overwrite_scores[7]),
		4500,
		"Noua valoare Level 7 trebuie salvata."
	)

	assert_false(
		overwrite_scores.has(3),
		"Valorile vechi excluse trebuie eliminate."
	)

	# ---------------------------------------------------------
	# COMPLETE DATA STRUCTURE
	# ---------------------------------------------------------

	SaveManager.save_game(
		6,
		2500,
		{
			1: 1000,
			2: 500,
			6: 1000
		},
		0.9,
		0.7,
		0.5
	)

	var structure_data: Dictionary = (
		SaveManager.load_game()
	)

	for key in [
		"unlocked_level",
		"high_score",
		"level_high_scores",
		"master_volume",
		"sfx_volume",
		"bgm_volume"
	]:

		assert_true(
			structure_data.has(key),
			"Save data trebuie sa contina cheia %s."
			% key
		)

	# ---------------------------------------------------------
	# EMPTY SCORES
	# ---------------------------------------------------------

	SaveManager.save_game(
		1,
		0,
		{}
	)

	var empty_data: Dictionary = (
		SaveManager.load_game()
	)

	assert_true(
		empty_data["level_high_scores"] is Dictionary,
		"Scorurile goale trebuie sa ramana Dictionary."
	)

	assert_true(
		empty_data["level_high_scores"].is_empty(),
		"level_high_scores trebuie sa fie gol."
	)


# =============================================================
# 9. AUDIO SETTINGS IN SAVE
# + SFX SETTINGS
# =============================================================

func test_audio_save_and_sfx_behaviour() -> void:

	# ---------------------------------------------------------
	# AUDIO SETTINGS SAVE
	# ---------------------------------------------------------

	SaveManager.save_game(
		4,
		2000,
		{},
		0.8,
		0.65,
		0.45
	)

	var data: Dictionary = (
		SaveManager.load_game()
	)

	assert_almost_eq(
		float(data["master_volume"]),
		0.8,
		0.001,
		"Master volume trebuie salvat."
	)

	assert_almost_eq(
		float(data["sfx_volume"]),
		0.65,
		0.001,
		"SFX volume trebuie salvat."
	)

	assert_almost_eq(
		float(data["bgm_volume"]),
		0.45,
		0.001,
		"BGM volume trebuie salvat."
	)

	# ---------------------------------------------------------
	# PLAY SFX NULL
	# ---------------------------------------------------------

	if SFXManager.sfx_player != null:
		SFXManager.sfx_player.stop()

	SFXManager.play_sfx(null)

	assert_false(
		SFXManager.sfx_player.playing,
		"play_sfx(null) nu trebuie sa porneasca sunet."
	)

	# ---------------------------------------------------------
	# PLAY SFX VALID
	# ---------------------------------------------------------

	var stream := AudioStreamGenerator.new()

	SFXManager.play_sfx(stream)

	assert_eq(
		SFXManager.sfx_player.stream,
		stream,
		"Stream-ul trebuie setat pe SFX player."
	)

	assert_true(
		SFXManager.sfx_player.playing,
		"SFX player trebuie sa porneasca."
	)


# =============================================================
# 10. UI SOUND + SLIDER SOUND
# =============================================================

func test_ui_and_slider_audio_behaviour() -> void:

	# ---------------------------------------------------------
	# UI NULL
	# ---------------------------------------------------------

	var before_null := (
		SFXManager.get_child_count()
	)

	SFXManager.play_ui_sound(null)

	assert_eq(
		SFXManager.get_child_count(),
		before_null,
		"play_ui_sound(null) nu trebuie sa creeze player."
	)

	# ---------------------------------------------------------
	# UI VALID
	# ---------------------------------------------------------

	var stream := AudioStreamGenerator.new()

	var before_valid := (
		SFXManager.get_child_count()
	)

	SFXManager.play_ui_sound(stream)

	assert_eq(
		SFXManager.get_child_count(),
		before_valid + 1,
		"play_ui_sound valid trebuie sa creeze player."
	)

	var temp_player := SFXManager.get_child(
		SFXManager.get_child_count() - 1
	)

	assert_true(
		temp_player is AudioStreamPlayer,
		"Player-ul temporar trebuie sa fie AudioStreamPlayer."
	)

	assert_eq(
		temp_player.stream,
		stream,
		"Player-ul UI trebuie sa primeasca stream-ul corect."
	)

	# ---------------------------------------------------------
	# SLIDER START
	# ---------------------------------------------------------

	SFXManager.start_slider_sound()

	assert_not_null(
		SFXManager.slider_player,
		"start_slider_sound trebuie sa creeze slider_player."
	)

	assert_true(
		SFXManager.slider_player.playing,
		"Slider sound trebuie sa porneasca."
	)

	# ---------------------------------------------------------
	# NU SE DUPLICA
	# ---------------------------------------------------------

	var first_player := (
		SFXManager.slider_player
	)

	SFXManager.start_slider_sound()

	assert_eq(
		SFXManager.slider_player,
		first_player,
		"Slider sound deja pornit nu trebuie recreat."
	)

	# ---------------------------------------------------------
	# STOP + CLEANUP
	# ---------------------------------------------------------

	SFXManager.stop_slider_sound()

	assert_null(
		SFXManager.slider_player,
		"stop_slider_sound trebuie sa curete player-ul."
	)


# =============================================================
# 11. LEVEL SCENES
# TOATE 10 EXIST + POT FI INCARCATE
# =============================================================

func test_all_level_scenes_exist_and_load() -> void:

	for level in range(1, 11):

		var path := "res://Level%d.tscn" % level

		assert_true(
			ResourceLoader.exists(path),
			"Trebuie sa existe scena Level %d."
			% level
		)

		var scene := load(path)

		assert_not_null(
			scene,
			"Level %d trebuie sa poata fi incarcat."
			% level
		)

	assert_true(
		ResourceLoader.exists("res://Level10.tscn"),
		"Level10.tscn trebuie sa existe."
	)

	assert_false(
		ResourceLoader.exists("res://Level11.tscn"),
		"Level11.tscn nu trebuie sa existe."
	)


# =============================================================
# 12. LEVEL FLOW
# LOCKED -> UNLOCKED -> PROGRESSION -> FINAL LEVEL
# =============================================================

func test_level_flow_progression_and_boundaries() -> void:

	GameState.developer_mode = false
	GameState.unlocked_level = 1

	assert_true(
		GameState.is_level_unlocked(1),
		"Level 1 trebuie sa fie accesibil."
	)

	assert_false(
		GameState.is_level_unlocked(2),
		"Level 2 trebuie sa fie locked initial."
	)

	GameState.unlocked_level = 2

	assert_true(
		GameState.is_level_unlocked(2),
		"Level 2 trebuie sa devina accesibil."
	)

	assert_false(
		GameState.is_level_unlocked(3),
		"Level 3 trebuie sa ramana locked."
	)

	for unlocked in range(1, 11):

		GameState.unlocked_level = unlocked

		assert_true(
			GameState.is_level_unlocked(unlocked),
			"Nivelul curent trebuie sa fie accesibil."
		)

		if unlocked < 10:

			assert_false(
				GameState.is_level_unlocked(unlocked + 1),
				"Urmatorul level trebuie sa ramana locked."
			)

	GameState.unlocked_level = 10

	assert_true(
		GameState.is_level_unlocked(10),
		"Level 10 trebuie sa fie accesibil."
	)

	assert_false(
		GameState.is_level_unlocked(11),
		"Level 11 trebuie sa fie indisponibil."
	)

	# ---------------------------------------------------------
	# RUN STATE RESET
	# ---------------------------------------------------------

	GameState.current_level = 7
	GameState.score = 2500
	GameState.last_level_delta = 600
	GameState.is_new_level_record = true

	GameState.current_level = 8
	GameState.score = 0
	GameState.last_level_delta = 0
	GameState.is_new_level_record = false

	assert_eq(
		GameState.current_level,
		8,
		"Current level trebuie sa poata fi schimbat pentru noua run."
	)

	assert_eq(
		GameState.score,
		0,
		"Score trebuie resetat pentru noua run."
	)

	assert_eq(
		GameState.last_level_delta,
		0,
		"Delta trebuie resetata."
	)

	assert_false(
		GameState.is_new_level_record,
		"Flag-ul de record trebuie resetat."
	)


# =============================================================
# 13. FINAL BOSS
# RESOURCES + INITIAL STATE + THRESHOLDS
# =============================================================

func test_final_boss_structure_and_initial_state() -> void:

	assert_true(
		ResourceLoader.exists("res://BossFinal.tscn"),
		"BossFinal.tscn trebuie sa existe."
	)

	assert_true(
		ResourceLoader.exists("res://DemonBloodBall.tscn"),
		"DemonBloodBall.tscn trebuie sa existe."
	)

	assert_true(
		ResourceLoader.exists("res://Level10.tscn"),
		"Level10.tscn trebuie sa existe."
	)

	var boss_scene := load(
		"res://BossFinal.tscn"
	)

	assert_not_null(
		boss_scene,
		"BossFinal.tscn trebuie sa poata fi incarcat."
	)

	var boss = boss_scene.instantiate()
	add_child_autofree(boss)

	assert_eq(
		boss.max_hp,
		6666,
		"Boss max_hp trebuie sa fie 6666."
	)

	assert_eq(
		boss.current_hp,
		6666.0,
		"Boss current_hp initial trebuie sa fie 6666."
	)

	assert_false(
		boss.is_dead,
		"Boss-ul nu trebuie sa fie mort la start."
	)

	assert_false(
		boss.is_active,
		"Boss-ul trebuie sa fie inactiv la start."
	)

	assert_false(
		boss.visible,
		"Boss-ul trebuie sa fie invizibil la start."
	)

	assert_true(
		boss.is_in_group("boss"),
		"Boss-ul trebuie sa fie in group-ul boss."
	)

	assert_eq(
		boss.vomit_thresholds.size(),
		3,
		"Boss-ul trebuie sa aiba 3 praguri de vomit."
	)

	assert_eq(
		boss.vomit_thresholds[0],
		5000,
		"Pragul 75% trebuie sa fie 5000."
	)

	assert_eq(
		boss.vomit_thresholds[1],
		3333,
		"Pragul 50% trebuie sa fie 3333."
	)

	assert_eq(
		boss.vomit_thresholds[2],
		1667,
		"Pragul 25% trebuie sa fie 1667."
	)


# =============================================================
# 14. FINAL BOSS START + DAMAGE + DEATH
# =============================================================

func test_final_boss_start_damage_and_death() -> void:

	var boss_scene := load(
		"res://BossFinal.tscn"
	)

	assert_not_null(
		boss_scene,
		"BossFinal.tscn trebuie sa existe."
	)

	var boss = boss_scene.instantiate()
	add_child_autofree(boss)

	# ---------------------------------------------------------
	# START
	# ---------------------------------------------------------

	boss.start_boss_fight()

	assert_true(
		boss.visible,
		"Boss-ul trebuie sa devina vizibil la start."
	)

	assert_true(
		boss.is_active,
		"Boss-ul trebuie sa devina activ."
	)

	assert_false(
		boss.is_dead,
		"Boss-ul nu trebuie sa fie dead."
	)

	assert_eq(
		boss.current_hp,
		6666.0,
		"Start fight trebuie sa seteze HP 6666."
	)

	assert_eq(
		boss.punch_timer,
		0.0,
		"Punch timer trebuie resetat."
	)

	assert_eq(
		boss.earthquake_timer,
		0.0,
		"Earthquake timer trebuie resetat."
	)

	assert_eq(
		boss.ranged_attack_timer,
		0.0,
		"Blood Ball timer trebuie resetat."
	)

	# ---------------------------------------------------------
	# DAMAGE
	# ---------------------------------------------------------

	boss.current_hp = 6666.0
	boss.is_active = true
	boss.is_dead = false

	boss.take_damage(100)

	assert_eq(
		boss.current_hp,
		6566.0,
		"100 damage trebuie sa reduca HP la 6566."
	)

	assert_false(
		boss.is_dead,
		"Boss-ul nu trebuie sa moara dupa 100 damage."
	)

	boss.take_damage(500)

	assert_eq(
		boss.current_hp,
		6066.0,
		"Damage-ul consecutiv trebuie sa se acumuleze."
	)

	# ---------------------------------------------------------
	# DEATH
	# ---------------------------------------------------------

	boss.is_attacking = false

	Engine.time_scale = 20.0

	boss.current_hp = 6666.0
	GameState.score = 0

	boss.take_damage(6666)

	assert_eq(
		boss.current_hp,
		0.0,
		"Boss HP trebuie sa ajunga la 0."
	)

	assert_true(
		boss.is_dead,
		"Boss-ul trebuie sa intre in starea dead."
	)

	assert_false(
		boss.is_active,
		"Boss-ul trebuie sa devina inactive la death."
	)

	assert_eq(
		GameState.score,
		666666,
		"Moartea boss-ului trebuie sa ofere 666666 score."
	)


# =============================================================
# 15. FINAL BOSS ATTACKS
# PUNCH + VOMIT + EARTHQUAKE
# =============================================================

func test_final_boss_attack_damage_behaviour() -> void:

	var boss_scene := load(
		"res://BossFinal.tscn"
	)

	assert_not_null(
		boss_scene,
		"BossFinal.tscn trebuie sa existe."
	)

	var boss = boss_scene.instantiate()
	add_child_autofree(boss)

	# ---------------------------------------------------------
	# PUNCH
	# ---------------------------------------------------------

	var punch_target := MockPlayer.new()
	add_child_autofree(punch_target)

	boss.is_dead = false
	boss.is_attacking = false

	boss.execute_punch(
		punch_target
	)

	assert_eq(
		punch_target.damages.size(),
		1,
		"Punch-ul trebuie sa aplice exact o lovitura."
	)

	assert_eq(
		punch_target.damages[0]["amount"],
		75,
		"Punch damage trebuie sa fie 75."
	)

	assert_eq(
		punch_target.damages[0]["source"],
		"final_boss",
		"Punch-ul trebuie sa aiba sursa final_boss."
	)

	assert_eq(
		punch_target.knockbacks.size(),
		1,
		"Punch-ul trebuie sa aplice knockback."
	)

	# ---------------------------------------------------------
	# VOMIT
	# ---------------------------------------------------------

	var vomit_area := Area2D.new()

	vomit_area.name = "TestVomitArea"
	vomit_area.monitoring = true
	vomit_area.monitorable = true
	vomit_area.collision_layer = 0
	vomit_area.collision_mask = 1

	var vomit_shape := CollisionShape2D.new()
	var vomit_circle := CircleShape2D.new()

	vomit_circle.radius = 100.0
	vomit_shape.shape = vomit_circle

	vomit_area.add_child(
		vomit_shape
	)

	add_child_autofree(
		vomit_area
	)

	var vomit_target := MockPhysicsPlayer.new()

	vomit_target.name = "TestVomitPlayer"
	vomit_target.collision_layer = 1
	vomit_target.collision_mask = 0

	var vomit_player_shape := CollisionShape2D.new()
	var vomit_player_circle := CircleShape2D.new()

	vomit_player_circle.radius = 16.0
	vomit_player_shape.shape = vomit_player_circle

	vomit_target.add_child(
		vomit_player_shape
	)

	add_child_autofree(
		vomit_target
	)

	vomit_target.add_to_group(
		"player"
	)

	vomit_area.global_position = (
		boss.global_position
	)

	vomit_target.global_position = (
		vomit_area.global_position
	)

	boss.vomit_area = vomit_area
	boss.vomit_area_distance_x = 0.0
	boss.player = vomit_target
	boss.is_dead = false
	boss.is_attacking = false

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var vomit_overlapping := (
		vomit_area.get_overlapping_bodies()
	)

	assert_true(
		vomit_overlapping.has(vomit_target),
		"Player-ul trebuie detectat de zona de vomit."
	)

	var vomit_health_before := (
		vomit_target.health
	)

	boss.execute_vomit_attack()

	assert_eq(
		vomit_health_before - vomit_target.health,
		50,
		"Vomit-ul trebuie sa aplice 50 damage."
	)

	assert_eq(
		vomit_target.damages.size(),
		1,
		"Vomit-ul trebuie sa aplice exact un damage."
	)

	assert_eq(
		vomit_target.damages[0]["amount"],
		50,
		"Vomit damage trebuie sa fie 50."
	)

	assert_eq(
		vomit_target.damages[0]["source"],
		"final_boss",
		"Vomit-ul trebuie sa aiba sursa final_boss."
	)

	# ---------------------------------------------------------
	# EARTHQUAKE
	# ---------------------------------------------------------

	var earthquake_area: Area2D = boss.get_node(
		"EarthquakeArea"
	)

	earthquake_area.monitoring = true
	earthquake_area.monitorable = true
	earthquake_area.collision_layer = 0
	earthquake_area.collision_mask = 1

	var earthquake_shape := (
		earthquake_area.get_node_or_null(
			"CollisionShape2D"
		)
	)

	assert_not_null(
		earthquake_shape,
		"EarthquakeArea trebuie sa aiba CollisionShape2D."
	)

	var earthquake_circle := CircleShape2D.new()
	earthquake_circle.radius = 500.0

	earthquake_shape.shape = earthquake_circle
	earthquake_shape.set_deferred(
		"disabled",
		false
	)

	var earthquake_target := MockPhysicsPlayer.new()

	earthquake_target.name = "TestEarthquakePlayer"
	earthquake_target.collision_layer = 1
	earthquake_target.collision_mask = 0

	var earthquake_player_shape := CollisionShape2D.new()
	var earthquake_player_circle := CircleShape2D.new()

	earthquake_player_circle.radius = 16.0
	earthquake_player_shape.shape = earthquake_player_circle

	earthquake_target.add_child(
		earthquake_player_shape
	)

	add_child_autofree(
		earthquake_target
	)

	earthquake_target.add_to_group(
		"player"
	)

	earthquake_target.global_position = (
		earthquake_area.global_position
	)

	boss.is_dead = false
	boss.is_attacking = false
	boss.first_earthquake = false

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var earthquake_overlapping := (
		earthquake_area.get_overlapping_bodies()
	)

	assert_true(
		earthquake_overlapping.has(earthquake_target),
		"Player-ul trebuie detectat de EarthquakeArea."
	)

	var earthquake_health_before := (
		earthquake_target.health
	)

	boss.trigger_earthquake()

	assert_eq(
		earthquake_health_before - earthquake_target.health,
		100,
		"Earthquake trebuie sa aplice 100 damage."
	)

	assert_eq(
		earthquake_target.damages.size(),
		1,
		"Earthquake trebuie sa aplice exact un damage."
	)

	assert_eq(
		earthquake_target.damages[0]["source"],
		"final_boss",
		"Earthquake trebuie sa foloseasca sursa final_boss."
	)


# =============================================================
# 16. BOSS ATTACK NON-OVERLAP
# + BLOOD BALL DIRECTION + DAMAGE
# =============================================================

func test_final_boss_attack_control_and_blood_ball() -> void:

	var boss_scene := load(
		"res://BossFinal.tscn"
	)

	assert_not_null(
		boss_scene,
		"BossFinal.tscn trebuie sa existe."
	)

	# ---------------------------------------------------------
	# NU SE SUPRAPUN
	# ---------------------------------------------------------

	var boss = boss_scene.instantiate()
	add_child_autofree(boss)

	var target := MockPlayer.new()
	add_child_autofree(target)

	target.add_to_group(
		"player"
	)

	boss.player = target
	boss.is_dead = false
	boss.is_attacking = true

	boss.execute_punch(
		target
	)

	boss.shoot_blood_ball()
	boss.trigger_earthquake()
	boss.execute_vomit_attack()

	assert_eq(
		target.damages.size(),
		0,
		"Cand boss-ul este deja in atac, alte atacuri nu trebuie sa porneasca."
	)

	assert_true(
		boss.is_attacking,
		"Boss-ul trebuie sa ramana in starea attacking."
	)

	# ---------------------------------------------------------
	# BLOOD BALL DIRECTION
	# ---------------------------------------------------------

	var boss2 = boss_scene.instantiate()
	add_child_autofree(boss2)

	var player2 := MockPlayer.new()
	add_child_autofree(player2)

	player2.add_to_group(
		"player"
	)

	player2.global_position = (
		boss2.global_position
		+ Vector2(400, 0)
	)

	boss2.player = player2
	boss2.is_dead = false
	boss2.is_attacking = false

	boss2.shoot_blood_ball()

	await get_tree().process_frame

	var blood_ball = null

	if get_tree().current_scene:

		for child in (
			get_tree().current_scene.get_children()
		):

			if (
				child.get_scene_file_path()
				== "res://DemonBloodBall.tscn"
			):

				blood_ball = child
				break

	assert_not_null(
		blood_ball,
		"Blood Ball trebuie sa fie creata de boss."
	)

	var launch_direction: Vector2 = (
		blood_ball.direction
	)

	player2.global_position = (
		boss2.global_position
		+ Vector2(-400, 0)
	)

	await get_tree().process_frame

	assert_eq(
		blood_ball.direction,
		launch_direction,
		"Blood Ball nu trebuie sa-si schimbe directia dupa lansare."
	)

	blood_ball.queue_free()

	# ---------------------------------------------------------
	# BLOOD BALL DAMAGE
	# ---------------------------------------------------------

	var ball_scene := load(
		"res://DemonBloodBall.tscn"
	)

	assert_not_null(
		ball_scene,
		"DemonBloodBall.tscn trebuie sa existe."
	)

	var ball = ball_scene.instantiate()
	add_child_autofree(ball)

	var ball_target := MockPlayer.new()
	add_child_autofree(ball_target)

	ball_target.add_to_group(
		"player"
	)

	ball._on_body_entered(
		ball_target
	)

	assert_eq(
		ball_target.damages.size(),
		1,
		"Blood Ball trebuie sa aplice exact o lovitura."
	)

	assert_eq(
		ball_target.damages[0]["amount"],
		50,
		"Blood Ball damage trebuie sa fie 50."
	)

	assert_eq(
		ball_target.damages[0]["source"],
		"final_boss",
		"Blood Ball trebuie sa foloseasca sursa final_boss."
	)


# =============================================================
# 17. LEVEL 10 DEPENDENCIES
# MAP2 + BOSS HEALTH BAR
# =============================================================

func test_level10_boss_dependencies() -> void:

	var level10_scene := load(
		"res://Level10.tscn"
	)

	assert_not_null(
		level10_scene,
		"Level10.tscn trebuie sa poata fi incarcat."
	)

	var level10 = level10_scene.instantiate()
	add_child_autofree(level10)

	assert_true(
		level10.has_node("Map2"),
		"Level10 trebuie sa contina Map2."
	)

	assert_true(
		level10.has_node(
			"CanvasLayer/BossHealthBar"
		),
		"Level10 trebuie sa contina BossHealthBar."
	)


# =============================================================
# 18. FINAL PORTAL
# INITIAL + ACTIVATE + NON-PLAYER
# =============================================================

func test_final_portal_behaviour() -> void:

	var portal_scene := load(
		"res://FinalPortal.tscn"
	)

	assert_not_null(
		portal_scene,
		"FinalPortal.tscn trebuie sa existe."
	)

	var portal = portal_scene.instantiate()
	add_child_autofree(portal)

	# ---------------------------------------------------------
	# INITIAL
	# ---------------------------------------------------------

	assert_false(
		portal.activated,
		"Portalul nu trebuie sa fie activ la start."
	)

	assert_false(
		portal.player_entered,
		"player_entered trebuie sa fie false la start."
	)

	assert_false(
		portal.win_screen_opened,
		"Win screen nu trebuie sa fie deschis la start."
	)

	assert_true(
		portal.is_in_group("final_portal"),
		"Portalul trebuie sa fie in group-ul final_portal."
	)

	assert_false(
		portal.visible,
		"Portalul trebuie sa fie invizibil la start."
	)

	assert_false(
		portal.monitoring,
		"Portalul nu trebuie sa monitorizeze la start."
	)

	# ---------------------------------------------------------
	# ACTIVATE
	# ---------------------------------------------------------

	portal.activate()

	assert_true(
		portal.activated,
		"Portalul trebuie sa devina activ."
	)

	assert_true(
		portal.visible,
		"Portalul trebuie sa devina vizibil."
	)

	assert_true(
		portal.monitoring,
		"Portalul trebuie sa porneasca monitoring."
	)

	# ---------------------------------------------------------
	# NON PLAYER
	# ---------------------------------------------------------

	var other_body := Node2D.new()
	add_child_autofree(other_body)

	portal._on_body_entered(
		other_body
	)

	assert_false(
		portal.player_entered,
		"Portalul nu trebuie sa considere non-player drept player."
	)

	assert_false(
		portal.win_screen_opened,
		"Win screen nu trebuie pornit pentru non-player."
	)


# =============================================================
# 19. MINI-BOSS
# INITIAL + DAMAGE
# =============================================================

func test_miniboss_core_behaviour() -> void:

	var turret_scene := load(
		"res://TurretGuardian.tscn"
	)

	assert_not_null(
		turret_scene,
		"TurretGuardian.tscn trebuie sa existe."
	)

	var turret = turret_scene.instantiate()
	add_child_autofree(turret)

	# ---------------------------------------------------------
	# INITIAL
	# ---------------------------------------------------------

	assert_eq(
		turret.max_health,
		550,
		"Mini-boss max health trebuie sa fie 550."
	)

	assert_eq(
		turret.current_health,
		550,
		"Mini-boss current health trebuie sa fie 550."
	)

	assert_false(
		turret.is_dead,
		"Mini-boss-ul nu trebuie sa fie mort la start."
	)

	assert_false(
		turret.is_busy,
		"Mini-boss-ul nu trebuie sa fie busy la start."
	)

	# ---------------------------------------------------------
	# DAMAGE
	# ---------------------------------------------------------

	turret.current_health = 550
	turret.is_dead = false

	turret.take_damage(100)

	assert_eq(
		turret.current_health,
		450,
		"100 damage trebuie sa lase 450 HP."
	)

	turret.take_damage(200)

	assert_eq(
		turret.current_health,
		250,
		"Damage-ul consecutiv trebuie sa se acumuleze."
	)

	assert_false(
		turret.is_dead,
		"Mini-boss-ul nu trebuie sa fie mort cat timp are HP."
	)


# =============================================================
# 20. MINI-BOSS -> FINAL BOSS
# ACTIVATION + DEATH -> BUFF + BOSS
# =============================================================

func test_miniboss_to_final_boss_integration() -> void:

	var turret_scene := load(
		"res://TurretGuardian.tscn"
	)

	assert_not_null(
		turret_scene,
		"TurretGuardian.tscn trebuie sa existe."
	)

	# ---------------------------------------------------------
	# CLEAN PLAYER GROUP
	# ---------------------------------------------------------

	for node in get_tree().get_nodes_in_group("player"):

		node.remove_from_group(
			"player"
		)

	# ---------------------------------------------------------
	# MOCK BUFF PLAYER
	# ---------------------------------------------------------

	var player := MockBuffPlayer.new()

	player.name = "IntegrationBuffPlayer"
	player.health = 100
	player.final_boss_shield = 0
	player.final_boss_damage_multiplier = 1.0
	player.buff_called = false

	player.add_to_group(
		"player"
	)

	add_child_autofree(
		player
	)

	await get_tree().process_frame

	assert_true(
		player.is_inside_tree(),
		"Mock player-ul trebuie sa fie in SceneTree."
	)

	assert_true(
		player.is_in_group("player"),
		"Mock player-ul trebuie sa fie in group-ul player."
	)

	assert_eq(
		get_tree().get_first_node_in_group("player"),
		player,
		"TurretGuardian trebuie sa gaseasca Mock player-ul."
	)

	# ---------------------------------------------------------
	# CLEAN BOSS GROUP
	# ---------------------------------------------------------

	for node in get_tree().get_nodes_in_group("boss"):

		node.remove_from_group(
			"boss"
		)

	# ---------------------------------------------------------
	# MOCK BOSS
	# ---------------------------------------------------------

	var boss := MockBoss.new()

	boss.name = "IntegrationMockBoss"

	add_child_autofree(
		boss
	)

	boss.add_to_group(
		"boss"
	)

	await get_tree().process_frame

	assert_true(
		boss.is_inside_tree(),
		"Mock boss-ul trebuie sa fie in SceneTree."
	)

	assert_true(
		boss.is_in_group("boss"),
		"Mock boss-ul trebuie sa fie in group-ul boss."
	)

	assert_eq(
		get_tree().get_first_node_in_group("boss"),
		boss,
		"TurretGuardian trebuie sa gaseasca Mock Boss-ul."
	)

	# ---------------------------------------------------------
	# REAL TURRET
	# ---------------------------------------------------------

	var turret = turret_scene.instantiate()

	add_child_autofree(
		turret
	)

	await get_tree().process_frame

	assert_not_null(
		turret,
		"TurretGuardian real trebuie sa poata fi creat."
	)

	# ---------------------------------------------------------
	# RECONFIRM GROUPS
	# ---------------------------------------------------------

	assert_eq(
		get_tree().get_first_node_in_group("player"),
		player,
		"Player-ul corect trebuie sa ramana in group."
	)

	assert_eq(
		get_tree().get_first_node_in_group("boss"),
		boss,
		"Mock Boss-ul corect trebuie sa ramana in group."
	)

	# ---------------------------------------------------------
	# INITIAL PLAYER STATE
	# ---------------------------------------------------------

	player.health = 100
	player.final_boss_shield = 0
	player.final_boss_damage_multiplier = 1.0
	player.buff_called = false

	assert_false(
		player.buff_called,
		"Buff-ul nu trebuie aplicat inainte de death."
	)

	# ---------------------------------------------------------
	# ACCELERATE ONLY TEST
	# ---------------------------------------------------------

	Engine.time_scale = 20.0

	# ---------------------------------------------------------
	# MINIBOSS DEATH
	# ---------------------------------------------------------

	turret.die()

	# ---------------------------------------------------------
	# WAIT FOR REAL FLOW
	# ---------------------------------------------------------

	var completed := false

	for i in range(300):

		if (
			player.buff_called
			and boss.start_called
		):

			completed = true
			break

		await get_tree().process_frame

	# ---------------------------------------------------------
	# FULL FLOW
	# ---------------------------------------------------------

	assert_true(
		completed,
		"Death flow trebuia sa ajunga la buff si activarea bossului."
	)

	assert_true(
		player.buff_called,
		"Moartea mini-bossului trebuie sa apeleze apply_final_boss_buffs()."
	)

	assert_eq(
		player.health,
		player.max_health,
		"Moartea mini-bossului trebuie sa refaca HP-ul."
	)

	assert_eq(
		player.final_boss_shield,
		777,
		"Moartea mini-bossului trebuie sa ofere shield 777."
	)

	assert_eq(
		player.final_boss_damage_multiplier,
		2.0,
		"Moartea mini-bossului trebuie sa ofere damage x2."
	)

	assert_true(
		boss.start_called,
		"Moartea mini-bossului trebuie sa ceara pornirea Final Boss."
	)


# =============================================================
# 21. INTEGRATION
# LEVEL 1 -> COMPLETE -> LEVEL 2 + SAVE
# =============================================================

func test_integration_level_completion_and_save() -> void:

	GameState.developer_mode = false
	GameState.current_level = 1
	GameState.unlocked_level = 1
	GameState.score = 1500

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.complete_level()

	assert_eq(
		GameState.current_level,
		1,
		"Completarea Level 1 nu trebuie sa schimbe current_level."
	)

	assert_eq(
		GameState.unlocked_level,
		2,
		"Completarea Level 1 trebuie sa deblocheze Level 2."
	)

	assert_true(
		GameState.is_level_unlocked(2),
		"Level 2 trebuie sa devina accesibil."
	)

	var saved_data: Dictionary = (
		SaveManager.load_game()
	)

	assert_eq(
		saved_data["unlocked_level"],
		2,
		"Progress-ul Level 2 trebuie sa fie salvat."
	)

	assert_eq(
		int(saved_data["level_high_scores"][1]),
		1500,
		"Scorul Level 1 trebuie sa fie salvat."
	)


# =============================================================
# 22. INTEGRATION
# LEVEL 2+ -> FINAL BOSS BUFF
# =============================================================

func test_integration_player_buff_flow() -> void:

	var player_scene := load(
		"res://Player.tscn"
	)

	assert_not_null(
		player_scene,
		"Player.tscn trebuie sa existe."
	)

	var player = player_scene.instantiate()
	add_child_autofree(player)

	GameState.current_level = 2
	GameState.has_shield = true
	GameState.shield_throw_unlocked = true

	player.apply_final_boss_buffs()

	assert_true(
		GameState.has_shield,
		"Shield state trebuie sa ramana activ."
	)

	assert_true(
		GameState.shield_throw_unlocked,
		"Shield throw trebuie sa fie unlocked din Level 2."
	)

	assert_eq(
		player.health,
		player.max_health,
		"Buff-ul Final Boss trebuie sa refaca HP."
	)

	assert_eq(
		player.final_boss_shield,
		777,
		"Final Boss shield trebuie sa fie 777."
	)

	assert_eq(
		player.final_boss_damage_multiplier,
		2.0,
		"Final Boss damage multiplier trebuie sa fie 2x."
	)


# =============================================================
# 23. INTEGRATION
# SAVE -> RELOAD -> PROGRESS RAMANE
# =============================================================

func test_integration_save_reload_progress() -> void:

	GameState.developer_mode = false

	GameState.current_level = 4
	GameState.unlocked_level = 4
	GameState.score = 2750

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.complete_level()

	var saved_data: Dictionary = (
		SaveManager.load_game()
	)

	assert_eq(
		saved_data["unlocked_level"],
		5,
		"Save-ul trebuie sa pastreze unlock-ul urmator."
	)

	assert_eq(
		int(saved_data["level_high_scores"][4]),
		2750,
		"Save-ul trebuie sa pastreze recordul Level 4."
	)

	# ---------------------------------------------------------
	# SIMULARE RESTART / RELOAD
	# ---------------------------------------------------------

	GameState.current_level = 1
	GameState.unlocked_level = 1
	GameState.score = 0
	GameState.total_score = 0
	GameState.high_score = 0

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.load_saved_data()

	assert_eq(
		GameState.unlocked_level,
		5,
		"Dupa reload, Level 5 trebuie sa ramana unlocked."
	)

	assert_true(
		GameState.level_high_scores.has(4),
		"Dupa reload, recordul Level 4 trebuie sa existe."
	)

	assert_eq(
		GameState.level_high_scores[4],
		2750,
		"Dupa reload, recordul Level 4 trebuie sa ramana 2750."
	)

	assert_eq(
		GameState.total_score,
		2750,
		"Dupa reload, total score trebuie recalculat corect."
	)


# =============================================================
# 24. FINAL FLOW SANITY
# Level 10 -> no Level 11
# + Save restore integrity handled by after_each()
# =============================================================

func test_final_flow_level10_boundary() -> void:

	GameState.developer_mode = false

	GameState.current_level = 10
	GameState.unlocked_level = 10
	GameState.score = 5000

	GameState.level_high_scores.clear()
	GameState.level_scores.clear()

	GameState.complete_level()

	assert_eq(
		GameState.unlocked_level,
		10,
		"Final flow trebuie sa ramana la Level 10."
	)

	assert_false(
		GameState.is_level_unlocked(11),
		"Level 11 trebuie sa ramana indisponibil."
	)

	assert_false(
		ResourceLoader.exists("res://Level11.tscn"),
		"Level11.tscn nu trebuie sa existe."
	)
