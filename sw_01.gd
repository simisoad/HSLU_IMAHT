@tool

extends Control

@export var redraw: bool = false
@export var minimizer_start: bool = false
@export var camera_speed: float = 800.0

@export var min_x: float = -10.0
@export var max_x: float = 10.0

@export var graph_width: float = 2.0

@onready var graph_df: Line2D = %graph_df
@onready var graph_f: Line2D = %graph_f
@onready var point_f: Sprite2D = $point_f
@onready var point_df: Sprite2D = $point_df
@onready var camera_2d: Camera2D = %Camera2D
@onready var coords: Label = %Coords
@onready var zoomlevel: Label = %zoomlevel
@onready var start_x_user: LineEdit = %start_x_user
@onready var runden_user: LineEdit = %runden_user
@onready var scale_x: float = 1.0
@onready var scale_y: float = 1.0
@onready var points_size: Vector2 = Vector2(0.15, 0.15)
@onready var canvas: Node2D = $Canvas
@onready var grid: Node2D = $Canvas/grid

@onready var minimizer_reset: bool = false
@onready var func_f_user_input: bool = false
@onready var func_df_user_input: bool = false
@onready var set_function_by_user: bool = false
@onready var func_f: HBoxContainer = %func_f


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	graph_f.clear_points()
	graph_df.clear_points()
	calc_points(min_x,max_x)
	#minimizer(3.0,10.0)
	#print(f(4.0))
	
	
func _process(delta: float) -> void:

	if self.redraw:
		self.redraw = false
		graph_f.clear_points()
		graph_df.clear_points()
		calc_points(min_x,max_x)
	
	if self.minimizer_start:
		self.minimizer_start = false
		var runden = 10
		if float(runden_user.text) > 0:
			runden = float(runden_user.text)
		minimizer(_get_start_value(),float(runden))
	if not Engine.is_editor_hint():
		
		grid.scale_x = self.scale_x
		grid.scale_y = self.scale_y
		
		coords.text = "x: " + str(get_global_mouse_position().x/100) + " y: " +str(-get_global_mouse_position().y/100)
		graph_f.width = camera_2d.zoom.x **-1 * graph_width
		graph_df.width = camera_2d.zoom.x **-1 * graph_width
		point_f.scale = camera_2d.zoom.x **-1 * points_size
		point_df.scale = camera_2d.zoom.x **-1 * points_size

		pass
	
	pass

func _get_start_value() -> float:
	if start_x_user.text != "":
		return start_x_user.text.to_float()
	else:
		return 0.0


func _input(event: InputEvent) -> void:
	
	pass
	
func f(x: float) -> float:
	var y: float
	if not func_f_user_input and not set_function_by_user:
		y = 0.1*x**6 - 1.35*x**5 + 4.301*x**4 + 5.1055*x**3 - 30.4597*x**2 + 3.53804*x + 27.9063
		#y = 1.0/12.0*x**4 + 1.0/6.0*x**3 - x**2.0 - x
	else:
		if func_f_user_input:
			y = func_f.calculate_function(x)
		elif set_function_by_user:
			y = _set_func_by_user(x)
	return y
	
func df(x: float) -> float:
	var y: float
	if not func_f_user_input and not set_function_by_user:
		y = 0.6*x**5 - 6.75*x**4 + 17.204*x**3 + 15.3165*x**2 - 60.9194*x + 3.53804
		#y = 1.0/3.0*x**3 + 1.0/2.0*x**2 - 2.0*x - 1.0
	else:
		if func_f_user_input:
			y = func_f.calculate_derivation(x)
		elif set_function_by_user:
			y = _get_function_parts(x)
	return y
	
func f1(x: float) -> float:
	var y: float = 1.0/12.0*x**4 + 1.0/6.0*x**3 - x**2.0 - x
	return y
	
func df2(x: float) -> float:
	var y: float = 1.0/3.0*x**3 + 1.0/2.0*x**2 - 2.0*x - 1.0
	return y
	
func calc_points(from: float, to:float):
	
	for i in range(from*100,to*100,1):
		var x = (i/100.0)
		var y = f(x)
		var point = Vector2(x*scale_x, -y*scale_y)
		graph_f.add_point(point*100.0)
		
	for i in range(from*100,to*100,1):
		var x = (i/100.0)
		var y = df(x)
		var point = Vector2(x*scale_x, -y*scale_y)
		graph_df.add_point(point*100.0)

	
	print(graph_df.points.size())	


