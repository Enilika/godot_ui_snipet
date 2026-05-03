extends Control

@onready var slot: Control = %Slot
@onready var status: Label = %Status
@onready var duration_slider: HSlider = %DurationSlider
@onready var duration_label: Label = %DurationLabel
var _toggle: bool = true  # Flipped to false on the first _make_content() call → starts at "A".


func _ready() -> void:
	%FadeBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.FADE, "FADE"))
	%SlideLeftBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.SLIDE_LEFT, "SLIDE_LEFT"))
	%SlideRightBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.SLIDE_RIGHT, "SLIDE_RIGHT"))
	%SlideUpBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.SLIDE_UP, "SLIDE_UP"))
	%SlideDownBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.SLIDE_DOWN, "SLIDE_DOWN"))
	%IrisBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.IRIS, "IRIS"))
	%FramesBtn.pressed.connect(func(): _swap(UISnipSceneTransition.Type.FRAMES, "FRAMES"))
	duration_slider.value_changed.connect(func(v): duration_label.text = "Duration: %.2fs" % v)
	duration_label.text = "Duration: %.2fs" % duration_slider.value
	# Seed the slot with initial content.
	slot.add_child(_make_content())


func _swap(t: int, label: String) -> void:
	if UISnipSceneTransition.is_busy():
		return
	status.text = "Transition: %s" % label
	await UISnipSceneTransition.swap_subscene(slot, _make_content, t, duration_slider.value)


func _make_content() -> Control:
	_toggle = not _toggle
	var rect := ColorRect.new()
	rect.color = Color(0.18, 0.32, 0.55, 1) if _toggle else Color(0.55, 0.32, 0.18, 1)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = "B" if _toggle else "A"
	label.add_theme_font_size_override("font_size", 96)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	rect.add_child(label)
	return rect
