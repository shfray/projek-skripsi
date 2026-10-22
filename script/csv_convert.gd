extends Node
class_name CsvConverter

const LEGACY_RESOURCE_FOLDER = "user://resources/"

## Fungsi dinamis yang dipanggil saat user memilih file CSV dari FileDialog
func import_from_path(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("CsvConverter: File tidak ditemukan -> " + file_path)
		return false
		
	var candidates_data = load_candidates_from_csv(file_path)
	if candidates_data.size() > 0:
		var output_folder := LEGACY_RESOURCE_FOLDER
		var candidate_csv_path := ""
		if not ProjectManager.active_project_dir.is_empty():
			output_folder = ProjectManager.get_active_candidate_resources_dir()
			candidate_csv_path = ProjectManager.get_active_candidate_csv_path()
		if not candidate_csv_path.is_empty() and not save_candidates_to_csv(candidates_data, candidate_csv_path):
			return false
		return convert_data_to_resources(candidates_data, output_folder)
		
	return false

func load_candidates_from_csv(file_path: String) -> Array:
	var parsed_data: Array = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return parsed_data
		
	var headers = file.get_csv_line() 
	
	while not file.eof_reached():
		var row = file.get_csv_line()
		if row.size() > 1 and not row[0].is_empty():
			var entry = {
				"id": row[0].strip_edges(),
				"nama": row[1].strip_edges(),
				"criteria": {} 
			}
			for i in range(2, headers.size()):
				if i < row.size():
					var criteria_name = headers[i].strip_edges().to_lower()
					entry["criteria"][criteria_name] = row[i].to_float()
			parsed_data.append(entry)
			
	file.close()
	return parsed_data

func save_candidates_to_csv(data: Array, file_path: String) -> bool:
	if data.is_empty():
		push_error("CsvConverter: Cannot save an empty candidate dataset.")
		return false

	var criteria_keys: Array[String] = []
	for item in data:
		var criteria: Dictionary = item["criteria"]
		for key in criteria.keys():
			if not criteria_keys.has(str(key)):
				criteria_keys.append(str(key))

	var make_dir_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(file_path.get_base_dir())
	)
	if make_dir_error != OK:
		push_error("CsvConverter: Cannot create project data folder: " + error_string(make_dir_error))
		return false

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("CsvConverter: Cannot save project CSV: " + error_string(FileAccess.get_open_error()))
		return false

	var headers := PackedStringArray(["id", "nama"])
	for key in criteria_keys:
		headers.append(key)
	file.store_csv_line(headers)
	for item in data:
		var row := PackedStringArray([str(item["id"]), str(item["nama"])])
		var criteria: Dictionary = item["criteria"]
		for key in criteria_keys:
			row.append(str(criteria.get(key, "")))
		file.store_csv_line(row)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("CsvConverter: Cannot write project CSV: " + error_string(write_error))
		return false
	return true

func convert_data_to_resources(data: Array, output_folder: String) -> bool:
	var make_dir_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(output_folder)
	)
	if make_dir_error != OK:
		push_error("CsvConverter: Tidak dapat membuat folder data: " + error_string(make_dir_error))
		return false

	# Bersihkan resource lama sebelum membuat data baru
	var res_dir = DirAccess.open(output_folder)
	if res_dir == null:
		push_error("CsvConverter: Tidak dapat membuka folder data: " + output_folder)
		return false
	for f in res_dir.get_files():
		if f.ends_with(".tres"):
			var remove_error := res_dir.remove(f)
			if remove_error != OK:
				push_error("CsvConverter: Tidak dapat menghapus data lama: " + f)
				return false

	for i in range(data.size()):
		var item: Dictionary = data[i]
		var new_resource = CandidateData.new()
		new_resource.id = str(item["id"])
		new_resource.nama = str(item["nama"])
		new_resource.criteria = item["criteria"].duplicate() 
		
		var save_path = output_folder.path_join("kandidat_" + str(i + 1) + ".tres")
		var save_error := ResourceSaver.save(new_resource, save_path)
		if save_error != OK:
			push_error("CsvConverter: Tidak dapat menyimpan kandidat " + new_resource.id + ": " + error_string(save_error))
			return false
	return true
