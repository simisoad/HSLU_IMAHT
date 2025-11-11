extends Control
signal clear_all_trajectories_signal

var camera_pos: Vector3

func _on_options_button_toggled(toggled_on: bool) -> void:
	print("hooodsfa")
	%SimulationOptions.visible = not %SimulationOptions.visible


func _on_clear_all_trajectories_button_toggled(toggled_on: bool) -> void:
	print("clear_all_trajectories_signal")
	emit_signal("clear_all_trajectories_signal")

func _process(delta: float) -> void:
	%camera_pos.text = str(camera_pos)

func _on_camera_speed_multipier(speed: float) -> void:
	print("signal received")
	%CameraSpeedMultiplier.text = "CameraSpeedMultiplier: " + str(speed).pad_decimals(10)

func _on_results_for_gui_signal(results: String) -> void:
	%ResultsLabel.text = results