func minimizer(start, runden):
	
	var x_0 = start
	var y = df(x_0)
	_place_point(x_0,y)
	var schritt = 0.1
	
	for i in range(runden):
		if df(x_0) > 0:
			while df(x_0)>0 and not minimizer_reset:
				y = df(x_0)
				_place_point(x_0,y)
				x_0 = x_0 - schritt
				await get_tree().create_timer(0.7).timeout
		else:
			while df(x_0) <0 and not minimizer_reset:
				y = df(x_0)
				_place_point(x_0,y)
				x_0 = x_0 + schritt
				await get_tree().create_timer(0.7).timeout
		schritt = schritt/10
	if minimizer_reset:
		minimizer_reset = false
		
func _place_point(x,y):
	print("point: x = " + str(x) + " y = " +str(f(x)) + " df_y: " + str(y))
	$CanvasLayer/HBoxContainer3/Label.text = "point: x = " + str(x) + " y = " +str(f(x)) + " df_y: " + str(y)
	point_f.global_position = Vector2(x*scale_x,-y*scale_y)*100
	point_df.global_position = Vector2(x*scale_x, -f(x)*scale_y)*100

func _on_button_minimizer_pressed() -> void:
	minimizer_start = true
	pass # Replace with function body.


func _on_button_scale_pressed() -> void:
	self.scale_x = float(%scale_x_user.text)
	self.scale_y = float(%scale_y_user.text)
	#$Canvas.scale = Vector2(self.scale_x, self.scale_y)
	self.redraw = true
	pass # Replace with function body.


func _on_show_func_f_pressed() -> void:
	if graph_f.visible:
		graph_f.visible = false
	else:
		graph_f.visible = true
	pass # Replace with function body.


func _on_show_func_df_pressed() -> void:
	if graph_df.visible:
		graph_df.visible = false
	else:
		graph_df.visible = true
	pass # Replace with function body.


func _on_start_x_user_text_submitted(new_text: String) -> void:
	var x = float(new_text)
	var y_f = f(x)
	var y = df(x)
	_place_point(x,y)
	pass # Replace with function body.


func _on_button_minimizer_reset_pressed() -> void:
	minimizer_reset = true
	pass # Replace with function body.


func _on_button_arg_min_pressed() -> void:
	self.min_x = float(%min_x_user.text)
	self.max_x = float(%max_x_user.text)
	self.redraw = true
	pass # Replace with function body.

func _set_func_by_user(x: float) -> float:
	var expression: = Expression.new()
	var user_input: String = %set_function_user.text
	user_input = _convert_string_for_math(user_input)
	expression.parse(user_input, ["x"])
	var y = expression.execute([x])
	return y
	
func _convert_string_for_math(user_input: String) -> String:
	user_input = user_input.replace("X","x")
	user_input = user_input.replace(" ","")
	user_input = user_input.replace("+-","-")
	user_input = user_input.replace("-+","-")
	user_input = user_input.replace("*x", "x")
	user_input = user_input.replace("x", "*x")
	user_input = user_input.replace("-*x", "-x")
	user_input = user_input.replace("+*x", "+x")
	if user_input.begins_with("*"):
		user_input = user_input.erase(0)
	user_input = user_input.replace("^", "**")
	user_input = user_input.replace("/", ".0/")
	return user_input
	
func _get_function_parts(x:float) -> float:
	var user_input: String = %set_function_user.text
	user_input = _convert_string_for_math(user_input)
	user_input = user_input.replace("-", "+-")
	var derivative: String = ""
	var parts: PackedStringArray = user_input.split("+")
	for i in range(parts.size()):
		var exponent: String = _find_exponet(parts[i])
		if exponent == "1":
			parts[i] = parts[i].replace("*x","")
		print(parts[i] + " exponent: "  + exponent)
		derivative = derivative + "+" + exponent + "*" + parts[i].replace("**" + exponent, "**" + str(float(exponent)-1))
		#parts[i]=derivative
	if derivative.begins_with("+"):
		derivative = derivative.erase(0)
	print(derivative)
	var expression: = Expression.new()
	expression.parse(derivative, ["x"])
	var y = expression.execute([x])
	return y

		
func _find_exponet(s: String) -> String:
	var index = s.find("**")
	var result: String = "1"
	if index != -1:
		result = s.substr(index+2)
	else:
		if not s.contains("x"):
			result = "0"
	return result

func _on_button_pressed() -> void:
	self.set_function_by_user = true
	self.redraw = true
	#_get_function_parts()
	pass # Replace with function body.
	
