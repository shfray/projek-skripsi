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

func _ready() -> void:
	_setup_file_dialog()
	btn_tambah_data.pressed.connect(_on_tambah_data_pressed)
	load_and_display_data()

func _setup_file_dialog() -> void:
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])
	file_dialog.file_selected.connect(_on_csv_selected)
	add_child(file_dialog)

func _on_tambah_data_pressed() -> void:
	file_dialog.popup_centered(Vector2i(700, 500))

func _on_csv_selected(path: String) -> void:
	var converter = CsvConverter.new()
	if converter.import_from_path(path):
		load_and_display_data()

func load_and_display_data() -> void:
	var candidates: Array[CandidateData] = []
	var dir = DirAccess.open("res://resources/")
	if dir:
		for f in dir.get_files():
			if f.ends_with(".tres"):
				var res = ResourceLoader.load("res://resources/".path_join(f)) as CandidateData
				if res: candidates.append(res)
				
	populate_table(candidates)

func populate_table(candidates: Array[CandidateData]) -> void:
	if table_rows == null:
		push_error("table_rows node not found.")
		return

	# Clear previous data rows while leaving table_header intact
	for child in table_rows.get_children():
		if child != table_header:
			child.queue_free()

	# Extract unique criteria keys across all candidate resources
	var criteria_keys: Array[String] = []
	for c in candidates:
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
