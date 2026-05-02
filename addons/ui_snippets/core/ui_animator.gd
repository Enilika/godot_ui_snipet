class_name UISnipAnimator
extends RefCounted

# Static helpers that build Tweens for common UI animations.
# All return the Tween so callers can `await tween.finished`.

const SLIDE_DEFAULT_DISTANCE := 32.0


static func fade_in(node: CanvasItem, duration: float = 0.2) -> Tween:
	node.modulate.a = 0.0
	node.visible = true
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, duration)
	return tw


static func fade_out(node: CanvasItem, duration: float = 0.2) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration)
	return tw


static func slide_in(node: Control, from_dir: Vector2, distance: float = SLIDE_DEFAULT_DISTANCE, duration: float = 0.25) -> Tween:
	var target_pos := node.position
	node.position = target_pos + from_dir.normalized() * distance
	node.modulate.a = 0.0
	node.visible = true
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration)
	return tw


static func slide_out(node: Control, to_dir: Vector2, distance: float = SLIDE_DEFAULT_DISTANCE, duration: float = 0.25) -> Tween:
	var target_pos := node.position + to_dir.normalized() * distance
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	return tw


static func pop_in(node: Control, overshoot: float = 1.1, duration: float = 0.25) -> Tween:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ZERO
	node.modulate.a = 0.0
	node.visible = true
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE * overshoot, duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(node, "scale", Vector2.ONE, duration * 0.3)
	tw.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
	return tw


static func pop_out(node: Control, duration: float = 0.2) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	return tw


static func shake(node: CanvasItem, amplitude: float = 4.0, duration: float = 0.25) -> Tween:
	var base: Vector2 = Vector2.ZERO
	if node is Control:
		base = (node as Control).position
	elif node is Node2D:
		base = (node as Node2D).position
	var prop := "position"
	var tw := node.create_tween()
	var steps := 6
	for i in steps:
		var off := Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
		tw.tween_property(node, prop, base + off, duration / float(steps))
	tw.tween_property(node, prop, base, duration / float(steps))
	return tw


# Reveal text on a Label or RichTextLabel via visible_ratio.
static func typewriter(label: CanvasItem, text: String, cps: float = 40.0) -> Tween:
	if label is Label:
		(label as Label).text = text
		(label as Label).visible_ratio = 0.0
	elif label is RichTextLabel:
		(label as RichTextLabel).text = text
		(label as RichTextLabel).visible_ratio = 0.0
	else:
		push_warning("UISnipAnimator.typewriter: unsupported node type %s" % label.get_class())
		return null
	var duration: float = max(text.length() / max(cps, 0.0001), 0.0)
	var tw := label.create_tween()
	tw.tween_property(label, "visible_ratio", 1.0, duration)
	return tw
