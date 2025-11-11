extends Control

signal point_size_changed_signal(point_size: float)
signal on_planet_radius_changed_signal()
signal on_toggle_2D_Graph(toggled: bool)
signal on_toggle_atmosphere(toggled: bool)
func _ready() -> void:
	%PointSizeSlider.value = Parameters.point_size
	%PlanetRadiusLineEdit.text = str(Parameters.planet_radius).pad_decimals(10)

func _on_point_size_slider_value_changed(value: float) -> void:
	Parameters.point_size = value
	emit_signal("point_size_changed_signal", value)
	

	
func _set_new_float_value(new_text: String, line_edit: LineEdit, parameter_value: float) -> float:
	
	if new_text.is_valid_float():
		var new_value: float = new_text.to_float()
		parameter_value = new_value
	else:
		line_edit.text = str(parameter_value).pad_decimals(10)
	return parameter_value

func _on_planet_radius_line_edit_text_changed(new_text: String) -> void:
	Parameters.planet_radius = _set_new_float_value(new_text, %PlanetRadiusLineEdit, Parameters.planet_radius)
	Parameters.projectile_start_pos.z = Parameters.planet_radius
	emit_signal("on_planet_radius_changed_signal")

func _process(delta: float) -> void:
	%PlanetMassLabel.text = "Planet Mass: " + str(Parameters.planet_mass)
	%PlanetRadiusLabel.text = "Planet Radius: " + str(Parameters.planet_radius)


func _on_d_graphs_check_button_toggled(toggled_on: bool) -> void:
	emit_signal("on_toggle_2D_Graph", toggled_on)
	pass # Replace with function body.
func _on_windows_Graph2D_closed() -> void:
	%"2DGraphsCheckButton".button_pressed = false


func _on_visualize_atmosphere_layers_check_button_2_toggled(toggled_on: bool) -> void:
	emit_signal("on_toggle_atmosphere", toggled_on)
