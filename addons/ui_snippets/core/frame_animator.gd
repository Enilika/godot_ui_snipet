class_name UISnipFrameAnimator
extends RefCounted

# Drives a list of Texture2D frames at a given fps. Stateless across ticks
# except for the elapsed accumulator and the current frame index.
#
# Usage:
#   var fa := UISnipFrameAnimator.new()
#   fa.set_frames(textures, 8.0)
#   ...in _process(delta):
#     if fa.tick(delta): nine_patch_rect.texture = fa.current_texture()

var _frames: Array[Texture2D] = []
var _fps: float = 8.0
var _elapsed: float = 0.0
var _index: int = 0
var paused: bool = false


func set_frames(frames: Array[Texture2D], fps: float = 8.0) -> void:
	_frames = frames
	_fps = max(fps, 0.0001)
	_index = 0
	_elapsed = 0.0


func set_fps(fps: float) -> void:
	_fps = max(fps, 0.0001)


func frame_count() -> int:
	return _frames.size()


func current_texture() -> Texture2D:
	if _frames.is_empty():
		return null
	return _frames[_index]


func set_index(i: int) -> void:
	if _frames.is_empty():
		_index = 0
		return
	_index = clampi(i, 0, _frames.size() - 1)
	_elapsed = 0.0


# Returns true if the texture changed this tick.
func tick(delta: float) -> bool:
	if paused or _frames.size() <= 1:
		return false
	_elapsed += delta
	var step := 1.0 / _fps
	if _elapsed < step:
		return false
	# Advance one or more frames if delta was large.
	var advance := int(_elapsed / step)
	_elapsed -= step * advance
	_index = (_index + advance) % _frames.size()
	return true


# Convenience: extract Texture2D[] from a SpriteFrames animation.
static func extract_from_sprite_frames(sf: SpriteFrames, anim: StringName) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if sf == null:
		return out
	if not sf.has_animation(anim):
		return out
	var n := sf.get_frame_count(anim)
	for i in n:
		var tex := sf.get_frame_texture(anim, i)
		if tex != null:
			out.append(tex)
	return out


# Convenience: read the animation speed (fps) from a SpriteFrames animation.
static func speed_from_sprite_frames(sf: SpriteFrames, anim: StringName, fallback: float = 8.0) -> float:
	if sf == null or not sf.has_animation(anim):
		return fallback
	return sf.get_animation_speed(anim)
