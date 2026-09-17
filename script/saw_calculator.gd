extends Node
class_name SawCalculator

const RESOURCE_FOLDER = "res://resources/"

## Menjalankan kalkulasi SAW dan mengembalikan Array terurut dari peringkat tertinggi
func calculate_from_resources(custom_weights: Dictionary = {}, custom_types: Dictionary = {}) -> Array[Dictionary]:
	var candidates = load_all_resources(RESOURCE_FOLDER)
	if candidates.is_empty():
		push_warning("SawCalculator: Tidak ada file CandidateData (.tres) ditemukan.")
		return []
		
	return calculate_saw(candidates, custom_weights, custom_types)

func load_all_resources(folder_path: String) -> Array[CandidateData]:
	var loaded_candidates: Array[CandidateData] = []
	var dir = DirAccess.open(folder_path)
	
	if dir:
		var files = dir.get_files()
		for file_name in files:
			if file_name.ends_with(".tres"):
				var resource_path = folder_path.path_join(file_name)
				var res = ResourceLoader.load(resource_path) as CandidateData
				if res:
					loaded_candidates.append(res)
	return loaded_candidates

func calculate_saw(candidates: Array[CandidateData], weights: Dictionary, c_type: Dictionary) -> Array[Dictionary]:
	var max_val: Dictionary = {}
	var min_val: Dictionary = {}
	var detected_keys: Array = []
	
	# 1. Deteksi seluruh kunci kriteria yang ada di data kandidat
	for candidate in candidates:
		for key in candidate.criteria.keys():
			if not key in detected_keys:
				detected_keys.append(key)
				
	if detected_keys.is_empty():
		return []

	# 2. Normalisasi Bobot Kriteria (Memastikan total bobot = 1.0)
	var total_raw_weight: float = 0.0
	var normalized_weights: Dictionary = {}
	
	for key in detected_keys:
		if not weights.has(key): weights[key] = 1.0
		if not c_type.has(key): c_type[key] = true # true = Benefit, false = Cost
		total_raw_weight += float(weights[key])

	for key in detected_keys:
		normalized_weights[key] = (float(weights[key]) / total_raw_weight) if total_raw_weight > 0 else 0.0
		max_val[key] = -INF
		min_val[key] = INF

	# 3. Cari Nilai Min & Max per Kriteria
	for candidate in candidates:
		var kriteria = candidate.criteria
		for key in detected_keys:
			var val: float = float(kriteria.get(key, 0.0))
			if val > max_val[key]: max_val[key] = val
			if val < min_val[key]: min_val[key] = val

	# 4. Hitung Skor Normalisasi & SAW
	var final_results: Array[Dictionary] = []
	
	for candidate in candidates:
		var total_score: float = 0.0
		var kriteria = candidate.criteria
		var norm_scores: Dictionary = {}
		
		for key in detected_keys:
			var raw_val: float = float(kriteria.get(key, 0.0))
			var norm_val: float = 0.0
			
			if c_type[key] == true: # Benefit
				norm_val = (raw_val / max_val[key]) if max_val[key] != 0.0 else 0.0
			else: # Cost
				norm_val = (min_val[key] / raw_val) if raw_val != 0.0 else 0.0
				
			norm_scores[key] = norm_val
			total_score += norm_val * normalized_weights[key]
			
		final_results.append({
			"id": candidate.id,
			"nama": candidate.nama,
			"score": total_score,
			"raw_criteria": kriteria.duplicate(),
			"normalized_criteria": norm_scores
		})
		
	# Urutkan berdasarkan skor tertinggi (Descending)
	final_results.sort_custom(func(a, b): return a["score"] > b["score"])
	return final_results
