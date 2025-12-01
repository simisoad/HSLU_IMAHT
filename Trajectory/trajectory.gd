extends Node3D

var old_curve: Curve3D = Curve3D.new()
var visualisation_points_array: Array

func _on_visualize_trajectory(data: Dictionary) -> void:
	#{"trajectory": trajectory, "times": times, "speed_data": self.speed_data, "thrust_array": thrust_array}
	var trajectory: Array = data.get("trajectory")
	var speed_data: Array = data.get("speed_data")
	##print(trajectory)
	_visualize_trajectory(trajectory, speed_data)

func _on_clear_all_trajectories() -> void:
	#print("Sali")
	var all_childs: Array = self.get_children()
	#print(all_childs)
	for i in all_childs.size():
		remove_child(all_childs[i])

func _random_color() -> Color:
	var colors = [Color.AQUA,Color.AQUAMARINE,Color.BLUE,Color.BROWN,Color.RED, Color.GREEN, Color.YELLOW, Color.YELLOW_GREEN, Color.CADET_BLUE, Color.CHOCOLATE, Color.DARK_GREEN]
	randomize()
	return colors[randi() % colors.size()]

func _on_point_size_changed(point_size: float) -> void:
	var points = get_children()
	for i in points.size()-1:
		if points[i].name.contains("point"):
			points[i].scale = Vector3(0.1,0.1,0.1)
			points[i].scale = point_size*Vector3(1,1,1)


func _get_max_speed(speed_data: Array) -> Array:
	speed_data.sort()
	speed_data.reverse()
	var max_speed: float = speed_data[0]
	var min_speed: float = speed_data[speed_data.size()-1]
	#print("max_speed: ", max_speed, ", min_speed: ", min_speed)
	return [max_speed, min_speed]

func _visualize_trajectory(trajectory: Array, speed_data: Array)-> void:
	# Erstelle eine Instanz von Curve3D

	##print("speed_data_size: ", speed_data.size(),", trajectory_size: ", trajectory.size())
	# nicht optimal :)
	#var max_speed: float = _get_max_speed(speed_data)[0]
	#var min_speed: float = _get_max_speed(speed_data)[1]

	speed_data.append(0.0) # Speed beim Einschlagspunkt 0? oder doch nicht?
	var curve = Curve3D.new()



	curve.clear_points()
	for point in trajectory:
		curve.add_point(Vector3(
			point[0],
			point[2],
			point[1]
		))
	if old_curve.get_baked_length() != curve.get_baked_length():
		old_curve = curve
	else:
		return
	#print("curve.get_point_count(): ", curve.get_point_count())
	# Erstelle eine Linie aus Curve3D mit SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINE_STRIP)
	var random_color: Color = _random_color()
	for i in range(curve.get_point_count()):
		var point = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.1
		point.mesh = sphere
		var material = StandardMaterial3D.new()


		material.albedo_color = _get_color_for_method()
		point.material_override = material
		add_child(point,true)
		point.name = "point" + str(i)

		point.global_position = curve.get_point_position(i)

		#surface_tool.set_color(Color(remap(speed_data[i], min_speed, max_speed, 0,1), 0, 0))
		#surface_tool.set_color(Color(
		#remap(speed_data[i]*10, min_speed, max_speed*10, 0.1,1),
		#remap(speed_data[i]*10, min_speed, max_speed*10, 1,0),
		#0))
		surface_tool.set_color(_get_color_for_method()*remap(speed_data[i], speed_data.min(), speed_data.max(), 0.0,1))

		surface_tool.add_vertex(curve.get_point_position(i))



	var mesh = surface_tool.commit()

	# Erstelle das MeshInstance3D-Objekt
	var line = MeshInstance3D.new()
	line.mesh = mesh
	# Material erstellen und Farbe ändern
	var material = StandardMaterial3D.new()

	material.vertex_color_use_as_albedo = true
	line.material_override = material  # Material auf das gesamte Mesh anwenden

	add_child(line)
	#_create_thick_line(curve,0.03)

