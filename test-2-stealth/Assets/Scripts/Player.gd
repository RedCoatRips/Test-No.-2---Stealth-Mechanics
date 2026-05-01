extends CharacterBody2D

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

# Smash-style push strength
const PUSH_FORCE = 120

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
var current_anim = ""

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

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):

	# cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jumps_left = MAX_JUMPS

	# input
	var dir = Input.get_axis("Left", "Right")

	# facing
	if dir != 0:
		facing = dir
		sprite.flip_h = facing < 0

	# hitbox positioning (CORRECT WAY)
	light_hitbox.position.x = facing * LIGHT_OFFSET
	heavy_hitbox.position.x = facing * HEAVY_OFFSET

	# jump
	if Input.is_action_just_pressed("Jump"):
		var jump_force = BASE_JUMP_FORCE * jump_stat
		if is_on_floor():
			velocity.y = jump_force
			jumps_left = MAX_JUMPS - 1
		elif jumps_left > 0:
			velocity.y = jump_force
			jumps_left -= 1

	# dash
	if Input.is_action_just_pressed("Dash") and can_dash:
		start_dash()

	if is_dashing:
		velocity.x = dash_direction * (DASH_BASE * agility)
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	# movement
	var speed = BASE_SPEED * agility

	if not is_dashing:
		if is_on_floor():
			if dir != 0:
				velocity.x = dir * speed
			else:
				velocity.x = move_toward(velocity.x, 0, 1500 * delta)
		else:
			velocity.x = move_toward(velocity.x, velocity.x + dir * speed, 200 * delta)

	# attacks
	if Input.is_action_just_pressed("Light_Attack") and not attacking and attack_cooldown <= 0:
		attack(light_hitbox, 0.3, "Light_Attack")
		attack_cooldown = LIGHT_COOLDOWN

	if Input.is_action_just_pressed("Heavy_Attack") and not attacking:
		attack(heavy_hitbox, 0.5, "Heavy_Attack")

	# MOVE FIRST
	move_and_slide()

	# =========================
	# SMASH-STYLE PLAYER COLLISION
	# =========================

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		print("HIT:", col.get_collider())
		var other = col.get_collider()

		if other is CharacterBody2D:
			var push_dir = sign(global_position.x - other.global_position.x)

			# smooth push (NO JITTER)
			other.velocity.x = lerp(other.velocity.x, -push_dir * PUSH_FORCE, 0.2)

	# animation
	update_animation(dir)

# =========================
# ATTACK
# =========================
func attack(hitbox, duration, anim):

	attacking = true
	sprite.play(anim)

	# startup
	await get_tree().create_timer(0.1).timeout
	hitbox.monitoring = true

	# active frames
	await get_tree().create_timer(0.1).timeout
	hitbox.monitoring = false

	# recovery
	await get_tree().create_timer(duration - 0.2).timeout

	attacking = false

	# FORCE animation recovery
	update_animation(Input.get_axis("Left", "Right"))

# =========================
# ANIMATION
# =========================
func update_animation(dir):

	if attacking:
		return

	if is_dashing:
		play_anim("Dash")
	elif not is_on_floor():
		play_anim("Jump")
	elif abs(velocity.x) > 10:
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
	var rad = deg_to_rad(angle)

	velocity.x = cos(rad) * force * strength * dir
	velocity.y = -sin(rad) * force * strength
