extends Node
@onready var _node_name: String = self.name
signal start_calculations_signal
signal send_data_signal(data: Dictionary)
signal calculation_ended
signal results_for_gui_signal(results: String)
signal end_pos_signal(end_pos: Vector3)
@onready var physics: PhysicsNode = PhysicsNode.new()
@onready var earth_middle: Vector3 =  Vector3.ZERO


@onready var speed_data: Array # Geschwindigkeiten für jeden Punkt
@onready var air_density_data: Array
@onready var has_thrust_array: Array
@onready var gravity_array: Array
@onready var drag_array: Array
@onready var height_data: Array

enum NumericalMethod { RK4, Euler, SymplecticVerlet, VelocityVerlet, RK4b, RK4Dynamisch }
var numerical_method = NumericalMethod.RK4  # Standard: RK4

var numerical_method_printed: bool = false


var reached_flight_distance: float = 0.0
var arc_distance: float = 0.0
var current_times: Array

var check_for_orbit: bool = false

var projectile_is_over_atmosphere: bool = false
var last_projectile_is_over_atmosphere: bool = true
var last_heigt: float = 0.0
var assign_last_height: bool = true
var projectile_reached_heighest_point: bool = false


func _process(delta: float) -> void:
	if last_projectile_is_over_atmosphere != projectile_is_over_atmosphere:
		last_projectile_is_over_atmosphere = projectile_is_over_atmosphere
		#print("projectile_is_over_atmosphere: ", projectile_is_over_atmosphere)

func _ready():

	connect("start_calculations_signal", Callable(self, "_on_start_calculations"))
	var parent_childs: Array = get_parent().get_children()
	for i in parent_childs.size()-1:
		if parent_childs[i].name == "SimulationGUI":
			var simulation_options_gui = parent_childs[i].get_child(0)
			#print("simulation_options_gui found!")
			physics.connect("orbital_velocity_calculated", Callable(simulation_options_gui, "_on_orbital_velocity_calculated"))
		else:
			pass
			#print("node names: ",parent_childs[i].name)
	physics._scale_down_earth_planet_size()
	physics._scale_up_factor_earth_planet_size()
	await get_tree().create_timer(0.5).timeout
	Parameters.projectile_muzzle_velocity = physics._calculate_orbital_velocity() #physics._calculate_v_esc()
	#_test_air_density_and_scale()
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
	if method == 5:
		numerical_method = NumericalMethod.RK4Dynamisch
	pass
		
func _start_calculations() -> Dictionary:
	speed_data.clear()
	current_times.clear()
	drag_array.clear()
	air_density_data.clear()
	height_data.clear()
	#print("_start_calculations wurde aufgerufen")
	##print("theta: " + str(Parameters.projectile_theta_inclination))
	var initial_conditions: Array = _ic(Parameters.projectile_muzzle_velocity,
	Parameters.projectile_phi_xy,
	Parameters.projectile_theta_inclination)
	
	##print("Parameters.ivp_step_size : " + str(Parameters.ivp_step_size))
	var trajectory: Array = await _ivp1_modified(Parameters.ivp_step_size,initial_conditions)
	##print("trajectory: ",trajectory)
	var times: Array = _calculate_times(trajectory)
	var results: Dictionary = {"trajectory": trajectory, "times": times, "speed_data": self.speed_data,
	"has_thrust_array": has_thrust_array, "current_times": current_times, "drag_data": drag_array,
	 "air_density_data": air_density_data, "height_data": height_data}
	##print("thrust array size: "+str(has_thrust_array.size()))
	#print("times array size: ", times.size(),", trajectory size: ", trajectory.size(), ", drag arry size: ", drag_array.size(), ", airdensity_data: ", air_density_data.size())
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
func _calculate_arc_distance(start_point: Vector3, end_point: Vector3) -> float:
	var v1 = start_point - Vector3.ZERO # Eigentlich doch überflüssig?
	var v2 = end_point - Vector3.ZERO # (3,2,-6) - (0,0,0) gibt ja denselben Vektor?!
	var cos_alpha = v1.dot(v2)/ (v1.length()*v2.length())
	var alpha = acos(cos_alpha)
	return (alpha*Parameters.planet_radius)*Parameters.scale_up_factor
	
