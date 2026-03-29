extends CharacterBody2D

const SPEED = 200
const JUMP_FORCE = -400
const GRAVITY = 900

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("P2_Jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# Movement
	var dir = Input.get_axis("P2_Left", "P2_Right")
	velocity.x = dir * SPEED

	move_and_slide()
