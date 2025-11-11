extends Node

@export var visualize_projectile: bool = true

@export var simulation_speed: float = 1.0

@export var projectile_start_pos: Vector3 = Vector3.ZERO
@export var projectile_has_thrust: bool = false
@export var projectile_thrust_force: float = 0.0
@export var projectile_thrust_duration: float = 3.0
@export var projectile_muzzle_velocity: float = 10.0#863.0
@export var projectile_drag_coefficient: float = 0.011
@export var projectile_diameter: float = 0.155
@export var projectile_area: float = 0.0188691908
@export var projectile_mass: float = 43.0
@export var projectile_phi_xy: float = 0.0
@export var projectile_theta_inclination: float = 45.0

@export var height_above_sea_level: float = 0.0
@export var numerical_method: int = 0
@export var ivp_step_size: float = 0.1
@export var dynamic_step_tolerance: float = 0.00001

#Planet Settings:
@export var planet_radius: float = 1000.0
@export var planet_density: float = 5515.0 #kg/m3
@export var planet_mass: float = INF
#Visual Options:
@export var point_size: float = 0.1

#Scale Settings:
var scale_up_factor: float = 1.0
var scale_down_factor: float = 1.0
