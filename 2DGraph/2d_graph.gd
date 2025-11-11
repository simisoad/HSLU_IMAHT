extends Window
signal windows_Graph2D_closed
@onready var camera_2d: ZoomableCamera = %Camera2D

@onready var scale_up_grap: float = 10.0


func _process(delta: float) -> void:
	%GraphTrajectoryLine2D.width = 2.0*camera_2d.zoom.x **-1
	%GraphHeightVSTimeLine2D.width = 2.0*camera_2d.zoom.x **-1
	%GraphSpeedVSTimeLine2D.width = 2.0*camera_2d.zoom.x **-1
	%GraphDragVSTimeLine2D.width = 2.0*camera_2d.zoom.x **-1
	%AtmosphereHeight.width = 2.0*camera_2d.zoom.x **-1

func _ready() -> void:
	var p1: Vector2 = Vector2(100000,(-84852*Parameters.scale_down_factor)*scale_up_grap)
	var p2: Vector2 = Vector2(-100000,(-84852*Parameters.scale_down_factor)*scale_up_grap)
	%AtmosphereHeight.add_point(p1)
	%AtmosphereHeight.add_point(p2)
func _on_visualize_trajectory(data: Dictionary) -> void:
	var trajectory: Array = data.get("trajectory")
	var speed_data: Array = data.get("speed_data")
	var current_times: Array = data.get("current_times")
	var drag_data: Array = data.get("drag_data")
	var height_data: Array = data.get("height_data")
	#print("last height",height_data[height_data.size()-1])
	
	
	##print(trajectory)
	_visualize_trajectory(trajectory, speed_data)
	_visualize_speed_vs_time(current_times, speed_data)
	_visualize_drag_vs_time(current_times,drag_data)
	_visualize_height_vs_time(current_times, height_data)
	


func _visualize_drag_vs_time(current_times: Array, drag_data: Array) -> void: 
	%GraphDragVSTimeLine2D.clear_points()
	#print("drag_date: ", drag_data)
	var drag_vs_time: Array
	var max_drag: float = drag_data.max()
	#print("max_drag: ", max_drag)
	#var scale: float = remap()
	
	for i in current_times.size()-1:
		drag_vs_time.append(Vector2(current_times[i], -drag_data[i]*Parameters.scale_up_factor*100)*scale_up_grap)
	%GraphDragVSTimeLine2D.points = drag_vs_time
	
func _visualize_trajectory(trajectory: Array, speed_data: Array)-> void:
	%GraphTrajectoryLine2D.clear_points()
	
	var xy_coords: Array
		
	for point in trajectory:
		var x: float = point[0]
		var y: float = point[1]
		var z: float = point[2]
		var x_2D: float = sqrt(x**2 + y**2)
		xy_coords.append(Vector2(x_2D,-z))
	%GraphTrajectoryLine2D.points = xy_coords
	
func _visualize_height_vs_time(current_times: Array, height_data: Array) -> void:
	%GraphHeightVSTimeLine2D.clear_points()
	var height_vs_time: Array
	for i in current_times.size()-1:
		height_vs_time.append(Vector2(current_times[i], -height_data[i])*scale_up_grap)
		#print("max height 2d: ", height_data.max())
	%GraphHeightVSTimeLine2D.points = height_vs_time
	
func _visualize_speed_vs_time(current_times: Array, speed_data: Array) -> void:
	%GraphSpeedVSTimeLine2D.clear_points()
	var speed_vs_time: Array
	#print("current_times.size(): ", current_times.size(), "current_times: ", current_times)
	for i in current_times.size()-1:
		speed_vs_time.append(Vector2(current_times[i], -speed_data[i]*1000)*scale_up_grap) 
		#print("speed_data[i]: ",speed_data[i] )
	%GraphSpeedVSTimeLine2D.points = speed_vs_time
	

func _on_toggle_planet_check_button_toggled(toggled_on: bool) -> void:
	%Earth2D.visible = toggled_on

func _on_focus_entered() -> void:
	%Camera2D.has_windows_focus = true
	pass # Replace with function body.


func _on_focus_exited() -> void:
	%Camera2D.has_windows_focus = false
	pass # Replace with function body.

func _on_toggle_2D_Graph(toggle: bool) -> void:
	self.visible = toggle


func _on_close_requested() -> void:
	self.visible = false
	emit_signal("windows_Graph2D_closed")
	pass # Replace with function body.


func _on_heigt_vs_time_check_button_toggled(toggled_on: bool) -> void:
	%GraphHeightVSTimeLine2D.visible = toggled_on


func _on_speed_vs_time_check_button_toggled(toggled_on: bool) -> void:
	%GraphSpeedVSTimeLine2D.visible = toggled_on


func _on_drag_vs_time_check_button_toggled(toggled_on: bool) -> void:
	%GraphDragVSTimeLine2D.visible = toggled_on


func _on_trajectory_check_button_toggled(toggled_on: bool) -> void:
	%GraphTrajectoryLine2D.visible = toggled_on
