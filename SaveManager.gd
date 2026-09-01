extends Node

const SAVE_PATH := "user://save.cfg"

func save_game(unlocked_level: int, high_score: int, level_high_scores: Dictionary = {}, master_vol: float = -1.0, sfx_vol: float = -1.0, bgm_vol: float = -1.0) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)

	config.set_value("progress", "unlocked_level", unlocked_level)
	config.set_value("progress", "high_score", high_score)
	config.set_value("progress", "level_high_scores", level_high_scores)

	if master_vol != -1.0:
		config.set_value("audio", "master_volume", master_vol)
	if sfx_vol != -1.0:
		config.set_value("audio", "sfx_volume", sfx_vol)
	if bgm_vol != -1.0:
		config.set_value("audio", "bgm_volume", bgm_vol)

	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("Could not save game. Error code: %d" % error)

func load_game() -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error != OK:
		return {
			"unlocked_level": 1,
			"high_score": 0,
			"level_high_scores": {},
			"master_volume": 1.0,
			"sfx_volume": 1.0,
			"bgm_volume": 1.0
		}

	return {
		"unlocked_level": int(config.get_value("progress", "unlocked_level", 1)),
		"high_score": int(config.get_value("progress", "high_score", 0)),
		"level_high_scores": config.get_value("progress", "level_high_scores", {}),
		"master_volume": float(config.get_value("audio", "master_volume", 1.0)),
		"sfx_volume": float(config.get_value("audio", "sfx_volume", 1.0)),
		"bgm_volume": float(config.get_value("audio", "bgm_volume", 1.0))
	}
