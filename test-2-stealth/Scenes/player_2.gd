extends CharacterBody2D

# =========================
# DEBUG
# =========================
const DEBUG_HITBOXES = true
const DEBUG_STATS = true

# =========================
# STAT POINTS
# =========================
var available_stat_points = 4

var strength_points = 1
var agility_points = 0
var jump_points = 0
var stat_menu_open = false
const STRENGTH_PER_POINT = 0.25
const AGILITY_PER_POINT = 0.25
const JUMP_PER_POINT = 0.25

# =========================
# STATS
# =========================
var BASE_STRENGTH = 1.0
var BASE_AGILITY = 1.0
var BASE_JUMP = 1.0
var damage = 0

var strength = BASE_STRENGTH
var agility = BASE_AGILITY
var jump_stat = BASE_JUMP

# =========================
# CONSTANTS
# =========================
const BASE_SPEED = 200
const BASE_JUMP_FORCE = -400
const GRAVITY = 800

const DASH_BASE = 600
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

const MAX_JUMPS = 2
const LIGHT_COOLDOWN = 0.3

# =========================
# STATE
# =========================
var jumps_left = MAX_JUMPS
var facing = 1

var is_dashing = false
var can_dash = true
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = 1

var attacking = false
var attack_cooldown = 0.0
var current_attack = ""
var already_hit = []

var current_anim = ""

var stat_input_cooldown = 0.0
const STAT_INPUT_DELAY = 0.5

# =========================
# HITBOX OFFSETS
# =========================
const LIGHT_OFFSET = 40
const HEAVY_OFFSET = 50

# =========================
# NODES
# =========================
@onready var sprite = $AnimatedSprite2D
@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack

#==========================
#StatMenu
#==========================
@onready var stat_menu = $"../UI/StatMenu"

# =========================
# READY
# =========================
func _ready():
	add_to_group("players")

	apply_stats()

	light_hitbox.monitoring = false
	heavy_hitbox.monitoring = false

	light_hitbox.body_entered.connect(_on_light_hitbox_body_entered)
	heavy_hitbox.body_entered.connect(_on_heavy_hitbox_body_entered)

	if DEBUG_HITBOXES:
		print(name, " ready")
		print("Light hitbox: ", light_hitbox)
		print("Heavy hitbox: ", heavy_hitbox)
		print("Players group count: ", get_tree().get_nodes_in_group("players").size())

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):

	handle_stat_debug_input()

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not can_dash:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0:
			can_dash = true

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jumps_left = MAX_JUMPS

	if stat_menu_open:

		handle_stat_debug_input()

		if stat_input_cooldown > 0:
			stat_input_cooldown -= delta

		# stop movement
		velocity.x = 0

	var dir = 0

	if not stat_menu_open:
		dir = Input.get_axis("P2_Left", "P2_Right")

	if dir != 0:
		facing = dir
		sprite.flip_h = facing < 0

	light_hitbox.position.x = facing * LIGHT_OFFSET
	heavy_hitbox.position.x = facing * HEAVY_OFFSET

	if Input.is_action_just_pressed("P2_Jump"):
		var jump_force = BASE_JUMP_FORCE * jump_stat

		if is_on_floor():
			velocity.y = jump_force
			jumps_left = MAX_JUMPS - 1
		elif jumps_left > 0:
			velocity.y = jump_force
			jumps_left -= 1

	if Input.is_action_just_pressed("P2_Dash") and can_dash:
		start_dash()

	if is_dashing:
		velocity.x = dash_direction * (DASH_BASE * agility)
		dash_time_left -= delta

		if dash_time_left <= 0:
			is_dashing = false

	var speed = BASE_SPEED * agility

	if not is_dashing:
		if is_on_floor():
			if dir != 0:
				velocity.x = dir * speed
			else:
				velocity.x = move_toward(velocity.x, 0, 1500 * delta)
		else:
			velocity.x = move_toward(
				velocity.x,
				velocity.x + dir * speed,
				200 * delta
			)

	if Input.is_action_just_pressed("P2_Light_Attack") and not attacking and attack_cooldown <= 0:
		attack(light_hitbox, 0.3, "Light_Attack")
		attack_cooldown = LIGHT_COOLDOWN

	if Input.is_action_just_pressed("P2_Heavy_Attack") and not attacking:
		attack(heavy_hitbox, 0.5, "Heavy_Attack")

	update_animation(dir)

	move_and_slide()