func _visualize_trajectory3D(trajectory: Array, speed_data: Array, thickness: float = 0.05) -> void:
	# Erstelle eine Instanz von Curve3D
	var max_speed: float = _get_max_speed(speed_data)[0]
	var min_speed: float = _get_max_speed(speed_data)[1]
	speed_data.append(0.0)  # Speed beim Einschlagspunkt 0

	var curve = Curve3D.new()
	curve.clear_points()
	for point in trajectory:
		curve.add_point(Vector3(
			point[0],
			point[2],
			point[1]
		))

	if old_curve.get_baked_length() != curve.get_baked_length():
		old_curve = curve
	else:
		return

	# Erstelle ein Band entlang der Kurve
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var draw_labels: bool = true
	for i in range(curve.get_point_count() - 1):

		#Punkte an den "berechneten Zeitpunkten" einfügen
		var point = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.1
		point.mesh = sphere
		# Füge die Punkte ein und setze ihr Material:
		var material = StandardMaterial3D.new()
		point.material_override = material
		add_child(point,true)
		point.name = "point" + str(i)
		point.global_position = curve.get_point_position(i)

		# Aktuelle und nächste Position auf der Kurve
		var current_point = curve.get_point_position(i)
		var next_point = curve.get_point_position(i + 1)

		# Berechne eine Richtung orthogonal zur Linie
		var direction = (next_point - current_point).normalized()
		var normal = Vector3(direction.y, -direction.x, 0).normalized() * thickness
		var binormal = direction.cross(normal).normalized() * thickness

		# Punkte für das Röhrenband
		var p1 = current_point + normal + binormal
		var p2 = current_point - normal + binormal
		var p3 = next_point + normal + binormal
		var p4 = next_point - normal + binormal

		var p5 = current_point + normal - binormal
		var p6 = current_point - normal - binormal
		var p7 = next_point + normal - binormal
		var p8 = next_point - normal - binormal

		if draw_labels:
			var p1_label: Label3D = Label3D.new()
			p1_label.text = "p1"
			p1_label.billboard = 2
			add_child(p1_label)
			p1_label.global_position = p1

			var p2_label: Label3D = Label3D.new()
			p2_label.text = "p2"
			p2_label.billboard = 2
			add_child(p2_label)
			p2_label.global_position = p2

			var p3_label: Label3D = Label3D.new()
			p3_label.text = "p3"
			p3_label.billboard = 2
			add_child(p3_label)
			p3_label.global_position = p3
			var p4_label: Label3D = Label3D.new()
			p4_label.text = "p4"
			p4_label.billboard = 2
			add_child(p4_label)
			p4_label.global_position = p4

			var p5_label: Label3D = Label3D.new()
			p5_label.text = "p5"
			p5_label.billboard = 2
			add_child(p5_label)
			p5_label.global_position = p5

			var p6_label: Label3D = Label3D.new()
			p6_label.text = "p6"
			p6_label.billboard = 2
			add_child(p6_label)
			p6_label.global_position = p6

			var p7_label: Label3D = Label3D.new()
			p7_label.text = "p7"
			p7_label.billboard = 2
			add_child(p7_label)
			p7_label.global_position = p7
			var p8_label: Label3D = Label3D.new()
			p8_label.text = "p8"
			p8_label.billboard = 2
			add_child(p8_label)
			p8_label.global_position = p8

			draw_labels = false
		# Farbe setzen
		var color = _get_color_for_method() * remap(speed_data[i], min_speed, max_speed, 0.1, 1)
		surface_tool.set_color(color)

		# Dreiecke für die Seite in Flugrichtung rechts:
		surface_tool.add_vertex(p1)
		surface_tool.add_vertex(p3)
		surface_tool.add_vertex(p2)

		surface_tool.add_vertex(p2)
		surface_tool.add_vertex(p3)
		surface_tool.add_vertex(p4)

		# Dreiecke für die Seite in Flugrichtung links:
		surface_tool.add_vertex(p5)
		surface_tool.add_vertex(p6)
		surface_tool.add_vertex(p7)

		surface_tool.add_vertex(p6)
		surface_tool.add_vertex(p8)
		surface_tool.add_vertex(p7)

		#Verbindungen Fläche oben:
		surface_tool.add_vertex(p2)
		surface_tool.add_vertex(p8)
		surface_tool.add_vertex(p6)

		surface_tool.add_vertex(p2)
		surface_tool.add_vertex(p4)
		surface_tool.add_vertex(p8)

		# Verbindungen Fläche unten:
		surface_tool.add_vertex(p1)
		surface_tool.add_vertex(p7)
		surface_tool.add_vertex(p3)

		surface_tool.add_vertex(p1)
		surface_tool.add_vertex(p5)
		surface_tool.add_vertex(p7)

	var mesh = surface_tool.commit()

	var line = MeshInstance3D.new()
	line.mesh = mesh


	# Material erstellen und Farbe ändern
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	line.material_override = material

	add_child(line)

func _get_color_for_method() -> Color:
	var color: Color = Color.BLACK
	if Parameters.numerical_method == 0:
		color = Color.AQUAMARINE
	elif Parameters.numerical_method == 1:
		color = Color.BLUE
	elif Parameters.numerical_method == 2:
		color = Color.BLUE_VIOLET
	elif Parameters.numerical_method == 3:
		color = Color.BROWN
	elif Parameters.numerical_method == 4:
		color = Color.CHARTREUSE
	elif Parameters.numerical_method == 5:
		color = Color.CRIMSON
	return color
