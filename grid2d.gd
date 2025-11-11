extends Node2D
@onready var camera_2d: ZoomableCamera = %Camera2D

var scale_x: float = 1.0
var scale_y: float = 1.0

@export var old_on = false
@export var max_grid_xy: int = 100000
var zoom_level: int = 100.0
func _ready() -> void:
	pass

func _draw():
	if old_on:
		_old_grid()
	else:
		_my_grid()

func _my_grid():
		for i in range(-max_grid_xy, max_grid_xy+1,zoom_level):
			draw_line(Vector2(-max_grid_xy,i), Vector2(max_grid_xy,i),Color.BLACK)
			draw_line(Vector2(i,-max_grid_xy), Vector2(i,max_grid_xy),Color.BLACK)

			
func _old_grid():
		var size = get_viewport_rect().size
		var cam = camera_2d.global_position
		for i in range(int((cam.x - size.x) / zoom_level) - 1, int((size.x + cam.x) / zoom_level) + 1):
			draw_line(Vector2(i * zoom_level, cam.y + size.y + max_grid_xy), Vector2(i * zoom_level, cam.y - size.y - max_grid_xy), "000000")
		for i in range(int((cam.y - size.y) / zoom_level) - 1, int((size.y + cam.y) / zoom_level) + 1):
			draw_line(Vector2(cam.x + size.x + max_grid_xy, i * zoom_level), Vector2(cam.x - size.x - max_grid_xy, i * zoom_level), "000000")
		#x-axis:
		draw_line(Vector2(-max_grid_xy,0), Vector2(max_grid_xy,0),Color.RED)
		#y-axis:
		draw_line(Vector2(0,-max_grid_xy), Vector2(0,max_grid_xy),Color.GREEN)
		
func _process(delta):
	
	_zoom_level_scale()
	queue_redraw()
	
func _zoom_level():
	if camera_2d.zoom.x <= 0.25/8:
		self.zoom_level = 3200.0
	elif camera_2d.zoom.x <= 0.25/4:
		self.zoom_level = 1600.0
	elif camera_2d.zoom.x <= 0.25/2:
		self.zoom_level = 800.0
	elif camera_2d.zoom.x <= 0.25:
		self.zoom_level = 400.0
	elif camera_2d.zoom.x <= 0.5:
		self.zoom_level = 200.0
	elif camera_2d.zoom.x <= 1.0:
		self.zoom_level = 100.0
	elif camera_2d.zoom.x <= 2.0:
		self.zoom_level = 50.0
		
func _zoom_level_scale():
	if camera_2d.zoom.x <= 0.25/8:
		self.scale = Vector2(32*scale_x,32*scale_y)	
	elif camera_2d.zoom.x <= 0.25/4:
		self.scale = Vector2(16*scale_x,16*scale_y)
	elif camera_2d.zoom.x <= 0.25/2:
		self.scale = Vector2(8*scale_x,8*scale_y)
	elif camera_2d.zoom.x <= 0.25:
		self.scale = Vector2(4*scale_x,4*scale_y)
	elif camera_2d.zoom.x <= 0.5:
		self.scale = Vector2(2*scale_x,2*scale_y)
	elif camera_2d.zoom.x <= 1.0:
		self.scale = Vector2(1*scale_x,1*scale_y)
	elif camera_2d.zoom.x <= 2.0:
		self.scale = Vector2(0.5*scale_x,0.5*scale_y)
