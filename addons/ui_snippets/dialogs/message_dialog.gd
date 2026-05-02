class_name UISnipMessageDialog
extends UISnipBaseDialog

# A simple typewriter-effect message dialog with one OK button. Set `text` and
# call `open()`. Resolves with `null` on close.

@export_multiline var text: String = ""
@export_range(1.0, 200.0) var typewriter_cps: float = 40.0
@export var ok_label: String = "OK"

var _label: RichTextLabel
var _ok_button: UISnipAnimatedButton


func _ready() -> void:
	super()
	var body := get_content_container()
	if body == null:
		push_warning("UISnipMessageDialog: missing content body")
		return
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_label)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(btn_row)
	_ok_button = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
	_ok_button.text = ok_label
	_ok_button.pressed.connect(func(): close(null))
	btn_row.add_child(_ok_button)


func open() -> void:
	super()
	if _label != null:
		UISnipAnimator.typewriter(_label, text, typewriter_cps)
	if _ok_button != null:
		_ok_button.grab_focus.call_deferred()


# Convenience factory: create, attach to tree, open, await closed.
static func popup(parent: Node, body: String) -> Variant:
	var dlg: UISnipMessageDialog = preload("res://addons/ui_snippets/dialogs/message_dialog.tscn").instantiate()
	dlg.text = body
	parent.add_child(dlg)
	dlg.open()
	return await dlg.closed
