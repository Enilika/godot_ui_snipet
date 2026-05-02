@tool
class_name UISnipAnimatedButton
extends Button

# A Button whose background is rendered by a UISnipAnimatedPanel and whose
# visual state (idle/hover/press/focus/disabled) swaps SpriteFrames + scales
# the whole button via a Tween.

@export var frames_idle: SpriteFrames:
	set(v):
		frames_idle = v
		if is_inside_tree():
			_apply_state(_current_state, true)
@export var frames_hover: SpriteFrames
@export var frames_press: SpriteFrames
@export var frames_focus: SpriteFrames
@export var frames_disabled: SpriteFrames
@export var border_frames: SpriteFrames:
	set(v):
		border_frames = v
		if is_inside_tree() and _panel != null:
			_panel.border_frames = v

@export_range(0.5, 1.5, 0.01) var press_scale: float = 0.96
@export_range(0.5, 1.5, 0.01) var hover_scale: float = 1.04
@export_range(0.0, 1.0, 0.01) var transition_duration: float = 0.12

var _panel: UISnipAnimatedPanel
var _current_state: int = UISnipState.ButtonVisualState.IDLE
var _last_disabled: bool = false
var _tween: Tween


func _ready() -> void:
	flat = true
	clip_contents = false
	_ensure_panel()
	# Make the button itself transparent so the panel shows through.
	# Tweening scale needs pivot at center.
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		button_down.connect(_on_button_down)
		button_up.connect(_on_button_up)
		focus_entered.connect(_on_focus_entered)
		focus_exited.connect(_on_focus_exited)
	_apply_state(_resolve_state(), true)


func _ensure_panel() -> void:
	_panel = get_node_or_null("Panel") as UISnipAnimatedPanel
	if _panel != null:
		return
	_panel = UISnipAnimatedPanel.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	move_child(_panel, 0)
	if Engine.is_editor_hint():
		_panel.owner = get_tree().edited_scene_root


func _resolve_state() -> int:
	if disabled:
		return UISnipState.ButtonVisualState.DISABLED
	if button_pressed or is_pressed():
		return UISnipState.ButtonVisualState.PRESS
	if has_focus():
		return UISnipState.ButtonVisualState.FOCUS
	return UISnipState.ButtonVisualState.IDLE


func _apply_state(state: int, immediate: bool = false) -> void:
	_current_state = state
	if _panel == null:
		return
	var frames := _frames_for(state)
	if frames != null:
		_panel.background_frames = frames
	if border_frames != null:
		_panel.border_frames = border_frames
	var target_scale: Vector2 = Vector2.ONE
	match state:
		UISnipState.ButtonVisualState.HOVER:
			target_scale = Vector2.ONE * hover_scale
		UISnipState.ButtonVisualState.PRESS:
			target_scale = Vector2.ONE * press_scale
		_:
			target_scale = Vector2.ONE
	pivot_offset = size * 0.5
	if immediate or transition_duration <= 0.0:
		scale = target_scale
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", target_scale, transition_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _frames_for(state: int) -> SpriteFrames:
	match state:
		UISnipState.ButtonVisualState.HOVER:
			return frames_hover if frames_hover != null else frames_idle
		UISnipState.ButtonVisualState.PRESS:
			return frames_press if frames_press != null else frames_idle
		UISnipState.ButtonVisualState.FOCUS:
			return frames_focus if frames_focus != null else frames_idle
		UISnipState.ButtonVisualState.DISABLED:
			return frames_disabled if frames_disabled != null else frames_idle
		_:
			return frames_idle


func _on_mouse_entered() -> void:
	if not disabled:
		_apply_state(UISnipState.ButtonVisualState.HOVER)


func _on_mouse_exited() -> void:
	if not disabled:
		_apply_state(_resolve_state())


func _on_button_down() -> void:
	if not disabled:
		_apply_state(UISnipState.ButtonVisualState.PRESS)


func _on_button_up() -> void:
	if not disabled:
		_apply_state(UISnipState.ButtonVisualState.HOVER if get_global_rect().has_point(get_global_mouse_position()) else _resolve_state())


func _on_focus_entered() -> void:
	if not disabled and _current_state == UISnipState.ButtonVisualState.IDLE:
		_apply_state(UISnipState.ButtonVisualState.FOCUS)


func _on_focus_exited() -> void:
	if not disabled:
		_apply_state(_resolve_state())


func _process(_delta: float) -> void:
	if disabled != _last_disabled:
		_last_disabled = disabled
		_apply_state(_resolve_state(), true)
