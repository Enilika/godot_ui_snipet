extends Control

const DEMO_PANEL := "res://demos/demo_animated_panel.tscn"
const DEMO_BUTTONS := "res://demos/demo_buttons.tscn"
const DEMO_DIALOGS := "res://demos/demo_dialogs.tscn"
const DEMO_TRANSITIONS := "res://demos/demo_transitions.tscn"
const DEMO_LISTS := "res://demos/demo_lists.tscn"

@onready var slot: Control = %Slot
@onready var status: Label = %Status
var _current: Node


func _ready() -> void:
	%PanelBtn.pressed.connect(func(): _swap(DEMO_PANEL, "AnimatedPanel"))
	%ButtonsBtn.pressed.connect(func(): _swap(DEMO_BUTTONS, "Buttons"))
	%DialogsBtn.pressed.connect(func(): _swap(DEMO_DIALOGS, "Dialogs"))
	%TransitionsBtn.pressed.connect(func(): _swap(DEMO_TRANSITIONS, "Transitions"))
	%ListsBtn.pressed.connect(func(): _swap(DEMO_LISTS, "Lists"))
	_swap(DEMO_PANEL, "AnimatedPanel")


func _swap(scene_path: String, label: String) -> void:
	if _current != null:
		_current.queue_free()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_warning("Failed to load %s" % scene_path)
		return
	_current = packed.instantiate()
	slot.add_child(_current)
	if _current is Control:
		(_current as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status.text = "Demo: %s" % label
