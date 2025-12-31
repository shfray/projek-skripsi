extends Control

# ------------------------
# Node references
# ------------------------

@onready var save_button: Button = $SaveButton
@onready var capture_viewport: SubViewport = $Capture/SubViewport

# ------------------------
# Constants
# ------------------------

const PYTHON_SCRIPT := "res://python/common/png_to_PDF.py"

# ------------------------
# Lifecycle
# ------------------------

func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)

# ------------------------
# Button callback
# ------------------------

func _on_save_pressed() -> void:
	# Ensure SubViewport has rendered
	await get_tree().process_frame
	await get_tree().process_frame

	var png_path := ProjectSettings.globalize_path("user://scene.png")
	var pdf_path := ProjectSettings.globalize_path("user://scene.pdf")

	save_scene_png(png_path)
	run_python_converter(png_path, pdf_path)

# ------------------------
# Capture SubViewport → PNG
# ------------------------

func save_scene_png(png_path: String) -> void:
	var texture: Texture2D = capture_viewport.get_texture()
	var image: Image = texture.get_image()
	image.save_png(png_path)

# ------------------------
# Python execution
# ------------------------

func run_python_converter(png_path: String, pdf_path: String) -> void:
	var python_path := get_python_path()
	if python_path.is_empty():
		push_error("Python interpreter not found for this OS.")
		return

	var script_path := ProjectSettings.globalize_path(PYTHON_SCRIPT)
	var args := [script_path, png_path, pdf_path]

	var output: Array[String] = []
	var exit_code := OS.execute(python_path, args, output, true)

	if exit_code != 0:
		push_error("Python failed:\n" + "\n".join(output))
	else:
		print("PDF created successfully:", pdf_path)

# ------------------------
# OS-aware Python path
# ------------------------

func get_python_path() -> String:
	match OS.get_name():
		"Linux":
			return ProjectSettings.globalize_path(
				"res://python/linux/venv/bin/python"
			)
		"Windows":
			return ProjectSettings.globalize_path(
				"res://python/windows/venv/Scripts/python.exe"
			)
		_:
			return ""
