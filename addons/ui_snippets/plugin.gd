@tool
extends EditorPlugin

# All snippets register their types via class_name, so this plugin script does
# not need to add custom types. It only exists so the addon can be enabled in
# project settings, which lets editor tools (the @tool scripts) be reloaded
# correctly when the addon is updated.


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
