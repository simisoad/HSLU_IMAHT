extends Node

signal start_calculations_signal
signal send_data_signal(data: Dictionary)
signal calculation_ended

signal end_pos_signal(end_pos: Vector3)

@onready var earth_middle: Vector3 =  Vector3(0,0,-6378000)


@onready var speed_data: Array # Geschwindigkeiten für jeden Punkt
@onready var physics: PhysicsNode = PhysicsNode.new()
@onready var air_density_data: Array
@onready var thrust_array: Array
@onready var gravity_array: Array
enum NumericalMethod { RK4, Euler, SymplecticVerlet, VelocityVerlet, RK4b }
var numerical_method = NumericalMethod.RK4  # Standard: RK4

var numerical_method_printed: bool = false

var max_heigth_array: Array
var reached_distance: float = 0.0
func _ready():
	
	connect("start_calculations_signal", Callable(self, "_on_start_calculations"))

	
func _on_start_calculations_signal() -> void:
	_start_calculations()
	
func _on_numerical_method_selected(method: int) -> void:
	#enum NumericalMethod { RK4, Euler, SymplecticVerlet, VelocityVerlet }
	#print("method: ", method)
	if method == 0: 
		numerical_method = NumericalMethod.RK4
	if method == 1: 
		numerical_method = NumericalMethod.Euler
	if method == 2: 
		numerical_method = NumericalMethod.SymplecticVerlet
	if method == 3: 
		numerical_method = NumericalMethod.VelocityVerlet
	if method == 4:
		numerical_method = NumericalMethod.RK4b				
	pass	
		
func _start_calculations() -> Dictionary:
	speed_data.clear()
	#print("_start_calculations wurde aufgerufen")
	##print("theta: " + str(Parameters.projectile_theta_inclination))
	var initial_conditions: Array = _ic(Parameters.projectile_muzzle_velocity,
	Parameters.projectile_phi_xy,
	Parameters.projectile_theta_inclination)
	
	##print("Parameters.ivp_step_size : " + str(Parameters.ivp_step_size))
	var trajectory: Array = _ivp1_modified(Parameters.ivp_step_size,initial_conditions)
	##print("trajectory: ",trajectory)
	var times: Array = _calculate_times(trajectory)
	var results: Dictionary = {"trajectory": trajectory, "times": times, "speed_data": self.speed_data,
	"thrust_array": thrust_array}
	##print("thrust array size: "+str(thrust_array.size()))
	##print("times array size: "+str(times.size()))
	_print_distance_infos(trajectory, times)
	emit_signal("send_data_signal", results)
	_print_lowest_air_density()
	
	self.emit_signal("calculation_ended")
	await get_tree().create_timer(0.1).timeout
	#d_max()
	return results
func d_max() -> void:
	var average_speed:float = 0.0
	for i in self.speed_data.size()-1:
		average_speed += self.speed_data[i]
	average_speed /= speed_data.size()
	
	var average_g: float = 0.0
	for i in gravity_array.size()-1:
		average_g += self.gravity_array[i]
	average_g /= gravity_array.size()
	average_speed = 10.0
	
	print_rich("[color=green][b]max_distance_calculated: ",(average_speed**2*sin(Parameters.projectile_theta_inclination))/average_g, " average speed: ", average_speed, " average_g: ", average_g)
func _print_distance_infos(trajectory: Array, times: Array) -> void:
	var trajectory_size = trajectory.size()-1
	var start_pos: Vector3 = Vector3(trajectory[0][0],trajectory[0][1],trajectory[0][2])
	var end_pos: Vector3 = Vector3(trajectory[trajectory_size][0],trajectory[trajectory_size][1],trajectory[trajectory_size][2])
	
	##print(start_pos)
	##print(end_pos)
	reached_distance = start_pos.distance_to(end_pos)
	emit_signal("end_pos_signal", end_pos)
	
	
	for i in trajectory_size:
		max_heigth_array.append(trajectory[i][2])
	max_heigth_array.sort()
	var full_time: float = 0.0
	for i in times.size()-1:
		full_time += times[i]
	
	print_rich("[color=green][b]Distance: " + str(reached_distance), ", used time: ", full_time,", max height: " + str(max_heigth_array[max_heigth_array.size()-1]))
	
