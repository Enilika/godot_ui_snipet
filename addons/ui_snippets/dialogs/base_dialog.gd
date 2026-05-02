class_name UISnipBaseDialog
extends CanvasLayer

# Base class for all dialogs. Wraps an animated panel with an optional modal
# backdrop and an AnimationPlayer that drives `open` and `close` animations.
# Derived dialogs should inherit the matching .tscn (scene inheritance) and
# fill in the `Content` container with their widgets.

signal opened
signal closed(result: Variant)

@export var is_modal: bool = true:
	set(v):
		is_modal = v
		if _backdrop != null:
			_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
@export var close_on_backdrop: bool = false
@export var close_on_esc: bool = true
@export_range(0.0, 1.0, 0.01) var backdrop_alpha: float = 0.55:
	set(v):
		backdrop_alpha = v
		if _backdrop != null:
			_backdrop.color.a = v

var _backdrop: ColorRect
var _panel: UISnipAnimatedPanel
var _content: Container
var _player: AnimationPlayer
var _is_open: bool = false
var _is_closing: bool = false
var _pending_result: Variant = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backdrop = get_node_or_null("Root/Backdrop") as ColorRect
	_panel = get_node_or_null("Root/Panel") as UISnipAnimatedPanel
	_content = get_node_or_null("Root/Panel/Content/Body") as Container
	_player = get_node_or_null("Root/AnimationPlayer") as AnimationPlayer
	if _backdrop != null:
		_backdrop.color.a = backdrop_alpha
		_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if is_modal else Control.MOUSE_FILTER_IGNORE
		_backdrop.gui_input.connect(_on_backdrop_input)
	if _player != null:
		_player.animation_finished.connect(_on_anim_finished)
	visible = false


func get_content_container() -> Container:
	return _content


func get_panel() -> UISnipAnimatedPanel:
	return _panel


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_is_closing = false
	visible = true
	if _player != null and _player.has_animation("open"):
		_player.stop()
		_player.play("open")
	else:
		_fallback_pop_in()
	opened.emit()


func close(result: Variant = null) -> void:
	if not _is_open or _is_closing:
		return
	_is_closing = true
	_pending_result = result
	if _player != null and _player.has_animation("close"):
		_player.stop()
		_player.play("close")
	else:
		_fallback_pop_out()


func _fallback_pop_in() -> void:
	if _panel != null:
		UISnipAnimator.pop_in(_panel, 1.05, 0.2)
	if _backdrop != null:
		UISnipAnimator.fade_in(_backdrop, 0.2)


func _fallback_pop_out() -> void:
	var tw: Tween
	if _panel != null:
		tw = UISnipAnimator.pop_out(_panel, 0.2)
	if _backdrop != null:
		UISnipAnimator.fade_out(_backdrop, 0.2)
	if tw != null:
		tw.finished.connect(_finalize_close)
	else:
		_finalize_close.call_deferred()


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"close":
		_finalize_close()


func _finalize_close() -> void:
	_is_open = false
	_is_closing = false
	visible = false
	closed.emit(_pending_result)
	queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if not close_on_backdrop:
		return
	if event is InputEventMouseButton and event.pressed:
		close(null)


func _unhandled_input(event: InputEvent) -> void:
	if not close_on_esc:
		return
	if event.is_action_pressed("ui_cancel") and _is_open and not _is_closing:
		get_viewport().set_input_as_handled()
		close(null)
