extends Node
#44.4349317841768

#44.3148703901441
#44.3148703901441
signal run_optimization
signal run_simulation_for_optimization
signal await_signal

# Parameter für die Optimierung
var theta_start: float = deg_to_rad(65)  # Startwinkel in Bogenmaß
var learning_rate: float = 0.0001  # Schrittweite des Gradientenverfahrens
var tolerance: float = 0.0000001  # Abbruchkriterium
var max_iterations: int = 100  # Maximale Anzahl an Iterationen

# Referenz auf die NumericalMethods
@onready var numerical_methods: Node = $"../NumericalMethods"

func _ready() -> void:
	self.connect("run_optimization", Callable(self, "_on_run_optimization"))
	numerical_methods.connect("calculation_ended", Callable(self, "_on_calculation_ended"))

# Signal-Callback, wenn die Berechnung abgeschlossen ist
func _on_calculation_ended() -> void:
	# Emitte das Signal, um `await`-Abhängigkeiten zu lösen
	print("_on_calculation_ended: Emitting await_signal")
	emit_signal("await_signal")

# Optimierungsroutine
func _on_run_optimization() -> void:
	print("Starting optimization...")
	optimize_for_max_range()

# Optimierungsroutine mit asynchronem Warten auf Signale
func optimize_for_max_range() -> void:
	var theta = theta_start
	var iteration = 0

	while iteration < max_iterations:
		print("Iteration: ", iteration)

		# Berechnung des Gradienten (Warten auf Berechnungsergebnisse)
		var gradient = calculate_gradient(theta)

		# Aktualisiere den Winkel
		theta += learning_rate * gradient
		print("theta: "  + str(theta))
		# Begrenze den Winkel auf den Bereich 0 bis 90 Grad
		theta = clamp(theta, deg_to_rad(0), deg_to_rad(90))
		# Abbruchbedingung
		if abs(gradient) < tolerance:
			print("Optimierung abgeschlossen! Optimierter Winkel: ", rad_to_deg(theta))
			return

		iteration += 1

	print("Maximale Iterationen erreicht! Optimierter Winkel: ", rad_to_deg(theta))

# Funktion zum Warten auf das Signal
func wait_for_signal() -> void:
	await await_signal  # Warten auf das Signal, dass die Berechnung abgeschlossen ist


# Zielfunktion: Berechne die Reichweite für einen gegebenen Winkel
func range_function(theta: float) -> float:
	print("range_function: Berechnung startet für Winkel ", rad_to_deg(theta))

	# Starte die numerische Berechnung
	numerical_methods.restart_calculations(rad_to_deg(theta))

	# Warte auf das Signal, dass die Berechnung abgeschlossen ist
	wait_for_signal()
	print("range_function: Signal erhalten, hole Reichweite")

	# Hole das Ergebnis der Reichweite
	return numerical_methods.get_range()

# Numerische Gradientenberechnung
func calculate_gradient(theta: float) -> float:
	print("calculate_gradient: Start für theta ", rad_to_deg(theta))
	var h = 0.000001  # Kleine Änderung des Winkels

	# Berechne f(theta + h) und f(theta - h)
	var range_plus = range_function(theta + h)

	var range_minus = range_function(theta - h)

	# Gradienten berechnen
	var gradient = (range_plus - range_minus) / (2 * h)
	print("calculate_gradient: Gradient berechnet: ", gradient)
	return gradient
