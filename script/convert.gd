extends Control

@onready var save_button: Button = $SaveButton
@onready var capture_viewport: SubViewport = $Capture/SubViewport

const PYTHON_PATH := "/home/reidra/Documents/project file/pepoproject/projek skripsi/projek-skripsi/venv/bin/python"
const PYTHON_SCRIPT := "res://png_to_PDF.py"

func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)

func _on_save_pressed() -> void:
	var png_path := ProjectSettings.globalize_path("user://scene.png")
	var pdf_path := ProjectSettings.globalize_path("user://scene.pdf")

	save_scene_png(png_path)
	run_python_converter(png_path, pdf_path)

# ------------------------

func save_scene_png(png_path: String) -> void:
	var texture: Texture2D = capture_viewport.get_texture()
	var image: Image = texture.get_image()
	image.save_png(png_path)

# ------------------------

func run_python_converter(png_path: String, pdf_path: String) -> void:
	var script_path := ProjectSettings.globalize_path(PYTHON_SCRIPT)
	var args := [script_path, png_path, pdf_path]

	var output: Array[String] = []
	var exit_code := OS.execute(PYTHON_PATH, args, output, true)

	if exit_code != 0:
		push_error("Python failed:\n" + "\n".join(output))
	else:
		print("PDF created successfully:", pdf_path)