func _print_distance_infos(trajectory: Array, times: Array) -> void:
	#print("_print_distance_infos")
	var trajectory_size = trajectory.size()-1
	var start_pos: Vector3 = Vector3(trajectory[0][0],trajectory[0][1],trajectory[0][2])
	var end_pos: Vector3 = Vector3(trajectory[trajectory_size][0],trajectory[trajectory_size][1],trajectory[trajectory_size][2])
	var scale_up: float = Parameters.scale_up_factor
	var end_pos_for_camera: Vector3 = Vector3(trajectory[trajectory_size][0],trajectory[trajectory_size][2],trajectory[trajectory_size][1])
	arc_distance = _calculate_arc_distance(start_pos, end_pos)
	#print("arc_distance: ", arc_distance)
	##print(start_pos)
	##print(end_pos)
	#reached_distance = ((start_pos.distance_to(end_pos))*scale_up)/1000 # Zu KM und auf Erdgrösse skaliert.
	emit_signal("end_pos_signal", end_pos_for_camera)
	reached_flight_distance = (_calculate_flight_distance(trajectory)*scale_up)/1000
	var max_height: float = (height_data.max()*scale_up)/1000 # Zu KM

	var full_time: float = 0.0
	for i in times.size()-1:
		full_time += times[i]
	full_time /= 60 # Zeit in Minuten
	
	var results: String = (
	"Distance: " + str(reached_flight_distance)+ 
	" km , used time: "+  str(full_time)+
	" min, max height: " + str(max_height)+
	" km, arc_distance: " + str(arc_distance) +
	" km, Calculated Points: "+ str(trajectory.size()))
	self.emit_signal("results_for_gui_signal", results)
	
	
func _calculate_flight_distance(trajectory: Array) -> float:
	var flight_distance: float = 0.0
	for i in trajectory.size()-1:
		var p1: Vector3 = Vector3(trajectory[i][0],trajectory[i][1], trajectory[i][2])
		var p2: Vector3 = Vector3(trajectory[i+1][0],trajectory[i+1][1], trajectory[i+1][2])
		flight_distance += p1.distance_to(p2)
	return flight_distance
	
func get_range(theta: float) -> float:
	
	#print("arc_distance for opti: ", arc_distance, ", angle: ", rad_to_deg(theta))
	return arc_distance
	
func restart_calculations(theta: float, v0: float = Parameters.projectile_muzzle_velocity) -> void:
	#print("Opti: restart_calculations", ", new theta: ", theta, "°, v0: ", v0)
	Parameters.projectile_muzzle_velocity = v0
	Parameters.projectile_theta_inclination = theta
	_start_calculations()

func _print_lowest_air_density() -> void:
	#print("air_density_data: " ,air_density_data)
	#print("lowest air density: ",air_density_data.min(), ", highest air density: ", air_density_data.max())
	pass


	
