

# Physikalische Funktion (inkl. Schubkraft)
func _ode(t: float, state: Array, add_thrust: bool = false) -> Array:
	var x = state[0]
	var y = state[1]
	var z = state[2]
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]
	var actual_pos: Vector3 = Vector3(x,y,z)
	var height = actual_pos.distance_to(earth_middle)-Parameters.planet_radius
	var u = Vector3(dx, dy, dz).length()
	# Methode get_air_density(z) aus Physics_Node!
	var rho = physics._get_air_density_at_height(height) # + height above sea level möglich, aber geht das hier?
	air_density_data.append(rho)
	###print("rho: " + str(rho))
	# Berechnung des dynamischen Drag-Koeffizienten
	var cd = physics.calculate_cd(u,height)#Parameters.projectile_drag_coefficient
	var A = Parameters.projectile_area


	# Luftwiderstand
	var drag_force = 0.5 * rho * u**2 * cd * A #physics._calculate_drag_force(u,rho,Parameters.projectile_diameter, epsilon) #
	var g = physics.calculate_g(height)


	var g_direction: Vector3 = actual_pos.direction_to(earth_middle)
	var g_vector: Vector3 = g_direction * g

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

	return [
		dx,
		dy,
		dz,
		(thrust.x - drag_force * (dx / u) + g_vector.x), # x-Komponente
		(thrust.y - drag_force * (dy / u) + g_vector.y), # y-Komponente
		(thrust.z - drag_force * (dz / u) + g_vector.z)  # z-Komponente
	]


# Anfangsbedingungen für Geschwindigkeit und Winkel
func _ic(v0: float, phi: float, theta: float) -> Array:
	var phi_rad = deg_to_rad(phi) # Winkel in der XY-Ebene
	var theta_rad = deg_to_rad(theta) # Neigungswinkel zur Z-Achse
	var startpos: Vector3 = Vector3(Parameters.projectile_start_pos.x, Parameters.projectile_start_pos.z, Parameters.projectile_start_pos.y)
	if v0 == 0.0 and Parameters.projectile_has_thrust:
		v0 = Parameters.projectile_thrust_force / Parameters.projectile_mass #* thrust_duration
		#v0 = physics._calculate_initial_velocity(phi,theta).length()
	elif v0 == 0:
		print_rich("[color=red][b]Error: Muzzle_Velocity 0.0 and no Thrust is not possible, v0 = 1")
		v0 = 1
	return [
		startpos.x, startpos.z, startpos.y, # Startposition Achtung XYZ Achsen Godot vs. Science
		v0 * cos(phi_rad) * cos(theta_rad),  # x-Komponente
		v0 * sin(phi_rad) * cos(theta_rad),  # y-Komponente
		v0 * sin(theta_rad)  # z-Komponente
		]

# Runge-Kutta-Verfahren 4. Ordnung
func _rk4(x0: float, y0: Array, h: float) -> Array:
	var x1 = x0 + h / 2.0
	var x2 = x0 + h
	var k1 = _ode(x0, y0,true)
	var k2 = _ode(x1, _array_add(y0, _array_multiply(k1, [h / 2.0])))
	var k3 = _ode(x1, _array_add(y0, _array_multiply(k2, [h / 2.0])))
	var k4 = _ode(x2, _array_add(y0, _array_multiply(k3, [h])))

	print("h: ", h, " x1:", x1, " x2:", x2, " k1: ", k1, " k2: ", k2, " k3: ", k3, " k4: ", k4)
	var result_state = _array_add(y0, _array_multiply(_array_add(k1, _array_add(_array_multiply(k2, [2.0]), _array_add(_array_multiply(k3, [2.0]), k4))), [h / 6.0]))
	return [x2, result_state]

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

func _euler(t: float, state: Array, h: float) -> Array:
	# Berechnung der nächsten Position und Geschwindigkeit mit dem Euler-Verfahren
	var dx = state[3]
	var dy = state[4]
	var dz = state[5]
	var accelerations = _ode(t, state, true)
	var next_state = _array_add(state, _array_multiply(accelerations,[h]))
	var next_time = t + h
	return [next_time, next_state]

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
		# Auswahl des Verfahrens

		match numerical_method:

			NumericalMethod.RK4:
				method = "rk4"
				result = _rk4(current_time, current_state, step_size)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.RK4b:
				method = "rk4b"
				result = _rk4b(current_time, current_state, step_size)  # RK4 verwenden
				_set_speed_data(current_state)
				##print(result)
			NumericalMethod.Euler:
				method = "euler"
				result = _euler(current_time, current_state, step_size)  # Euler-Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.SymplecticVerlet:
				method = "symplectic_verlet"
				result = _symplectic_verlet(current_time, current_state, step_size)  # Verlet Verfahren verwenden
				_set_speed_data(current_state)
			NumericalMethod.VelocityVerlet:
				method = "velocity_verlet"
				result = _velocity_verlet(current_time, current_state, step_size, true)  # Verlet Verfahren verwenden
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
		#print(_node_name, ": result: ", result)
		# Abbruchbedingungungen prüfen
		if _stop_ivp_collision(current_state, next_state):

			var result2 = await _interpolate(current_time, current_state, next_time, next_state, await _interpolate_raycast(current_state))
			#var result2 = _interpolate_nd(current_time,current_state, next_time,next_state)
			#print(_node_name + ": Abbruchbedingung erreicht: result2: ", result2[1])
			#print(states[states.size() - 1])
			states[states.size() - 1] =  result2[1]
			break
		elif _stop_ivp_orbit(current_state, states):
			break
		elif max_step > 10:
			print("ivp_stopped, to many calculations!")
			break
		current_times.append(current_time)
		# Vorbereitung für nächsten Schleifendurchlauf
		current_time = next_time
		current_state = next_state

	return states
