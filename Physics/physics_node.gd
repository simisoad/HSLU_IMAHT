class_name PhysicsNode

signal orbital_velocity_calculated(orbital_velocity: float)

var mach_vs_drag_coefficient: Curve = preload("res://Curves/155mmShelMachVSDragCoefficient.tres")
	
var gamma: float = 1.4  # Adiabatenexponent
var R: float = 287.0   # Spezifische Gaskonstante für Luft (J/kg·K)
var sea_level_temp: float = 288.15  # Temperatur auf Meereshöhe (K)
var sea_level_pressure: float = 101325.0  # Druck auf Meereshöhe (Pa)
var actual_planet_radius: float = 0.0
var G: float = 6.6740e-11
var real_earth_radius: float = 6378000 #m
var is_t_for_thrust_at_max_height_set: bool = false

func _scale_up_factor_earth_planet_size() -> float:
	
	var result: float = real_earth_radius/Parameters.planet_radius
	Parameters.scale_up_factor = result
	return result
	
func _scale_down_earth_planet_size() -> float:
	var result: float = Parameters.planet_radius/real_earth_radius
	Parameters.scale_down_factor = result
	return result
	
func _calculate_orbital_velocity() -> float:
	_calculate_planet_mass()
	var start_height: float = Parameters.projectile_start_pos.length() - Parameters.planet_radius
	print("start_height: ", start_height)
	var orbital_velocity = sqrt(_calculate_gravitational_parameter()*(2/(Parameters.planet_radius+start_height) - 1/(Parameters.planet_radius+start_height)))
	emit_signal("orbital_velocity_calculated", orbital_velocity)
	#print("orbital_velocity: ", orbital_velocity)
	
	return orbital_velocity
func _calculate_gravitational_parameter() -> float:
	return G*(Parameters.planet_mass + Parameters.projectile_mass)

func _calculate_v_esc() -> float:
	_calculate_planet_mass()
	var result: float = sqrt((2*G*Parameters.planet_mass)/ Parameters.planet_radius+5)
	print("v_esc: ", result)
	return result
func _calculate_planet_mass() -> void:
	Parameters.planet_mass = Parameters.planet_density * _calculate_planet_volume()
	print(Parameters.planet_mass)
	
func _calculate_planet_volume() -> float:
	return (4.0/3.0)*Parameters.planet_radius**3*PI

func calculate_g(height: float) -> float:
	#height = height *_scale_up_factor_earth_planet_size()
	if actual_planet_radius!= Parameters.planet_radius:
		actual_planet_radius = Parameters.planet_radius
		_calculate_planet_mass()
	#var g = (G*5.9722e24)/(real_earth_radius+height)**2
	
	var g = ((G*Parameters.planet_mass)/((Parameters.planet_radius+height + Parameters.height_above_sea_level)**2))
	#print("g not scaled: ", g , " scaled: ", g*_scale_up_factor_earth_planet_size(), " at height: ", height*_scale_up_factor_earth_planet_size())
	return g

func _get_air_density_at_height(height: float) -> float:
	height *= _scale_up_factor_earth_planet_size()
	if height > 84852:
		return 0.0
	#if height < 0.0:
		#return INF
	var ref_height: float = _get_reference_height(height)
	var mass_density: float = _get_mass_density_at_height(height)
	var static_pressure: float = _get_static_pressure_at_height(height)
	var standard_temperature: float = _get_standard_temp_at_height(height)
	var temperature_lapse_rate: float = _get_temperature_lapse_rate_at_height(height)
	var universal_gas_constant: float = 8.3144598 #N·m/(mol·K)
	var spezific_gas_constant: float = 287.058 #J/(kg·K)
	var molar_mass_air: float = 0.0289644 #kg/mol
	var g: float = calculate_g(height*_scale_down_earth_planet_size())
	g = g *_scale_up_factor_earth_planet_size()
	#print("height: ", height,"ref_height: ",ref_height ,", temperature_lapse_rate: ",temperature_lapse_rate, ", standard_temperature: ",standard_temperature)
	
	var air_density: float = 0.0
	if temperature_lapse_rate == 0:
		var hs = (spezific_gas_constant * standard_temperature)/g
		air_density = mass_density*exp(-(height-ref_height)/hs)
	else:
		var beta = (g)/(spezific_gas_constant*temperature_lapse_rate)
		air_density = mass_density*(1+(temperature_lapse_rate*(height-ref_height))/standard_temperature)**(-beta-1)
	#print("air density: ", air_density, " at height: ", height, " and g: ", g )
	return air_density
	
func _get_reference_height(height: float) -> float:
	var ref_height: float = 71000.0
	if height < 11000.0:
		ref_height = 0
	elif height < 20000.0:
		ref_height = 11000.0
	elif height < 32000.0:
		ref_height = 20000.0
	elif height < 47000.0:
		ref_height = 32000.0
	elif height < 51000.0:
		ref_height = 47000.0
	elif height < 71000.0:
		ref_height = 51000.0
	return ref_height
	
func _get_temperature_lapse_rate_at_height(height: float) -> float:
	var lapse_rate: float = -0.002
	if height < 11000.0:
		lapse_rate = -0.0065
	elif height < 20000.0:
		lapse_rate = 0.0
	elif height < 32000.0:
		lapse_rate = 0.001
	elif height < 47000.0:
		lapse_rate = 0.0028
	elif height < 51000.0:
		lapse_rate = 0.0
	elif height < 71000.0:
		lapse_rate = -0.0028
	return lapse_rate
		
