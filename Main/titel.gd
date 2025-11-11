extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Close_Titel"):
		self.visible = false
