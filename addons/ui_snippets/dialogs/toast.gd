class_name UISnipToast
extends CanvasLayer

# Lightweight, non-modal notification that slides in, holds, then fades out.
# Stack-friendly: multiple toasts placed at the same anchor stack vertically.

enum ToastPosition {
	TOP_CENTER,
	BOTTOM_CENTER,
	TOP_RIGHT,
	BOTTOM_RIGHT,
}

@export var text: String = ""
@export var duration: float = 2.0
@export var position_preset: ToastPosition = ToastPosition.BOTTOM_CENTER

var _panel: UISnipAnimatedPanel
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = get_node("Panel") as UISnipAnimatedPanel
	_label = get_node("Panel/Margin/Label") as Label
	if _label != null:
		_label.text = text
	_apply_position()
	_run_lifecycle.call_deferred()


func _apply_position() -> void:
	if _panel == null:
		return
	# Reset anchors and set per preset, with safe-area margins.
	_panel.anchor_left = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var w: float = clampf(_panel.size.x, 200.0, viewport_size.x - 32.0)
	var h: float = max(_panel.size.y, 56.0)
	_panel.size = Vector2(w, h)
	var margin := 24.0
	match position_preset:
		ToastPosition.TOP_CENTER:
			_panel.position = Vector2((viewport_size.x - w) * 0.5, margin)
		ToastPosition.BOTTOM_CENTER:
			_panel.position = Vector2((viewport_size.x - w) * 0.5, viewport_size.y - h - margin)
		ToastPosition.TOP_RIGHT:
			_panel.position = Vector2(viewport_size.x - w - margin, margin)
		ToastPosition.BOTTOM_RIGHT:
			_panel.position = Vector2(viewport_size.x - w - margin, viewport_size.y - h - margin)


func _run_lifecycle() -> void:
	if _panel == null:
		return
	var slide_dir := Vector2.DOWN if position_preset in [ToastPosition.TOP_CENTER, ToastPosition.TOP_RIGHT] else Vector2.UP
	UISnipAnimator.slide_in(_panel, -slide_dir, 32.0, 0.25)
	await get_tree().create_timer(duration).timeout
	var tw := UISnipAnimator.fade_out(_panel, 0.25)
	if tw != null:
		await tw.finished
	queue_free()


static func show_toast(parent: Node, p_text: String, p_duration: float = 2.0, p_pos: int = ToastPosition.BOTTOM_CENTER) -> UISnipToast:
	var t: UISnipToast = preload("res://addons/ui_snippets/dialogs/toast.tscn").instantiate()
	t.text = p_text
	t.duration = p_duration
	t.position_preset = p_pos
	parent.add_child(t)
	return t
