extends Node

signal run_optimization
signal run_simulation_for_optimization
signal await_signal
signal angle_optimized_signal(angle: float)

# Parameter für die Optimierung
var theta_start: float = deg_to_rad(Parameters.projectile_theta_inclination)  # Startwinkel in Bogenmaß
var learning_rate: float = 0.1  # Schrittweite des Gradientenverfahrens
var tolerance: float = 0.01  # Abbruchkriterium
var max_iterations: int = 200  # Maximale Anzahl an Iterationen
var minimum_angle: float = deg_to_rad(5)
var maximum_angle: float = deg_to_rad(85)
var last_h: float = 0.0
var calculated_distances: Array
# Nelder-Mead-Parameter
var reflection_factor: float = 1.0
var expansion_factor: float = 2.0
var contraction_factor: float = 0.5
var shrink_factor: float = 0.5

@onready var numerical_methods: Node = $"../NumericalMethods"

func _ready() -> void:
	self.connect("run_optimization", Callable(self, "_on_run_optimization"))
	numerical_methods.connect("calculation_ended", Callable(self, "_on_calculation_ended"))
# Funktion zum Warten auf das Signal
func wait_for_signal() -> void:
	await await_signal  # Warten auf das Signal, dass die Berechnung abgeschlossen ist

func _on_calculation_ended() -> void:
	emit_signal("await_signal")


# Hauptmethode zum Starten der Optimierung
func _on_run_optimization(opt_method: String = "gradient") -> void:
	if opt_method == "gradient":
		#print("Opti: Starting gradient optimization...")
		calculated_distances.clear()
		var optimized_angle: float = await optimize_for_max_range_gradient()
		emit_signal("angle_optimized_signal", optimized_angle)
	elif opt_method == "gradient2d":
		optimize_angle_and_velocity_combined()
	elif opt_method == "nelder_mead":
		#print("Opti: Starting Nelder-Mead optimization...")
		optimize_for_max_range_nelder_mead()
	elif opt_method == "nelder_mead_2d":
		optimize_for_max_range_2d()
	else:
		pass
		#print("Opti: Unknown optimization method: ", opt_method)

# Zielfunktion: Reichweite berechnen
func range_function(theta: float, nelder_mead: bool = false) -> float:
	##print("Opti: range_function: Berechnung startet für Winkel ", rad_to_deg(theta))
	# Starte die numerische Berechnung
	numerical_methods.restart_calculations(rad_to_deg(theta))
	# Warte auf das Signal, dass die Berechnung abgeschlossen ist
	await wait_for_signal()
	##print("Opti: range_function: Signal erhalten, hole Reichweite")
	# Hole das Ergebnis der Reichweite
	var result: float = numerical_methods.get_range(theta)
	if nelder_mead:
		result = result * -1
	return result

func range_function_2d(theta: float, v0: float, nelder_mead: bool = false) -> float:
	##print("Opti: Berechnung startet für Winkel ", rad_to_deg(theta), " und Geschwindigkeit ", v0)
	numerical_methods.restart_calculations(rad_to_deg(abs(theta)), abs(v0))
	wait_for_signal()
	var result: float = numerical_methods.get_range()
	#print("Opti: Reichweite für θ = ", rad_to_deg(theta), ", v0 = ", v0, ": ", result)
	if nelder_mead:
		result *= -1
	return result  # Negativ für Minimierung

# ------------------ Gradientenverfahren Problem 01------------------
func optimize_for_max_range_gradient() -> float:
	var theta = deg_to_rad(Parameters.projectile_theta_inclination)  # Startwinkel
	var iteration = 0
	print("Opti: Gradientenverfahren gestartet. Startwinkel: ", rad_to_deg(theta))

	while iteration < max_iterations:
		# Gradienten berechnen
		var gradient = await calculate_gradient(theta)
		#print("Opti: Iteration:", iteration, ", Gradient:", gradient, ", Theta:", rad_to_deg(theta))

		# Schritt in Richtung Maximum, versuch Dynamisch:
		var step = learning_rate * gradient / (1 + abs(gradient))
		#var step = learning_rate * gradient
		theta += step

		# Winkel auf physikalisch mögliche Grenzen beschränken
		theta = clamp(theta, minimum_angle, maximum_angle)
		calculated_distances.append(await range_function(theta))
		# Überprüfen, ob der Gradient nahe 0 ist (Abbruchbedingung)
		if abs(gradient) < tolerance:
			print("Opti: Optimierung abgeschlossen. Optimaler Winkel: ", rad_to_deg(theta))
			print("Max Range: ", calculated_distances.max())
			return theta

		iteration += 1

	print("Opti: Maximale Iterationen erreicht. Letzter Winkel: ", rad_to_deg(theta))
	return theta

