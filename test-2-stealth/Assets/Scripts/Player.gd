extends CharacterBody2D

# =========================
# STOCKS
# =========================
var stocks = 3
var respawn_position = Vector2.ZERO

# =========================
# BLAST ZONES
# =========================
var BLAST_TOP = -2000
var BLAST_BOTTOM = 2000
var BLAST_LEFT = -4000
var BLAST_RIGHT = 4000

# =========================
# MOVEMENT
# =========================
var RUN_SPEED = 260.0
var AIR_ACCELERATION = 900.0
var ACCELERATION = 1800.0
var FRICTION = 2000.0

# =========================
# JUMP
# =========================
var JUMP_FORCE = -460.0
var DOUBLE_JUMP_FORCE = -430.0
var BASE_JUMPS = 2

# =========================
# WALL SYSTEM
# =========================
var WALL_SLIDE_SPEED = 120.0
var WALL_JUMP_X = 500.0
var WALL_JUMP_Y = -500.0
var WALL_HOLD_GRAVITY = 100.0

var wall_sliding = false
var wall_direction = 0

# =========================
# GRAVITY
# =========================
var GRAVITY = 1000
var FAST_FALL_GRAVITY = 2600.0
var MAX_FALL_SPEED = 1500.0

# =========================
# DASH
# =========================
var DASH_SPEED = 700.0
var DASH_TIME = 0.14
var DASH_COOLDOWN = 0.45

# =========================
# AIR DODGE
# =========================
var AIR_DODGE_SPEED = 800.0
var AIR_DODGE_TIME = 0.20
var AIR_DODGE_INVINCIBILITY = 2.0

# =========================
# ATTACKS
# =========================
var LIGHT_DAMAGE = 8
var HEAVY_DAMAGE = 15

var LIGHT_FORCE = 200
var HEAVY_FORCE = 400

var LIGHT_ANGLE = 35
var HEAVY_ANGLE = 45

var LIGHT_COOLDOWN = 0.20
var HEAVY_COOLDOWN = 0.45

# =========================
# COMBOS
# =========================
var combo_step = 0
var combo_timer = 0.0
var COMBO_RESET_TIME = 0.8

# =========================
# STATS
# =========================
var available_stat_points = 4

var strength_points = 1
var agility_points = 1
var jump_points = 1
var lifesteal_points = 1

# =========================
# STAT SCALING
# =========================
var STRENGTH_PER_POINT = 0.25
var AGILITY_PER_POINT = 0.15
var JUMP_PER_POINT = 0.20
var LIFE_STEAL_PER_POINT = 0.1

# =========================
# FINAL STATS
# =========================
var strength = 1.0
var agility = 1.0
var jump_stat = 1.0

# =========================
# DAMAGE
# =========================
var damage = 0.0

# =========================
# STATE
# =========================
var jumps_left = 2
var facing = 1

var attacking = false
var attack_cooldown = 0.0

var is_dashing = false
var dash_timer = 0.0

var can_dash = true
var dash_cooldown = 0.0

var is_air_dodging = false

var invincible = false
var invincible_timer = 0.0

var stat_menu_open = false

var current_anim = ""
var current_attack = ""

# =========================
# HITBOXS
# =========================
const LIGHT_OFFSET = 40
const HEAVY_OFFSET = 60

# =========================
# NODES
# =========================
@onready var sprite = $AnimatedSprite2D
@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack

# =========================
# READY
# =========================
func _ready():

	respawn_position = global_position

	light_hitbox.monitoring = false
	heavy_hitbox.monitoring = false

	light_hitbox.body_entered.connect(_on_light_hitbox_body_entered)
	heavy_hitbox.body_entered.connect(_on_heavy_hitbox_body_entered)

	apply_stats()

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):

	check_blast_zone()

	# cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_step = 0

	if dash_cooldown > 0:
		dash_cooldown -= delta
	else:
		can_dash = true

	if invincible_timer > 0:
		invincible_timer -= delta
	else:
		invincible = false

	# =========================
	# INPUT
	# =========================
	var dir = 0

	if not stat_menu_open:
		dir = Input.get_axis("Left", "Right")

	# =========================
	# WALL DETECTION
	# =========================
	wall_sliding = false

	if is_on_wall() and not is_on_floor() and velocity.y > 0:

		wall_sliding = true

		if get_wall_normal().x > 0:
			wall_direction = 1
		else:
			wall_direction = -1

	# =========================
	# GRAVITY
	# =========================
	if not is_on_floor():

		if wall_sliding:

			velocity.y += WALL_HOLD_GRAVITY * delta
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

		elif Input.is_action_pressed("Down"):

			velocity.y += FAST_FALL_GRAVITY * delta

		else:

			velocity.y += GRAVITY * delta

	else:

		jumps_left = BASE_JUMPS + max(0, agility_points - 2)

	velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# =========================
	# FACING
	# =========================
	if dir != 0:
		facing = sign(dir)
		sprite.flip_h = facing < 0

	# =========================
	# HITBOX POSITIONS
	# =========================
	light_hitbox.position.x = LIGHT_OFFSET * facing
	heavy_hitbox.position.x = HEAVY_OFFSET * facing

	# =========================
	# JUMP
	# =========================
	if not stat_menu_open and Input.is_action_just_pressed("Jump"):

		# WALL JUMP
		if wall_sliding:

			velocity.x = WALL_JUMP_X * wall_direction
			velocity.y = WALL_JUMP_Y

			wall_sliding = false

		elif is_on_floor():

			velocity.y = JUMP_FORCE * jump_stat
			jumps_left -= 1

		elif jumps_left > 0:

			velocity.y = DOUBLE_JUMP_FORCE * jump_stat
			jumps_left -= 1

	# =========================
	# DASH / AIR DODGE
	# =========================
	if not stat_menu_open and Input.is_action_just_pressed("Dash"):

		if not is_on_floor():
			start_air_dodge(dir)

		elif can_dash:
			start_dash()

	# =========================
	# DASH MOVEMENT
	# =========================
	if is_dashing:

		dash_timer -= delta

		velocity.x = DASH_SPEED * facing

		if dash_timer <= 0:
			is_dashing = false

	# =========================
	# NORMAL MOVEMENT
	# =========================
	if not is_dashing and not is_air_dodging and not wall_sliding:

		var target_speed = dir * RUN_SPEED * agility

		if is_on_floor():

			velocity.x = move_toward(
				velocity.x,
				target_speed,
				ACCELERATION * delta
			)

			if dir == 0:
				velocity.x = move_toward(
					velocity.x,
					0,
					FRICTION * delta
				)

		else:

			velocity.x = move_toward(
				velocity.x,
				target_speed,
				AIR_ACCELERATION * delta
			)

	# =========================
	# ATTACKS
	# =========================
	if not stat_menu_open:

		if Input.is_action_just_pressed("Light_Attack"):
			do_light_attack()

		if Input.is_action_just_pressed("Heavy_Attack"):
			do_heavy_attack()

	update_animation(dir)

	move_and_slide()

