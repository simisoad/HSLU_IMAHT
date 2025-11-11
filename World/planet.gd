extends MeshInstance3D

@onready var world_collision_shape_3d: CollisionShape3D = $WorldArea3D/WorldCollisionShape3D

func _on_planet_radius_changed() -> void:
	var radius: float = Parameters.planet_radius
	self.mesh.radius = radius
	self.mesh.height = radius*2
	world_collision_shape_3d.shape.radius = radius
	
