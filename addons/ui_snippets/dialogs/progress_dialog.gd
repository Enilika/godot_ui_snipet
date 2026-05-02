class_name UISnipProgressDialog
extends UISnipBaseDialog

# Progress dialog showing a determinate ProgressBar. Set value via
# `set_progress(0..1)`. Optional cancel button resolves with `false`; auto-close
# on completion resolves with `true`.

signal cancelled

@export var title_text: String = "Loading..."
@export var allow_cancel: bool = true
@export var cancel_label: String = "Cancel"
@export var auto_close_on_complete: bool = true

var _label: Label
var _bar: ProgressBar
var _cancel: UISnipAnimatedButton
var _value: float = 0.0


func _ready() -> void:
	super()
	close_on_esc = false  # progress should not close arbitrarily
	close_on_backdrop = false
	var body := get_content_container()
	if body == null:
		return
	_label = Label.new()
	_label.text = title_text
	body.add_child(_label)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.01
	_bar.value = 0.0
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_bar)
	if allow_cancel:
		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_END
		body.add_child(btn_row)
		_cancel = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
		_cancel.text = cancel_label
		_cancel.pressed.connect(_on_cancel)
		btn_row.add_child(_cancel)


func set_progress(v: float) -> void:
	_value = clampf(v, 0.0, 1.0)
	if _bar != null:
		_bar.value = _value
	if auto_close_on_complete and _value >= 1.0:
		close(true)


func set_title(t: String) -> void:
	title_text = t
	if _label != null:
		_label.text = t


func _on_cancel() -> void:
	cancelled.emit()
	close(false)


static func popup(parent: Node, p_title: String, allow_cancel: bool = true) -> UISnipProgressDialog:
	var dlg: UISnipProgressDialog = preload("res://addons/ui_snippets/dialogs/progress_dialog.tscn").instantiate()
	dlg.title_text = p_title
	dlg.allow_cancel = allow_cancel
	parent.add_child(dlg)
	dlg.open()
	return dlg
