extends PanelContainer

signal back_requested
signal project_opened

@onready var project_list: VBoxContainer = $VBoxContainer/ProjectScroll/ProjectList
@onready var status_label: Label = $VBoxContainer/Status
@onready var open_button: Button = $VBoxContainer/Actions/OpenButton
@onready var delete_button: Button = $VBoxContainer/Actions/DeleteButton

var selected_project: Dictionary = {}
var project_buttons: Array[Button] = []
var delete_confirmation: ConfirmationDialog

func _ready() -> void:
	$VBoxContainer/Header/BackButton.pressed.connect(func() -> void: back_requested.emit())
	open_button.pressed.connect(_open_selected_project)
	delete_button.pressed.connect(_confirm_delete_selected_project)
	open_button.disabled = true
	delete_button.disabled = true
	_create_delete_confirmation()
	refresh_projects()

func _create_delete_confirmation() -> void:
	delete_confirmation = ConfirmationDialog.new()
	delete_confirmation.title = "Delete Project"
	delete_confirmation.confirmed.connect(_delete_selected_project)
	add_child(delete_confirmation)

func refresh_projects() -> void:
	for child in project_list.get_children():
		child.queue_free()
	project_buttons.clear()
	selected_project.clear()
	open_button.disabled = true
	delete_button.disabled = true

	var projects: Array[Dictionary] = ProjectManager.discover_projects()
	if projects.is_empty():
		status_label.text = "No saved projects found."
		return

	status_label.text = "Select a project to open."
	for project in projects:
		var project_button := Button.new()
		project_button.text = str(project["name"])
		project_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		project_button.toggle_mode = true
		project_button.pressed.connect(_select_project.bind(project, project_button))
		project_list.add_child(project_button)
		project_buttons.append(project_button)

func _select_project(project: Dictionary, selected_button: Button) -> void:
	selected_project = project
	for project_button in project_buttons:
		project_button.set_pressed_no_signal(project_button == selected_button)
	open_button.disabled = false
	delete_button.disabled = false
	status_label.text = "Selected: " + str(project["name"])

func _open_selected_project() -> void:
	if selected_project.is_empty():
		return
	if ProjectManager.open_project_manifest(str(selected_project["path"])):
		project_opened.emit()
	else:
		status_label.text = ProjectManager.last_error
		push_error("File selector: " + status_label.text)

func _confirm_delete_selected_project() -> void:
	if selected_project.is_empty():
		return
	delete_confirmation.dialog_text = "Permanently delete \"%s\" and all files in its project folder?" % str(selected_project["name"])
	delete_confirmation.popup_centered()

func _delete_selected_project() -> void:
	if selected_project.is_empty():
		return
	if ProjectManager.delete_project(str(selected_project["path"])):
		status_label.text = "Project deleted."
		refresh_projects()
	else:
		status_label.text = ProjectManager.last_error
		push_error("File selector: " + status_label.text)
