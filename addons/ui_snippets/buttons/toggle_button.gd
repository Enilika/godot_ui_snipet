@tool
class_name UISnipToggleButton
extends UISnipAnimatedButton

# A two-state animated button. ON/OFF flips frames_idle between two SpriteFrames.

@export var frames_off: SpriteFrames:
	set(v):
		frames_off = v
		_refresh_state_visual()
@export var frames_on: SpriteFrames:
	set(v):
		frames_on = v
		_refresh_state_visual()


func _ready() -> void:
	toggle_mode = true
	super()
	toggled.connect(_on_toggled)
	_refresh_state_visual()


func _on_toggled(_pressed: bool) -> void:
	_refresh_state_visual()


func _refresh_state_visual() -> void:
	if button_pressed and frames_on != null:
		frames_idle = frames_on
	elif not button_pressed and frames_off != null:
		frames_idle = frames_off
