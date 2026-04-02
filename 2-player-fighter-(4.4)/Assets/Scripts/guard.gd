extends CharacterBody2D

@onready var ray = $RayCast2D

var speed = 100
var direction = -1

func _physics_process(delta):
	velocity.x = direction * speed
	move_and_slide()

	# Turn around on wall
	if is_on_wall():
		direction *= -1
		scale.x *= -1

	# Vision check
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.name == "Player":
			get_tree().reload_current_scene()
