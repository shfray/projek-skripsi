extends Node

signal project_activated(project_dir: String, manifest: Dictionary)
signal project_closed

const PROJECTS_DIR := "user://projects"
const MANIFEST_NAME := "project.json"
const MANIFEST_VERSION := 1
const CANDIDATE_FILE := "candidates.csv"

var active_project_dir := ""
var active_project_manifest: Dictionary = {}
var last_error := ""

func create_project(project_name: String) -> bool:
	var clean_name := project_name.strip_edges()
	if clean_name.is_empty():
		last_error = "Project name cannot be empty."
		return false

	var make_dir_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(PROJECTS_DIR)
	)
	if make_dir_error != OK:
		last_error = "Cannot create projects folder: " + error_string(make_dir_error)
		return false

	var project_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var project_dir := PROJECTS_DIR.path_join(project_id)
	var project_dir_error := DirAccess.make_dir_absolute(
		ProjectSettings.globalize_path(project_dir)
	)
	if project_dir_error != OK:
		last_error = "Cannot create project folder: " + error_string(project_dir_error)
		return false

	var resources_dir := project_dir.path_join("resources")
	var resources_error := DirAccess.make_dir_absolute(
		ProjectSettings.globalize_path(resources_dir)
	)
	if resources_error != OK:
		last_error = "Cannot create project resources folder: " + error_string(resources_error)
		_remove_project_folder(project_dir)
		return false

	var manifest := {
		"format_version": MANIFEST_VERSION,
		"project_id": project_id,
		"name": clean_name,
		"created_at": Time.get_datetime_string_from_system(true),
		"candidate_file": CANDIDATE_FILE,
		"criteria": {}
	}
	var manifest_path := project_dir.path_join(MANIFEST_NAME)
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot create project manifest: " + error_string(FileAccess.get_open_error())
		_remove_project_folder(project_dir)
		return false

	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Cannot write project manifest: " + error_string(write_error)
		_remove_project_folder(project_dir)
		return false

	var candidates_path := project_dir.path_join(CANDIDATE_FILE)
	var candidates_file := FileAccess.open(candidates_path, FileAccess.WRITE)
	if candidates_file == null:
		last_error = "Cannot create project candidate file: " + error_string(FileAccess.get_open_error())
		_remove_project_folder(project_dir)
		return false
	candidates_file.store_csv_line(PackedStringArray(["id", "nama"]))
	candidates_file.flush()
	var candidates_error := candidates_file.get_error()
	candidates_file.close()
	if candidates_error != OK:
		last_error = "Cannot initialize project candidate file: " + error_string(candidates_error)
		_remove_project_folder(project_dir)
		return false

	_activate_project(project_dir, manifest)
	return true

func open_project_manifest(manifest_path: String) -> bool:
	var manifest := _read_project_manifest(manifest_path)
	if manifest.is_empty():
		return false

	_activate_project(ProjectSettings.localize_path(manifest_path.get_base_dir()), manifest)
	return true

func get_active_candidate_csv_path() -> String:
	if active_project_dir.is_empty():
		return ""
	return active_project_dir.path_join(str(active_project_manifest["candidate_file"]))

func get_active_candidate_resources_dir() -> String:
	if active_project_dir.is_empty():
		return ""
	return active_project_dir.path_join("resources")

func delete_project(manifest_path: String) -> bool:
	var normalized_manifest_path := ProjectSettings.localize_path(manifest_path).simplify_path()
	if normalized_manifest_path.get_file() != MANIFEST_NAME:
		last_error = "Only a project.json manifest can be used to delete a project."
		return false

	var project_dir := normalized_manifest_path.get_base_dir()
	var projects_root := ProjectSettings.localize_path(PROJECTS_DIR).simplify_path()
	if project_dir == projects_root or project_dir.get_base_dir() != projects_root:
		last_error = "Project folder must be a direct child of the saved projects folder."
		return false

	var manifest := _read_project_manifest(normalized_manifest_path)
	if manifest.is_empty():
		return false
	if str(manifest["project_id"]) != project_dir.get_file():
		last_error = "Project ID does not match its folder name."
		return false

	if not _remove_directory_contents(project_dir):
		return false
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(project_dir))
	if remove_error != OK:
		last_error = "Cannot remove project folder: " + error_string(remove_error)
		return false

	if active_project_dir.simplify_path() == project_dir:
		active_project_dir = ""
		active_project_manifest.clear()
		project_closed.emit()
	last_error = ""
	return true

