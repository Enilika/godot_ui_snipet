extends Control

@export var bg_static: SpriteFrames
@export var bg_anim: SpriteFrames
@export var border_static: SpriteFrames
@export var border_anim: SpriteFrames

@onready var panel: UISnipAnimatedPanel = %Panel
@onready var size_slider: HSlider = %SizeSlider
@onready var bg_margin_slider: HSlider = %BgMarginSlider
@onready var border_margin_slider: HSlider = %BorderMarginSlider
@onready var size_label: Label = %SizeLabel
@onready var bg_anim_toggle: CheckButton = %BgAnimToggle
@onready var border_anim_toggle: CheckButton = %BorderAnimToggle
@onready var pause_toggle: CheckButton = %PauseToggle


func _ready() -> void:
	size_slider.value_changed.connect(_on_size_changed)
	bg_margin_slider.value_changed.connect(func(v): panel.bg_patch_margin = int(v))
	border_margin_slider.value_changed.connect(func(v): panel.border_patch_margin = int(v))
	bg_anim_toggle.toggled.connect(_on_bg_anim_toggled)
	border_anim_toggle.toggled.connect(_on_border_anim_toggled)
	pause_toggle.toggled.connect(func(p): panel.paused = p)
	_on_size_changed(size_slider.value)
	_on_bg_anim_toggled(bg_anim_toggle.button_pressed)
	_on_border_anim_toggled(border_anim_toggle.button_pressed)


func _on_size_changed(v: float) -> void:
	panel.custom_minimum_size = Vector2(v, v * 0.6)
	panel.size = panel.custom_minimum_size
	size_label.text = "Panel size: %d x %d" % [int(panel.size.x), int(panel.size.y)]


func _on_bg_anim_toggled(use_anim: bool) -> void:
	panel.background_frames = bg_anim if use_anim else bg_static


func _on_border_anim_toggled(use_anim: bool) -> void:
	panel.border_frames = border_anim if use_anim else border_static
