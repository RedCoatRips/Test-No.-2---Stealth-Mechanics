extends CanvasLayer

# =========================
# UI REFERENCES
# =========================
@onready var p1_label = $P1_Damage
@onready var p2_label = $P2_Damage

@onready var p1_stocks = $P1_Stocks
@onready var p2_stocks = $P2_Stocks

@onready var stat_menu = $StatMenu

# =========================
# PLAYERS
# =========================
var player1 = null
var player2 = null

# =========================
# READY
# =========================
func _ready():

	player1 = get_node("../Player")
	player2 = get_node("../Player_2")

	stat_menu.visible = false

# =========================
# PROCESS
# =========================
func _process(_delta):

	# =========================
	# TOGGLE MENU
	# =========================
	if Input.is_action_just_pressed("Toggle_Stats_Menu"):

		stat_menu.visible = !stat_menu.visible

		player1.stat_menu_open = stat_menu.visible
		player2.stat_menu_open = stat_menu.visible

	# =========================
	# DAMAGE UI
	# =========================
	if player1 != null:
		update_label(p1_label, player1.damage)

	if player2 != null:
		update_label(p2_label, player2.damage)

	# =========================
	# STOCKS
	# =========================
	if player1 != null:
		p1_stocks.text = "Stocks: " + str(player1.stocks)

	if player2 != null:
		p2_stocks.text = "Stocks: " + str(player2.stocks)

# =========================
# DAMAGE LABEL
# =========================
func update_label(label, dmg):

	label.text = str(int(dmg)) + "%"

	label.modulate = get_damage_color(dmg)

	var scale_amount = 1 + (dmg / 200.0)

	label.scale = Vector2(scale_amount, scale_amount)

# =========================
# DAMAGE COLORS
# =========================
func get_damage_color(dmg):

	if dmg < 50:
		return Color.WHITE

	elif dmg < 100:
		return Color.YELLOW

	elif dmg < 150:
		return Color.ORANGE

	else:
		return Color.RED
