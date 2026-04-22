extends Control

@onready var label = $WinnerText

func show_winner(player_name: String):
	visible = true
	label.text = player_name + " WINS!"
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
