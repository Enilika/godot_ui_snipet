extends Control

@onready var status: Label = %Status


func _ready() -> void:
	%MessageBtn.pressed.connect(_on_message)
	%ConfirmBtn.pressed.connect(_on_confirm)
	%ChoiceBtn.pressed.connect(_on_choice)
	%InputBtn.pressed.connect(_on_input)
	%ProgressBtn.pressed.connect(_on_progress)
	%ToastBtn.pressed.connect(_on_toast)


func _on_message() -> void:
	await UISnipMessageDialog.popup(self, "[b]Hello![/b] This dialog reveals its body via [color=yellow]typewriter[/color] effect, then closes when you press OK or hit ESC.")
	_set_status("Message dialog closed")


func _on_confirm() -> void:
	var ok: bool = await UISnipConfirmDialog.popup(self, "Delete the file?  This cannot be undone.")
	_set_status("Confirm: %s" % ("Yes" if ok else "No"))


func _on_choice() -> void:
	var idx: int = await UISnipChoiceDialog.popup(self, "Pick a difficulty:", PackedStringArray(["Easy", "Normal", "Hard", "Nightmare"]))
	_set_status("Choice index: %d" % idx)


func _on_input() -> void:
	var text: Variant = await UISnipInputDialog.popup(self, "What is your name?", "Player")
	_set_status("Input: %s" % str(text))


func _on_progress() -> void:
	var dlg := UISnipProgressDialog.popup(self, "Loading data...", true)
	var was_cancelled := [false]
	dlg.cancelled.connect(func(): was_cancelled[0] = true)
	var t := 0.0
	while t < 1.0:
		await get_tree().create_timer(0.05).timeout
		if was_cancelled[0] or not is_instance_valid(dlg):
			_set_status("Progress cancelled")
			return
		t += 0.04
		dlg.set_progress(t)
	_set_status("Progress complete")


func _on_toast() -> void:
	UISnipToast.show_toast(self, "Saved!", 1.5, UISnipToast.ToastPosition.BOTTOM_CENTER)
	_set_status("Toast shown")


func _set_status(s: String) -> void:
	status.text = s
	status.modulate.a = 1.0
	UISnipAnimator.fade_out(status, 2.0)