func optimize_for_max_range_gradient_old() -> float:
	var theta = deg_to_rad(Parameters.projectile_theta_inclination)
	print("Opti: theta start: " , theta)
	var iteration = 0
	print_rich("[color=red][b]optimize_for_max_range_gradient")
	while iteration < max_iterations:
		var gradient = await calculate_gradient(theta)
		theta -= learning_rate * gradient
		theta = clamp(theta, deg_to_rad(1), deg_to_rad(89))  # Winkel begrenzen
		print("Opti: new theta: ", theta)
		if abs(gradient) < tolerance:
			print("Opti: Gradient optimization finished. Optimized angle: ", rad_to_deg(theta))

			return theta

		iteration += 1
	print_rich("[color=red][b]Max iterations reached. Last angle: ", rad_to_deg(theta))
	return theta


func calculate_gradient(theta: float) -> float:
	# Dynamische Schrittweite h
	var h = deg_to_rad(0.1) * (1 / sqrt(1 + Parameters.projectile_muzzle_velocity))
	h = clamp(h, deg_to_rad(0.001), deg_to_rad(1))  # Begrenzung der Schrittweite

	# Berechnung der Reichweiten für Theta +/- h
	var angle_plus: float = theta + h
	var angle_minus: float = theta - h
	angle_minus = max(angle_minus, minimum_angle)  # Winkelbegrenzung
	angle_plus = min(angle_plus, maximum_angle)

	var range_plus = await range_function(angle_plus)
	var range_minus = await range_function(angle_minus)

	# Berechnung des Gradienten
	var gradient = (range_plus - range_minus) / (2 * h)

	# Normierung durch die maximal erreichbare Reichweite
	gradient /= max(range_plus, range_minus, 1.0)

	#print("range_plus: ", range_plus, ", range_minus: ", range_minus, ", h: ", rad_to_deg(h))
	return gradient


func optimize_angle_and_velocity_gradient_old( ) -> Dictionary:
	var step_size_angle: float = 0.01
	var step_size_velocity: float = 10

	var toleranz_angle: float = 0.001
	var toleranz_velocity: float = 0.5

	var alpha_angle: float = 0.01
	var alpha_velocity: float = 5
	var theta = theta_start
	var velocity = Parameters.projectile_muzzle_velocity
	var max_iterations = max_iterations
	var iteration = 0

	while iteration < max_iterations:
		iteration += 1

		# Berechnung des Gradienten
		var range_current = range_function_2d(theta, velocity)
		var gradient_theta = (range_function_2d(theta + step_size_angle, velocity) - range_current) / step_size_angle
		var gradient_velocity = (range_function_2d(theta, velocity + step_size_velocity) - range_current) / step_size_velocity

		# Gradientenaufstieg
		theta += alpha_angle * gradient_theta
		#theta = theta_start
		velocity += alpha_velocity * gradient_velocity

		# Begrenzungen
		theta = clamp(theta, deg_to_rad(1), deg_to_rad(80))
		velocity = max(0, velocity)  # Geschwindigkeit kann nicht negativ sein

		# Abbruchbedingung
		if abs(gradient_theta) < toleranz_angle and abs(gradient_velocity) < toleranz_velocity:
			break

	#print("Opti: Optimaler Winkel: ", rad_to_deg(theta), ", optimale Mündungsgeschw.: ", velocity, " Max. Dist: ", range_function_2d(theta, velocity))
	return {
		"theta": theta,
		"velocity": velocity,
		"range": range_function_2d(theta, velocity),
		"iterations": iteration
	}

