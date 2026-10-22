extends RefCounted
class_name XlsxImporter

func convert_to_csv(xlsx_path: String, csv_path: String) -> bool:
	var zip := ZIPReader.new()
	var open_error := zip.open(xlsx_path)
	if open_error != OK:
		push_error("XlsxImporter: Tidak dapat membuka file XLSX: " + error_string(open_error))
		return false

	var workbook_xml := zip.read_file("xl/workbook.xml")
	var relationships_xml := zip.read_file("xl/_rels/workbook.xml.rels")
	if workbook_xml.is_empty() or relationships_xml.is_empty():
		zip.close()
		push_error("XlsxImporter: Struktur workbook XLSX tidak lengkap.")
		return false

	var sheet_path := _get_first_sheet_path(workbook_xml, relationships_xml)
	if sheet_path.is_empty():
		zip.close()
		push_error("XlsxImporter: Tidak dapat menemukan worksheet pertama.")
		return false

	var sheet_xml := zip.read_file(sheet_path)
	if sheet_xml.is_empty():
		zip.close()
		push_error("XlsxImporter: Worksheet pertama tidak dapat dibaca.")
		return false

	var shared_strings: Array[String] = []
	var shared_strings_xml := zip.read_file("xl/sharedStrings.xml")
	if not shared_strings_xml.is_empty():
		shared_strings = _parse_shared_strings(shared_strings_xml)

	var rows := _parse_worksheet(sheet_xml, shared_strings)
	zip.close()

	var csv_rows := _build_csv_rows(rows)
	if csv_rows.is_empty():
		push_error("XlsxImporter: Worksheet harus memiliki header dan setidaknya satu baris data.")
		return false

	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file == null:
		push_error("XlsxImporter: Tidak dapat membuat CSV: " + error_string(FileAccess.get_open_error()))
		return false

	for row in csv_rows:
		csv_file.store_csv_line(row)
	csv_file.close()
	return true

func _get_first_sheet_path(workbook_xml: PackedByteArray, relationships_xml: PackedByteArray) -> String:
	var parser := XMLParser.new()
	if parser.open_buffer(workbook_xml) != OK:
		return ""

	var relationship_id := ""
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "sheet":
			for i in range(parser.get_attribute_count()):
				var attribute_name := parser.get_attribute_name(i)
				if attribute_name == "id" or attribute_name.ends_with(":id"):
					relationship_id = parser.get_attribute_value(i)
					break
			if not relationship_id.is_empty():
				break

	if relationship_id.is_empty():
		return ""

	var relationships_parser := XMLParser.new()
	if relationships_parser.open_buffer(relationships_xml) != OK:
		return ""
	var target := ""
	while relationships_parser.read() == OK:
		if relationships_parser.get_node_type() == XMLParser.NODE_ELEMENT and relationships_parser.get_node_name() == "Relationship":
			if relationships_parser.get_named_attribute_value_safe("Id") == relationship_id:
				target = relationships_parser.get_named_attribute_value_safe("Target")
				break

	if target.is_empty():
		return ""
	if target.begins_with("/"):
		target = target.trim_prefix("/")
	elif not target.begins_with("xl/"):
		target = "xl/".path_join(target)
	return target.simplify_path()

func _parse_shared_strings(xml: PackedByteArray) -> Array[String]:
	var result: Array[String] = []
	var parser := XMLParser.new()
	if parser.open_buffer(xml) != OK:
		return result

	var in_string := false
	var in_text := false
	var value := ""
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				if parser.get_node_name() == "si":
					in_string = true
					value = ""
				elif in_string and parser.get_node_name() == "t":
					in_text = true
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				if in_string and in_text:
					value += parser.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "t":
					in_text = false
				elif parser.get_node_name() == "si":
					result.append(value)
					in_string = false
	return result

func _parse_worksheet(xml: PackedByteArray, shared_strings: Array[String]) -> Dictionary:
	var rows: Dictionary = {}
	var parser := XMLParser.new()
	if parser.open_buffer(xml) != OK:
		return rows

	var row_index := -1
	var next_row_index := 0
	var cell_index := -1
	var cell_type := ""
	var cell_value := ""
	var capture_text := false

	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					"row":
						var row_number := parser.get_named_attribute_value_safe("r").to_int()
						row_index = row_number - 1 if row_number > 0 else next_row_index
						next_row_index = row_index + 1
						if not rows.has(row_index):
							rows[row_index] = {}
					"c":
						cell_index = _column_index(parser.get_named_attribute_value_safe("r"))
						cell_type = parser.get_named_attribute_value_safe("t")
						cell_value = ""
					"v", "t":
						if cell_index >= 0:
							capture_text = true
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				if capture_text:
					cell_value += parser.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				match parser.get_node_name():
					"v", "t":
						capture_text = false
					"c":
						if row_index >= 0 and cell_index >= 0:
							if cell_type == "s":
								var shared_index := cell_value.to_int()
								if shared_index >= 0 and shared_index < shared_strings.size():
									cell_value = shared_strings[shared_index]
							rows[row_index][cell_index] = cell_value
						cell_index = -1
					"row":
						row_index = -1
	return rows

func _column_index(cell_reference: String) -> int:
	var column := 0
	for character in cell_reference.to_upper():
		var code := character.unicode_at(0)
		if code < 65 or code > 90:
			break
		column = column * 26 + code - 64
	return column - 1

func _build_csv_rows(rows: Dictionary) -> Array[PackedStringArray]:
	var row_indices: Array = rows.keys()
	row_indices.sort()
	var header_row: Dictionary = {}
	var header_row_index := -1
	for row_index in row_indices:
		if not rows[row_index].is_empty():
			header_row = rows[row_index]
			header_row_index = row_index
			break
	if header_row_index < 0:
		return []

	var max_column := -1
	for column in header_row:
		max_column = maxi(max_column, int(column))
	if max_column < 1:
		return []

	var headers := PackedStringArray()
	for column in range(max_column + 1):
		var header := str(header_row.get(column, "")).strip_edges()
		if header.is_empty():
			return []
		headers.append(header)

	var csv_rows: Array[PackedStringArray] = [headers]
	for row_index in row_indices:
		if int(row_index) <= header_row_index:
			continue
		var source_row: Dictionary = rows[row_index]
		var values := PackedStringArray()
		for column in range(max_column + 1):
			values.append(str(source_row.get(column, "")).strip_edges())
		if values[0].is_empty() or values[1].is_empty():
			continue
		for column in range(2, values.size()):
			if not values[column].is_empty() and not values[column].is_valid_float():
				push_error("XlsxImporter: Nilai kriteria harus berupa angka pada baris " + str(int(row_index) + 1) + ".")
				return []
		csv_rows.append(values)
	if csv_rows.size() < 2:
		return []
	return csv_rows
