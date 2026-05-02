extends Control

@onready var disable_toggle: CheckButton = %DisableToggle
@onready var animated_btn: UISnipAnimatedButton = %AnimatedBtn
@onready var icon_btn: UISnipIconButton = %IconBtn
@onready var toggle_btn: UISnipToggleButton = %ToggleBtn
@onready var status: Label = %Status
@onready var menu: UISnipMenuButton = %Menu


func _ready() -> void:
	disable_toggle.toggled.connect(_on_disable_toggled)
	animated_btn.pressed.connect(func(): _flash("AnimatedButton pressed"))
	icon_btn.pressed.connect(func(): _flash("IconButton pressed"))
	toggle_btn.toggled.connect(func(p): _flash("ToggleButton: %s" % ("ON" if p else "OFF")))
	menu.selected.connect(func(i, b): _flash("Menu selected #%d (%s)" % [i, b.text]))
	menu.labels = PackedStringArray(["Start", "Continue", "Options", "Quit"])


func _on_disable_toggled(d: bool) -> void:
	animated_btn.disabled = d
	icon_btn.disabled = d
	toggle_btn.disabled = d


func _flash(msg: String) -> void:
	status.text = msg
	status.modulate.a = 1.0
	UISnipAnimator.fade_out(status, 1.5)
