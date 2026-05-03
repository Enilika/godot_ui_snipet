class_name UISnipThumbnailItem
extends Resource

# A single entry in a UISnipThumbnailList. `data` is free-form metadata that
# the consumer can stash on each item (an id, a struct dictionary, etc.) and
# pull back out via the list's signals.

@export var label: String = ""
@export var thumbnail: Texture2D
@export var data: Variant = null
