extends Node

# Hubungkan Node-nya melalui Inspector, atau pastikan mereka ada di Scene
@onready var csv_converter = $CsvConverter
@onready var saw_calculator = $SawCalculator

func _ready():
    # 1. Jalankan konversi (jika data CSV ada yang baru)
    csv_converter.process_csv()
    
    # 2. Definisikan bobot dinamis secara bebas! 
    # (Kamu bisa mengirim Dictionary kosong jika ingin menggunakan nilai default)
    var my_dynamic_weights = {
        "c1": 0.5, 
        "c2": 0.3, 
        "c3": 0.2
    }
    var my_dynamic_types = {
        "c1": true, 
        "c2": true, 
        "c3": false # Misal c3 sekarang adalah Cost
    }
    
    # 3. Jalankan kalkulator
    saw_calculator.run_calculation(my_dynamic_weights, my_dynamic_types)