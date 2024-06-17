@tool
extends TabBar


func _ready():
	for _i in range(1, tab_count):
		remove_tab(1)
	current_tab = 0


func _on_tab_changed(tab):
	# Prevent the first tab "Library" from being deleted
	if tab == 0:
		tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
	else:
		tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