# =========================
# STAT SYSTEM
# =========================
func add_stat_points(amount):
	available_stat_points += amount

	if DEBUG_STATS:
		print(name, " gained ", amount, " stat points. Available: ", available_stat_points)

func spend_stat_point(stat_name):

	if available_stat_points <= 0:
		if DEBUG_STATS:
			print("No stat points available")
		return

	match stat_name:
		"strength":
			strength_points += 1
		"agility":
			agility_points += 1
		"jump":
			jump_points += 1
		_:
			if DEBUG_STATS:
				print("Unknown stat: ", stat_name)
			return

	available_stat_points -= 1
	apply_stats()

func apply_stats():
	strength = BASE_STRENGTH + (strength_points * STRENGTH_PER_POINT)
	agility = BASE_AGILITY + (agility_points * AGILITY_PER_POINT)
	jump_stat = BASE_JUMP + (jump_points * JUMP_PER_POINT)

	if DEBUG_STATS:
		print_stats()

func print_stats():
	print("====== ", name, " STATS ======")
	print("Available Points: ", available_stat_points)
	print("Strength Points: ", strength_points, " | Strength: ", strength)
	print("Agility Points: ", agility_points, " | Agility: ", agility)
	print("Jump Points: ", jump_points, " | Jump Power: ", jump_stat)
	print("==========================")

func handle_stat_debug_input():

	if not stat_menu_open:
		return

	if stat_input_cooldown > 0:
		return

	if Input.is_key_pressed(KEY_I):
		spend_stat_point("strength")
		stat_input_cooldown = STAT_INPUT_DELAY

	if Input.is_key_pressed(KEY_J):
		spend_stat_point("agility")
		stat_input_cooldown = STAT_INPUT_DELAY

	if Input.is_key_pressed(KEY_L):
		spend_stat_point("jump")
		stat_input_cooldown = STAT_INPUT_DELAY

# =========================
# ATTACK SYSTEM
# =========================
func attack(hitbox, duration, anim):

	attacking = true
	current_attack = anim
	already_hit.clear()

	play_anim(anim)

	if DEBUG_HITBOXES:
		print(name, " started attack: ", anim)

	await get_tree().create_timer(0.1).timeout

	hitbox.monitoring = true

	if DEBUG_HITBOXES:
		print(name, " hitbox ON: ", hitbox.name)

	await get_tree().physics_frame

	for body in hitbox.get_overlapping_bodies():
		register_hit(body)

	await get_tree().create_timer(0.1).timeout

	hitbox.monitoring = false

	if DEBUG_HITBOXES:
		print(name, " hitbox OFF: ", hitbox.name)

	await get_tree().create_timer(max(duration - 0.2, 0.0)).timeout

	attacking = false
	current_attack = ""
	already_hit.clear()

	update_animation(Input.get_axis("P2_Left", "P2_Right"))

func register_hit(body):

	if body == self:
		return

	if already_hit.has(body):
		return

	if not body.has_method("take_hit"):
		if DEBUG_HITBOXES:
			print("Hit something without take_hit(): ", body.name)
		return

	already_hit.append(body)

	if current_attack == "Heavy_Attack":
		body.take_hit(global_position, 45, 600 * strength, 15)
	else:
		body.take_hit(global_position, 35, 400 * strength, 8)

	if DEBUG_HITBOXES:
		print(name, " HIT ", body.name, " with ", current_attack)

func _on_light_hitbox_body_entered(body):
	if current_attack == "Light_Attack":
		register_hit(body)

func _on_heavy_hitbox_body_entered(body):
	if current_attack == "Heavy_Attack":
		register_hit(body)

# =========================
# ANIMATION SYSTEM
# =========================
func update_animation(dir):

	if attacking:
		return

	if is_dashing:
		play_anim("Dash")
		return

	if not is_on_floor():
		play_anim("Jump")
		return

	if abs(velocity.x) > 10:
		play_anim("Run")
	else:
		play_anim("Idle")

func play_anim(name):

	if current_anim == name:
		return

	current_anim = name
	sprite.play(name)

# =========================
# DASH
# =========================
func start_dash():

	is_dashing = true
	can_dash = false

	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	dash_direction = facing

# =========================
# HIT
# =========================
func take_hit(pos, angle := 45, force := 400, dmg := 10):

	damage += dmg

	var dir = sign(global_position.x - pos.x)

	if dir == 0:
		dir = 1

	var rad = deg_to_rad(angle)

	velocity.x = cos(rad) * force * dir
	velocity.y = -sin(rad) * force

	if DEBUG_HITBOXES:
		print(name, " took hit. Damage is now: ", damage)
