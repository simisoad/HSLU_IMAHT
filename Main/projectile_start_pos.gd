extends Marker3D
var start_direction_pos_y: float

func _on_planet_radius_changed() ->void:
	print("_on_planet_radius_changed")
	self.global_position.y = Parameters.planet_radius
	
func _on_start_position_changed_signal() -> void:
	self.global_position.x = Parameters.projectile_start_pos.x
	self.global_position.y = Parameters.projectile_start_pos.z
	self.global_position.z = Parameters.projectile_start_pos.y
	
func _ready() -> void:
	start_direction_pos_y = %StartDirection.mesh.height/2
	%StartDirection.position.y += start_direction_pos_y
	pass
	
func _process(delta: float) -> void:
	%StartDirectionRotation.rotation.y = deg_to_rad(-Parameters.projectile_phi_xy)
	%StartDirectionRotation.rotation.z = deg_to_rad(Parameters.projectile_theta_inclination)-PI/2
	
