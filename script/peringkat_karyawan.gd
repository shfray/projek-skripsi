extends VBoxContainer

@onready var table_rows: VBoxContainer = %TableRows
@onready var table_header: HBoxContainer = $IsiPanel/MainBody/VBoxContainer/TableHeader
@onready var btn_hitung: Button = $TombolAksi/Hitung

@export_group("Table Styling")
@export var header_bg_color: Color = Color(0.12, 0.14, 0.18)
@export var even_row_color: Color = Color(0.18, 0.2, 0.25)
@export var odd_row_color: Color = Color(0.12, 0.14, 0.18)
@export var cell_margin_top: float = 8.0
@export var cell_margin_bottom: float = 8.0
@export var corner_radius: int = 4
@export var border_width: int = 0
@export var border_color: Color = Color(0.25, 0.28, 0.35)

func _ready() -> void:
	btn_hitung.pressed.connect(_on_hitung_pressed)
	render_rankings()

func _on_hitung_pressed() -> void:
	render_rankings()

func render_rankings() -> void:
	var calculator = SawCalculator.new()
	var ranked_results = calculator.calculate_from_resources()

	for child in table_rows.get_children():
		child.queue_free()
	for child in table_header.get_children():
		child.queue_free()

	var criteria_keys: Array[String] = []
	if not ranked_results.is_empty():
		for key in ranked_results[0]["raw_criteria"].keys():
			criteria_keys.append(str(key))

	table_header.add_child(_create_cell("Peringkat", true, false))
	table_header.add_child(_create_cell("Nama Karyawan", true, false))
	for key in criteria_keys:
		table_header.add_child(_create_cell(key.capitalize(), true, false))
	table_header.add_child(_create_cell("Skor SAW", true, false))

	for i in range(ranked_results.size()):
		var res = ranked_results[i]
		var is_even := i % 2 == 0
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		row.add_child(_create_cell(str(i + 1), false, is_even))
		row.add_child(_create_cell(str(res["nama"]), false, is_even))
		for key in criteria_keys:
			row.add_child(_create_cell(str(res["raw_criteria"].get(key, "-")), false, is_even))
		row.add_child(_create_cell("%.4f" % res["score"], false, is_even))

		table_rows.add_child(row)

func _create_cell(text_value: String, is_header: bool, is_even: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if is_header:
		var style := StyleBoxFlat.new()
		style.bg_color = header_bg_color if is_header else (even_row_color if is_even else odd_row_color)
		style.content_margin_top = cell_margin_top
		style.content_margin_bottom = cell_margin_bottom
		style.set_corner_radius_all(corner_radius)
		style.set_border_width_all(border_width)
		style.border_color = border_color
		panel.add_theme_stylebox_override("panel", style)
	else:
		var style := StyleBoxEmpty.new()
		style.content_margin_top = cell_margin_top
		style.content_margin_bottom = cell_margin_bottom 	
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
