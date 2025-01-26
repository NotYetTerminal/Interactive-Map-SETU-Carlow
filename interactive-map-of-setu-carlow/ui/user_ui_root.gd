extends Control

# Signals for outside nodes
signal level_up_button
signal level_down_button
signal navigation_button
signal zoom_in_button
signal zoom_out_button


func _on_to_search_bar_line_edit_text_changed(_new_text: String) -> void:
	pass # Replace with function body.


func _on_from_search_bar_line_edit_text_changed(_new_text: String) -> void:
	pass # Replace with function body.


func _on_level_up_button_button_down() -> void:
	level_up_button.emit()


func _on_level_down_button_button_down() -> void:
	level_down_button.emit()


func _on_navigation_button_button_down() -> void:
	navigation_button.emit()


func _on_zoom_in_button_button_down() -> void:
	zoom_in_button.emit()


func _on_zoom_out_button_button_down() -> void:
	zoom_out_button.emit()
