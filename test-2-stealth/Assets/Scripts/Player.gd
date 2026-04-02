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
@onready var dash_effect_scene = preload("res://Scenes/dash_effect.tscn")
# --------------------
# ATTACKS
# --------------------
var attacking = false

@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack
@onready var anim = get_node_or_null("AnimationPlayer")
@onready var sprite = $Sprite2D

# --------------------
# FACING
# --------------------
var facing = 1  # 1 = right, -1 = left

# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta):

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- INPUT ---
	var dir = Input.get_axis("Left", "Right")

	# --- UPDATE FACING ---
	if dir != 0:
		facing = dir
		sprite.flip_h = facing < 0

	# --- JUMP ---
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# --- DASH INPUT ---
	if Input.is_action_just_pressed("Dash") and can_dash:
		start_dash()

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
	if Input.is_action_just_pressed("Light_Attack") and not attacking:
		attack(light_hitbox, 0.2, "Light_Attack")

	if Input.is_action_just_pressed("Heavy_Attack") and not attacking:
		attack(heavy_hitbox, 0.4, "Heavy_Attack")

	# --- ANIMATION ---
	update_animation(dir)

	move_and_slide()

# --------------------
# DASH
# --------------------
func start_dash():
	is_dashing = true
	can_dash = false

	spawn_dash_effect()

	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN

	dash_direction = facing

	play_anim("dash")

func spawn_dash_effect():
	var effect = dash_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
# --------------------
# ATTACK
# --------------------
func attack(hitbox: Area2D, duration: float, anim_name: String):
	attacking = true
	play_anim(anim_name)

	hitbox.monitoring = true
	await get_tree().create_timer(duration).timeout
	hitbox.monitoring = false

	attacking = false

# --------------------
# KNOCKBACK
# --------------------
func take_hit(attacker_pos: Vector2):
	var direction = sign(global_position.x - attacker_pos.x)
	velocity.x = direction * 400
	velocity.y = -250

# --------------------
# ANIMATION LOGIC
# --------------------
func update_animation(dir):

	if attacking:
		return

	if is_dashing:
		play_anim("dash")
		return

	if not is_on_floor():
		play_anim("jump")
		return

	if dir != 0:
		play_anim("run")
	else:
		play_anim("idle")

# --------------------
# SAFE ANIMATION PLAY
# --------------------
func play_anim(_String):
	if anim == null:
		return
		
	if anim.current_animation != name:
		anim.play(name)
