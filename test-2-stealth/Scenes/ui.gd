extends CanvasLayer

@onready var p1_label = $P1_Damage
@onready var p2_label = $P2_Damage

var player1 = null
var player2 = null

func _ready():
	# Adjust paths if your nodes are named differently
	player1 = get_node("../Player")
	player2 = get_node("../Player_2")

func _process(_delta):

	if player1 != null:
		update_label(p1_label, player1.damage)

	if player2 != null:
		update_label(p2_label, player2.damage)

# --- UPDATE LABEL ---
func update_label(label, dmg):

	label.text = str(int(dmg)) + "%"

	# Color based on damage
	label.modulate = get_damage_color(dmg)

	# Scale based on damage (Smash feel)
	var scale_amount = 1 + (dmg / 200.0)
	label.scale = Vector2(scale_amount, scale_amount)

# --- DAMAGE COLOR SYSTEM ---
func get_damage_color(dmg):

	if dmg < 50:
		return Color(1, 1, 1) # White

	elif dmg < 100:
		return Color(1, 1, 0) # Yellow

	elif dmg < 150:
		return Color(1, 0.5, 0) # Orange

	else:
		return Color(1, 0, 0) # Red
