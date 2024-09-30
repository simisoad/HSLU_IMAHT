class_name ZoomableCamera extends Camera2D

@export var zoom_multiplier: float = 1.1
@export var zoom_max: Vector2 = Vector2(1.0,1.0)
@export var zoom_min: Vector2 = Vector2(0.05,0.05)
@export var zoom_smoothness: float = 10
@export var camera_speed: float = 600.0
var camera_speed_start: float = camera_speed
@export var camera_temp_speed_multiplier: float = 1.0
var zoomTarget: Vector2

func _ready() -> void:
	zoomTarget = self.zoom
	pass

func _process(delta: float) -> void:
	_zoom(delta)
	_camera_movement(delta)
	camera_speed = self.zoom.x **-1 * camera_speed_start
	
func _zoom(delta: float) -> void:
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoomTarget = zoomTarget * zoom_multiplier
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoomTarget = zoomTarget * (1-zoom_multiplier+1)
	zoomTarget = zoomTarget.clamp(zoom_min, zoom_max)
	self.zoom = self.zoom.slerp(zoomTarget, zoom_smoothness*delta)
	
	pass

func _camera_movement(delta: float) -> void:
	if Input.is_action_pressed("camera_speed_up_temp"):
		camera_temp_speed_multiplier = 5.0
	else:
		camera_temp_speed_multiplier = 1.0
	
	if Input.is_action_pressed("camera_move_down"):
		self.global_position.y += camera_speed*camera_temp_speed_multiplier * delta
	if Input.is_action_pressed("camera_move_left"):
		self.global_position.x -= camera_speed*camera_temp_speed_multiplier * delta
	if Input.is_action_pressed("camera_move_right"):
		self.global_position.x += camera_speed*camera_temp_speed_multiplier * delta
	if Input.is_action_pressed("camera_move_up"):
		self.global_position.y -= camera_speed*camera_temp_speed_multiplier * delta
