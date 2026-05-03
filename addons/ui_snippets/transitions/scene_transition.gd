extends CanvasLayer

# Autoload-friendly scene transition manager. The corresponding .tscn is
# registered as a singleton named `UISnipSceneTransition` in project.godot.
#
# Usage (after the autoload is registered):
#
#   await UISnipSceneTransition.change_scene_to_file("res://next.tscn",
#       UISnipSceneTransition.Type.FADE, 0.4)
#
#   # In-place demo swap (does not change the active SceneTree scene):
#   await UISnipSceneTransition.swap_subscene(host_control,
#       func(): return packed.instantiate(),
#       UISnipSceneTransition.Type.SLIDE_LEFT)

enum Type {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	IRIS,
	FRAMES,
}

@export var color: Color = Color(0, 0, 0, 1):
	set(v):
		color = v
		_apply_color()
@export var default_duration: float = 0.4
@export var frames: SpriteFrames

var _cover: ColorRect
var _iris: ColorRect
var _frame_panel: UISnipAnimatedPanel
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cover = get_node_or_null("Cover") as ColorRect
	_iris = get_node_or_null("Iris") as ColorRect
	_frame_panel = get_node_or_null("FramePanel") as UISnipAnimatedPanel
	_apply_color()
	_hide_all()


func is_busy() -> bool:
	return _busy


func transition_out(t: int, duration: float = 0.0) -> void:
	if duration <= 0.0:
		duration = default_duration
	match t:
		Type.FADE:
			await _fade(0.0, 1.0, duration)
		Type.SLIDE_LEFT:
			await _slide_cover_out(Vector2.LEFT, duration)
		Type.SLIDE_RIGHT:
			await _slide_cover_out(Vector2.RIGHT, duration)
		Type.SLIDE_UP:
			await _slide_cover_out(Vector2.UP, duration)
		Type.SLIDE_DOWN:
			await _slide_cover_out(Vector2.DOWN, duration)
		Type.IRIS:
			await _iris_animate(true, duration)
		Type.FRAMES:
			await _frames_cover(duration)


func transition_in(t: int, duration: float = 0.0) -> void:
	if duration <= 0.0:
		duration = default_duration
	match t:
		Type.FADE:
			await _fade(1.0, 0.0, duration)
		Type.SLIDE_LEFT:
			await _slide_cover_in(Vector2.LEFT, duration)
		Type.SLIDE_RIGHT:
			await _slide_cover_in(Vector2.RIGHT, duration)
		Type.SLIDE_UP:
			await _slide_cover_in(Vector2.UP, duration)
		Type.SLIDE_DOWN:
			await _slide_cover_in(Vector2.DOWN, duration)
		Type.IRIS:
			await _iris_animate(false, duration)
		Type.FRAMES:
			await _frames_uncover(duration)
	_hide_all()


# Cover the screen, change the SceneTree's current scene to `path`, then reveal.
func change_scene_to_file(path: String, t: int = Type.FADE, duration: float = 0.0) -> Error:
	if _busy:
		return ERR_BUSY
	_busy = true
	await transition_out(t, duration)
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		push_warning("change_scene_to_file failed (%d) for %s" % [err, path])
	await get_tree().process_frame
	await transition_in(t, duration)
	_busy = false
	return err


# As above but with a preloaded PackedScene.
func change_scene_to_packed(packed: PackedScene, t: int = Type.FADE, duration: float = 0.0) -> Error:
	if _busy:
		return ERR_BUSY
	_busy = true
	await transition_out(t, duration)
	var err: Error = get_tree().change_scene_to_packed(packed)
	if err != OK:
		push_warning("change_scene_to_packed failed (%d)" % err)
	await get_tree().process_frame
	await transition_in(t, duration)
	_busy = false
	return err


# Cover, replace `host`'s children with the result of `factory.call()` (or with
# `factory.instantiate()` if a PackedScene is passed instead), then reveal.
# Useful for in-place demos that don't actually change the active scene.
func swap_subscene(host: Node, factory: Variant, t: int = Type.FADE, duration: float = 0.0) -> Node:
	if _busy or host == null:
		return null
	_busy = true
	await transition_out(t, duration)
	for child in host.get_children():
		child.queue_free()
	var node: Node
	if factory is PackedScene:
		node = (factory as PackedScene).instantiate()
	elif factory is Callable:
		node = (factory as Callable).call()
	else:
		push_warning("swap_subscene: factory must be PackedScene or Callable")
		_hide_all()
		_busy = false
		return null
	host.add_child(node)
	if node is Control:
		(node as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await transition_in(t, duration)
	_busy = false
	return node


func _fade(from_a: float, to_a: float, duration: float) -> void:
	if _cover == null:
		return
	_cover.color = color
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.modulate.a = from_a
	_cover.visible = true
	var tw := create_tween()
	tw.tween_property(_cover, "modulate:a", to_a, duration)
	await tw.finished


func _slide_cover_out(direction: Vector2, duration: float) -> void:
	if _cover == null:
		return
	var size := _viewport_size()
	_cover.color = color
	_cover.size = size
	_cover.modulate.a = 1.0
	_cover.position = -direction * size
	_cover.visible = true
	var tw := create_tween()
	tw.tween_property(_cover, "position", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func _slide_cover_in(direction: Vector2, duration: float) -> void:
	if _cover == null:
		return
	var size := _viewport_size()
	_cover.color = color
	_cover.size = size
	_cover.modulate.a = 1.0
	_cover.position = Vector2.ZERO
	_cover.visible = true
	var tw := create_tween()
	tw.tween_property(_cover, "position", direction * size, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished


func _iris_animate(closing: bool, duration: float) -> void:
	if _iris == null:
		return
	_iris.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_iris.visible = true
	var mat := _iris.material as ShaderMaterial
	if mat == null:
		return
	var start_radius := 1.5 if closing else 0.0
	var end_radius := 0.0 if closing else 1.5
	mat.set_shader_parameter("radius", start_radius)
	mat.set_shader_parameter("fill_color", color)
	var tw := create_tween()
	tw.tween_method(func(r: float): mat.set_shader_parameter("radius", r), start_radius, end_radius, duration)
	await tw.finished


func _frames_cover(duration: float) -> void:
	if _frame_panel == null:
		await _fade(0.0, 1.0, duration)
		return
	if frames != null:
		_frame_panel.background_frames = frames
	_frame_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame_panel.modulate.a = 0.0
	_frame_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_frame_panel, "modulate:a", 1.0, duration)
	await tw.finished


func _frames_uncover(duration: float) -> void:
	if _frame_panel == null:
		await _fade(1.0, 0.0, duration)
		return
	var tw := create_tween()
	tw.tween_property(_frame_panel, "modulate:a", 0.0, duration)
	await tw.finished
	_frame_panel.visible = false


func _hide_all() -> void:
	if _cover != null:
		_cover.visible = false
	if _iris != null:
		_iris.visible = false
	if _frame_panel != null:
		_frame_panel.visible = false


func _apply_color() -> void:
	if _cover != null:
		_cover.color = color
	if _iris != null and _iris.material is ShaderMaterial:
		(_iris.material as ShaderMaterial).set_shader_parameter("fill_color", color)


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size
