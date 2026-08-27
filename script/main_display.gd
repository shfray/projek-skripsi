extends Control 

# Exported PackedScenes so you can assign them in the Godot Inspector
@export var menu_utama: PackedScene
@export var menu_karyawan: PackedScene
@export var menu_kriteria: PackedScene
@export var menu_hitung_saw: PackedScene
@export var menu_laporan: PackedScene
@export var menu_pengaturan: PackedScene

## Replaces current display content with a new instantiated PackedScene
func change_display(new_scene: PackedScene) -> void:
	if new_scene == null:
		push_error("mak kau scene nya hilang")
		return
	# Clear previous active display scenes
	for child in get_children():
		child.queue_free()
	# Instantiate and add the new scene
	var instance = new_scene.instantiate()
	add_child(instance)
