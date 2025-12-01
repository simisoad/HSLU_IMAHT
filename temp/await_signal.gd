extends Node

signal awaitsignal

func await_declared():
	await awaitsignal
	print("my declared signal was emitted")

func _ready() -> void:
	await_declared()
	await get_tree().create_timer(4.0).timeout
	_on_send_signal()

func _on_send_signal() -> void:
	awaitsignal.emit()