func get_range() -> float:
	return reached_distance
func restart_calculations(theta: float, v0: float = Parameters.projectile_muzzle_velocity) -> void:
	##print("restart_calculations")
	Parameters.projectile_muzzle_velocity = v0
	Parameters.projectile_theta_inclination = theta
	_start_calculations()

func _print_lowest_air_density() -> void:
	air_density_data.sort()
	##print("lowest air pressure: "+str(air_density_data[0]))
	


	
# Physikalische Funktion (inkl. Schubkraft)	
func _ode(t: float, state: Array, add_thrust: bool = false) -> Array:
	var x = state[0]
	var y = state[1]
	var z = state[2]
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]
	
	var u = Vector3(dx, dy, dz).length()
	# Methode get_air_density(z) aus Physics_Node!
	var rho = physics._get_air_density(z) # + height above sea level möglich, aber geht das hier?
	air_density_data.append(rho)
	###print("rho: " + str(rho))
	# Berechnung des dynamischen Drag-Koeffizienten
	var cd = physics.calculate_cd(u,z)#Parameters.projectile_drag_coefficient
	var A = Parameters.projectile_area
	
		# Basisentlastungseffekt
	var a = physics.calculate_speed_of_sound(z)
	var M = u / a
	var P_b = physics.calculate_base_pressure(M, z)
	var base_area = Parameters.projectile_area  # Querschnitt am hinteren Ende des Projektils

	# Luftwiderstand
	var drag_force = 0.5 * rho * u**2 * cd * A #physics._calculate_drag_force(u,rho,Parameters.projectile_diameter, epsilon) #
	drag_force -= base_area * P_b  # Basisentlastung berücksichtigen
	
	# Gravitationskraft g:
	var g = physics.calculate_g(z)
	
	var actual_pos: Vector3 = Vector3(x,y,z)
	var g_direction: Vector3 = actual_pos.direction_to(earth_middle)
	var g_vector: Vector3 = g_direction * g
	
	#var g_direction = Vector3(0,0,1)
	#print("g_direction * g: ", g*g_direction)
	#print(g_vector.length())
	# Schubkraft berechnen 
	var thrust: Vector3 = Vector3.ZERO
	thrust = physics._calculate_thrust(t, state,Parameters.projectile_mass) #calculate_thrust
	###print("thrust" + str(thrust) + "t: " + str(t))
	if add_thrust:
		#print("g_x: ", g_vector.x, ", g_y: ", g_vector.y, ", g_z: ", g_vector.z)
		gravity_array.append(g) # auch nur dann.
		if thrust == Vector3.ZERO:
			thrust_array.append(false)
		else:
			thrust_array.append(true)
		#thrust = Vector3.ZERO
	
	
	
	# Beschleunigungen berechnen
	return [
		dx,
		dy,
		dz,
		(thrust.x - drag_force * (dx / u) + g_vector.x), # x-Komponente
		(thrust.y - drag_force * (dy / u) + g_vector.y), # y-Komponente
		(thrust.z - drag_force * (dz / u) + g_vector.z)  # z-Komponente
	]