# Physikalische Funktion (inkl. Schubkraft)	
func _ode(t: float, state: Array, add_to_arrays: bool = false) -> Array:
	var x = state[0]
	var y = state[1]
	var z = state[2]
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]
	var actual_pos: Vector3 = Vector3(x,y,z)
	var distance_to_planet_middle: float = actual_pos.distance_to(earth_middle)
	#if distance_to_planet_middle < 0.0 :
		#print("distance_to_planet_middle: ", distance_to_planet_middle)
	var height = actual_pos.distance_to(earth_middle)-Parameters.planet_radius
	var u = Vector3(dx, dy, dz).length()
	# Methode get_air_density(z) aus Physics_Node!
	var rho = physics._get_air_density_at_height(height) # + height above sea level möglich, aber geht das hier?
	
	###print("rho: " + str(rho))
	# Berechnung des dynamischen Drag-Koeffizienten
	var cd = physics.calculate_cd(u,height)#Parameters.projectile_drag_coefficient
	
	var A = Parameters.projectile_area
	
		# Basisentlastungseffekt
	#var a = physics.calculate_speed_of_sound(height)
	#var M = u / a
	#var P_b = physics.calculate_base_pressure(M, height)
	#var base_area = Parameters.projectile_area  # Querschnitt am hinteren Ende des Projektils

	# Luftwiderstand
	var drag_force = 0.5 * rho * u**2 * cd * A #physics._calculate_drag_force(u,rho,Parameters.projectile_diameter, epsilon) #
	#drag_force -= base_area * P_b  # Basisentlastung berücksichtigen
	#drag_force = 0
	# Gravitationskraft g:
	
	var g = physics.calculate_g(height)
	var g_direction: Vector3 = actual_pos.direction_to(earth_middle)
	var g_vector: Vector3 = g_direction * g
	
	#var g_direction = Vector3(0,0,1)
	#print("g_direction * g: ", g*g_direction)
	#print(g_vector.length())
	# Schubkraft berechnen 
	var thrust: Vector3 = Vector3.ZERO
	#thrust = physics._calculate_thrust(t, state,Parameters.projectile_mass, projectile_reached_heighest_point) #calculate_thrust
	thrust = physics._calculate_thrust(t, state,Parameters.projectile_mass) #calculate_thrust
	###print("thrust" + str(thrust) + "t: " + str(t))
	if add_to_arrays:
		#print("g_x: ", g_vector.x, ", g_y: ", g_vector.y, ", g_z: ", g_vector.z)
		#gravity, airdensity und drag array werden auch nur dann gefüllt
		#print(rho)
		air_density_data.append(rho)
		gravity_array.append(g)
		drag_array.append(drag_force)
		height_data.append(height)
		if thrust == Vector3.ZERO:
			has_thrust_array.append(false)
		else:
			has_thrust_array.append(true)
		#thrust = Vector3.ZERO
	#print("u: ", u, " drag_force: ", drag_force, " g_vector: ", g_vector)
	
	# Beschleunigungen berechnen
	return [
		dx,
		dy,
		dz,
		(thrust.x - drag_force * (dx / u) + g_vector.x), # x-Komponente
		(thrust.y - drag_force * (dy / u) + g_vector.y), # y-Komponente
		(thrust.z - drag_force * (dz / u) + g_vector.z)#, # z-Komponente

	]


# Anfangsbedingungen für Geschwindigkeit und Winkel
func _ic(v0: float, phi: float, theta: float) -> Array:
	var phi_rad = deg_to_rad(phi) # Winkel in der XY-Ebene
	var theta_rad = deg_to_rad(theta) # Neigungswinkel zur Z-Achse
	var startpos: Vector3 = Vector3(Parameters.projectile_start_pos.x, Parameters.projectile_start_pos.z, Parameters.projectile_start_pos.y)
	var height: float = startpos.distance_to(earth_middle)-Parameters.planet_radius
	var initail_drag_force: float = 0.0
	var initial_air_density: float = physics._get_air_density_at_height(height)
	var initial_thrust: float = Parameters.projectile_thrust_force
	
	
	height_data.append(height)
	drag_array.append(0.0)
	air_density_data.append(initial_air_density)
	if Parameters.projectile_has_thrust:
		if initial_thrust > 0.0:
			has_thrust_array.append(true)
	
	
	if v0 == 0.0 and Parameters.projectile_has_thrust:
		var projectile_mass = Parameters.projectile_mass
		v0 = (initial_thrust / projectile_mass)*Parameters.scale_down_factor # Damit, die v0 Geschwindigkeit an der Skalierung angepasst wird.
		print("initial_thrust: ", initial_thrust, ", projectile mass: ", projectile_mass, ", v0 with thrust: ", v0)
		#v0 = physics._calculate_initial_velocity(phi,theta).length()
	elif v0 == 0:
		print_rich("[color=red][b]Error: Muzzle_Velocity 0.0 and no Thrust is not possible, v0 = 1")
		v0 = 0.0001

	return [
		startpos.x, startpos.z, startpos.y, # Startposition Achtung XYZ Achsen Godot vs. Science
		v0 * cos(phi_rad) * cos(theta_rad),  # x-Komponente
		v0 * sin(phi_rad) * cos(theta_rad),  # y-Komponente
		v0 * sin(theta_rad),  # z-Komponente
		]

