class_name UISnipConfirmDialog
extends UISnipBaseDialog

# Yes/No dialog. Resolves with bool.

@export_multiline var text: String = "Are you sure?"
@export var yes_label: String = "Yes"
@export var no_label: String = "No"

var _label: Label
var _yes: UISnipAnimatedButton
var _no: UISnipAnimatedButton


func _ready() -> void:
	super()
	var body := get_content_container()
	if body == null:
		return
	_label = Label.new()
	_label.text = text
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_label)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 12)
	body.add_child(btn_row)
	_no = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
	_no.text = no_label
	_no.pressed.connect(func(): close(false))
	btn_row.add_child(_no)
	_yes = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
	_yes.text = yes_label
	_yes.pressed.connect(func(): close(true))
	btn_row.add_child(_yes)


func open() -> void:
	super()
	if _label != null:
		_label.text = text
	if _yes != null:
		_yes.grab_focus.call_deferred()


static func popup(parent: Node, prompt: String) -> bool:
	var dlg: UISnipConfirmDialog = preload("res://addons/ui_snippets/dialogs/confirm_dialog.tscn").instantiate()
	dlg.text = prompt
	parent.add_child(dlg)
	dlg.open()
	var result: Variant = await dlg.closed
	return bool(result) if result != null else false
