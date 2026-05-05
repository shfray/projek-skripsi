extends Resource
class_name CandidateData

@export var id: String = ""
@export var nama: String = ""
# Dictionary ini akan menyimpan semua kriteria secara dinamis.
# Contoh isi nantinya: {"c1": 80.0, "c2": 90.0, "c3": 75.0}
@export var criteria: Dictionary = {}