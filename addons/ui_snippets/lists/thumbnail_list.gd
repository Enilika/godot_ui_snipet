@tool
class_name UISnipThumbnailList
extends Control

# A paginated list that shows N items at a time as thumbnail tiles, with a
# sliding page transition and a cursor that follows the focused slot. Built
# from existing snippets (UISnipAnimatedPanel for the frame, UISnipAnimatedButton
# for each slot and the prev/next buttons).
#
# Items are UISnipThumbnailItem resources. Empty trailing slots on the last
# page are disabled and dimmed.

signal selection_changed(index: int, item: UISnipThumbnailItem)
signal item_activated(index: int, item: UISnipThumbnailItem)
signal page_changed(page: int, total_pages: int)

@export var items: Array[UISnipThumbnailItem] = []:
	set(v):
		items = v
		_refresh_page_layout()
@export_range(1, 8) var per_page: int = 3:
	set(v):
		per_page = max(1, v)
		if is_inside_tree():
			_rebuild_slots()
			_refresh_page_layout()

@export var item_min_size: Vector2 = Vector2(120, 140):
	set(v):
		item_min_size = v
		for b in _slot_buttons:
			b.custom_minimum_size = v

@export_group("Theme")
@export var background_frames: SpriteFrames:
	set(v):
		background_frames = v
		if _frame != null:
			_frame.background_frames = v
@export var border_frames: SpriteFrames:
	set(v):
		border_frames = v
		if _frame != null:
			_frame.border_frames = v
@export var item_idle_frames: SpriteFrames
@export var item_hover_frames: SpriteFrames
@export var item_focus_frames: SpriteFrames
@export var item_press_frames: SpriteFrames
@export var cursor_frames: SpriteFrames:
	set(v):
		cursor_frames = v
		if is_inside_tree():
			_setup_cursor()
@export var cursor_text: String = "▶":
	set(v):
		cursor_text = v
		if is_inside_tree() and cursor_frames == null:
			_setup_cursor()

@export_group("Animation")
@export_range(0.05, 1.0, 0.01) var page_slide_duration: float = 0.28
@export_range(0.0, 1.0, 0.01) var cursor_follow_duration: float = 0.18
@export var cursor_offset: Vector2 = Vector2(-30, 0)

const _ANIMATED_BUTTON_SCENE := preload("res://addons/ui_snippets/buttons/animated_button.tscn")
const _ANIMATED_PANEL_SCENE := preload("res://addons/ui_snippets/core/animated_panel.tscn")

var _page: int = 0
var _focused_index: int = -1
var _slot_buttons: Array[UISnipAnimatedButton] = []
var _busy: bool = false

var _frame: UISnipAnimatedPanel
var _viewport: Control
var _slots: HBoxContainer
var _prev_btn: UISnipAnimatedButton
var _next_btn: UISnipAnimatedButton
var _page_indicator: Label
var _cursor: Control


func _ready() -> void:
	_frame = get_node_or_null("Frame") as UISnipAnimatedPanel
	_viewport = get_node_or_null("Frame/Margin/Row/Viewport") as Control
	_slots = get_node_or_null("Frame/Margin/Row/Viewport/Slots") as HBoxContainer
	_prev_btn = get_node_or_null("Frame/Margin/Row/PrevBtn") as UISnipAnimatedButton
	_next_btn = get_node_or_null("Frame/Margin/Row/NextBtn") as UISnipAnimatedButton
	_page_indicator = get_node_or_null("PageIndicator") as Label
	_cursor = get_node_or_null("Cursor") as Control

	if _frame != null:
		if background_frames != null:
			_frame.background_frames = background_frames
		if border_frames != null:
			_frame.border_frames = border_frames
	if not Engine.is_editor_hint():
		if _prev_btn != null and not _prev_btn.pressed.is_connected(prev_page):
			_prev_btn.pressed.connect(prev_page)
		if _next_btn != null and not _next_btn.pressed.is_connected(next_page):
			_next_btn.pressed.connect(next_page)

	_rebuild_slots()
	_refresh_page_layout()
	_setup_cursor()


func total_pages() -> int:
	if items.is_empty():
		return 1
	return int(ceil(float(items.size()) / float(per_page)))


func current_page() -> int:
	return _page


func get_focused() -> UISnipThumbnailItem:
	if _focused_index < 0 or _focused_index >= items.size():
		return null
	return items[_focused_index]


