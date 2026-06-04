extends VBoxContainer
class_name PartyPanel

signal unit_selected(unit_name: String)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared


func show_party(units: Array[UnitDefinition], selected_unit_name: String) -> void:
	_clear_children()

	var title := Label.new()
	title.text = "Party"
	add_child(title)

	for unit: UnitDefinition in units:
		var button := Button.new()
		button.text = "%s | HP %d | P%d M%d A%d I%d" % [unit.display_name, unit.max_hp, unit.physical_damage, unit.magic_damage, unit.armor, unit.action_interval]
		button.toggle_mode = true
		button.button_pressed = unit.display_name == selected_unit_name
		button.pressed.connect(_on_unit_button_pressed.bind(unit.display_name))
		_bind_resource_tooltip(button, unit)
		add_child(button)


func _on_unit_button_pressed(unit_name: String) -> void:
	unit_selected.emit(unit_name)


func _bind_resource_tooltip(control: Control, resource: Resource) -> void:
	control.mouse_entered.connect(_on_resource_mouse_entered.bind(control, resource))
	control.mouse_exited.connect(_on_resource_mouse_exited)


func _on_resource_mouse_entered(source: Control, resource: Resource) -> void:
	resource_tooltip_requested.emit(source, resource)


func _on_resource_mouse_exited() -> void:
	tooltip_cleared.emit()


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
