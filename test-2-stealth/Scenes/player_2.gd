extends CharacterBody2D

const SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 800

const DASH_SPEED = 600
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

#Double Jump
const MAX_JUMPS = 2
var jumps_left = MAX_JUMPS

var is_dashing = false
var can_dash = true
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = 1

var attacking = false
var current_attack = ""
var current_anim = ""
var light_shape_base_x = 0
var heavy_shape_base_x = 0
const KNOCKBACK_X = 150   # horizontal force
const KNOCKBACK_Y = -50  # vertical lift
var damage = 0 #Damage System
const LIGHT_HIT_FREEZE = 0.01 #Hit Freeze Time
const HEAVY_HIT_FREEZE = 0.015
var hitstun = 0.0 #HitStun
const HITSTUN_TIME = 0.2
const CRIT_DAMAGE_THRESHOLD = 100 #Percentage until Crit
const CRIT_MULTIPLIER = 2.5
@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack
@onready var sprite = $AnimatedSprite2D
@onready var light_shape = $LightAttack/CollisionShape2D
@onready var heavy_shape = $HeavyAttack/CollisionShape2D

var facing = 1

func _physics_process(delta):

# --- HITSTUN TIMER ---
	if hitstun > 0:
		hitstun -= delta

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		jumps_left = MAX_JUMPS

	# --- INPUT ---
	var dir = Input.get_axis("P2_Left", "P2_Right")

	# --- FACING ---
	if dir != 0:
		facing = dir
		sprite.flip_h = facing < 0

# --- HITBOX FLIP ---
	light_hitbox.scale.x = facing
	heavy_hitbox.scale.x = facing

	# --- JUMP / DOUBLE JUMP ---
	if Input.is_action_just_pressed("P2_Jump"):
		if is_on_floor():
			velocity.y = JUMP_FORCE
			jumps_left = MAX_JUMPS - 1
		elif jumps_left > 0:
			velocity.y = JUMP_FORCE
			jumps_left -= 11

	# --- DASH ---
	if Input.is_action_just_pressed("P2_Dash") and can_dash:
		start_dash()

	# --- DASH MOVEMENT ---
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	# --- MOVEMENT ---
	if not is_dashing:

		if hitstun > 0:
			# ADD small influence (does NOT cancel knockback)
			velocity.x += dir * SPEED * 0.1 * delta

		else:
			# Normal control
			if is_on_floor():
				if dir != 0:
					velocity.x = dir * SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, 1500 * delta)
			else:
				velocity.x = move_toward(velocity.x, velocity.x + dir * SPEED, 200 * delta)

	# --- DASH COOLDOWN ---
	if not can_dash:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0:
			can_dash = true

	# --- ATTACKS ---
	if Input.is_action_just_pressed("P2_Light_Attack") and not attacking:
		current_attack = "Light_Attack"
		attack(light_hitbox, 0.4, "Light_Attack")

	if Input.is_action_just_pressed("P2_Heavy_Attack") and not attacking:
		current_attack = "Heavy_Attack"
		attack(heavy_hitbox, 0.5, "Heavy_Attack")

	# --- ANIMATION ---
	update_animation(dir)

# --- KNOCKBACK DECAY (AIR ONLY) ---
	if not is_on_floor():
		velocity.x *= 0.98

	# --- BLAST ZONE CHECK ---
	if global_position.y > 1000 or global_position.y < -500 or global_position.x > 1500 or global_position.x < -1500:
		respawn()

	move_and_slide()

func respawn():

	global_position = Vector2(424, 34)  # spawn point
	velocity = Vector2.ZERO

	damage = 0
	jumps_left = MAX_JUMPS
	hitstun = 0

	# Optional: small freeze for effect
	hit_freeze(0.05)

func _ready():
	light_shape_base_x = light_shape.position.x
	heavy_shape_base_x = heavy_shape.position.x

#Hit Freeze
func hit_freeze(time := 0.05):
	Engine.time_scale = 0.05   # slow almost to stop
	
	await get_tree().create_timer(time).timeout
	
	Engine.time_scale = 1.0    # restore normal speed

#Hit Flash
func hit_flash():
	# slightly white (not full white)
	sprite.modulate = Color(1.3, 1.3, 1.3)

	await get_tree().create_timer(0.08).timeout

	sprite.modulate = Color(1, 1, 1)
#Take Hit
func take_hit(attacker_pos: Vector2, base_kb_x := 300, base_kb_y := -200, damage_add := 10):

	var direction = sign(global_position.x - attacker_pos.x)

	# --- ADD DAMAGE ---
	damage += damage_add

	# --- BASE SCALING ---
	var kb_scale = 1.0 + (damage / 120.0)

	# --- HIGH DAMAGE BOOST (SMASH FEEL) ---
	if damage > 80:
		kb_scale += (damage - 80) / 100.0

	# --- APPLY KNOCKBACK ---
	velocity.x = direction * base_kb_x * kb_scale
	velocity.y = base_kb_y * kb_scale

	# --- HITSTUN SCALES TOO ---
	hitstun = 0.1 + (damage / 200.0)

	hit_flash()
	hit_freeze(0.05)

func start_dash():
	is_dashing = true
	can_dash = false

	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	dash_direction = facing

func attack(hitbox: Area2D, duration: float, anim_name: String):
	if attacking:
		return

	attacking = true
	
	sprite.stop()
	sprite.play(anim_name)

	hitbox.monitoring = true 

	var t = get_tree().create_timer(duration)
	await t.timeout

	hitbox.monitoring = false
	attacking = false

	sprite.play("Idle")

func update_animation(dir):

	if attacking:
		return  # DO NOT override attack animation

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

func play_anim(name: String):
	if sprite.animation == name:
		return
	sprite.play(name)

func _on_light_attack_body_entered(body):
	if body != self and body.has_method("take_hit"):
		body.take_hit(global_position)
		hit_freeze(LIGHT_HIT_FREEZE)

func _on_heavy_attack_body_entered(body):
	if body != self and body.has_method("take_hit"):
		body.take_hit(global_position, 400, -250, 15)
		hit_freeze(HEAVY_HIT_FREEZE)
