extends Node

const CSV_FOLDER = "res://csv/" # Renamed to clarify it is a folder, not a file

# Define your weights and criteria types here
var weights = {
	"c1": 0.5, 
	"c2": 0.3, 
	"c3": 0.2
}
# true = Benefit, false = Cost
var criteria_type = {
	"c1": true, 
	"c2": true,
	"c3": true # Note: You changed this to true. Make sure C3 is actually a Benefit!
} 

func _ready():
	# 1. Use the scanner to find the actual .csv file inside the folder
	var target_csv_path = get_first_csv_in_folder(CSV_FOLDER)
	
	if target_csv_path != "":
		# 2. Load the data using the exact file path we just found
		var candidates_data = load_candidates_from_csv(target_csv_path)
		
		# 3. If data loaded successfully, run the SAW calculation
		if candidates_data.size() > 0:
			var saw_results = calculate_saw(candidates_data, weights, criteria_type)
			print_results(saw_results)
	else:
		print("Process aborted: No CSV file found to load.")

# --- DIRECTORY SCANNER FUNCTION ---
func get_first_csv_in_folder(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	
	if dir:
		var files = dir.get_files()
		for file_name in files:
			if file_name.ends_with(".csv"):
				print("Found CSV file: ", file_name)
				return folder_path.path_join(file_name) # Safely joins folder and file
		print("Error: No .csv files found inside ", folder_path)
	else:
		print("Error: Could not open the directory ", folder_path)
		
	return ""

# --- CSV READING FUNCTION ---
func load_candidates_from_csv(file_path: String) -> Array:
	var parsed_data = []
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var _headers = file.get_csv_line() 
		
		while not file.eof_reached():
			var row = file.get_csv_line()
			if row.size() > 1:
				var entry = {
					"id": row[0],
					"nama": row[1],
					"c1": row[2].to_float(), 
					"c2": row[3].to_float(),
					"c3": row[4].to_float()
				}
				parsed_data.append(entry)
				
		file.close()
		print("Successfully loaded ", parsed_data.size(), " candidates from CSV.")
	else:
		print("Error: Could not find CSV file at ", file_path)
		
	return parsed_data

# --- SAW CALCULATION FUNCTION ---
func calculate_saw(data: Array, w: Dictionary, c_type: Dictionary) -> Array:
	var max_val = {"c1": 0.0, "c2": 0.0, "c3": 0.0}
	var min_val = {"c1": INF, "c2": INF, "c3": INF}
	
	for item in data:
		for key in c_type.keys():
			if item[key] > max_val[key]: max_val[key] = item[key]
			if item[key] < min_val[key]: min_val[key] = item[key]

	var final_results = []
	
	for item in data:
		var total_score = 0.0
		
		for key in c_type.keys():
			var normalized_val = 0.0
			if c_type[key] == true: 
				normalized_val = item[key] / max_val[key]
			else: 
				normalized_val = min_val[key] / item[key]
				
			total_score += normalized_val * w[key]
			
		final_results.append({
			"nama": item.nama,
			"score": total_score
		})
		
	final_results.sort_custom(func(a, b): return a.score > b.score)
	return final_results

# --- HELPER TO DISPLAY RESULTS ---
func print_results(results: Array):
	print("\n--- Final SAW Rankings ---")
	for i in range(results.size()):
		var rank = i + 1
		var formatted_score = snapped(results[i].score, 0.0001)
		print("%d. %s | Score: %s" % [rank, results[i].nama, formatted_score])
