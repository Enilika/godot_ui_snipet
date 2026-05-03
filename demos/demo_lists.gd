extends Control

@onready var list: UISnipThumbnailList = %List
@onready var status: Label = %Status
@onready var per_page_slider: HSlider = %PerPageSlider
@onready var per_page_label: Label = %PerPageLabel


func _ready() -> void:
	var thumb := load("res://icon.svg") as Texture2D
	var sample: Array[UISnipThumbnailItem] = []
	for i in 8:
		var item := UISnipThumbnailItem.new()
		item.label = "Item %s" % char(0x41 + i)  # A, B, C, ..., H
		item.thumbnail = thumb
		item.data = i
		sample.append(item)
	list.items = sample

	list.selection_changed.connect(_on_selection_changed)
	list.item_activated.connect(_on_item_activated)
	list.page_changed.connect(_on_page_changed)
	per_page_slider.value_changed.connect(_on_per_page_changed)
	per_page_label.text = "Per page: %d" % int(per_page_slider.value)


func _on_selection_changed(idx: int, item: UISnipThumbnailItem) -> void:
	status.text = "Selected: %s  (#%d)" % [item.label, idx]


func _on_item_activated(idx: int, item: UISnipThumbnailItem) -> void:
	status.text = "Activated: %s  (#%d)" % [item.label, idx]
	UISnipAnimator.shake(list, 4.0, 0.2)


func _on_page_changed(page: int, total: int) -> void:
	# Status not overwritten here so selection text persists.
	pass


func _on_per_page_changed(v: float) -> void:
	var n := int(v)
	per_page_label.text = "Per page: %d" % n
	list.per_page = n
