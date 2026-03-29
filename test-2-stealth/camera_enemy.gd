extends Node2D

@onready var ray = $RayCast2D

var rotation_speed = 1.5

func _process(delta):
	rotation += sin(Time.get_ticks_msec() / 1000.0) * rotation_speed * delta

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.name == "Player":
			get_tree().reload_current_scene()
