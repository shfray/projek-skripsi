extends VBoxContainer

@onready var table_rows: VBoxContainer = %TableRows

@export_group("Row Styling")
@export var even_row_color: Color = Color(0.18, 0.2, 0.25)
@export var odd_row_color: Color = Color(0.12, 0.14, 0.18)
@export var cell_margin_top: float = 8.0
@export var cell_margin_bottom: float = 8.0
@export var corner_radius: int = 6
@export var border_width: int = 1
@export var border_color: Color = Color(0.3, 0.35, 0.4)

@export_group("Label Alignment & Defaults")
@export var text_horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
@export var text_vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER
@export var default_empty_text: String = "-"

# Dummy dataset matching your header columns
var dummy_data: Array[Dictionary] = [
	{"id": "EMP-001", "nama": "Ahmad Subagja", "dapur": "Ya", "pelayanan": "-", "distribusi": "-"},
	{"id": "EMP-002", "nama": "Siti Rahmawati", "dapur": "-", "pelayanan": "Ya", "distribusi": "-"},
	{"id": "EMP-003", "nama": "Budi Santoso", "dapur": "-", "pelayanan": "-", "distribusi": "Ya"},
	{"id": "EMP-004", "nama": "Dewi Lestari", "dapur": "Ya", "pelayanan": "-", "distribusi": "-"},
	{"id": "EMP-005", "nama": "Eko Prasetyo", "dapur": "-", "pelayanan": "Ya", "distribusi": "-"},
	{"id": "EMP-006", "nama": "Fajar Nugraha", "dapur": "-", "pelayanan": "-", "distribusi": "Ya"},
	{"id": "EMP-007", "nama": "Gita Gutawa", "dapur": "Ya", "pelayanan": "-", "distribusi": "-"},
	{"id": "EMP-008", "nama": "Hendra Wijaya", "dapur": "-", "pelayanan": "Ya", "distribusi": "-"},
	{"id": "EMP-009", "nama": "Indah Permata", "dapur": "-", "pelayanan": "-", "distribusi": "Ya"},
	{"id": "EMP-010", "nama": "Joko Widodo", "dapur": "Ya", "pelayanan": "-", "distribusi": "-"},
	{"id": "EMP-011", "nama": "Kurniawan Dwi", "dapur": "-", "pelayanan": "Ya", "distribusi": "-"},
	{"id": "EMP-012", "nama": "Lina Marlina", "dapur": "-", "pelayanan": "-", "distribusi": "Ya"},
	{"id": "EMP-013", "nama": "Mega Utami", "dapur": "Ya", "pelayanan": "-", "distribusi": "-"},
	{"id": "EMP-014", "nama": "Nurdin Halid", "dapur": "-", "pelayanan": "Ya", "distribusi": "-"},
	{"id": "EMP-015", "nama": "Oki Setiana", "dapur": "-", "pelayanan": "-", "distribusi": "Ya"}
]

func _ready() -> void:
	populate_table(dummy_data)

func populate_table(data_list: Array[Dictionary]) -> void:
	# Clear default children
	for child in table_rows.get_children():
		child.queue_free()

	# Create dynamic table rows
	for i in range(data_list.size()):
		var item = data_list[i]
		var is_even_row = (i % 2 == 0)
		var row_node = create_row_node(item, is_even_row)
		table_rows.add_child(row_node)

func create_row_node(data: Dictionary, is_even: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var keys = ["id", "nama", "dapur", "pelayanan", "distribusi"]

	for key in keys:
		# Create a fresh PanelContainer instance for each column
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style = StyleBoxFlat.new()
		style.bg_color = even_row_color if is_even else odd_row_color
		style.content_margin_top = cell_margin_top
		style.content_margin_bottom = cell_margin_bottom
		style.set_corner_radius_all(corner_radius)
		style.set_border_width_all(border_width)
		style.border_color = border_color
		panel.add_theme_stylebox_override("panel", style)

		var label = Label.new()
		label.text = str(data.get(key, default_empty_text))
		label.horizontal_alignment = text_horizontal_alignment
		label.vertical_alignment = text_vertical_alignment

		panel.add_child(label)
		row.add_child(panel)

	return row