func optimize_angle_and_velocity_gradient_nur_anfangsWinkel() -> Dictionary:
	# 1. Winkel optimieren
	#print("Opti: Starte Winkel-Optimierung...")
	var optimized_theta = await optimize_for_max_range_gradient()


	# 2. Geschwindigkeit optimieren (Winkel fixieren)
	#print("Opti: Starte Geschwindigkeits-Optimierung...")
	var step_size_velocity: float = 10
	var toleranz_velocity: float = 0.5
	var alpha_velocity: float = 5
	var velocity = Parameters.projectile_muzzle_velocity
	var max_iterations = max_iterations
	var iteration = 0

	while iteration < max_iterations:
		iteration += 1

		# Berechnung des Gradienten für die Geschwindigkeit
		var range_current = range_function_2d(optimized_theta, velocity)
		var gradient_velocity = (range_function_2d(optimized_theta, velocity + step_size_velocity) - range_current) / step_size_velocity

		# Gradientenaufstieg
		velocity += alpha_velocity * gradient_velocity

		# Geschwindigkeit begrenzen
		velocity = max(0, velocity)

		# Abbruchbedingung
		if abs(gradient_velocity) < toleranz_velocity:
			break

	#print("Opti: Optimierter Winkel: ", rad_to_deg(optimized_theta), ", optimierte Mündungsgeschw.: ", velocity, " Max. Dist: ", range_function_2d(optimized_theta, velocity))
	return {
		"theta": optimized_theta,
		"velocity": velocity,
		"range": range_function_2d(optimized_theta, velocity),
		"iterations": iteration
	}

func optimize_angle_and_velocity_combined() -> Dictionary:
	var theta = theta_start
	var velocity = Parameters.projectile_muzzle_velocity

	var max_iterations = max_iterations
	var iteration = 0
	var prev_theta = theta
	var prev_velocity = velocity
	var convergence_tolerance = 0.01  # Abbruchkriterium für Änderungen

	while iteration < max_iterations:
		iteration += 1

		# Schritt 1: Winkel optimieren bei fixer Geschwindigkeit
		#print("Opti: Iteration ", iteration, ": Optimiere Winkel bei v0 = ", velocity)
		theta = optimize_for_max_range_gradient_at_velocity(velocity)

		# Schritt 2: Geschwindigkeit optimieren bei fixiertem Winkel
		#print("Opti: Iteration ", iteration, ": Optimiere Geschwindigkeit bei θ = ", rad_to_deg(theta))
		velocity = optimize_velocity_at_angle(theta)

		# Überprüfen, ob sich die Werte ausreichend stabilisiert haben
		if abs(theta - prev_theta) < convergence_tolerance and abs(velocity - prev_velocity) < convergence_tolerance:
			break
		if velocity < 10 or theta <= deg_to_rad(1):
			#print("Opti: Abbruch: Geschwindigkeit oder Winkel außerhalb des zulässigen Bereichs.")
			break
		prev_theta = theta
		prev_velocity = velocity

	#print("Opti: Optimierter Winkel: ", rad_to_deg(theta), ", optimierte Mündungsgeschw.: ", velocity, " Max. Dist: ", range_function_2d(theta, velocity))
	return {
		"theta": theta,
		"velocity": velocity,
		"range": range_function_2d(theta, velocity),
		"iterations": iteration
	}

func optimize_for_max_range_gradient_at_velocity(v0: float) -> float:
	var theta = theta_start
	var iteration = 0

	while iteration < max_iterations:
		var h = 0.00001
		var range_plus = range_function_2d(theta + h, v0)
		var range_minus = range_function_2d(theta - h, v0)
		var gradient = (range_plus - range_minus) / (2 * h)

		theta += learning_rate * gradient
		theta = clamp(theta, deg_to_rad(1), deg_to_rad(89))  # Winkel begrenzen

		if abs(gradient) < tolerance:
			return theta
		iteration += 1

	return theta


func optimize_velocity_at_angle(theta: float) -> float:
	var velocity = Parameters.projectile_muzzle_velocity
	var step_size_velocity: float = 10
	var toleranz_velocity: float = 0.5
	var alpha_velocity: float = 5
	var iteration = 0

	while iteration < max_iterations:
		iteration += 1

		var range_current = range_function_2d(theta, velocity)
		var gradient_velocity = (range_function_2d(theta, velocity + step_size_velocity) - range_current) / step_size_velocity
		# Aktualisiere Geschwindigkeit
		velocity += alpha_velocity * gradient_velocity
		velocity = max(10, velocity)  # Geschwindigkeit darf nicht unter 10 m/s fallen
		#print("Opti: Gradient Velocity: ", gradient_velocity, ", Aktuelle Geschwindigkeit: ", velocity)
		if abs(gradient_velocity) < toleranz_velocity:
			break

	return velocity

