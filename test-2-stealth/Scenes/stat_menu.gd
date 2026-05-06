extends Control

@onready var player1 = $"../../Player"
@onready var player2 = $"../../Player_2"

@onready var p1_points = $Panel/P1Points
@onready var p1_strength = $Panel/P1Strength
@onready var p1_agility = $Panel/P1Agility
@onready var p1_jump = $Panel/P1Jump

@onready var p2_points = $Panel/P2Points
@onready var p2_strength = $Panel/P2Strength
@onready var p2_agility = $Panel/P2Agility
@onready var p2_jump = $Panel/P2Jump

func _process(delta):

	# update player 1
	p1_points.text = "P1 Points: " + str(player1.available_stat_points)
	p1_strength.text = "Strength: " + str(player1.strength_points)
	p1_agility.text = "Agility: " + str(player1.agility_points)
	p1_jump.text = "Jump: " + str(player1.jump_points)

	# update player 2
	p2_points.text = "P2 Points: " + str(player2.available_stat_points)
	p2_strength.text = "Strength: " + str(player2.strength_points)
	p2_agility.text = "Agility: " + str(player2.agility_points)
	p2_jump.text = "Jump: " + str(player2.jump_points)
