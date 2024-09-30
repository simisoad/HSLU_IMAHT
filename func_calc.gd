extends HBoxContainer

@onready var a: float = float($CenterContainer_a/LineEdit_a.text)
@onready var b: float = float($CenterContainer_b/LineEdit_b.text)
@onready var c: float = float($CenterContainer_c/LineEdit_c.text)
@onready var d: float = float($CenterContainer_d/LineEdit_d.text)
@onready var e: float = float($CenterContainer_e/LineEdit_e.text)
@onready var f: float = float($CenterContainer_f/LineEdit_f.text)
@onready var g: float = float($CenterContainer_g/LineEdit_g.text)
@onready var h: float = float($CenterContainer_h/LineEdit_h.text)
@onready var i: float = float($CenterContainer_i/LineEdit_i.text)

@onready var sw_01: Control = $"../../.."

func _on_button_pressed() -> void:
	
	sw_01.func_f_user_input = true
	sw_01.redraw = true
	pass # Replace with function body.

func calculate_function(x) -> float:
	_get_new_values()#ups nicht optimal hier, wird ja für jedes x wiederholt...
	var y: float = (a*x**8)+(b*x**7)+(c*x**6)+(d*x**5)+(e*x**4)+(f*x**3)+(g*x**2)+(h*x)+(i)
	return y
func calculate_derivation(x) -> float:
	var y: float = (8*a*x**7)+(7*b*x**6)+(6*c*x**5)+(5*d*x**4)+(4*e*x**3)+(3*f*x**2)+(2*g*x**1)+(1*h*x**0)
	return y
	
func _get_new_values() -> void:
	
	a = _division($CenterContainer_a/LineEdit_a.text)
	b = _division($CenterContainer_b/LineEdit_b.text)
	c = _division($CenterContainer_c/LineEdit_c.text)
	d = _division($CenterContainer_d/LineEdit_d.text)
	e = _division($CenterContainer_e/LineEdit_e.text)
	f = _division($CenterContainer_f/LineEdit_f.text)
	g = _division($CenterContainer_g/LineEdit_g.text)
	h = _division($CenterContainer_h/LineEdit_h.text)
	i = _division($CenterContainer_i/LineEdit_i.text)

func _division(xy_string: String) -> float:
	var xy: float
	print("hallo")
	if xy_string.contains("/"):
		var dividend: float = float(xy_string.substr(0,xy_string.find("/")))
		var divisor: float = float(xy_string.substr(xy_string.find("/")-1))
		print(xy_string)
		print("dividend: " + str(dividend) + " divisor: " + str(divisor))
		xy = dividend/divisor
		print("calculated: " + str(xy))
	else:
		xy = float(xy_string)
	return xy