# ------------------ Nelder-Mead-Verfahren ------------------
func optimize_for_max_range_nelder_mead() -> void:
	var simplex = []
	simplex.append([theta_start])
	# Anstelle von einfach 100 metern dynamisch machen:
	#var initial_step = deg_to_rad(10) if range_function(theta_start, true) < (max_range_based_on_speed * speed_factor) else deg_to_rad(2)
	var initial_step = deg_to_rad(10) if await range_function(theta_start,true) < 100 else deg_to_rad(2)
	#print("Opti: initial_step: " + str(rad_to_deg(initial_step)) + " distance: " + str(range_function(theta_start,false)))
	simplex.append([theta_start + initial_step])
	simplex.append([theta_start - initial_step])

	var iteration = 0

	while iteration < max_iterations:
		if abs(simplex[2][0] - simplex[0][0]) < deg_to_rad(0.00001):  # Stop bei kleiner Differenz
			#print("Opti: nahe genug!")
			break
		simplex.sort_custom(Callable(self, "_simplex_compare"))  # Sortiere Simplex nach Reichweite

		var centroid = (simplex[0][0] + simplex[1][0]) / 2.0

		# Reflexion
		var reflected = centroid + reflection_factor * (centroid - simplex[2][0])
		var reflected_value = await range_function(reflected,true)
		if reflected_value < await range_function(simplex[0][0],true):
			var expanded = centroid + expansion_factor * (reflected - centroid)
			if await range_function(expanded,true) < reflected_value:
				simplex[2][0] = expanded
			else:
				simplex[2][0] = reflected
		elif reflected_value < await range_function(simplex[1][0],true):
			simplex[2][0] = reflected
		else:
			var contracted = centroid + contraction_factor * (simplex[2][0] - centroid)
			if await range_function(contracted,true) < await range_function(simplex[2][0],true):
				simplex[2][0] = contracted
			else:
				for i in range(1, simplex.size()):
					simplex[i][0] = simplex[0][0] + shrink_factor * (simplex[i][0] - simplex[0][0])
		iteration += 1

	#print("Opti: Nelder-Mead optimization finished. Optimized angle: ", rad_to_deg(simplex[0][0]))

func _simplex_compare(a, b) -> int:
	return -1 if await range_function(a[0],true) < await range_function(b[0],true) else 1

func optimize_for_max_range_2d() -> void:
	var simplex = []
	var theta_start = deg_to_rad(60)  # Vernünftiger Startwinkel
	var v0_start = 10.0  # Startgeschwindigkeit
	var step_theta = deg_to_rad(3)  # Schrittweite für Winkel
	var step_v0 = 0.1  # Schrittweite für Geschwindigkeit

	# Initialisiere den Simplex (3 Punkte in 2D)
	simplex.append([theta_start, v0_start])
	simplex.append([theta_start + step_theta, v0_start])
	simplex.append([theta_start, v0_start + step_v0])

	var iteration = 0
	while iteration < max_iterations:
		simplex.sort_custom(Callable(self, "_simplex_compare_2d"))

		var centroid = [
			(simplex[0][0] + simplex[1][0]) / 2.0,
			(simplex[0][1] + simplex[1][1]) / 2.0,
		]

		# Reflexion
		var reflected = [
			centroid[0] + reflection_factor * (centroid[0] - simplex[2][0]),
			centroid[1] + reflection_factor * (centroid[1] - simplex[2][1]),
		]
		var reflected_value = range_function_2d(reflected[0], reflected[1], true)
		if reflected_value < range_function_2d(simplex[0][0], simplex[0][1], true):
			var expanded = [
				centroid[0] + expansion_factor * (reflected[0] - centroid[0]),
				centroid[1] + expansion_factor * (reflected[1] - centroid[1]),
			]
			if range_function_2d(expanded[0], expanded[1], true) < reflected_value:
				simplex[2] = expanded
			else:
				simplex[2] = reflected
		elif reflected_value < range_function_2d(simplex[1][0], simplex[1][1], true):
			simplex[2] = reflected
		else:
			var contracted = [
				centroid[0] + contraction_factor * (simplex[2][0] - centroid[0]),
				centroid[1] + contraction_factor * (simplex[2][1] - centroid[1]),
			]
			if range_function_2d(contracted[0], contracted[1], true) < range_function_2d(simplex[2][0], simplex[2][1], true):
				simplex[2] = contracted
			else:
				for i in range(1, simplex.size()):
					simplex[i] = [
						simplex[0][0] + shrink_factor * (simplex[i][0] - simplex[0][0]),
						simplex[0][1] + shrink_factor * (simplex[i][1] - simplex[0][1]),
					]
		iteration += 1

	#print("Opti: Optimierung abgeschlossen. Winkel: ", rad_to_deg(simplex[0][0]), ", Geschwindigkeit: ", simplex[0][1])