func go_to_page(p: int, animated: bool = true) -> void:
	if _busy:
		return
	var target: int = clampi(p, 0, max(0, total_pages() - 1))
	if target == _page:
		return
	_busy = true
	var dir: int = 1 if target > _page else -1
	if animated and _slots != null and _viewport != null:
		var w: float = _viewport.size.x
		var tw1 := create_tween()
		tw1.tween_property(_slots, "position:x", -dir * w, page_slide_duration / 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await tw1.finished
		_page = target
		_populate_slots_for_page()
		_slots.position.x = dir * w
		var tw2 := create_tween()
		tw2.tween_property(_slots, "position:x", 0.0, page_slide_duration / 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw2.finished
	else:
		_page = target
		_populate_slots_for_page()
		if _slots != null:
			_slots.position.x = 0.0
	_update_page_indicator()
	_update_page_buttons()
	page_changed.emit(_page, total_pages())
	_focus_first_visible()
	_busy = false


func next_page() -> void:
	go_to_page(_page + 1)


func prev_page() -> void:
	go_to_page(_page - 1)


func focus_index(i: int) -> void:
	if i < 0 or i >= items.size():
		return
	var page_for_i: int = i / per_page
	if page_for_i != _page:
		go_to_page(page_for_i, false)
	var slot_idx: int = i % per_page
	if slot_idx < _slot_buttons.size():
		_slot_buttons[slot_idx].grab_focus.call_deferred()


func _refresh_page_layout() -> void:
	if not is_inside_tree() or _slots == null:
		return
	_page = clampi(_page, 0, max(0, total_pages() - 1))
	_populate_slots_for_page()
	_update_page_indicator()
	_update_page_buttons()


func _rebuild_slots() -> void:
	if _slots == null:
		return
	for c in _slots.get_children():
		c.queue_free()
	_slot_buttons.clear()

	for i in per_page:
		var btn: UISnipAnimatedButton = _ANIMATED_BUTTON_SCENE.instantiate()
		btn.custom_minimum_size = item_min_size
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.text = ""
		btn.clip_contents = true
		if item_idle_frames != null:
			btn.frames_idle = item_idle_frames
		if item_hover_frames != null:
			btn.frames_hover = item_hover_frames
		if item_focus_frames != null:
			btn.frames_focus = item_focus_frames
		if item_press_frames != null:
			btn.frames_press = item_press_frames

		var layout := VBoxContainer.new()
		layout.name = "Layout"
		layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_theme_constant_override("separation", 6)
		# Add inner margin so the panel art is not occluded by the thumbnail/label.
		var margin := MarginContainer.new()
		margin.name = "Margin"
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		btn.add_child(margin)
		margin.add_child(layout)

		var thumb := TextureRect.new()
		thumb.name = "Thumb"
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(thumb)

		var label := Label.new()
		label.name = "ItemLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(label)

		var slot_idx := i
		if not Engine.is_editor_hint():
			btn.focus_entered.connect(func(): _on_slot_focused(slot_idx))
			btn.pressed.connect(func(): _on_slot_pressed(slot_idx))

		_slots.add_child(btn)
		_slot_buttons.append(btn)


func _populate_slots_for_page() -> void:
	if _slot_buttons.is_empty():
		return
	for i in per_page:
		var global_idx: int = _page * per_page + i
		var btn: UISnipAnimatedButton = _slot_buttons[i]
		var thumb := btn.get_node_or_null("Margin/Layout/Thumb") as TextureRect
		var label := btn.get_node_or_null("Margin/Layout/ItemLabel") as Label
		if global_idx < items.size():
			var item: UISnipThumbnailItem = items[global_idx]
			if thumb != null:
				thumb.texture = item.thumbnail
			if label != null:
				label.text = item.label
			btn.disabled = false
			btn.modulate.a = 1.0
			btn.focus_mode = Control.FOCUS_ALL
		else:
			if thumb != null:
				thumb.texture = null
			if label != null:
				label.text = ""
			btn.disabled = true
			btn.modulate.a = 0.4
			btn.focus_mode = Control.FOCUS_NONE


func _focus_first_visible() -> void:
	for i in _slot_buttons.size():
		var idx: int = _page * per_page + i
		if idx < items.size():
			_slot_buttons[i].grab_focus.call_deferred()
			return


func _on_slot_focused(slot_idx: int) -> void:
	if slot_idx >= _slot_buttons.size():
		return
	var global_idx: int = _page * per_page + slot_idx
	if global_idx >= items.size():
		return
	_focused_index = global_idx
	_move_cursor_to(_slot_buttons[slot_idx])
	selection_changed.emit(global_idx, items[global_idx])


func _on_slot_pressed(slot_idx: int) -> void:
	var global_idx: int = _page * per_page + slot_idx
	if global_idx >= items.size():
		return
	item_activated.emit(global_idx, items[global_idx])


func _setup_cursor() -> void:
	if _cursor == null:
		return
	for c in _cursor.get_children():
		c.queue_free()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cursor_frames != null:
		var panel: UISnipAnimatedPanel = _ANIMATED_PANEL_SCENE.instantiate()
		panel.background_frames = cursor_frames
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cursor.add_child(panel)
		_cursor.custom_minimum_size = Vector2(32, 32)
		_cursor.size = Vector2(32, 32)
	else:
		var lbl := Label.new()
		lbl.text = cursor_text
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.modulate = Color(1, 0.85, 0.4, 1)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cursor.add_child(lbl)
		_cursor.custom_minimum_size = Vector2(24, 24)
		_cursor.size = Vector2(24, 24)
	_cursor.visible = false


func _move_cursor_to(target: Control) -> void:
	if _cursor == null or target == null:
		return
	_cursor.visible = true
	var local: Vector2 = target.global_position - global_position
	var dest: Vector2 = local + cursor_offset
	dest.y += (target.size.y - _cursor.size.y) * 0.5
	var tw := create_tween()
	tw.tween_property(_cursor, "position", dest, cursor_follow_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_page_indicator() -> void:
	if _page_indicator == null:
		return
	_page_indicator.text = "%d / %d" % [_page + 1, total_pages()]


func _update_page_buttons() -> void:
	var t: int = total_pages()
	if _prev_btn != null:
		_prev_btn.disabled = _page <= 0
	if _next_btn != null:
		_next_btn.disabled = _page >= t - 1


func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree() or not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if get_global_rect().has_point(mb.global_position):
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
					prev_page()
				else:
					next_page()
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("ui_page_down"):
		next_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_page_up"):
		prev_page()
		get_viewport().set_input_as_handled()
