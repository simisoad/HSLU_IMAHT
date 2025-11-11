extends Control
signal numerical_method(method: int)
signal has_thrust_toggled_signal(has_thrust: bool)
signal calculate_oribital_velocity_signal
signal on_start_position_changed_signal
signal check_for_orbit_toggled_signal(toggled: bool)

func _ready() -> void:
	
	%VisualizeProjectile.set_pressed_no_signal(Parameters.visualize_projectile)
	%SimulationSpeedSlider.custom_minimum_size.x = %VBoxContainer.size.x
	%SimulationSpeedSlider.value = Parameters.simulation_speed
	%SimulationSpeedLabel.text = "Simulation Speed: " + str(Parameters.simulation_speed)
	await get_tree().create_timer(0.1).timeout
	var start_pos_projectile: Vector3 = Parameters.projectile_start_pos
	#print("Gui: Parameters.projectile_start_pos",Parameters.projectile_start_pos)
	%x_LineEdit.text = str(start_pos_projectile.x)
	%y_LineEdit.text = str(start_pos_projectile.y)
	%z_LineEdit.text = str(start_pos_projectile.z)
	%ProjectileHasThrust.set_pressed_no_signal(Parameters.projectile_has_thrust)
	%ProjectileThrustForceLineEdit.text = str(Parameters.projectile_thrust_force).pad_decimals(10)
	%ProjectileThrustDurationLineEdit.text = str(Parameters.projectile_thrust_duration).pad_decimals(10)
	%ProjectileMuzzleVelocityLineEdit.text = str(Parameters.projectile_muzzle_velocity).pad_decimals(10)
	%ProjectileDragCoefficientLineEdit.text = str(Parameters.projectile_drag_coefficient).pad_decimals(10)
	%ProjectileDiameterLineEdit.text = str(Parameters.projectile_diameter).pad_decimals(10)
	%ProjectileAreaLineEdit.text = str(Parameters.projectile_area).pad_decimals(10)
	%ProjectileMassLineEdit.text =  str(Parameters.projectile_mass).pad_decimals(10) 
	%ProjectilePhiXYLineEdit.text = str(Parameters.projectile_phi_xy).pad_decimals(10) 
	%ProjectileThetaInclinationLineEdit.text =  str(Parameters.projectile_theta_inclination).pad_decimals(10)
	%HeightAboveSeaLevelLineEdit.text = str(Parameters.height_above_sea_level).pad_decimals(10)
	%IvpStepSizeLineEdit.text = str(Parameters.ivp_step_size).pad_decimals(10)
	%DynamicStepToleranceLineEdit.text = str(Parameters.dynamic_step_tolerance).pad_decimals(10)
	#await, damit das Signal nicht zu früh los geschickt wird und somit nicht empfangen!
	await get_tree().create_timer(0.1).timeout
	emit_signal("numerical_method", %NumericalMethod.selected)
#	dynamic_step_tolerance
func _on_visualize_projectile_toggled(toggled_on: bool) -> void:
	Parameters.visualize_projectile = toggled_on
	
func _on_simulation_speed_slider_value_changed(value: float) -> void:
	Parameters.simulation_speed = %SimulationSpeedSlider.value
	%SimulationSpeedLabel.text = "Simulation Speed: " + str(Parameters.simulation_speed).pad_decimals(10)
	
func _on_x_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_start_pos.x = _set_new_float_value(new_text, %x_LineEdit, Parameters.projectile_start_pos.x)
	emit_signal("on_start_position_changed_signal")
	
func _on_y_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_start_pos.y = _set_new_float_value(new_text, %y_LineEdit, Parameters.projectile_start_pos.y)
	emit_signal("on_start_position_changed_signal")

func _on_z_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_start_pos.z = _set_new_float_value(new_text, %z_LineEdit, Parameters.projectile_start_pos.z)
	emit_signal("on_start_position_changed_signal")
	
func _on_projectile_has_thrust_toggled(toggled_on: bool) -> void:
	Parameters.projectile_has_thrust = toggled_on
	emit_signal("has_thrust_toggled_signal", toggled_on)

func _on_projectile_thrust_force_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_thrust_force = _set_new_float_value(new_text, %ProjectileThrustForceLineEdit, Parameters.projectile_thrust_force)
	
