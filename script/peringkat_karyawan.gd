extends VBoxContainer

@onready var table_rows: VBoxContainer = %TableRows
@onready var btn_hitung: Button = $TombolAksi/Hitung

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

	for i in range(ranked_results.size()):
		var res = ranked_results[i]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# No Peringkat
		row.add_child(_create_cell(str(i + 1)))
		# Nama Karyawan
		row.add_child(_create_cell(res["nama"]))
		
		# Skor Tiap Kriteria
		for c_key in res["raw_criteria"].keys():
			row.add_child(_create_cell(str(res["raw_criteria"][c_key])))
			
		# Total Skor SAW (4 Digit Presisi)
		row.add_child(_create_cell("%.4f" % res["score"]))

		table_rows.add_child(row)

func _create_cell(text_value: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel
