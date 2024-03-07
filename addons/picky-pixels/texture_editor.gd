@tool
extends VBoxContainer

const LIGHT_LEVEL_TAB = preload("res://addons/picky-pixels/light_level_tab.tscn")
@onready var light_levels_tabs = $Main/LightLevelData/ScrollContainer/LightLevelsTabs


func _on_light_level_value_changed(value):
	var value_diff = value - light_levels_tabs.get_child_count()
	
	if value_diff > 0:
		for i in value_diff:
			var new_tab = LIGHT_LEVEL_TAB.instantiate()
			new_tab.text = str(light_levels_tabs.get_child_count() + 1)
			light_levels_tabs.add_child(new_tab)
	elif value_diff < 0:
		light_levels_tabs.get_children()
		for i in abs(value_diff):
			light_levels_tabs.remove_child(
				light_levels_tabs.get_children().back()
			)
