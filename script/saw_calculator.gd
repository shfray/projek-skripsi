extends Node
class_name SawCalculator

const RESOURCE_FOLDER = "res://resources/"

# Kamu bisa memanggil ini dari UI atau script lain
func run_calculation(custom_weights: Dictionary = {}, custom_types: Dictionary = {}) -> void:
    var candidates = load_all_resources(RESOURCE_FOLDER)
    
    if candidates.size() > 0:
        var results = calculate_saw(candidates, custom_weights, custom_types)
        print_results(results)
    else:
        print("SawCalculator: Tidak ada file .tres yang ditemukan untuk dihitung.")

# --- FUNGSI MUAT RESOURCE ---
func load_all_resources(folder_path: String) -> Array:
    var loaded_candidates = []
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

# --- FUNGSI HITUNG SAW (SANGAT DINAMIS) ---
func calculate_saw(candidates: Array, weights: Dictionary, c_type: Dictionary) -> Array:
    var max_val = {}
    var min_val = {}
    var detected_keys = []
    
    # 1. DETEKSI KRITERIA OTOMATIS
    # Mencari semua kunci kriteria yang ada di dalam semua resource kandidat
    for candidate in candidates:
        for key in candidate.criteria.keys():
            if not key in detected_keys:
                detected_keys.append(key)
                
    # 2. PERSIAPAN VARIABEL DINAMIS (Auto-Fill)
    # Jika parameter weights/c_type tidak diisi untuk kriteria tertentu, kita beri default
    for key in detected_keys:
        max_val[key] = 0.0
        min_val[key] = INF
        
        # Default: Bobot 1.0 jika tidak ada
        if not weights.has(key): 
            weights[key] = 1.0 
        # Default: Benefit (true) jika tidak ada
        if not c_type.has(key): 
            c_type[key] = true 

    # 3. MENCARI NILAI MIN & MAX
    for candidate in candidates:
        var kriteria = candidate.criteria
        for key in detected_keys:
            if kriteria.has(key): 
                if kriteria[key] > max_val[key]: max_val[key] = kriteria[key]
                if kriteria[key] < min_val[key]: min_val[key] = kriteria[key]

    var final_results = []
    
    # 4. MENGHITUNG SKOR
    for candidate in candidates:
        var total_score = 0.0
        var kriteria = candidate.criteria
        
        for key in detected_keys:
            if not kriteria.has(key): continue 
            
            var normalized_val = 0.0
            var nilai = kriteria[key]
            
            if c_type[key] == true: # Benefit
                if max_val[key] != 0.0: normalized_val = nilai / max_val[key]
            else: # Cost
                if nilai != 0.0: normalized_val = min_val[key] / nilai
                
            total_score += normalized_val * weights[key]
            
        final_results.append({
            "nama": candidate.nama,
            "score": total_score
        })
        
    final_results.sort_custom(func(a, b): return a.score > b.score)
    return final_results

# --- FUNGSI TAMPILKAN HASIL ---
func print_results(results: Array) -> void:
    print("\n--- Final SAW Rankings (Dynamic Mode) ---")
    for i in range(results.size()):
        print("%d. %s | Score: %s" % [i + 1, results[i].nama, snapped(results[i].score, 0.0001)])