# Runge-Kutta-Verfahren 4. Ordnung
func _rk4(x0: float, y0: Array, h: float) -> Array:
	var x1 = x0 + h / 2.0
	var x2 = x0 + h
	var k1 = _ode(x0, y0,true)
	var k2 = _ode(x1, _array_add(y0, _array_multiply(k1, [h / 2.0])))
	var k3 = _ode(x1, _array_add(y0, _array_multiply(k2, [h / 2.0])))
	var k4 = _ode(x2, _array_add(y0, _array_multiply(k3, [h])))
	
	#print("h: ", h, " x1:", x1, " x2:", x2, " k1: ", k1, " k2: ", k2, " k3: ", k3, " k4: ", k4)
	var result_state = _array_add(y0, _array_multiply(_array_add(k1, _array_add(_array_multiply(k2, [2.0]), _array_add(_array_multiply(k3, [2.0]), k4))), [h / 6.0]))
	return [x2, result_state]
# Runge-Kutta-Verfahren 4. Ordnung

func _rk4b(x0: float, y0: Array, h: float, add_array_data: bool ) -> Array:
	
	var x1: float = x0 + h / 2.0
	var x2: float = x0 + h
	var hk1 = _array_multiply([h], _ode(x0,y0,add_array_data))
	var hk2 = _array_multiply([h], _ode(x1, _array_add(y0, _array_divide(hk1, [2.0]))))
	var hk3 = _array_multiply([h], _ode(x1, _array_add(y0, _array_divide(hk2, [2.0]))))
	var hk4 = _array_multiply([h], _ode(x2, _array_add(y0, hk3)))
	# Geschwindigkeiten berechnen: (gehört eigentlich nicht zum Runge-Kutte Verfahren!)
	#if get_speed_data:
	#print("h: ", h, " x1:", x1, " x2:", x2, " hk1: ", hk1, " hk2: ", hk2, " hk3: ", hk3, " hk4: ", hk4)
		#speed_data.append(Vector3(y0.get(3).to_float(),y0.get(4).to_float(),y0.get(5).to_float()).length())
		
	var state:Array = _array_add(y0, _array_divide( _array_add(hk1, _array_add(_array_multiply([2.0], _array_add(hk2, hk3)), hk4)), [6.0]))
	##print("state: " + str(state))
	
	return [x2,state]
	
func _rk4b_adaptive(x0: float, y0: Array, h: float) -> Array:
	var tolerance: float = Parameters.dynamic_step_tolerance
	var x2: float = x0 + h

	# Berechnung mit voller Schrittweite
	var y_coarse = _rk4b(x0, y0, h, false)[1]

	# Berechnung mit halber Schrittweite
	var h_half = h / 2.0
	var mid_state = _rk4b(x0, y0, h_half, false)[1]
	var y_fine = _rk4b(x0 + h_half, mid_state, h_half, true)[1]

	# Fehlerschätzung (z. B. maximaler Unterschied)
	var error = 0.0
	for i in range(y0.size()):
		
		error = max(error, abs(y_fine[i] - y_coarse[i]))
	#print("y-fine: ", y_fine, ", y_coarse: ", y_coarse)
	# Anpassen der Schrittweite
	var safety_factor = 0.9  # Sicherheitsfaktor zur Vermeidung von zu großen Änderungen

	if error > tolerance * 10.0:  # Falls Fehler deutlich größer ist
		safety_factor = 0.7  # Vorsichtiger
	elif error < tolerance / 10.0:  # Falls Fehler viel kleiner ist
		safety_factor = 1.0  # Weniger Vorsicht

	var new_h = h
	

	if error > tolerance:
		# Schrittweite verringern
		new_h = safety_factor * h * pow(tolerance / error, 0.25)
	elif error < tolerance / 4.0:
		# Schrittweite erhöhen
		new_h = min(h * 2.0, safety_factor * h * pow(tolerance / error, 0.25))
		
	#new_h = clampf(new_h,0.01,10000)
	#print("error: ", error, " tolerance: ", tolerance, ", new_h: ", new_h)
	# Ergebnis zurückgeben
	return [x2,y_fine,new_h]
	
	
	
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

