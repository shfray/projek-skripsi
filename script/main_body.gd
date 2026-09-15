extends HBoxContainer

@onready var main_display = $MainDisplay
@onready var v_box_container: VBoxContainer = $ListMenu/SideNavbar/VBoxContainer

func _ready() -> void:
	# Map each button node name to its corresponding display target
	var menu_map = {
		"MenuUtama": main_display.menu_utama,
		"ProfilKaryawan": main_display.menu_profil_karyawan,
		"DataKaryawan": main_display.menu_data_karyawan,
		"PeringkatKaryawan": main_display.menu_peringkat_karyawan,
		"Kriteria": main_display.menu_kriteria,
		"Laporan": main_display.menu_laporan
	}
	
	# Configure buttons and dynamically connect pressed signals
	for child in v_box_container.get_children():
		if child is Button and child.name in menu_map:
			child.toggle_mode = true # Enables visual toggle state strictly via code
			var target_display = menu_map[child.name]
			
			child.pressed.connect(
				func(): _select_menu(child, target_display)
			)
			
	# Set default starting page to MenuUtama
	var default_button = v_box_container.get_node_or_null("MenuUtama")
	if default_button:
		_select_menu(default_button, main_display.menu_utama)

# Handles display switching and visual updates in one central place
func _select_menu(active_button: Button, target_display) -> void:
	main_display.change_display(target_display)
	
	# Highlight only the active button visually without triggering signals
	for child in v_box_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(child == active_button)
