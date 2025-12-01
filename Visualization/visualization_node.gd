extends Node3D


@onready var projectile_mesh: MeshInstance3D = %ProjectileMesh
@onready var is_follow_projectile: bool = false
var projectile_speed: float = 0.0
func _ready():
	# Initialisiere die Visualisierung

	projectile_mesh = %ProjectileMesh

func _update_visualization(projectile: Projectile):
	# Aktualisiere die Position des Mesh

	projectile_mesh.global_position = projectile.get_position()
	projectile_mesh.look_at(projectile.get_look_at_vector(), Vector3.UP)
	projectile_mesh.rotate_z(projectile.get_rotation())
	projectile_speed = projectile.get_velocity()
	%SpeedLabel3D.text = (
	"speed: " + str(projectile_speed*Parameters.scale_up_factor) +
	", drag: " + str(projectile.get_drag()*Parameters.scale_up_factor)+
	", height: " + str((projectile_mesh.global_position.distance_to(Vector3.ZERO)-Parameters.planet_radius)*Parameters.scale_up_factor) +
	", air density: " + str(projectile.get_actual_air_density()))

	if projectile.get_thrust_active() and projectile.get_has_thrust():
		%ThrustMesh.visible = true
	else:
		%ThrustMesh.visible = false
func _on_update_visualization(projectile: Projectile):
	_update_visualization(projectile)

func _on_simulation_started() -> void:
	print("Projectile rest")
	projectile_mesh.visible = true

func _on_projectile_impact(projectile: Projectile) -> void:
	print("projectile.get_position(): ", projectile.get_position())
	print("_on_projectile_impact", "projectile_mesh.global_position: ", self.projectile_mesh.global_position)
	projectile_mesh.visible = false
	%Explosion.global_position = projectile_mesh.global_position
	print(%Explosion.global_position)
	%Explosion.restart()
	%Explosion.one_shot = true
	%Explosion.emitting = true



func _process(delta: float) -> void:

	_follow_projectile()
	if is_follow_projectile:
		#%CameraRotation.global_rotation = Vector3(0,0,0)
		#%FollowCamera3D.global_rotation = Vector3(0,0,0)
		%CameraRotation.global_position = projectile_mesh.global_position
		var camera_rotation_pos: Vector3 = %CameraRotation.global_position
		var camera_pos: Vector3 = %FollowCamera3D.global_position
		#print(camera_rotation_pos.distance_to(camera_pos))
		#%FollowCamera3D.rotation = Vector3(0,0,0)
	if not Parameters.visualize_projectile:
		self.visible = false
	else:
		self.visible = true


func _follow_projectile() -> void:
	if Input.is_action_just_pressed("Follow_Projectil"):
		if is_follow_projectile:
			is_follow_projectile = false

			%FollowCamera3D.current = false
			var freecam: Node3D = self.get_parent().find_child("FreeViewCamera")
			freecam.global_position = %FollowCamera3D.global_position

		else:
			is_follow_projectile = true
			%FollowCamera3D.current = true