func _dynamic_step_size_height(current_state: Array) -> float:
	# Versuch: step_size an Höhe anpassen: kleinere Schrittweite in der Atmosphäre
	var height: float = (Vector3(current_state[0], current_state[1], current_state[2]).distance_to(Vector3(0,0,0)))-Parameters.planet_radius
	if assign_last_height:
		last_heigt = height
		assign_last_height = false
	if !projectile_reached_heighest_point:	
		if last_heigt > height:
			projectile_reached_heighest_point = true
			#$MeshInstance3D.visible = true
			#$MeshInstance3D.global_position = Vector3(current_state[0], current_state[2], current_state[1])
			#print("Projektil sinkt!")
	if last_heigt!= height:
		last_heigt = height
		
	height *= Parameters.scale_up_factor
	var factor: float = 1.0
	#print("height: ", height)
	if height < 84852:
		projectile_is_over_atmosphere = false
		factor = 10.0
	else:
		projectile_is_over_atmosphere = true
	return factor

# Anfangswertproblem lösen
func _ivp1_modified(step_size: float, initial_conditions: Array) -> Array:
	var current_time: float = 0.0
	var current_state: Array = initial_conditions
	var states: Array = [initial_conditions]  # Initialzustand speichern
	var method: String
	var max_step:int = 0.0
	while true:
		var result: Array
		##print("curren_state: " + str(current_state))
		max_step += 1
		var dynamic_step_factor: float = _dynamic_step_size_height(current_state)
		#print("factor: ", dynamic_step_factor)
		# Auswahl des Verfahrens
		match numerical_method:
			
			NumericalMethod.RK4:
				method = "rk4"
				result = _rk4(current_time, current_state, step_size/dynamic_step_factor)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.RK4b:
				method = "rk4b"
				result = _rk4b(current_time, current_state, step_size/dynamic_step_factor, true)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.Euler:
				method = "euler"
				result = _euler(current_time, current_state, step_size/dynamic_step_factor)  # Euler-Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.SymplecticVerlet:
				method = "symplectic_verlet"
				result = _symplectic_verlet(current_time, current_state, step_size/dynamic_step_factor)  # Verlet Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.VelocityVerlet:
				method = "velocity_verlet"
				result = _velocity_verlet(current_time, current_state, step_size/dynamic_step_factor, true)  # Verlet Verfahren verwenden
			NumericalMethod.RK4Dynamisch:
				method = "rk4_dynamic"
				result = _rk4b_adaptive(current_time, current_state, step_size)
				#print("step_size: ", step_size)
				step_size = result[2]
				_set_speed_data(current_state)
		if not numerical_method_printed:
			
			print(method)
			numerical_method_printed = true
		#await get_tree().create_timer(0.1).timeout	
		var next_time: float = result[0]
		var next_state: Array = result[1]
		
		states.append(next_state)
		current_times.append(current_time)
		
		#drag_array.append(next_state[7])
		#air_density_data.append(next_state[8])
		#has_thrust_array.append(next_state[9])
		
		#print(_node_name, ": result: ", result)
		# Abbruchbedingungungen prüfen
		if _stop_ivp_collision(current_state, next_state):
			var bevor_time: float = current_times[(current_times.size()-1)-2]
			#print(states[(states.size()-1)-2])
			var bevor_state: Array = states[(states.size()-1)-2]
			#_quadratic_interpolate
			var result2 = await _interpolate(current_time, current_state, next_time, next_state, await _interpolate_raycast(current_state))
			#var result2 = _quadratic_interpolate(current_time, current_state, next_time, next_state, bevor_time,bevor_state,Parameters.planet_radius)
			#var result2 = _interpolate_nd(current_time,current_state, next_time,next_state)
			#print(_node_name + ": Abbruchbedingung erreicht: result2: ", result2[1])
			#print(states[states.size() - 1])
			states[states.size() - 1] =  result2[1]
			break
		elif check_for_orbit:
			if _stop_ivp_orbit(current_state, states):
				break
		elif max_step > 10000:
			print("ivp_stopped, to many calculations!")
			break
		
		# Vorbereitung für nächsten Schleifendurchlauf
		current_time = next_time
		current_state = next_state

	return states

