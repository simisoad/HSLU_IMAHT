extends Camera3D
@export var camera_zoom_steps: float = 1.0
@export var camera_min_zoom: float = 3.0
@export var camera_max_zoom: float = 400.0

@export var camera_rotation: Node3D
@export var camera_rotation_x: Node3D
var camera_rotation_node_exists: bool = false
# diesen Wert gibt es auch in der FreeCam! Für settings!
@export var mouse_sensitivity: float = 0.005

var camera_zoom: float
var camera_active: bool = true
func _ready() -> void:
	get_window().focus_entered.connect(Callable(self,"_on_focus_entered"))
	get_window().focus_exited.connect(Callable(self,"_on_focus_exited"))
	camera_zoom = self.position.x
	if camera_rotation == null:
		print("ERROR: No Camera Rotation Node assigned!")
		camera_rotation_node_exists = false
	else:
		camera_rotation_node_exists = true
	 
func _process(delta: float) -> void:
	if camera_active:
		_camera_movement(delta)
func _camera_movement(delta: float) -> void:
	if Input.is_action_just_released("2D_camera_zoom_in"):
		camera_zoom += -camera_zoom_steps
		
	if Input.is_action_just_released("2D_camera_zoom_out"):
		camera_zoom += camera_zoom_steps
		
	camera_zoom = clamp(camera_zoom,camera_min_zoom,camera_max_zoom)
	self.position.x = camera_zoom
			
func _input(event: InputEvent) -> void:
	if camera_rotation_node_exists:
		if Input.is_action_pressed("camera_rotate") and not Input.is_action_pressed("camera_move"):
			if event is InputEventMouseMotion:
				if event.relative.x != 0:
					camera_rotation.rotate_object_local(camera_rotation.transform.basis.y, -event.relative.x * mouse_sensitivity)
				if event.relative.y != 0:
					camera_rotation_x.rotate_object_local(camera_rotation_x.transform.basis.z, -event.relative.y * mouse_sensitivity)
func _on_focus_entered() ->void:
	camera_active = true
	
func _on_focus_exited() -> void:
	camera_active = false
