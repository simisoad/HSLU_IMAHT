extends Node3D
signal start_position_changed_with_mouse_signal
@export var camera: Camera3D
var mouse: Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse = event.position
	if event.is_action_pressed("get_position_from_Mouse"):
		var new_projectile_start_position: Vector3 = _get_3D_positino_from_mouse()
		#new_projectile_start_position+= Vector3(1,1,1)
		if new_projectile_start_position != Vector3.INF:
			print("new_projectile_start_position: ", Vector3i(new_projectile_start_position))
			Parameters.projectile_start_pos.x = new_projectile_start_position.x
			Parameters.projectile_start_pos.y = new_projectile_start_position.z
			Parameters.projectile_start_pos.z = new_projectile_start_position.y
			emit_signal("start_position_changed_with_mouse_signal")
func _get_3D_positino_from_mouse() -> Vector3:
	var worldspace = camera.get_world_3d().direct_space_state
	var start: Vector3 = camera.project_ray_origin(mouse)
	var end: Vector3  = camera.project_position(mouse, 1000)
	var params = PhysicsRayQueryParameters3D.new()
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.from = start
	params.to = end
	var result: Dictionary = worldspace.intersect_ray(params)
	if not result.is_empty():
		#print(result.get("collider"))
		var result_position: Vector3 = result.get("position")
		return result_position
	else:
		return Vector3.INF