func _set_speed_data(current_state: Array) -> void:
	speed_data.append(Vector3(current_state[3],current_state[4],current_state[5]).length())

func _stop_ivp_orbit(current_state: Array, states: Array) -> bool:
	var position: Vector3 = Vector3(current_state[0], current_state[1], current_state[2])
	var position_2: Vector3 = Vector3(Parameters.projectile_start_pos.x, Parameters.projectile_start_pos.y, Parameters.projectile_start_pos.z)
	if states.size() > 10:
		if (position.distance_to(position_2)) <= 10:
			print("position: ", position, "position_2: ", position_2)
			print_rich("[color=blue][b]Orbit reached!!")
			return true
	return false
	
func _stop_ivp_collision(z0: Array, z1: Array) -> bool:
	#earth_middle
	var point_1: Vector3 = Vector3(z0[0], z0[1], z0[2])
	var point_2: Vector3 = Vector3(z1[0], z1[1], z1[2])
	#print("z0:", z0, " z1:", z1)
	var point1_distance_to_earth_middle: float = point_1.distance_to(earth_middle)
	var point2_distance_to_earth_middle: float = point_2.distance_to(earth_middle)
	
	#print("point1_distance_to_earth_middle:", point1_distance_to_earth_middle, ", point2_distance_to_earth_middle: ", point2_distance_to_earth_middle)
	#print(Parameters.planet_radius)
	if point_1.distance_to(earth_middle) > Parameters.planet_radius and point_2.distance_to(earth_middle) < Parameters.planet_radius:
		#print("neuer Punkt innerhalb erde")
		%UnderEarthVisualizer.global_position = Vector3(point_2.x,point_2.z,point_2.y )
		#%UnderEarthVisualizer.visible = true
		%OverEarthVisualizer.global_position = Vector3(point_1.x,point_1.z,point_1.y )
		#%OverEarthVisualizer.visible = true
		return true
	else:
		return false
		
	#return z0[2] > 0.0 and z1[2] <= 0.0 and abs(z1[2]) < 1e6
func _interpolate_raycast(z0: Array) -> float:
	##Berechnet die Höhe bzw. den Radius wo das Projektil die Erdoberfläche trifft.
	
	# Achtung hier 0,2,1 wegen Godot Koordinatensystem:
	var point_1: Vector3 = Vector3(z0[0], z0[2], z0[1])
		
	%InterpolateRaycast.enabled = false
	%InterpolateRaycast.global_position = point_1
	%InterpolateRaycast.target_position =  %UnderEarthVisualizer.global_position -point_1
	%InterpolateRaycast.enabled = true
	
	var intersection_point: Array
	var collision_position: Vector3 = Vector3.ZERO
	if %InterpolateRaycast.collide_with_bodies:
		await get_tree().create_timer(0.01).timeout
		collision_position = %InterpolateRaycast.get_collision_point()
		var collider: Node = %InterpolateRaycast.get_collider()
		
		#print("collider", collider, " collision point: ", collision_position)
		%HitPoint.global_position=collision_position
		#%HitPoint.visible = true
		#print("collision_position.length(): ", collision_position.length())
	
	return collision_position.length()
	
