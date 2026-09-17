extends Node
class_name CsvConverter

const RESOURCE_FOLDER = "res://resources/"

## Fungsi dinamis yang dipanggil saat user memilih file CSV dari FileDialog
func import_from_path(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("CsvConverter: File tidak ditemukan -> " + file_path)
		return false
		
	var candidates_data = load_candidates_from_csv(file_path)
	if candidates_data.size() > 0:
		convert_data_to_resources(candidates_data, RESOURCE_FOLDER)
		return true
		
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

func convert_data_to_resources(data: Array, output_folder: String) -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_folder):
		dir.make_dir_recursive(output_folder)

	# Bersihkan resource lama sebelum membuat data baru
	var res_dir = DirAccess.open(output_folder)
	if res_dir:
		for f in res_dir.get_files():
			if f.ends_with(".tres"):
				res_dir.remove(f)

	for item in data:
		var new_resource = CandidateData.new()
		new_resource.id = str(item["id"])
		new_resource.nama = str(item["nama"])
		new_resource.criteria = item["criteria"].duplicate() 
		
		var save_path = output_folder.path_join("kandidat_" + str(new_resource.id) + ".tres")
		ResourceSaver.save(new_resource, save_path)
