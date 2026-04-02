extends CharacterBody2D

# --------------------
# MOVEMENT
# --------------------
const SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 900

# --------------------
# DASH
# --------------------
const DASH_SPEED = 600
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

var is_dashing = false
var can_dash = true
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = 1

# --------------------
# ATTACKS
# --------------------
var attacking = false

@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack

# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta):

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- INPUT ---
	var dir = Input.get_axis("Left", "Right")

	# --- JUMP ---
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# --- DASH INPUT ---
	if Input.is_action_just_pressed("Dash") and can_dash:
		start_dash(dir)

	# --- DASH MOVEMENT ---
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	# --- NORMAL MOVEMENT ---
	if not is_dashing:
		if dir != 0:
			velocity.x = dir * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	# --- DASH COOLDOWN ---
	if not can_dash:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0:
			can_dash = true

	# --- ATTACKS ---
	if Input.is_action_just_pressed("P2_Light_Attack") and not attacking:
		attack(light_hitbox, 0.2)
	if Input.is_action_just_pressed("P2_Heavy_Attack") and not attacking:
		attack(heavy_hitbox, 0.4)

	move_and_slide()

# --------------------
# DASH HELPER
# --------------------
func start_dash(input_dir):
	is_dashing = true
	can_dash = false
	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN

	dash_direction = input_dir
	if dash_direction == 0:
		dash_direction = 1

# --------------------
# ATTACK HELPER
# --------------------
func attack(hitbox: Area2D, duration: float) -> void:
	attacking = true
	hitbox.monitoring = true
	await get_tree().create_timer(duration).timeout
	hitbox.monitoring = false
	attacking = false

# --------------------
# KNOCKBACK SYSTEM
# Call this on hit:
# player.take_hit(attacker.global_position)
# --------------------
func take_hit(attacker_pos: Vector2) -> void:
	var direction = sign(global_position.x - attacker_pos.x)
	velocity.x = direction * 400
	velocity.y = -250
