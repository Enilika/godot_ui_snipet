class_name UISnipInputDialog
extends UISnipBaseDialog

# Single-line text input dialog. Resolves with the entered String, or null on
# cancel/ESC.

@export var prompt: String = "Enter a value:"
@export var placeholder: String = ""
@export var default_text: String = ""
@export var ok_label: String = "OK"
@export var cancel_label: String = "Cancel"

var _label: Label
var _line: LineEdit
var _ok: UISnipAnimatedButton
var _cancel: UISnipAnimatedButton


func _ready() -> void:
	super()
	var body := get_content_container()
	if body == null:
		return
	_label = Label.new()
	_label.text = prompt
	body.add_child(_label)
	_line = LineEdit.new()
	_line.placeholder_text = placeholder
	_line.text = default_text
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.text_submitted.connect(func(t): close(t))
	body.add_child(_line)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 12)
	body.add_child(btn_row)
	_cancel = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
	_cancel.text = cancel_label
	_cancel.pressed.connect(func(): close(null))
	btn_row.add_child(_cancel)
	_ok = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
	_ok.text = ok_label
	_ok.pressed.connect(func(): close(_line.text))
	btn_row.add_child(_ok)


func open() -> void:
	super()
	if _label != null:
		_label.text = prompt
	if _line != null:
		_line.text = default_text
		_line.placeholder_text = placeholder
		_line.grab_focus.call_deferred()


static func popup(parent: Node, p_prompt: String, p_default: String = "") -> Variant:
	var dlg: UISnipInputDialog = preload("res://addons/ui_snippets/dialogs/input_dialog.tscn").instantiate()
	dlg.prompt = p_prompt
	dlg.default_text = p_default
	parent.add_child(dlg)
	dlg.open()
	return await dlg.closed
