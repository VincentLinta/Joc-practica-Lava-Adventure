extends Control


# =============================================================
# CONFIGURARE
# =============================================================

@export var boss_name: String = "THE BLOOD DEMON"

@export var bar_width: float = 600.0
@export var bar_height: float = 26.0

# Distanța față de marginea de jos a ecranului.
@export var bottom_margin: float = 35.0


# =============================================================
# HP
# =============================================================

var max_hp: float = 3000.0
var hp: float = 3000.0

var displayed_hp: float = 3000.0
var delayed_hp: float = 3000.0


# =============================================================
# EFECTE
# =============================================================

var hit_flash: float = 0.0
var bar_shake: float = 0.0

var earthquake_flash: float = 0.0
var vomit_flash: float = 0.0

var intro_animation: float = 0.0

var is_visible_bar: bool = false


# =============================================================
# READY
# =============================================================

func _ready() -> void:
	# Bara este ascunsă până începe boss fight-ul.
	visible = false

	# Nu vrem să interacționeze cu mouse-ul.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Control-ul acoperă viewport-ul.
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

	queue_redraw()


# =============================================================
# VIEWPORT RESIZE
# =============================================================

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		size = get_viewport().get_visible_rect().size
		queue_redraw()


# =============================================================
# SHOW BAR
# =============================================================

func show_bar(p_max_hp: float) -> void:
	max_hp = max(p_max_hp, 1.0)

	hp = max_hp
	displayed_hp = max_hp
	delayed_hp = max_hp

	hit_flash = 0.0
	bar_shake = 0.0

	earthquake_flash = 0.0
	vomit_flash = 0.0

	intro_animation = 0.0

	is_visible_bar = true
	visible = true

	# Reconfirmăm dimensiunea viewport-ului.
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size

	queue_redraw()


# =============================================================
# HIDE BAR
# =============================================================

func hide_bar() -> void:
	is_visible_bar = false
	visible = false

	queue_redraw()


# =============================================================
# UPDATE HP
# =============================================================

func update_hp(new_hp: float, damage: int) -> void:
	hp = clamp(
		new_hp,
		0.0,
		max_hp
	)

	hit_flash = 1.0

	# Damage mai mare = shake ceva mai puternic.
	bar_shake = clamp(
		(float(damage) / max_hp) * 80.0,
		2.0,
		8.0
	)

	queue_redraw()


# =============================================================
# EARTHQUAKE EFFECT
# =============================================================

func earthquake_effect() -> void:
	if not is_visible_bar:
		return

	earthquake_flash = 1.0

	bar_shake = max(
		bar_shake,
		8.0
	)

	queue_redraw()


# =============================================================
# VOMIT EFFECT
# =============================================================

func vomit_effect() -> void:
	if not is_visible_bar:
		return

	vomit_flash = 1.0

	bar_shake = max(
		bar_shake,
		5.0
	)

	queue_redraw()


# =============================================================
# PROCESS
# =============================================================

func _process(delta: float) -> void:
	if not is_visible_bar:
		return


	# =========================================================
	# HP PRINCIPAL - SCĂDERE LINĂ
	# =========================================================

	displayed_hp = lerp(
		displayed_hp,
		hp,
		12.0 * delta
	)

	if abs(displayed_hp - hp) < 0.5:
		displayed_hp = hp


	# =========================================================
	# BARA DE DAMAGE ÎNTÂRZIATĂ
	# =========================================================

	if delayed_hp > displayed_hp:

		delayed_hp = lerp(
			delayed_hp,
			displayed_hp,
			3.0 * delta
		)

	else:

		delayed_hp = displayed_hp


	# =========================================================
	# FLASH
	# =========================================================

	hit_flash = max(
		hit_flash - delta * 5.0,
		0.0
	)

	earthquake_flash = max(
		earthquake_flash - delta * 2.5,
		0.0
	)

	vomit_flash = max(
		vomit_flash - delta * 3.0,
		0.0
	)


	# =========================================================
	# SHAKE
	# =========================================================

	bar_shake = move_toward(
		bar_shake,
		0.0,
		delta * 25.0
	)


	# =========================================================
	# INTRO
	# =========================================================

	if intro_animation < 1.0:

		intro_animation = min(
			intro_animation + delta * 2.5,
			1.0
		)


	queue_redraw()