# Hauptberechnung in der ODE-Methode
func _ode_advanced(t: float, state: Array, add_thrust: bool = false) -> Array:
	var x = state[0]
	var y = state[1]
	var z = state[2]
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]

	var u = Vector3(dx, dy, dz).length()
	var epsilon = 1e-6
	u = max(u, epsilon)
	# Berechnung der Luftdichte
	var rho = physics._get_air_density(z)
	air_density_data.append(rho)

	# Berechnung des dynamischen Drag-Koeffizienten
	var cd = physics.calculate_cd(u, z)
	var A = Parameters.projectile_area

	# Basisentlastungseffekt
	var a = physics.calculate_speed_of_sound(z)
	var M = u / a
	var P_b = physics.calculate_base_pressure(M, z)
	var base_area = Parameters.projectile_area  # Querschnitt am hinteren Ende des Projektils

	# Luftwiderstand
	var drag_force = 0.5 * rho * u * u * physics.calculate_cd(u,z) * A
	drag_force -= base_area * P_b  # Basisentlastung berücksichtigen

	# Schubkraft
	var thrust: Vector3 = Vector3.ZERO
	thrust = physics._calculate_thrust(t, state, Parameters.projectile_mass)

	if add_thrust:
		thrust_array.append(thrust != Vector3.ZERO)

	# Gravitationskraft
	var g = physics.calculate_g(z)

	# Beschleunigungen berechnen
	return [
		dx,
		dy,
		dz,
		(thrust.x - drag_force * (dx / u)),  # x-Komponente
		(thrust.y - drag_force * (dy / u)),  # y-Komponente
		(thrust.z - drag_force * (dz / u) - g)  # z-Komponente
	]
	
# Anfangsbedingungen für Geschwindigkeit und Winkel
func _ic(v0: float, phi: float, theta: float) -> Array:
	var phi_rad = deg_to_rad(phi) # Winkel in der XY-Ebene
	var theta_rad = deg_to_rad(theta) # Neigungswinkel zur Z-Achse
	var startpos: Vector3 = Parameters.projectile_start_pos
	return [
		startpos.x, startpos.z, startpos.y, # Startposition Achtung XYZ Achsen Godot vs. Science
		v0 * cos(phi_rad) * cos(theta_rad),  # x-Komponente
		v0 * sin(phi_rad) * cos(theta_rad),  # y-Komponente
		v0 * sin(theta_rad)  # z-Komponente
		]

# Runge-Kutta-Verfahren 4. Ordnung
func _rk4(x0: float, y0: Array, h: float, get_speed_data: bool = false) -> Array:
	var x1 = x0 + h / 2.0
	var x2 = x0 + h
	var k1 = _ode(x0, y0,true)
	var k2 = _ode(x1, _array_add(y0, _array_multiply(k1, [h / 2.0])))
	var k3 = _ode(x1, _array_add(y0, _array_multiply(k2, [h / 2.0])))
	var k4 = _ode(x2, _array_add(y0, _array_multiply(k3, [h])))
	var result_state = _array_add(y0, _array_multiply(_array_add(k1, _array_add(_array_multiply(k2, [2.0]), _array_add(_array_multiply(k3, [2.0]), k4))), [h / 6.0]))
	return [x2, result_state]
# Runge-Kutta-Verfahren 4. Ordnung
func _rk4b(x0: float, y0: Array, h: float, get_speed_data: bool = false) -> Array:
	
	var x1: float = x0 + h / 2.0
	var x2: float = x0 + h
	var hk1 = _array_multiply([h], _ode(x0,y0,true))
	var hk2 = _array_multiply([h], _ode(x1, _array_add(y0, _array_divide(hk1, [2.0]))))
	var hk3 = _array_multiply([h], _ode(x1, _array_add(y0, _array_divide(hk2, [2.0]))))
	var hk4 = _array_multiply([h], _ode(x2, _array_add(y0, hk3)))
	# Geschwindigkeiten berechnen: (gehört eigentlich nicht zum Runge-Kutte Verfahren!)
	#if get_speed_data:
		
		#speed_data.append(Vector3(y0.get(3).to_float(),y0.get(4).to_float(),y0.get(5).to_float()).length())
		
	var state:Array = _array_add(y0, _array_divide( _array_add(hk1, _array_add(_array_multiply([2.0], _array_add(hk2, hk3)), hk4)), [6.0]))
	##print("state: " + str(state))
	
	return [x2,state]
# Hilfsfunktionen
func _array_add(a: Array, b: Array) -> Array:
	var result = []
	for i in range(a.size()):
		result.append(a[i] + b[i])
	return result

