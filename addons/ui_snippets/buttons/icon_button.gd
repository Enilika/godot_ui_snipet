@tool
class_name UISnipIconButton
extends UISnipAnimatedButton

# Animated button with an icon shown to the left of the label.

@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		_apply_icon()
@export_range(8, 128) var icon_size: int = 24:
	set(v):
		icon_size = v
		_apply_icon()

var _icon_rect: TextureRect


func _ready() -> void:
	super()
	icon = null  # We render via TextureRect to control sizing precisely.
	_ensure_icon_rect()
	_apply_icon()


func _ensure_icon_rect() -> void:
	_icon_rect = get_node_or_null("IconRect") as TextureRect
	if _icon_rect != null:
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconRect"
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon_rect)
	if Engine.is_editor_hint():
		_icon_rect.owner = get_tree().edited_scene_root


func _apply_icon() -> void:
	if _icon_rect == null:
		return
	_icon_rect.texture = icon_texture
	_icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	_icon_rect.size = Vector2(icon_size, icon_size)
	_icon_rect.position = Vector2(12, (size.y - icon_size) * 0.5)


func _process(delta: float) -> void:
	super(delta)
	if _icon_rect != null:
		_icon_rect.position = Vector2(12, (size.y - icon_size) * 0.5)
