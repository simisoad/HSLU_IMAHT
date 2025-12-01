class_name FreeViewCamera extends Node3D

signal camera_speed_multiplier_sigal(speed: float)

@onready var camera_3d: Camera3D = %Camera3D
@onready var gimbal: Node3D = %Gimbal
@onready var inner_gimbal: Node3D = %InnerGimbal

@export var speed_movement_xz: float = 0.3
var speed_movement_xz_initial: float
@export var speed_movement_up_down: float = 0.1
var speed_movement_up_down_initial: float
@export var speed_multiplier: float = 10
@export var speed_up_multiplier: float = 1.1
@export var drag_speed: float = 0.005
@export var acceleration: float = 0.08
@export var mouse_sensitivity: float = 0.005

@export var camara_height_max: float = 4.0
@export var camera_height_min: float = 0.5

@export var camera_max_x: float = 5.0
@export var camera_min_x: float = 0.0
@export var camera_max_z: float = 5.0
@export var camera_min_z: float = 0.0

var camera_move: Vector3

var camera_start_transform: Transform3D
var camera_start_pos: Vector3
var camera_moves: bool = false
var camera_active: bool = true

var speed_up_allowed: bool = false
var projectile_target_position: Vector3
var projectile_target_calculated: bool = false

func _ready() -> void:
	get_window().focus_entered.connect(Callable(self,"_on_focus_entered"))
	get_window().focus_exited.connect(Callable(self,"_on_focus_exited"))
	camera_start_transform = self.global_transform
	speed_movement_xz_initial = speed_movement_xz
	speed_movement_up_down_initial = speed_movement_up_down

	camera_start_pos = self.global_position

	await get_tree().create_timer(0.1).timeout
	emit_signal("camera_speed_multiplier_sigal", speed_multiplier)

	pass


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("camera_go_to_target"):
		if projectile_target_calculated:
			#camera_move = projectile_target_position
			global_position = projectile_target_position# + camera_start_pos

	if Input.is_action_pressed("camera_rotate") and not Input.is_action_pressed("camera_move"):
		if event is InputEventMouseMotion:
			if event.relative.x != 0:
				gimbal.rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
			if event.relative.y != 0:
				inner_gimbal.rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)
				inner_gimbal.rotation.x = clampf(inner_gimbal.rotation.x, -PI/2, PI/2)

	if Input.is_action_pressed("camera_move"):
		if event is InputEventMouseMotion:
			camera_move.x -= event.relative.x * drag_speed
			camera_move.z -= event.relative.y * drag_speed
	if Input.is_action_just_pressed("camera_reset"):
		self.global_transform = camera_start_transform
		self.global_position = Vector3(Parameters.projectile_start_pos.x, Parameters.projectile_start_pos.z,Parameters.projectile_start_pos.y)

func _process(delta: float) -> void:
	if camera_active:
		_camera_movement(delta)


func _camera_movement(delta: float) -> void:

	if Input.is_action_just_released("2D_camera_speed_down") and speed_up_allowed:
		speed_multiplier *= (1/speed_up_multiplier)
		speed_multiplier = clamp(speed_multiplier, 10, 1000)
		emit_signal("camera_speed_multiplier_sigal", speed_multiplier)
	if Input.is_action_just_released("2D_camera_speed_up") and speed_up_allowed:
		speed_multiplier *= speed_up_multiplier
		speed_multiplier = clamp(speed_multiplier, 10, 1000)
		emit_signal("camera_speed_multiplier_sigal", speed_multiplier)
	if Input.is_action_pressed("2D_camera_speed_up_temp"):
		speed_up_allowed = true
		speed_movement_up_down =  speed_movement_up_down_initial * speed_multiplier
		speed_movement_xz = speed_movement_xz_initial * speed_multiplier
	if Input.is_action_just_released("2D_camera_speed_up_temp"):
		speed_up_allowed = false
		speed_movement_up_down =  speed_movement_up_down_initial
		speed_movement_xz = speed_movement_xz_initial

	if Input.is_action_pressed("camera_forward"):
		camera_moves = true
		camera_move.z = lerpf(camera_move.z, -speed_movement_xz, acceleration)
	elif Input.is_action_pressed("camera_backward"):
		camera_moves = true
		camera_move.z = lerpf(camera_move.z, speed_movement_xz, acceleration)
	else:
		camera_move.z = lerpf(camera_move.z, 0, acceleration)


	if Input.is_action_pressed("camera_left"):
		camera_moves = true
		camera_move.x = lerpf(camera_move.x, -speed_movement_xz, acceleration)
	elif Input.is_action_pressed("camera_right"):
		camera_moves = true
		camera_move.x = lerpf(camera_move.x, speed_movement_xz, acceleration)
	else:
		camera_move.x = lerpf(camera_move.x, 0, acceleration)

	if Input.is_action_pressed("camera_up"):
		camera_moves = true
		camera_move.y = lerpf(camera_move.y, speed_movement_up_down, acceleration)
	elif Input.is_action_pressed("camera_down"):
		camera_moves = true
		camera_move.y = lerpf(camera_move.y, -speed_movement_up_down, acceleration)
	else:
		camera_move.y = lerpf(camera_move.y, 0, acceleration)

	if not (Input.is_action_pressed("camera_left") and
		Input.is_action_pressed("camera_right") and
		Input.is_action_pressed("camera_up") and
		Input.is_action_pressed("camera_down")):
		camera_moves = false



	global_position += camera_move.rotated(Vector3.UP, gimbal.rotation.y) * delta * 10
	#print("Cam min Height: " + str(camera_height_min))
	#global_position.y = clampf(global_position.y, camera_height_min, camara_height_max)
	#global_position.x = clampf(global_position.x, camera_min_x, camera_max_x)
	#global_position.z = clampf(global_position.z, camera_min_z, camera_max_z)



func _on_end_pos_received(end_pos: Vector3) -> void:
	#print("end_pos is: ", end_pos)
	projectile_target_position = end_pos
	projectile_target_calculated = true


func _on_focus_entered() ->void:
	camera_active = true

func _on_focus_exited() -> void:
	camera_active = false
