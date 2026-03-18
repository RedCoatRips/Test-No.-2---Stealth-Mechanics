extends CharacterBody2D

const SPEED = 200.0

func _physics_process(_delta):
	# Get input direction (W, A, S, D or Arrow Keys)
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	
	velocity = direction * SPEED
	move_and_slide()
