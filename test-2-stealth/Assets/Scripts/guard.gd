extends CharacterBody2D

@onready var vision_ray = $RayCast2D

func _process(_delta):
	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider.name == "Player":
			print("SPOTTED!") 
			# Later, you can add: get_tree().reload_current_scene()  
			
