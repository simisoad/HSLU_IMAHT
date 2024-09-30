extends Node2D

@onready var camera_2d: ZoomableCamera = %Camera2D
@onready var grid_max_grid_xy = $"../grid".max_grid_xy

func _draw() -> void:
	#x-axis:
	draw_line(Vector2(-grid_max_grid_xy,0), Vector2(grid_max_grid_xy,0),Color.BLACK, 2.0*camera_2d.zoom.x **-1)
	#y-axis:
	draw_line(Vector2(0,-grid_max_grid_xy), Vector2(0,grid_max_grid_xy),Color.BLACK,2.0*camera_2d.zoom.x **-1)	
	
func _process(delta: float) -> void:
	queue_redraw()
