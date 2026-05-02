class_name UISnipChoiceDialog
extends UISnipBaseDialog

# N-choice dialog. Resolves with the index of the chosen option, or -1 on
# cancel/ESC.

@export_multiline var text: String = "Pick one:"
@export var choices: PackedStringArray = PackedStringArray(["Option A", "Option B", "Option C"])

var _label: Label
var _buttons: Array[UISnipAnimatedButton] = []


func _ready() -> void:
	super()
	var body := get_content_container()
	if body == null:
		return
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_label)
	var btn_col := VBoxContainer.new()
	btn_col.add_theme_constant_override("separation", 8)
	btn_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(btn_col)
	_label.text = text
	for i in choices.size():
		var btn: UISnipAnimatedButton = preload("res://addons/ui_snippets/buttons/animated_button.tscn").instantiate()
		btn.text = choices[i]
		btn.pressed.connect(func(): close(i))
		btn_col.add_child(btn)
		_buttons.append(btn)


func open() -> void:
	super()
	if _label != null:
		_label.text = text
	if _buttons.size() > 0:
		_buttons[0].grab_focus.call_deferred()


static func popup(parent: Node, prompt: String, options: PackedStringArray) -> int:
	var dlg: UISnipChoiceDialog = preload("res://addons/ui_snippets/dialogs/choice_dialog.tscn").instantiate()
	dlg.text = prompt
	dlg.choices = options
	parent.add_child(dlg)
	dlg.open()
	var result: Variant = await dlg.closed
	return int(result) if result != null else -1