# =========================
# STAT SYSTEM
# =========================
func spend_stat_point(stat_name):

	if available_stat_points <= 0:
		return

	match stat_name:

		"strength":
			strength_points += 1

		"agility":
			agility_points += 1

		"jump":
			jump_points += 1

		"lifesteal":
			lifesteal_points += 1

	available_stat_points -= 1

	apply_stats()

func apply_stats():

	strength = 1.0 + (strength_points * STRENGTH_PER_POINT)

	agility = 1.0 + (agility_points * AGILITY_PER_POINT)

	jump_stat = 1.0 + (jump_points * JUMP_PER_POINT)

# =========================
# ATTACKS
# =========================
func do_light_attack():

	if attacking or attack_cooldown > 0:
		return

	attacking = true

	combo_step += 1

	if combo_step > 3:
		combo_step = 1

	combo_timer = COMBO_RESET_TIME

	play_anim("Light_Attack")

	light_hitbox.monitoring = true

	await get_tree().create_timer(0.12).timeout

	light_hitbox.monitoring = false

	await get_tree().create_timer(0.15).timeout

	attacking = false

	attack_cooldown = LIGHT_COOLDOWN

func do_heavy_attack():

	if attacking:
		return

	attacking = true

	play_anim("Heavy_Attack")

	heavy_hitbox.monitoring = true

	await get_tree().create_timer(0.16).timeout

	heavy_hitbox.monitoring = false

	await get_tree().create_timer(0.25).timeout

	attacking = false

	attack_cooldown = HEAVY_COOLDOWN

# =========================
# HIT
# =========================
func register_hit(body, damage_amount, force, angle):

	if body == self:
		return

	if not body.has_method("take_hit"):
		return

	body.take_hit(global_position, angle, force * strength, damage_amount)

	var steal = damage_amount * (lifesteal_points * LIFE_STEAL_PER_POINT)

	damage = max(0, damage - steal)

func take_hit(pos, angle := 45, force := 400, dmg := 10):

	if invincible:
		return

	damage += dmg

	var kb_scale = 1.0 + (damage / 100.0)

	var dir = sign(global_position.x - pos.x)

	var rad = deg_to_rad(angle)

	velocity.x = cos(rad) * force * kb_scale * dir
	velocity.y = -sin(rad) * force * kb_scale

# =========================
# HITBOX CALLBACKS
# =========================
func _on_light_hitbox_body_entered(body):

	register_hit(body, LIGHT_DAMAGE, LIGHT_FORCE, LIGHT_ANGLE)

func _on_heavy_hitbox_body_entered(body):

	register_hit(body, HEAVY_DAMAGE, HEAVY_FORCE, HEAVY_ANGLE)

# =========================
# DASH
# =========================
func start_dash():

	is_dashing = true
	can_dash = false

	dash_timer = DASH_TIME
	dash_cooldown = DASH_COOLDOWN

func start_air_dodge(dir):

	is_air_dodging = true

	invincible = true
	invincible_timer = AIR_DODGE_INVINCIBILITY

	velocity.x = dir * AIR_DODGE_SPEED

	await get_tree().create_timer(AIR_DODGE_TIME).timeout

	is_air_dodging = false

# =========================
# STOCKS
# =========================
func lose_stock():

	if stocks <= 0:
		return

	stocks -= 1

	available_stat_points += 2

	damage = 0

	global_position = respawn_position

	velocity = Vector2.ZERO

func check_blast_zone():

	if (
		global_position.y > BLAST_BOTTOM
		or global_position.y < BLAST_TOP
		or global_position.x < BLAST_LEFT
		or global_position.x > BLAST_RIGHT
	):
		lose_stock()

# =========================
# ANIMATION
# =========================
func update_animation(dir):

	if attacking:
		return

	if wall_sliding:
		play_anim("Jump")
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

func play_anim(anim):

	if current_anim == anim:
		return

	current_anim = anim

	sprite.play(anim)
