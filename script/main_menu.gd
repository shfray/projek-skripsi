extends Control

@onready var welcome_screen: Control = $WelcomeScreen
@onready var file_selector: Control = $FileSelector

func _ready() -> void:
	welcome_screen.connect("open_projects_requested", _show_file_selector)
	file_selector.connect("back_requested", _show_welcome_screen)
	file_selector.connect("project_opened", _show_welcome_screen)

func _show_file_selector() -> void:
	file_selector.call("refresh_projects")
	welcome_screen.hide()
	file_selector.show()

func _show_welcome_screen() -> void:
	file_selector.hide()
	welcome_screen.show()
