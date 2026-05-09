extends Control

@onready var player1 = $"../../Player"
@onready var player2 = $"../../Player_2"

# =========================
# PLAYER 1
# =========================
@onready var p1_points = $Panel/P1Points
@onready var p1_strength = $Panel/P1Strength
@onready var p1_agility = $Panel/P1Agility
@onready var p1_jump = $Panel/P1Jump
@onready var p1_lifesteal = $Panel/P1LifeSteal

# =========================
# PLAYER 2
# =========================
@onready var p2_points = $Panel/P2Points
@onready var p2_strength = $Panel/P2Strength
@onready var p2_agility = $Panel/P2Agility
@onready var p2_jump = $Panel/P2Jump
@onready var p2_lifesteal = $Panel/P2LifeSteal

# =========================
# INPUT
# =========================
var input_delay = 0.15
var input_timer = 0.0

func _process(delta):

	if not visible:
		return

	# =========================
	# INPUT TIMER
	# =========================
	if input_timer > 0:
		input_timer -= delta

	# =========================
	# PLAYER 1 INPUTS
	# =========================
	if input_timer <= 0:

		if Input.is_key_pressed(KEY_W):
			player1.spend_stat_point("strength")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_A):
			player1.spend_stat_point("agility")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_D):
			player1.spend_stat_point("jump")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_S):
			player1.spend_stat_point("lifesteal")
			input_timer = input_delay

	# =========================
	# PLAYER 2 INPUTS
	# =========================
	if input_timer <= 0:

		if Input.is_key_pressed(KEY_I):
			player2.spend_stat_point("strength")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_J):
			player2.spend_stat_point("agility")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_L):
			player2.spend_stat_point("jump")
			input_timer = input_delay

		elif Input.is_key_pressed(KEY_K):
			player2.spend_stat_point("lifesteal")
			input_timer = input_delay

	# =========================
	# PLAYER 1 UI
	# =========================
	p1_points.text = "P1 Points: " + str(player1.available_stat_points)

	p1_strength.text = "Strength: " + str(player1.strength_points)

	p1_agility.text = "Agility: " + str(player1.agility_points)

	p1_jump.text = "Jump: " + str(player1.jump_points)

	p1_lifesteal.text = "Life Steal: " + str(player1.lifesteal_points)

	# =========================
	# PLAYER 2 UI
	# =========================
	p2_points.text = "P2 Points: " + str(player2.available_stat_points)

	p2_strength.text = "Strength: " + str(player2.strength_points)

	p2_agility.text = "Agility: " + str(player2.agility_points)

	p2_jump.text = "Jump: " + str(player2.jump_points)

	p2_lifesteal.text = "Life Steal: " + str(player2.lifesteal_points)
