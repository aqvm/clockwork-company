extends SceneTree

const UnitActionPanelScript := preload("res://scripts/ui/unit_action_panel.gd")
const BurningStatus := preload("res://resources/statuses/burning.tres")
const BleedStatus := preload("res://resources/statuses/bleed.tres")


func _init() -> void:
	var panel = UnitActionPanelScript.new()
	root.add_child(panel)
	var tactic := TacticDefinition.new()
	tactic.display_name = "Burn Finish"
	tactic.condition = "Target Status Stacks At Least"
	tactic.status = BurningStatus
	tactic.status_stack_threshold = 4
	var unit := UnitDefinition.new()
	unit.display_name = "Author"
	var signal_probe := {"created": false}
	panel.planning_tactic_add_requested.connect(func(created_tactic): signal_probe["created"] = created_tactic == null)
	panel.show_actions(
		null,
		unit,
		unit.display_name,
		"",
		false,
		false,
		false,
		false,
		false,
		[],
		[],
		[],
		[],
		{},
		[{"tactic": tactic, "label": tactic.display_name, "equipped": true, "statuses": [BleedStatus, BurningStatus]}]
	)
	var buttons := _descendants_of_type(panel, "Button")
	var option_buttons := _descendants_of_type(panel, "OptionButton")
	var spin_boxes := _descendants_of_type(panel, "SpinBox")
	assert(_button_named(buttons, "New Tactic") != null, "The player tactic editor should expose a New Tactic action.")
	_button_named(buttons, "New Tactic").pressed.emit()
	assert(bool(signal_probe["created"]), "New Tactic should request a fresh player-authored tactic.")
	assert(_option_has(option_buttons, "Target Pending Status Damage At Least HP") and _option_has(option_buttons, "Target Slower Than Self"), "The player tactic editor should expose the full implemented condition library.")
	assert(_option_has(option_buttons, "Burning") and _option_has(option_buttons, "Bleed"), "Status-aware tactics should expose the available status library.")
	assert(spin_boxes.size() == 1 and int(spin_boxes[0].value) == 4, "Stack-aware tactics should expose their authored stack threshold.")
	print("Tactic authoring validation passed: creation, full condition library, and contextual status controls worked.")
	quit(0)


func _descendants_of_type(parent: Node, type_name: String) -> Array:
	var matches: Array = []
	for child in parent.get_children():
		if child.is_class(type_name):
			matches.append(child)
		matches.append_array(_descendants_of_type(child, type_name))
	return matches


func _button_named(buttons: Array, text: String):
	for button in buttons:
		if button.text == text:
			return button
	return null


func _option_has(option_buttons: Array, text: String) -> bool:
	for selector in option_buttons:
		for index in selector.item_count:
			if selector.get_item_text(index) == text:
				return true
	return false
