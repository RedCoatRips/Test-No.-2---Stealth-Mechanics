extends CharacterBody2D

const SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 800

const DASH_SPEED = 600
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

var is_dashing = false
var can_dash = true
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = 1

var attacking = false
var current_attack = ""
var current_anim = ""

@onready var light_hitbox = $LightAttack
@onready var heavy_hitbox = $HeavyAttack
@onready var sprite = $AnimatedSprite2D

var facing = 1

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var dir = Input.get_axis("P2_Left", "P2_Right")

	if dir != 0:
		facing = dir
		sprite.flip_h = facing < 0

	if Input.is_action_just_pressed("P2_Jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	if Input.is_action_just_pressed("P2_Dash") and can_dash:
		start_dash()

	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	if not is_dashing:
		if dir != 0:
			velocity.x = dir * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	if not can_dash:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0:
			can_dash = true

	if Input.is_action_just_pressed("P2_Light_Attack") and not attacking:
		current_attack = "Light_Attack"
		attack(light_hitbox, 0.2)

	if Input.is_action_just_pressed("P2_Heavy_Attack") and not attacking:
		current_attack = "Heavy_Attack"
		attack(heavy_hitbox, 0.5)

	update_animation(dir)
	move_and_slide()

func start_dash():
	is_dashing = true
	can_dash = false

	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	dash_direction = facing

func attack(hitbox: Area2D, duration: float):
	attacking = true
	hitbox.monitoring = true

	var t = get_tree().create_timer(duration)
	await t.timeout

	hitbox.monitoring = false
	attacking = false

func update_animation(dir):

	if attacking:
		play_anim(current_attack)
		return

	if is_dashing:
		play_anim("Dash")
		return

	if not is_on_floor():
		play_anim("Jump")
		return

	if dir != 0:
		play_anim("Run")
	else:
		play_anim("Idle")

func play_anim(name: String):
	if sprite.animation == name and sprite.is_playing():
		return
		
	sprite.play(name)
	sprite.speed_scale = 1.0   # force fix

func _on_light_attack_body_entered(body):
	if body != self and body.is_in_group("player"):
		body.take_hit(global_position)

func _on_heavy_attack_body_entered(body):
	if body != self and body.is_in_group("player"):
		body.take_hit(global_position + Vector2(-200 * facing, 0))