func _quadratic_interpolate(t0: float, z0: Array, t1: float, z1: Array, t2: float, z2: Array, target_radius: float) -> Array:
	# Extrahiere die Positionen (radii) und Zeiten
	print("_quadratic_interpolate")
	var z0_position: Vector3 = Vector3(z0[0], z0[1], z0[2])
	var z0_velocity: Vector3 = Vector3(z0[3], z0[4], z0[5])
	var z1_position: Vector3 = Vector3(z1[0], z1[1], z1[2])
	var z1_velocity: Vector3 = Vector3(z1[3], z1[4], z1[5])
	var z2_position: Vector3 = Vector3(z2[0], z2[1], z2[2])
	var z2_velocity: Vector3 = Vector3(z2[3], z2[4], z2[5])
	
	var r0 = z0_position.length()  # Abstand vom Ursprung für z0
	var r1 = z1_position.length()  # Abstand vom Ursprung für z1
	var r2 = z2_position.length()  # Abstand vom Ursprung für z2
	
	# Extrahiere Zeiten
	var t_values = [t0, t1, t2]
	var r_values = [r0, r1, r2]
	
	# Interpoliere Koeffizienten der quadratischen Funktion: P(r) = a*r^2 + b*r + c
	var a = ((r_values[1] - r_values[0]) / ((t_values[1] - t_values[0]) * (t_values[1] - t_values[2]))) - \
		((r_values[2] - r_values[0]) / ((t_values[2] - t_values[0]) * (t_values[2] - t_values[1])))
	
	var b = ((r_values[1] - r_values[0]) / (t_values[1] - t_values[0])) - a * (t_values[1] + t_values[0])
	
	var c = r_values[0] - a * t_values[0]**2 - b * t_values[0]
	
	# Löse die quadratische Gleichung: a*r^2 + b*r + c = target_radius
	var discriminant = b**2 - 4 * a * (c - target_radius)
	
	if discriminant < 0:
		push_error("Quadratic interpolation failed: Discriminant is negative.")
		return []
	
	# Berechne die Lösungen (Schnittpunkte)
	var root1 = (-b + sqrt(discriminant)) / (2 * a)
	var root2 = (-b - sqrt(discriminant)) / (2 * a)
	print("root1: ", root1, " root2: ", root2," t0: ", t0, " t2: ", t2)
	# Wähle die physikalisch sinnvolle Lösung (diejenige im Intervall [t0, t1, t2])
	var interpolated_time = 0.0
	if t0 <= root1 and root1 <= t2:
		interpolated_time = root1
	elif t0 <= root2 and root1 <= t2:
		interpolated_time = root2
	else:
		print("No valid root found in the interval.")
		return []
	
	# Interpoliere Position und Geschwindigkeit
	var interpolated_position = lerp(z0_position, z1_position, (interpolated_time - t0) / (t1 - t0))
	print("interpolated_position: ", interpolated_position)
	var interpolated_velocity = lerp(z0_velocity, z1_velocity, (interpolated_time - t0) / (t1 - t0))
	
	# Rückgabe der Ergebnisse
	return [interpolated_time, [interpolated_position.x, interpolated_position.y, interpolated_position.z, interpolated_velocity.x, interpolated_velocity.y, interpolated_velocity.z]]
	
