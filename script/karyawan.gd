extends VBoxContainer

@onready var table_rows: VBoxContainer = %TableRows
@onready var search_box: TextEdit = $PanelContainer/UpperBody/SearchBox
@onready var btn_tambah_data: Button = $PanelContainer/UpperBody/TambahData
@onready var table_header: HBoxContainer = $MainBody/VBoxContainer/TableScroll/TableRows/TableHeader

@export_group("Row Styling")
@export var header_bg_color: Color = Color(0.12, 0.14, 0.18)
@export var even_row_color: Color = Color(0.18, 0.2, 0.25)
@export var odd_row_color: Color = Color(0.12, 0.14, 0.18)
@export var cell_margin_top: float = 8.0
@export var cell_margin_bottom: float = 8.0
@export var corner_radius: int = 4
@export var border_width: int = 0
@export var border_color: Color = Color(0.25, 0.28, 0.35)

var file_dialog: FileDialog
var all_candidates: Array[CandidateData] = []

func _ready() -> void:
	_setup_file_dialog()
	btn_tambah_data.pressed.connect(_on_tambah_data_pressed)
	search_box.text_changed.connect(_on_search_text_changed)
	load_and_display_data()

func _setup_file_dialog() -> void:
	file_dialog = FileDialog.new()
	file_dialog.title = "Pilih File Data Karyawan"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray([
		"*.csv ; CSV Files (*.csv)",
		"*.xlsx ; Excel Workbook (*.xlsx)",
		"*.tres ; Resource Files (*.tres)",
		"*.json ; JSON Files (*.json)"
	])
	# Enable OS native picker if running Godot 4.2+
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _on_tambah_data_pressed() -> void:
	file_dialog.popup_centered(Vector2i(700, 500))

func _on_file_selected(path: String) -> void:
	var ext = path.get_extension().to_lower()
	match ext:
		"csv":
			var converter = CsvConverter.new()
			if converter.import_from_path(path):
				load_and_display_data()
		"xlsx":
			var csv_path := "user://xlsx_import.csv"
			var xlsx_importer := XlsxImporter.new()
			if xlsx_importer.convert_to_csv(path, csv_path):
				var converter := CsvConverter.new()
				if converter.import_from_path(csv_path):
					load_and_display_data()
		"tres":
			var res = ResourceLoader.load(path) as CandidateData
			if res:
				all_candidates.append(res)
				populate_table(all_candidates)
		_:
			push_warning("Format file tidak didukung: " + ext)

func load_and_display_data() -> void:
	if not ProjectManager.active_project_dir.is_empty():
		var project_resources_dir := ProjectManager.get_active_candidate_resources_dir()
		all_candidates = _load_candidates_from_folder(project_resources_dir)
	else:
		all_candidates = _load_candidates_from_folder("user://resources/")
		if all_candidates.is_empty():
			all_candidates = _load_candidates_from_folder("res://resources/")
	populate_table(all_candidates)

func _load_candidates_from_folder(folder_path: String) -> Array[CandidateData]:
	var candidates: Array[CandidateData] = []
	var dir = DirAccess.open(folder_path)
	if dir:
		for file_name in dir.get_files():
			var clean_filename = file_name.trim_suffix(".remap")
			if clean_filename.ends_with(".tres"):
				var resource_path = folder_path.path_join(clean_filename)
				var candidate = ResourceLoader.load(resource_path) as CandidateData
				if candidate:
					candidates.append(candidate)
	return candidates

func _on_search_text_changed() -> void:
	var query = search_box.text.strip_edges().to_lower()
	
	if query == "":
		populate_table(all_candidates)
		return
		
	var first_word_matches: Array[CandidateData] = []
	var secondary_word_matches: Array[CandidateData] = []
	
	for c in all_candidates:
		var name_lower = c.nama.to_lower()
		
		# Priority 1: First word starts with the query (e.g. "an" matches "Andi")
		if name_lower.begins_with(query):
			first_word_matches.append(c)
		else:
			# Priority 2: A secondary word starts with the query (e.g. "nur" matches "Andi Nurdin")
			var words = name_lower.split(" ", false)
			for i in range(1, words.size()):
				if words[i].begins_with(query):
					secondary_word_matches.append(c)
					break

	# Combine first-word matches first, followed by secondary-word matches
	var filtered_candidates: Array[CandidateData] = []
	filtered_candidates.append_array(first_word_matches)
	filtered_candidates.append_array(secondary_word_matches)
	
	populate_table(filtered_candidates)

func populate_table(candidates: Array[CandidateData]) -> void:
	if table_rows == null:
		push_error("table_rows node not found.")
		return

	# Clear previous data rows while leaving table_header intact
	for child in table_rows.get_children():
		if child != table_header:
			child.queue_free()

	# Extract unique criteria keys from ALL loaded candidates so headers remain visible
	var criteria_keys: Array[String] = []
	for c in all_candidates:
		for k in c.criteria.keys():
			if not k in criteria_keys:
				criteria_keys.append(k)

	# Rebuild table header cells
	if table_header != null:
		for child in table_header.get_children():
			child.queue_free()

		table_header.add_child(_create_cell("ID", true, false))
		table_header.add_child(_create_cell("Nama", true, false))
		
		for key in criteria_keys:
			table_header.add_child(_create_cell(key.capitalize(), true, false))

	# Display "Data Tidak Ditemukan" row if candidate list is empty
	if candidates.is_empty():
		var empty_panel = PanelContainer.new()
		empty_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var style = StyleBoxFlat.new()
		style.bg_color = odd_row_color
		style.content_margin_top = cell_margin_top * 2.0
		style.content_margin_bottom = cell_margin_bottom * 2.0
		style.set_corner_radius_all(corner_radius)
		empty_panel.add_theme_stylebox_override("panel", style)

		var empty_label = Label.new()
		empty_label.text = "Data karyawan tidak ditemukan"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		empty_panel.add_child(empty_label)
		table_rows.add_child(empty_panel)
		return

	# Rebuild data rows matching the header columns
	for i in range(candidates.size()):
		var c = candidates[i]
		var is_even = (i % 2 == 0)
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		row.add_child(_create_cell(c.id, false, is_even))
		row.add_child(_create_cell(c.nama, false, is_even))
		
		for key in criteria_keys:
			var val_str = str(c.criteria.get(key, "-"))
			row.add_child(_create_cell(val_str, false, is_even))

		table_rows.add_child(row)

func _create_cell(text_value: String, is_header: bool, is_even: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = header_bg_color if is_header else (even_row_color if is_even else odd_row_color)
	style.content_margin_top = cell_margin_top
	style.content_margin_bottom = cell_margin_bottom
	style.set_corner_radius_all(corner_radius)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if is_header:
		label.add_theme_font_size_override("font_size", 14)

	panel.add_child(label)
	return panel
