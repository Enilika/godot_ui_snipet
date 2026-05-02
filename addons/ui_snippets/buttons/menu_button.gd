class_name UISnipMenuButton
extends Control

# A vertical RPG-style menu of UISnipAnimatedButtons. The currently focused
# button gets a sliding cursor (a Panel whose position is tweened to track
# the focus target).

signal selected(index: int, button: UISnipAnimatedButton)

@export var labels: PackedStringArray = PackedStringArray():
	set(v):
		labels = v
		_rebuild()
@export var spacing: int = 8:
	set(v):
		spacing = v
		if _vbox != null:
			_vbox.add_theme_constant_override("separation", v)

@export var cursor_text: String = "->"
@export_range(0.0, 1.0, 0.01) var cursor_follow_duration: float = 0.18

var _vbox: VBoxContainer
var _cursor: Label
var _buttons: Array[UISnipAnimatedButton] = []
var _cursor_tween: Tween


func _ready() -> void:
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vbox.add_theme_constant_override("separation", spacing)
	add_child(_vbox)
	_cursor = Label.new()
	_cursor.text = cursor_text
	_cursor.modulate = Color(1, 0.85, 0.5, 1)
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cursor)
	_rebuild()


func _rebuild() -> void:
	if _vbox == null:
		return
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for i in labels.size():
		var btn: UISnipAnimatedButton = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
		btn.text = labels[i]
		btn.focus_entered.connect(func(): _move_cursor_to(btn))
		btn.pressed.connect(func(): selected.emit(i, btn))
		_vbox.add_child(btn)
		_buttons.append(btn)
	if _buttons.size() > 0:
		_buttons[0].grab_focus.call_deferred()


func _move_cursor_to(target: UISnipAnimatedButton) -> void:
	if _cursor == null:
		return
	var target_pos := Vector2(target.position.x - 24, target.position.y + (target.size.y - _cursor.size.y) * 0.5)
	if _cursor_tween != null and _cursor_tween.is_valid():
		_cursor_tween.kill()
	_cursor_tween = create_tween()
	_cursor_tween.tween_property(_cursor, "position", target_pos, cursor_follow_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