func _array_multiply(a: Array, scale: Array) -> Array:
	if scale.size() == 1:
		for i in range(a.size()-1):
			scale.append(scale[0])
	if a.size() == 1:
		for i in range(scale.size()-1):
			a.append(a[0])
	var result = []
	for i in range(a.size()):
		result.append(a[i] * scale[i])
	return result
	
func _array_divide(a: Array, scale: Array) -> Array:
	if scale.size() == 1:
		for i in range(a.size()-1):
			scale.append(scale[0])
	if a.size() == 1:
		for i in range(scale.size()-1):
			a.append(a[0])
	var result = []
	for i in range(a.size()):
		result.append(a[i] / scale[i])
	return result
	
#Euler-Verfahren:
func _euler(t: float, state: Array, h: float) -> Array:
	# Berechnung der nächsten Position und Geschwindigkeit mit dem Euler-Verfahren
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]

	# Berechne Beschleunigungen
	var accelerations = _ode(t, state, true)
	##print("state: ", state, ", accel: ", accelerations)
	##print("_array_multiply([h], accelerations): ", _array_multiply(accelerations,[h]))
	var next_state = _array_add(state, _array_multiply(accelerations,[h]))

	# Berechne den nächsten Zeitpunkt
	var next_time = t + h

	return [next_time, next_state]



func _velocity_verlet(x0: float, y0: Array, h: float, get_speed_data: bool = false) -> Array:
	# Extrahiere Position und Geschwindigkeit aus dem aktuellen Zustand
	var position: Vector3 = Vector3(y0[0], y0[1], y0[2])
	var velocity: Vector3 = Vector3(y0[3], y0[4], y0[5])
	
	# Berechne die anfängliche Beschleunigung
	var acceleration_array: Array = _extract_velocity(_ode(x0, y0,true))
	var acceleration: Vector3 = Vector3(acceleration_array[0],acceleration_array[1],acceleration_array[2])
	
	# Update Position
	var new_position: Vector3 = position + velocity * h + 0.5 * acceleration * h * h
	
	# Berechne die neue Beschleunigung (basierend auf der neuen Position)
	var new_state_temp: Array = [
		new_position.x, new_position.y, new_position.z,
		velocity.x, velocity.y, velocity.z
	]
	acceleration_array = _extract_velocity(_ode(x0 + h, new_state_temp))
	var new_acceleration: Vector3 = Vector3(acceleration_array[0],acceleration_array[1],acceleration_array[2])
	
	# Update Geschwindigkeit
	var new_velocity: Vector3 = velocity + 0.5 * (acceleration + new_acceleration) * h
	
	# Erstelle den neuen Zustand
	var new_state: Array = [
		new_position.x, new_position.y, new_position.z,
		new_velocity.x, new_velocity.y, new_velocity.z
	]
	
	# Optionale Speicherung der Geschwindigkeit
	if get_speed_data:
		speed_data.append(new_velocity.length())
	
	# Nächste Zeit und neuer Zustand zurückgeben
	var x1: float = x0 + h
	return [x1, new_state]
	
func _symplectic_verlet(t: float, state: Array, h: float) -> Array:
	# Berechne die Beschleunigungen basierend auf dem aktuellen Zustand
	var accelerations: Array= _extract_velocity(_ode(t, state,true))

	# Aktuelle Geschwindigkeit mit symplektischer Methode (wird zuerst mit Beschleunigung angepasst)
	var new_velocity = _array_add(_extract_velocity(state), _array_multiply([h], accelerations))

	# Berechne die neue Position unter Verwendung der symplektischen Methode
	var new_position = _array_add(_extract_position(state), _array_multiply([h], new_velocity))
	
	# Kombiniere die Position und Geschwindigkeit in einem neuen Zustand
	
	var new_state = new_position
	new_state.append_array(new_velocity)
	# Berechne den nächsten Zeitpunkt
	var next_time = t + h

	return [next_time, new_state]

func _extract_velocity(velocity: Array) -> Array:
	# Position: [x, y, z], Geschwindigkeit: [Vx, Vy, Vz]
	return [velocity[3], velocity[4], velocity[5]]

