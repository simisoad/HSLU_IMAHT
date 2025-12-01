class_name Projectile

var _position: Vector3
var _velocity: float
var _drag: float
var _acceleration: Vector3
var _actual_air_density: float

var _rotation: float
var _look_at_vector: Vector3

var _has_thrust: bool = Parameters.projectile_has_thrust #Projectile has a Engine!
var _thrust_active: bool = false #Is Engine acitve?


#constructor:
func _init(position: Vector3, velocity: float, acceleration: Vector3):
	self._position = position
	self._velocity = velocity
	self._acceleration = acceleration

func get_position() -> Vector3:
	return self._position
func get_velocity() -> float:
	return self._velocity
func get_drag() -> float:
	return self._drag
func get_acceleration() -> Vector3:
	return self._acceleration
func get_actual_air_density() -> float:
	return self._actual_air_density
func get_rotation() -> float:
	return self._rotation
func get_look_at_vector() -> Vector3:
	return self._look_at_vector
func get_has_thrust() -> bool:
	return self._has_thrust
func get_thrust_active() -> bool:
	return self._thrust_active

func set_position(pos:Vector3) -> void:
	self._position = pos
func set_velocity(vel:float) -> void:
	self._velocity = vel
func set_drag(drag: float) -> void:
	self._drag = drag
func set_acceleration(acc:Vector3) -> void:
	self._acceleration = acc
func set_actual_air_density(dens: float) -> void:
	self._actual_air_density = dens
func set_rotation(rot:float) -> void:
	self._rotation = rot
func set_look_at_vector(look_at_vec:Vector3) -> void:
	self._look_at_vector = look_at_vec
func set_has_thrust(has_thrust:bool) -> void:
	self._has_thrust = has_thrust
func set_thrust_active(thrust_active:bool) -> void:
	self._thrust_active = thrust_active

func reset_projectile() -> void:
	self._position = Vector3.ZERO
	self._velocity = 0.0
	self._drag = 0.0
	self._acceleration = Vector3.ZERO
	self._rotation = 0.0
	self._look_at_vector = Vector3.ZERO
	self._has_thrust = Parameters.projectile_has_thrust
	self._thrust_active = false
	self._actual_air_density = 0.0
