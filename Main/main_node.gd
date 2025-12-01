extends Node



@onready var simulation_node: Node = $SimulationNode
@onready var visualization_node: Node3D = $VisualizationNode
@onready var numerical_methods: Node = $NumericalMethods
@onready var trajectory: Node3D = $Trajectory
@onready var optimization_node: Node = $OptimizationNode
@onready var graph_2d: Window = $Graph2D

var simulation_started: bool = false

func _ready():

	Parameters.projectile_start_pos = Vector3(%StartPos.global_position.x,%StartPos.global_position.z, %StartPos.global_position.y)
	Parameters.planet_radius = %Planet.mesh.radius

	%Graph2D.connect("windows_Graph2D_closed", Callable(%SimulationGUI.get_child(1), "_on_windows_Graph2D_closed"))
	# Verbinde das Signal der Simulation mit der Visualisierung
#	angle_optimized_signal
	optimization_node.connect("angle_optimized_signal", Callable(%SimulationGUI.get_child(0), "_on_angle_optimized_signal"))
	optimization_node.connect("run_simulation_for_optimization", Callable(self, "_on_run_simulation_for_optimization"))
	simulation_node.connect("simulation_updated_signal", Callable(visualization_node, "_on_update_visualization"))
	simulation_node.connect("projectile_impact_signal", Callable(visualization_node, "_on_projectile_impact"))
	simulation_node.connect("start_simulation_signal", Callable(visualization_node, "_on_simulation_started"))
	simulation_node.connect("simulation_ended", Callable(self, "_on_simulation_ended"))
	numerical_methods.connect("send_data_signal", Callable(trajectory, "_on_visualize_trajectory"))
	numerical_methods.connect("send_data_signal", Callable(graph_2d, "_on_visualize_trajectory"))
	numerical_methods.connect("send_data_signal",Callable(simulation_node, "_on_data_received"))
	%FreeViewCamera.get_child(1).connect("start_position_changed_with_mouse_signal", Callable(%StartPos, "_on_start_position_changed_signal"))
	%FreeViewCamera.get_child(1).connect("start_position_changed_with_mouse_signal", Callable(%SimulationGUI.get_child(0), "_on_start_position_changed_signal"))
#	emit_signal("on_start_position_changed_signal")
	# SimulationOptionsGUI Index 0!
	if %SimulationGUI.get_child(0).name == "SimulationOptions":
		%SimulationGUI.get_child(0).connect("numerical_method", Callable(numerical_methods, "_on_numerical_method_selected"))
		%SimulationGUI.get_child(0).connect("has_thrust_toggled_signal", Callable(simulation_node, "_on_has_thrust_toggled"))
		%SimulationGUI.get_child(0).connect("calculate_oribital_velocity_signal", Callable(numerical_methods, "_on_calculate_oribital_velocity"))
		%SimulationGUI.get_child(0).connect("on_start_position_changed_signal", Callable(%StartPos, "_on_start_position_changed_signal"))
		%SimulationGUI.get_child(0).connect("check_for_orbit_toggled_signal", Callable(numerical_methods, "_on_check_for_orbit_toggled_signal"))


#
	# VisualOptionsGUI Index 0!	 on_toggle_atmosphere
	if %SimulationGUI.get_child(1).name == "VisualOptionsGui":
		%SimulationGUI.get_child(1).connect("point_size_changed_signal", Callable(trajectory, "_on_point_size_changed"))
		%SimulationGUI.get_child(1).connect("on_planet_radius_changed_signal", Callable(%Planet, "_on_planet_radius_changed"))
		%SimulationGUI.get_child(1).connect("on_planet_radius_changed_signal", Callable(%SimulationGUI.get_child(0), "_on_planet_radius_changed"))
		%SimulationGUI.get_child(1).connect("on_planet_radius_changed_signal", Callable(%StartPos, "_on_planet_radius_changed"))
		%SimulationGUI.get_child(1).connect("on_toggle_2D_Graph", Callable(%Graph2D, "_on_toggle_2D_Graph"))
		%SimulationGUI.get_child(1).connect("on_toggle_atmosphere", Callable(self, "_on_toggle_atmosphere"))

	%SimulationGUI.connect("clear_all_trajectories_signal", Callable(trajectory, "_on_clear_all_trajectories"))
	numerical_methods.connect("results_for_gui_signal", Callable(%SimulationGUI, "_on_results_for_gui_signal"))
	numerical_methods.connect("end_pos_signal", Callable(%FreeViewCamera, "_on_end_pos_received"))
	%FreeViewCamera.connect("camera_speed_multiplier_sigal", Callable(%SimulationGUI, "_on_camera_speed_multipier"))
func _input(event):
	if event.is_action_pressed("Start_Simulation") and not simulation_started:
		simulation_started = true
		print("Leertaste gedrückt: Starte Simulation")
		numerical_methods.emit_signal("start_calculations_signal")
		simulation_node.emit_signal("start_simulation_signal")
	if event.is_action_pressed("Run_Optimization"):

		optimization_node.emit_signal("run_optimization","gradient")
		#optimization_node.emit_signal("run_optimization","gradient2d")
		#optimization_node.emit_signal("run_optimization","nelder_mead")
		#optimization_node.emit_signal("run_optimization","nelder_mead_2d")

func _on_simulation_ended() -> void:
	simulation_started = false
	print("Simulation ist fertig")

func _on_run_simulation_for_optimization() -> void:
	#print("simulation für optimierung!")
	numerical_methods.emit_signal("start_calculations_signal")
	#simulation_node.emit_signal("start_simulation_signal")

func _process(delta: float) -> void:
	%SimulationGUI.camera_pos = %FreeViewCamera.global_position

func _on_toggle_atmosphere(toggled: bool) -> void:
	%Atmosphere.visible = toggled
