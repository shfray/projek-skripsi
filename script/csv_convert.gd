extends Node
class_name CsvConverter

const CSV_FOLDER = "res://csv/"
const RESOURCE_FOLDER = "res://resources/"

func _ready() -> void:
	# Memulai proses saat Node aktif
	process_csv()

func process_csv() -> void:
	var target_csv_path = get_first_csv_in_folder(CSV_FOLDER)
	if target_csv_path != "":
		var candidates_data: Array = load_candidates_from_csv(target_csv_path)
		if typeof(candidates_data) == TYPE_ARRAY and candidates_data.size() > 0:
			convert_data_to_resources(candidates_data, RESOURCE_FOLDER)
		else:
			print("CsvConverter: Data CSV gagal dimuat atau berformat salah.")
	else:
		print("CsvConverter: File CSV tidak ditemukan.")

func get_first_csv_in_folder(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	if dir:
		var files = dir.get_files()
		for file_name in files:
			if file_name.ends_with(".csv"):
				return folder_path.path_join(file_name) 
	return ""

func load_candidates_from_csv(file_path: String) -> Array:
	var parsed_data: Array = []
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var headers = file.get_csv_line() 
		
		while not file.eof_reached():
			var row = file.get_csv_line()
			if row.size() > 1 and not row[0].is_empty():
				var entry = {
					"id": row[0],
					"nama": row[1],
					"criteria": {} 
				}
				for i in range(2, headers.size()):
					if i < row.size():
						var criteria_name = headers[i].strip_edges()
						entry["criteria"][criteria_name] = row[i].to_float()
				parsed_data.append(entry)
		file.close()
	return parsed_data

func convert_data_to_resources(data: Array, output_folder: String) -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_folder):
		dir.make_dir_recursive(output_folder)

	for item in data:
		var new_resource = CandidateData.new()
		new_resource.id = str(item["id"])
		new_resource.nama = str(item["nama"])
		new_resource.criteria = item["criteria"].duplicate() 
		
		var save_path = output_folder + "kandidat_" + str(new_resource.id) + ".tres"
		ResourceSaver.save(new_resource, save_path)
	print("CsvConverter: Konversi CSV ke Resource Selesai!")
