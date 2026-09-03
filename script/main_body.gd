extends HBoxContainer

@onready var main_display = $MainDisplay

func _ready() -> void:
	main_display.change_display(main_display.menu_utama)

func _on_menu_utama_pressed() -> void:
	main_display.change_display(main_display.menu_utama)

func _on_karyawan_pressed() -> void:
	main_display.change_display(main_display.menu_karyawan)

func _on_kriteria_pressed() -> void:
		main_display.change_display(main_display.menu_kriteria)

func _on_hitung_saw_pressed() -> void:
		main_display.change_display(main_display.menu_peringkat_karyawan)

func _on_pengaturan_pressed() -> void:
		main_display.change_display(main_display.menu_pengaturan)
