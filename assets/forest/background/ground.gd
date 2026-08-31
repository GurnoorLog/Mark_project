extends StaticBody2D

func _physics_process(_dt):
	var cam = get_viewport().get_camera_2d()
	if cam:
		position.x = cam.global_position.x
