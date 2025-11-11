extends Node

signal start_simulation_signal
signal simulation_updated_signal(projectile: Projectile)
signal simulation_ended
signal projectile_impact_signal(projectile: Projectile)

var simulation_started: bool = false
var data_received: bool = false
var step_size = 0.1
var projectile: Projectile
var speed_data: Array
var drag_data: Array
var air_density: Array
@onready var current_segment: int = 0  # Der aktuelle Abschnitt
@onready var segment_time: float = 0.0  # Verstrichene Zeit im aktuellen Abschnitt
#Array für die brechneten Daten:
@onready var times: Array = []  # Speichert die Zeiten pro Abschnitt
@onready var thrust_array: Array
@onready var trajectory: Array # für die berechnete Flugbahn

var flight_time: float = 0.0

func _ready():
	projectile = Projectile.new(Parameters.projectile_start_pos, 0.0, Vector3.ZERO)
	connect("simulation_ended", Callable(self, "_on_simulation_ended"))
	pass
	
func _on_simulation_ended() ->void:
	times.clear()
	thrust_array.clear()
	trajectory.clear()
	segment_time = 0.0
	current_segment = 0
	flight_time = 0.0
	
func _start_simulation():
	# Starte die Simulation
	simulation_started = true
	
	print("simulation started!")
func _on_data_received(data: Dictionary) -> void:
	#{"trajectory": trajectory, "times": times, "speed_data": self.speed_data, "thrust_array": thrust_array}
	times = data.get("times")  # Speichert die Zeiten pro Abschnitt
	thrust_array = data.get("has_thrust_array")
	trajectory = data.get("trajectory")
	speed_data = data.get("speed_data")
	drag_data = data.get("drag_data")
	air_density = data.get("air_density_data")
	data_received = true
	
	
func _on_start_simulation():
	# Start-Methode wird aufgerufen, wenn das Signal ausgelöst wird
	print("Signal: start_simulation_signal recived!" )
	_start_simulation()
	
func _process(delta: float) -> void:
	if simulation_started and data_received:
		if Parameters.visualize_projectile:
			_simulation_projectile(delta, speed_data)
		else:
			emit_signal("simulation_ended")
			simulation_started = false
			data_received = false
		
func _simulation_projectile(delta: float, speed_data:Array):
	if current_segment >= times.size():
		return  # Simulation beendet
	projectile.set_velocity(speed_data[current_segment])
	projectile.set_drag(drag_data[current_segment])
	projectile.set_actual_air_density(air_density[current_segment])
	# Fortschritt im aktuellen Segment
	segment_time += delta * Parameters.simulation_speed
	if segment_time >= times[current_segment]:
		# Zum nächsten Abschnitt wechseln
		flight_time += segment_time
		segment_time = 0.0
		current_segment += 1
		if current_segment >= trajectory.size() - 1:
			#%Explosion.global_position = projectile.global_position
			
			print("flight_time: " + str(flight_time))
			simulation_started = false
			data_received = false
			emit_signal("projectile_impact_signal", projectile)
			await get_tree().create_timer(1).timeout
			emit_signal("simulation_ended")
			projectile.reset_projectile()
			#%Explosion.emitting = true
			return  # Ende der Simulation

	# Interpolation im aktuellen Abschnitt
	var t = segment_time / (times[current_segment])
	
	var p1 = trajectory[current_segment]
	var p2 = trajectory[current_segment + 1]
	var projectile_position = Vector3(
		lerp(p1[0], p2[0], t),
		lerp(p1[2], p2[2], t),
		lerp(p1[1], p2[1], t)
	)

	var next_position = Vector3(p2[0], p2[2], p2[1])
	var projectile_direction = (next_position - projectile_position).normalized()
	projectile.set_position(projectile_position)
	projectile.set_look_at_vector(projectile_position + projectile_direction)
	projectile.set_rotation(-PI / 2)  # Anpassung an die Ausrichtung
	#print("thrust_array:" , thrust_array)
	if projectile.get_has_thrust():
		if thrust_array[current_segment] == true:
			projectile.set_thrust_active(true)
		else:
			projectile.set_thrust_active(false)
	
	emit_signal("simulation_updated_signal", projectile)
	
func _on_has_thrust_toggled(has_thrust: bool) -> void:
	print("_on_has_thrust_toggled: has_thrust: ", has_thrust)
	projectile.set_has_thrust(has_thrust)
