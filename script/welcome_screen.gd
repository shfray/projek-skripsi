extends PanelContainer

signal open_projects_requested

@onready var project_status: Label = $VBoxContainer/ProjectStatus
@onready var new_project_button: Button = $VBoxContainer/HBoxContainer/NewFile
@onready var open_project_button: Button = $VBoxContainer/HBoxContainer/OpenFile

var project_name_dialog: ConfirmationDialog
var project_name_input: LineEdit

func _ready() -> void:
	new_project_button.pressed.connect(_show_new_project_dialog)
	open_project_button.pressed.connect(func() -> void: open_projects_requested.emit())
	_create_dialogs()
	ProjectManager.project_activated.connect(_on_project_activated)
	ProjectManager.project_closed.connect(_on_project_closed)
	if not ProjectManager.active_project_dir.is_empty():
		_on_project_activated(
			ProjectManager.active_project_dir,
			ProjectManager.active_project_manifest
		)

func _create_dialogs() -> void:
	project_name_dialog = ConfirmationDialog.new()
	project_name_dialog.title = "Create Project"
	project_name_dialog.dialog_text = "Enter a name for the new project."
	project_name_input = LineEdit.new()
	project_name_input.placeholder_text = "Project name"
	project_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_name_dialog.add_child(project_name_input)
	project_name_dialog.confirmed.connect(_create_project)
	add_child(project_name_dialog)

func _show_new_project_dialog() -> void:
	project_name_input.clear()
	project_name_dialog.popup_centered(Vector2i(420, 160))
	project_name_input.grab_focus()

func _create_project() -> void:
	if ProjectManager.create_project(project_name_input.text):
		project_status.text = "Active project: " + str(ProjectManager.active_project_manifest["name"])
	else:
		_show_project_error(ProjectManager.last_error)

func _on_project_activated(_project_dir: String, manifest: Dictionary) -> void:
	project_status.text = "Active project: " + str(manifest["name"])

func _on_project_closed() -> void:
	project_status.text = "No project selected"

func _show_project_error(message: String) -> void:
	project_status.text = "Project error: " + message
	push_error("Main menu: " + message)
