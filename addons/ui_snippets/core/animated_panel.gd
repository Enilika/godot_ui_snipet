@tool
class_name UISnipAnimatedPanel
extends Control

# A two-layer Control that renders a background and a border via NinePatchRect,
# each driven by its own SpriteFrames. Works for 1-frame (static) and N-frame
# (animated) inputs uniformly. Layout, anchors and stretching follow regular
# Control conventions because both layers are NinePatchRect.

@export var background_frames: SpriteFrames:
	set(v):
		background_frames = v
		_rebuild_background()
@export var background_animation: StringName = &"default":
	set(v):
		background_animation = v
		_rebuild_background()

@export var border_frames: SpriteFrames:
	set(v):
		border_frames = v
		_rebuild_border()
@export var border_animation: StringName = &"default":
	set(v):
		border_animation = v
		_rebuild_border()

@export_range(0.1, 60.0, 0.1) var fps_override: float = 0.0:
	set(v):
		fps_override = v
		_apply_fps()

@export_group("9-slice margins")
@export_range(0, 256) var bg_patch_margin: int = 16:
	set(v):
		bg_patch_margin = v
		_apply_margins()
@export_range(0, 256) var border_patch_margin: int = 16:
	set(v):
		border_patch_margin = v
		_apply_margins()

@export_group("Playback")
@export var paused: bool = false:
	set(v):
		paused = v
		_bg_anim.paused = v
		_border_anim.paused = v

var _bg_anim := UISnipFrameAnimator.new()
var _border_anim := UISnipFrameAnimator.new()
var _bg_layer: NinePatchRect
var _border_layer: NinePatchRect


func _ready() -> void:
	_ensure_layers()
	_rebuild_background()
	_rebuild_border()
	_apply_margins()
	_apply_fps()
	set_process(true)


func _process(delta: float) -> void:
	if _bg_anim.tick(delta) and _bg_layer != null:
		_bg_layer.texture = _bg_anim.current_texture()
	if _border_anim.tick(delta) and _border_layer != null:
		_border_layer.texture = _border_anim.current_texture()


func play() -> void:
	paused = false


func stop() -> void:
	paused = true


func set_frame(i: int) -> void:
	_bg_anim.set_index(i)
	_border_anim.set_index(i)
	if _bg_layer != null:
		_bg_layer.texture = _bg_anim.current_texture()
	if _border_layer != null:
		_border_layer.texture = _border_anim.current_texture()


func _ensure_layers() -> void:
	# Look for existing children first (when the panel is built from a .tscn).
	_bg_layer = get_node_or_null("BackgroundLayer") as NinePatchRect
	_border_layer = get_node_or_null("BorderLayer") as NinePatchRect
	if _bg_layer == null:
		_bg_layer = NinePatchRect.new()
		_bg_layer.name = "BackgroundLayer"
		_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_bg_layer)
		if Engine.is_editor_hint():
			_bg_layer.owner = get_tree().edited_scene_root
	if _border_layer == null:
		_border_layer = NinePatchRect.new()
		_border_layer.name = "BorderLayer"
		_border_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_border_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_border_layer)
		if Engine.is_editor_hint():
			_border_layer.owner = get_tree().edited_scene_root


func _rebuild_background() -> void:
	if _bg_layer == null:
		return
	var frames := UISnipFrameAnimator.extract_from_sprite_frames(background_frames, background_animation)
	_bg_anim.set_frames(frames, _resolve_fps(background_frames, background_animation))
	_bg_layer.texture = _bg_anim.current_texture()


func _rebuild_border() -> void:
	if _border_layer == null:
		return
	var frames := UISnipFrameAnimator.extract_from_sprite_frames(border_frames, border_animation)
	_border_anim.set_frames(frames, _resolve_fps(border_frames, border_animation))
	_border_layer.texture = _border_anim.current_texture()


func _apply_margins() -> void:
	if _bg_layer != null:
		_bg_layer.patch_margin_left = bg_patch_margin
		_bg_layer.patch_margin_top = bg_patch_margin
		_bg_layer.patch_margin_right = bg_patch_margin
		_bg_layer.patch_margin_bottom = bg_patch_margin
	if _border_layer != null:
		_border_layer.patch_margin_left = border_patch_margin
		_border_layer.patch_margin_top = border_patch_margin
		_border_layer.patch_margin_right = border_patch_margin
		_border_layer.patch_margin_bottom = border_patch_margin


func _apply_fps() -> void:
	if fps_override > 0.0:
		_bg_anim.set_fps(fps_override)
		_border_anim.set_fps(fps_override)


func _resolve_fps(sf: SpriteFrames, anim: StringName) -> float:
	if fps_override > 0.0:
		return fps_override
	return UISnipFrameAnimator.speed_from_sprite_frames(sf, anim, 8.0)