func _interpolate(t0: float, z0: Array, t1: float, z1: Array, target_radius: float, planet_center: Vector3 = Vector3.ZERO) -> Array:
	var z0_position: Vector3 = Vector3(z0[0], z0[1], z0[2])
	var z0_velocity: Vector3 = Vector3(z0[3], z0[4], z0[5])
	var z1_position: Vector3 = Vector3(z1[0], z1[1], z1[2])
	var z1_velocity: Vector3 = Vector3(z1[3], z1[4], z1[5])
	
	# Abstand der Positionen vom Planetenmittelpunkt
	var r0: float = (z0_position).length()
	var r1: float = (z1_position).length()
	
	# Differenz in den Radien
	var h: float = abs(r1 - r0)
	if h == 0.0:
		# Sonderfall: Beide Punkte haben den gleichen Radius, kein Schnittpunkt
		print("Sonderfall!")
		return z0
	
	# Normierung basierend auf Zielradius
	var f: float = (target_radius - r1) / h
	var g: float = (target_radius - r0) / h
	
	# Interpolierter Zeitpunkt
	var interpolated_time: float = f * t0 - g * t1
	
	# Interpolierte Position
	var interpolated_position: Vector3 = f * z0_position - g * z1_position
	var interpolated_velocity: Vector3 = f * z0_velocity - g * z1_velocity
	
	# Ergebnis zusammenstellen
	var result: Array = []
	result.append(interpolated_time)
	var state: Array = []
	state.append_array([interpolated_position.x, interpolated_position.y, interpolated_position.z])
	state.append_array([interpolated_velocity.x, interpolated_velocity.y, interpolated_velocity.z])
	result.append(state)
	
	return result
	
func _interpolate_onlyZ(t0: float, z0: Array, t1: float, z1: Array, target_height: float = 0.0) -> Array:
	#print("z0: ", z0)

	var z0_position: Vector3 = Vector3(z0[0], z0[1], z0[2])
	var z0_velocity: Vector3 = Vector3(z0[3], z0[4], z0[5])
	var z1_position: Vector3 = Vector3(z1[0], z1[1], z1[2])
	var z1_velocity: Vector3 = Vector3(z1[3], z1[4], z1[5])
	
	#target_height = (z0_position.length()-%HitPoint.global_position.length())
	#print("target_height: ", target_height)
	var g:float = z0[2]  # z-Komponente von z0
	var f:float = z1[2]  # z-Komponente von z1
	var h:float = abs(f - g)  # Differenz in z
	print("h: ", h)
	# Normierung
	f = (target_height - f)/h
	g = (target_height - g)/h
	
	# Interpolierter Zeitpunkt
	var interpolated_time:float = f * t0 - g * t1
	
	# Interpolierte Position
	var interpolated_position: Vector3 = Vector3(f*z0_position+ -g * z1_position)
	
	var interpolated_velocity: Vector3 = Vector3(f*z0_velocity+ -g * z1_velocity)
	print(_node_name, ": interpolated_velocity: ", interpolated_velocity, " f:", f,
	" z0_velocity: ", z0_velocity, " -g", -g, " z1_velocity: ", z1_velocity, "z1_position: ",
	z1_position, " RayCast3D Schnittpunkt: ", %HitPoint.global_position , " interpolated pos: ", interpolated_position)
	var result: Array
	result.append(interpolated_time)
	var state: Array

	state.append_array([interpolated_position.x,interpolated_position.y,interpolated_position.z])
	state.append_array([interpolated_velocity.x,interpolated_velocity.y,interpolated_velocity.z])
	result.append(state)
	print("result: ", result)
	return result
		
func _calculate_times(trajectory: Array) -> Array:
	# Berechnet die Zeiten für jeden Abschnitt
	var times: Array = []
	times.clear()
	#times.append(0.0)
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
	#print("times: ", times)
	return times
func _on_calculate_oribital_velocity() -> void:
	
	Parameters.projectile_muzzle_velocity = physics._calculate_orbital_velocity()


func _on_check_for_orbit_toggled_signal(toggled: bool) -> void:
	print("value: ", toggled, " check_for_orbit")
	check_for_orbit = toggled
