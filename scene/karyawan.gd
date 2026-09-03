extends VBoxContainer

@onready var table_rows: VBoxContainer = %TableRows

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

	# Column keys in order: ID, Nama Karyawan, Divisi Dapur, Divisi Pelayanan, Divisi Distribusi
	var keys = ["id", "nama", "dapur", "pelayanan", "distribusi"]

	for key in keys:
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Alternating row background for visual contrast
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.2, 0.25) if is_even else Color(0.12, 0.14, 0.18)
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)

		var label = Label.new()
		label.text = str(data.get(key, "-"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		panel.add_child(label)
		row.add_child(panel)

	return row