func _get_static_pressure_at_height(height: float) -> float:
	var static_pressure: float = 3.95642
	if height < 11000.0:
		static_pressure = 101325.0
	elif height < 20000.0:
		static_pressure = 22632.1
	elif height < 32000.0:
		static_pressure = 5474.89
	elif height < 47000.0:
		static_pressure = 868.019
	elif height < 51000.0:
		static_pressure = 110.906
	elif height < 71000.0:
		static_pressure = 66.9389
	return static_pressure
	
func _get_standard_temp_at_height(height: float) -> float:
	var standard_temperature: float = 214.65
	if height < 11000.0:
		standard_temperature = 288.15
	elif height < 20000.0:
		standard_temperature = 216.65
	elif height < 32000.0:
		standard_temperature = 216.65
	elif height < 47000.0:
		standard_temperature = 228.65
	elif height < 51000.0:
		standard_temperature = 270.65
	elif height < 71000.0:
		standard_temperature = 270.65
	return standard_temperature
	
func _get_mass_density_at_height(height: float) -> float:
	var standard_temperature: float = 0.000064
	if height < 11000.0:
		standard_temperature = 1.2250
	elif height < 20000.0:
		standard_temperature = 0.36391
	elif height < 32000.0:
		standard_temperature = 0.08803
	elif height < 47000.0:
		standard_temperature = 0.01322
	elif height < 51000.0:
		standard_temperature = 0.00143
	elif height < 71000.0:
		standard_temperature = 0.00086
	return standard_temperature

	
	
# Berechnung der Schallgeschwindigkeit abhängig von der Höhe
func calculate_speed_of_sound(height: float) -> float:
	
	var T = _get_air_temperature(height + Parameters.height_above_sea_level)
	return sqrt(gamma * R * T)

# Näherung für die Temperatur abhängig von der Höhe (linear bis Tropopause)
func _get_air_temperature(height: float) -> float:
	
	if( height + Parameters.height_above_sea_level) < 11000:  # Troposphäre (linear abnehmend)
		return sea_level_temp - 0.0065 * (height + Parameters.height_above_sea_level)
	else:  # Ab der Tropopause konstante Temperatur
		return 216.65

# Druckberechnung (barometrische Höhenformel, Näherung)
func _get_air_pressure(height: float) -> float:
	
	if (height + Parameters.height_above_sea_level) < 11000:
		var T = sea_level_temp - 0.0065 * (height + Parameters.height_above_sea_level)
		return sea_level_pressure * pow((T / sea_level_temp), (calculate_g((height + Parameters.height_above_sea_level)) / (R * 0.0065)))
	else:
		return sea_level_pressure * exp(-calculate_g((height + Parameters.height_above_sea_level)) * ((height + Parameters.height_above_sea_level) - 11000) / (R * 216.65))

# Berechnung des Drag-Koeffizienten basierend auf der Mach-Zahl
func calculate_cd(u: float, height: float) -> float:
	u *= _scale_up_factor_earth_planet_size()
	height *= _scale_up_factor_earth_planet_size()
	var a = calculate_speed_of_sound((height + Parameters.height_above_sea_level))
	var M = u / a  # Mach-Zahl
	var cd: float = 0.0
	cd = mach_vs_drag_coefficient.sample(M/2.6)
	return cd

# Berechnung des Basisdrucks für den Basisentlastungseffekt
func calculate_base_pressure(M: float, height: float) -> float:
	
	var P_a = _get_air_pressure((height + Parameters.height_above_sea_level))
	if M > 1:
		return P_a * (1 - 0.90 * exp(-0.1*pow(M - 1, 2)))
	else:
		return 0.0

func _calculate_thrust(t: float, state: Array, projectile_mass: float, thrust_at_max_height: bool = false) -> Vector3:
	
	if thrust_at_max_height:
		if not is_t_for_thrust_at_max_height_set:
			is_t_for_thrust_at_max_height_set = true
			Parameters.projectile_thrust_duration -= t
		
	
	
	if not Parameters.projectile_has_thrust:
		return Vector3.ZERO
	var thrust_duration = Parameters.projectile_thrust_duration
	var thrust_force = Parameters.projectile_thrust_force
	var velocity = Vector3(state[3],state[4],state[5])
	if velocity.length() > 0:
		var thrust_direction = velocity.normalized()
		if t <= thrust_duration:
			#print("Thrust: t: ", t, ", duration: ", Parameters.projectile_thrust_duration)
			return (thrust_direction * thrust_force / projectile_mass)*Parameters.scale_down_factor
		#else:
			#print("Thrust: finished!")
	return Vector3.ZERO

func _calculate_initial_velocity( phi: float, theta: float) -> Vector3:
	# Berechne Geschwindigkeit durch Schub
	
	var v_start = Parameters.projectile_thrust_force / Parameters.projectile_mass #* thrust_duration

	# Zerlege Geschwindigkeit in Komponenten
	var phi_rad = deg_to_rad(phi)  # Winkel in der XY-Ebene
	var theta_rad = deg_to_rad(theta)  # Neigungswinkel zur Z-Achse

	var vx = v_start * cos(phi_rad) * cos(theta_rad)  # x-Komponente
	var vy = v_start * sin(phi_rad) * cos(theta_rad)  # y-Komponente
	var vz = v_start * sin(theta_rad)  # z-Komponente

	return Vector3(vx, vy, vz)
