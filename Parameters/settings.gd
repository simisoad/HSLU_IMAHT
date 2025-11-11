extends Node
#variables:
#-------------------------------------------------------
#@export var visualize_projectile: bool = true

@export var simulation_speed: float = 1.0

@export var projectile_start_pos: Vector3 = Vector3.ZERO
@export var projectile_has_thrust: bool = false
@export var projectile_thrust_force: float = 0.0
@export var projectile_thrust_duration: float = 3.0
@export var projectile_muzzle_velocity: float = 863.0
@export var projectile_drag_coefficient: float = 0.011
@export var projectile_diameter: float = 0.155
@export var projectile_area: float = 0.0188691908
@export var projectile_mass: float = 43.0
@export var projectile_phi_xy: float = 0.0
@export var projectile_theta_inclination: float = 45.0

@export var height_above_sea_level: float = 200.0

@export var ivp_step_size: float = 0.1

enum NumericalMethod { RK4, Euler, SymplecticVerlet, VelocityVerlet }
@export var numerical_method = NumericalMethod.RK4  # Standard: RK4

@onready var numerical_methods: Node = $'../NumericalMethods'



func _ready() -> void:
	pass
	##Parameters.visualize_projectile = self.visualize_projectile
	#
	#Parameters.simulation_speed = self.simulation_speed
	#
	#Parameters.projectile_start_pos = self.projectile_start_pos
	#Parameters.projectile_has_thrust = self.projectile_has_thrust
	#Parameters.projectile_thrust_force = self.projectile_thrust_force
	#Parameters.projectile_thrust_duration = self.projectile_thrust_duration
	#Parameters.projectile_muzzle_velocity = self.projectile_muzzle_velocity
	#Parameters.projectile_drag_coefficient = self.projectile_drag_coefficient
	#Parameters.projectile_diameter = self.projectile_diameter
	#Parameters.projectile_area = self.projectile_area
	#Parameters.projectile_mass = self.projectile_mass
	#Parameters.projectile_phi_xy = self.projectile_phi_xy
	#Parameters.projectile_theta_inclination = self.projectile_theta_inclination
#
	#Parameters.height_above_sea_level = self.height_above_sea_level
#
	#Parameters.ivp_step_size = self.ivp_step_size
	#numerical_methods.numerical_method = self.numerical_method



	
	
	
	
	
	
	