# =============================================================
# DRAW
# =============================================================

func _draw() -> void:
	if not is_visible_bar:
		return

	var font = ThemeDB.fallback_font


	# =========================================================
	# HP RATIOS
	# =========================================================

	var hp_ratio: float = 0.0

	if max_hp > 0.0:

		hp_ratio = clamp(
			hp / max_hp,
			0.0,
			1.0
		)


	var displayed_ratio: float = 0.0

	if max_hp > 0.0:

		displayed_ratio = clamp(
			displayed_hp / max_hp,
			0.0,
			1.0
		)


	var delayed_ratio: float = 0.0

	if max_hp > 0.0:

		delayed_ratio = clamp(
			delayed_hp / max_hp,
			0.0,
			1.0
		)


	# =========================================================
	# SHAKE
	# =========================================================

	var shake_offset := Vector2.ZERO

	if bar_shake > 0.0:

		shake_offset = Vector2(
			randf_range(
				-bar_shake,
				bar_shake
			),
			randf_range(
				-bar_shake,
				bar_shake
			)
		)


	# =========================================================
	# BAR POSITION
	# =========================================================

	var center_x: float = size.x * 0.5

	var intro_scale: float = lerp(
		0.7,
		1.0,
		intro_animation
	)

	var scaled_width: float = bar_width * intro_scale

	var bar_x: float = (
		center_x
		- scaled_width * 0.5
		+ shake_offset.x
	)

	# Bara este poziționată în partea de jos.
	var bar_y: float = (
		size.y
		- bottom_margin
		- 64.0
		+ shake_offset.y
	)


	# =========================================================
	# LOW HP
	# =========================================================

	var low_hp: bool = hp_ratio <= 0.30


	# =========================================================
	# BOSS NAME
	# =========================================================

	var title_color := Color(
		1.0,
		0.65,
		0.20
	)

	if low_hp:

		title_color = Color(
			1.0,
			0.20,
			0.05
		)


	draw_string(
		font,
		Vector2(
			center_x - 220.0,
			bar_y - 12.0
		),
		"☠ " + boss_name + " ☠",
		HORIZONTAL_ALIGNMENT_CENTER,
		440.0,
		18,
		title_color
	)


	# =========================================================
	# OUTER GLOW
	# =========================================================

	draw_rect(
		Rect2(
			bar_x - 10.0,
			bar_y - 10.0,
			scaled_width + 20.0,
			bar_height + 20.0
		),
		Color(
			0.70,
			0.00,
			0.00,
			0.10
		)
	)


	# =========================================================
	# OUTER BLACK FRAME
	# =========================================================

	draw_rect(
		Rect2(
			bar_x - 5.0,
			bar_y - 5.0,
			scaled_width + 10.0,
			bar_height + 10.0
		),
		Color(
			0.01,
			0.005,
			0.005,
			1.0
		)
	)


	# =========================================================
	# INNER DARK FRAME
	# =========================================================

	draw_rect(
		Rect2(
			bar_x - 2.0,
			bar_y - 2.0,
			scaled_width + 4.0,
			bar_height + 4.0
		),
		Color(
			0.20,
			0.01,
			0.015,
			1.0
		)
	)


	# =========================================================
	# EMPTY BAR
	# =========================================================

	draw_rect(
		Rect2(
			bar_x,
			bar_y,
			scaled_width,
			bar_height
		),
		Color(
			0.035,
			0.005,
			0.008,
			1.0
		)
	)


	# =========================================================
	# DELAYED DAMAGE BAR
	# =========================================================

	if delayed_ratio > 0.0:

		draw_rect(
			Rect2(
				bar_x,
				bar_y,
				scaled_width * delayed_ratio,
				bar_height
			),
			Color(
				0.32,
				0.018,
				0.02,
				1.0
			)
		)


	# =========================================================
	# MAIN HP BAR
	# =========================================================

	var hp_color := Color(
		0.88,
		0.035,
		0.02,
		1.0
	)

	if low_hp:

		hp_color = Color(
			1.0,
			0.06,
			0.015,
			1.0
		)


	if displayed_ratio > 0.0:

		draw_rect(
			Rect2(
				bar_x,
				bar_y,
				scaled_width * displayed_ratio,
				bar_height
			),
			hp_color
		)


	# =========================================================
	# DARK RED LOWER SHADOW
	# =========================================================

	if displayed_ratio > 0.0:

		draw_rect(
			Rect2(
				bar_x,
				bar_y + bar_height * 0.65,
				scaled_width * displayed_ratio,
				bar_height * 0.35
			),
			Color(
				0.30,
				0.00,
				0.00,
				0.38
			)
		)


	# =========================================================
	# TOP HIGHLIGHT
	# =========================================================

	if displayed_ratio > 0.0:

		draw_rect(
			Rect2(
				bar_x,
				bar_y,
				scaled_width * displayed_ratio,
				4.0
			),
			Color(
				1.0,
				0.35,
				0.25,
				0.85
			)
		)


	# =========================================================
	# HIT FLASH
	# =========================================================

	if hit_flash > 0.0:

		draw_rect(
			Rect2(
				bar_x,
				bar_y,
				scaled_width * displayed_ratio,
				bar_height
			),
			Color(
				1.0,
				0.90,
				0.80,
				hit_flash * 0.65
			)
		)


	# =========================================================
	# EARTHQUAKE EFFECT
	# =========================================================

	if earthquake_flash > 0.0:

		draw_rect(
			Rect2(
				bar_x - 2.0,
				bar_y - 2.0,
				scaled_width + 4.0,
				bar_height + 4.0
			),
			Color(
				1.0,
				0.70,
				0.20,
				earthquake_flash * 0.25
			),
			false,
			3.0
		)


	# =========================================================
	# VOMIT EFFECT
	# =========================================================

	if vomit_flash > 0.0:

		draw_rect(
			Rect2(
				bar_x - 2.0,
				bar_y - 2.0,
				scaled_width + 4.0,
				bar_height + 4.0
			),
			Color(
				0.30,
				1.0,
				0.20,
				vomit_flash * 0.20
			),
			false,
			3.0
		)


	# =========================================================
	# PRAGURI 75 / 50 / 25
	# =========================================================

	var thresholds := [
		0.75,
		0.50,
		0.25
	]

	for ratio in thresholds:

		var marker_x: float = (
			bar_x
			+ scaled_width * ratio
		)

		draw_line(
			Vector2(
				marker_x,
				bar_y - 6.0
			),
			Vector2(
				marker_x,
				bar_y + bar_height + 6.0
			),
			Color(
				1.0,
				0.80,
				0.40,
				0.65
			),
			2.0
		)


	# =========================================================
	# LEFT / RIGHT END CAPS
	# =========================================================

	draw_line(
		Vector2(
			bar_x,
			bar_y - 2.0
		),
		Vector2(
			bar_x,
			bar_y + bar_height + 2.0
		),
		Color(
			0.65,
			0.08,
			0.05,
			1.0
		),
		2.0
	)

	draw_line(
		Vector2(
			bar_x + scaled_width,
			bar_y - 2.0
		),
		Vector2(
			bar_x + scaled_width,
			bar_y + bar_height + 2.0
		),
		Color(
			0.65,
			0.08,
			0.05,
			1.0
		),
		2.0
	)


	# =========================================================
	# HP TEXT
	# =========================================================

	var hp_text := "%d / %d" % [
		int(hp),
		int(max_hp)
	]

	draw_string(
		font,
		Vector2(
			center_x - 100.0,
			bar_y + bar_height + 20.0
		),
		hp_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		200.0,
		14,
		Color(
			0.90,
			0.90,
			0.90,
			1.0
		)
	)


	# =========================================================
	# ENRAGED
	# =========================================================

	if low_hp:

		draw_string(
			font,
			Vector2(
				center_x - 100.0,
				bar_y + bar_height + 38.0
			),
			"ENRAGED",
			HORIZONTAL_ALIGNMENT_CENTER,
			200.0,
			13,
			Color(
				1.0,
				0.15,
				0.05,
				1.0
			)
		)
