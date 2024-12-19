@tool
extends PopupPanel

signal pressed

@onready var button: Button = $Button

@export var hex_code: String = "000000":
	get: return hex_code
	set(val):
		hex_code = val
		if not is_node_ready():
			await ready
		button.text = "Copy hex code (#" + hex_code + ") to clipboard"


func _on_button_pressed() -> void:
	pressed.emit()