func discover_projects() -> Array[Dictionary]:
	var projects: Array[Dictionary] = []
	var projects_dir := DirAccess.open(PROJECTS_DIR)
	if projects_dir == null:
		return projects

	projects_dir.list_dir_begin()
	var entry_name := projects_dir.get_next()
	while not entry_name.is_empty():
		if projects_dir.current_is_dir() and entry_name != "." and entry_name != "..":
			var project_dir := PROJECTS_DIR.path_join(entry_name)
			var manifest_path := project_dir.path_join(MANIFEST_NAME)
			if FileAccess.file_exists(manifest_path):
				var manifest := _read_project_manifest(manifest_path)
				if not manifest.is_empty():
					projects.append({
						"path": manifest_path,
						"name": manifest["name"],
						"project_id": manifest["project_id"]
					})
				else:
					push_warning("ProjectManager: Skipping invalid project manifest: " + manifest_path + " (" + last_error + ")")
		entry_name = projects_dir.get_next()
	projects_dir.list_dir_end()
	projects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]).to_lower() < str(b["name"]).to_lower()
	)
	return projects

func _read_project_manifest(manifest_path: String) -> Dictionary:
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		last_error = "Cannot open project manifest: " + error_string(FileAccess.get_open_error())
		return {}

	var content := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary:
		last_error = "Project manifest must contain a JSON object."
		return {}

	var manifest: Dictionary = parsed
	if manifest.get("format_version") != MANIFEST_VERSION:
		last_error = "Unsupported project format version."
		return {}
	if not manifest.get("project_id") is String or str(manifest["project_id"]).is_empty():
		last_error = "Project manifest is missing a valid project_id."
		return {}
	if not manifest.get("name") is String or str(manifest["name"]).strip_edges().is_empty():
		last_error = "Project manifest is missing a valid name."
		return {}
	if manifest.get("candidate_file") != CANDIDATE_FILE:
		last_error = "Project manifest must use the supported candidate file: " + CANDIDATE_FILE
		return {}
	if not manifest.get("criteria", {}) is Dictionary:
		last_error = "Project criteria must be a JSON object."
		return {}
	last_error = ""
	return manifest

func _activate_project(project_dir: String, manifest: Dictionary) -> void:
	active_project_dir = project_dir
	active_project_manifest = manifest.duplicate(true)
	last_error = ""
	project_activated.emit(active_project_dir, active_project_manifest)

func _remove_project_folder(project_dir: String) -> void:
	var absolute_dir := ProjectSettings.globalize_path(project_dir)
	if not DirAccess.dir_exists_absolute(absolute_dir):
		return
	if not _remove_directory_contents(project_dir):
		push_error("ProjectManager: Failed to clean up incomplete project: " + last_error)
		return
	var remove_error := DirAccess.remove_absolute(absolute_dir)
	if remove_error != OK:
		push_error("ProjectManager: Failed to remove incomplete project folder: " + error_string(remove_error))

func _remove_directory_contents(directory_path: String) -> bool:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		last_error = "Cannot open project folder: " + directory_path
		return false

	directory.include_hidden = true
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if entry_name != "." and entry_name != "..":
			var entry_path := directory_path.path_join(entry_name)
			if directory.current_is_dir():
				if not _remove_directory_contents(entry_path):
					directory.list_dir_end()
					return false
				var remove_dir_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(entry_path))
				if remove_dir_error != OK:
					directory.list_dir_end()
					last_error = "Cannot remove project subfolder: " + entry_path
					return false
			else:
				var remove_file_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(entry_path))
				if remove_file_error != OK:
					directory.list_dir_end()
					last_error = "Cannot remove project file: " + entry_path
					return false
		entry_name = directory.get_next()
	directory.list_dir_end()
	return true