func _extract_position(position: Array) -> Array:
	# Position: [x, y, z], Geschwindigkeit: [Vx, Vy, Vz]
	return [position[0], position[1], position[2]]


# Anfangswertproblem lösen
func _ivp1_modified(step_size: float, initial_conditions: Array) -> Array:
	var current_time: float = 0.0
	var current_state: Array = initial_conditions
	var states: Array = [initial_conditions]  # Initialzustand speichern
	var method: String
	while true:
		var result: Array
		##print("curren_state: " + str(current_state))
		
		# Auswahl des Verfahrens
		
		match numerical_method:
			
			NumericalMethod.RK4:
				method = "rk4"
				result = _rk4(current_time, current_state, step_size, true)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.RK4b:
				method = "rk4b"
				result = _rk4(current_time, current_state, step_size, true)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.Euler:
				method = "euler"
				result = _euler(current_time, current_state, step_size)  # Euler-Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.SymplecticVerlet:
				method = "symplectic_verlet"
				result = _symplectic_verlet(current_time, current_state, step_size)  # Verletztes Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.VelocityVerlet:
				method = "velocity_verlet"
				result = _velocity_verlet(current_time, current_state, step_size, true)  # Verletztes Verfahren verwenden
				
		if not numerical_method_printed:
			
			#print(method)
			numerical_method_printed = true
			
		var next_time: float = result[0]
		var next_state: Array = result[1]
		
		states.append(next_state)

		# Abbruchbedingung prüfen
		if _stop_ivp(current_state, next_state):
			states[states.size() - 1] = _interpolate(current_time, current_state, next_time, next_state)[1]
			break

		# Vorbereitung für nächsten Schleifendurchlauf
		current_time = next_time
		current_state = next_state

	return states

func _set_speed_data(current_state: Array) -> void:
	speed_data.append(Vector3(current_state[3],current_state[4],current_state[5]).length())

func _stop_ivp(z0: Array, z1: Array) -> bool:
	
	return z0[2] > 0.0 and z1[2] <= 0.0 and abs(z1[2]) < 1e6
	
func _interpolate(t0: float, z0: Array, t1: float, z1: Array) -> Array:
	#print("z0: ", z0, ", z1: ", z1)
	var g:float = z0[2]  # z-Komponente von z0
	var f:float = z1[2]  # z-Komponente von z1
	var h:float = f - g  # Differenz in z
	
	# Normierung
	f /= h
	g /= h
	
	# Interpolierter Zeitpunkt
	var interpolated_time:float = f * t0 - g * t1
	
	# Interpolierte Position
	var interpolated_position = _array_add(_array_multiply([f],z0), _array_multiply([-g] , z1))
	#print("interpolated_position: ", interpolated_position)
	var result: Array =[interpolated_time, interpolated_position]
	#print("interpolated state: ", result)
	return result

	
func _calculate_times(trajectory: Array) -> Array:
	# Berechnet die Zeiten für jeden Abschnitt
	var times: Array = []
	times.clear()
	#print("trajectory.size: ",trajectory.size())
	for i in range(trajectory.size() - 1):
		##print("i: ", i , ", i+1: ", i+1)
		var p1_x: float = trajectory[i][0]
		var p1_y: float = trajectory[i][1]
		var p1_z: float = trajectory[i][2]
		var p2_x: float = trajectory[i+1][0]
		var p2_y: float = trajectory[i+1][1]
		var p2_z: float = trajectory[i+1][2]
		
		##print("i: ", i , ", i+1: ", i+1,", p1_x: ",p1_x, ", p2_x:",p2_x, " ,trajectory[i]:", trajectory[i]," ,trajectory[i+1]:", trajectory[i+1])
		
		var p1: Vector3 = Vector3(p1_x, p1_y, p1_z)
		var p2: Vector3 = Vector3(p2_x, p2_y, p2_z)
		var part_length = p1.distance_to(p2)
		var speed = speed_data[i]
		if speed > 0:
			times.append(part_length / speed)
		else:
			times.append(0.0)  # Verhindert Division durch 0
	return times