func _on_projectile_thrust_duration_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_thrust_duration = _set_new_float_value(new_text, %ProjectileThrustDurationLineEdit, Parameters.projectile_thrust_duration)

func _on_projectile_muzzle_velocity_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		var velocity: float = new_text.to_float()
		velocity *= Parameters.scale_down_factor
		new_text = str(velocity)
	Parameters.projectile_muzzle_velocity = _set_new_float_value(new_text, %ProjectileMuzzleVelocityLineEdit, Parameters.projectile_muzzle_velocity)
	
func _on_projectile_drag_coefficient_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_drag_coefficient = _set_new_float_value(new_text, %ProjectileDragCoefficientLineEdit, Parameters.projectile_drag_coefficient)

func _on_projectile_diameter_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_diameter = _set_new_float_value(new_text, %ProjectileDiameterLineEdit, Parameters.projectile_diameter)


func _on_projectile_area_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_area = _set_new_float_value(new_text, %ProjectileAreaLineEdit, Parameters.projectile_area)


func _on_projectile_mass_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_mass = _set_new_float_value(new_text, %ProjectileMassLineEdit, Parameters.projectile_mass)


func _on_projectile_phi_xy_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_phi_xy = _set_new_float_value(new_text, %ProjectilePhiXYLineEdit, Parameters.projectile_phi_xy)


func _on_projectile_theta_inclination_line_edit_text_changed(new_text: String) -> void:
	Parameters.projectile_theta_inclination = _set_new_float_value(new_text, %ProjectileThetaInclinationLineEdit, Parameters.projectile_theta_inclination)


func _on_height_above_sea_level_line_edit_text_changed(new_text: String) -> void:
	Parameters.height_above_sea_level = _set_new_float_value(new_text, %HeightAboveSeaLevelLineEdit, Parameters.height_above_sea_level)


func _on_ivp_step_size_line_edit_text_changed(new_text: String) -> void:
	Parameters.ivp_step_size = _set_new_float_value(new_text, %IvpStepSizeLineEdit, Parameters.ivp_step_size)

func _on_dynamic_step_tolerance_line_edit_text_changed(new_text: String) -> void:
	Parameters.dynamic_step_tolerance = _set_new_float_value(new_text, %DynamicStepToleranceLineEdit, Parameters.dynamic_step_tolerance)
	
func _set_new_float_value(new_text: String, line_edit: LineEdit, parameter_value: float) -> float:
	
	if new_text.is_valid_float():
		var new_value: float = new_text.to_float()
		parameter_value = new_value
	else:
		line_edit.text = str(parameter_value).pad_decimals(10)
	return parameter_value

func _on_numerical_method_item_selected(index: int) -> void:
	Parameters.numerical_method = index
	emit_signal("numerical_method",index)
	
func _on_planet_radius_changed() -> void:
	var start_pos_projectile: Vector3 = Parameters.projectile_start_pos
	#print("Gui: Parameters.projectile_start_pos",Parameters.projectile_start_pos)
	%x_LineEdit.text = str(start_pos_projectile.x)
	%y_LineEdit.text = str(start_pos_projectile.y)
	%z_LineEdit.text = str(start_pos_projectile.z)
	

func _on_calculate_oribital_velocity_button_pressed() -> void:
	emit_signal("calculate_oribital_velocity_signal")
	
func _on_orbital_velocity_calculated(orbital_velocity: float) -> void:
	
	print("_on_orbital_velocity_calculated! Parameters.scale_up_factor: ", Parameters.scale_up_factor)
	%ProjectileMuzzleVelocityLineEdit.text = str(orbital_velocity*Parameters.scale_up_factor)

func _on_start_position_changed_signal() -> void:
	_on_planet_radius_changed()


func _on_check_for_orbit_check_button_toggled(toggled_on: bool) -> void:
	emit_signal("check_for_orbit_toggled_signal", toggled_on)
	pass # Replace with function body.

func _on_angle_optimized_signal(angle: float) -> void:
	angle = rad_to_deg(angle)
	Parameters.projectile_theta_inclination = angle
	%ProjectileThetaInclinationLineEdit.text = str(angle).pad_decimals(10)
