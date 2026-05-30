# `extends` chooses the Godot base type this script inherits from. `RefCounted`
# is a lightweight script object, useful when we want logic without a scene node.
extends RefCounted

# `class_name` registers this script as a named type Godot can reference from
# other scripts, similar to giving the file an importable class name.
class_name CombatSimulator

# `const` creates a value that should not change at runtime. `:=` lets Godot
# infer the variable's type from the value on the right side.
const TEAM_ALLY := "Allies"
const TEAM_ENEMY := "Enemies"
const MAX_ACTIONS := 100
const DEMO_UNIT_DEFINITIONS: Array[UnitDefinition] = [
	preload("res://resources/units/alden_guard.tres"),
	preload("res://resources/units/mira_scout.tres"),
	preload("res://resources/units/sol_apprentice.tres"),
	preload("res://resources/units/iron_brute.tres"),
	preload("res://resources/units/ash_cutpurse.tres"),
	preload("res://resources/units/glass_wisp.tres"),
]
const DEMO_EQUIPPED_ITEMS: Array = [
	preload("res://resources/items/reinforced_buckler.tres"),
	preload("res://resources/items/light_step_boots.tres"),
	preload("res://resources/items/glass_focus.tres"),
	preload("res://resources/items/reinforced_buckler.tres"),
	preload("res://resources/items/shortblade.tres"),
	null,
]


# `class` declares a small helper class inside this script. Here it represents
# one unit's combat-only runtime state, separate from the source Resource.
class UnitState:
	# `var` declares a mutable variable. These default values also tell Godot
	# what type each field should usually hold.
	var unit_name := ""
	var team := ""
	var max_hp := 1
	var hp := 1
	var damage := 1
	var armor := 0
	var action_interval := 10
	var next_action_time := 10
	var slot_index := 0
	var equipped_item: ItemDefinition = null

	# `func` declares a function. `_init` is Godot's constructor hook, called
	# when code uses `UnitState.new(...)`. The text after `:` gives parameter
	# types, and `-> void` means this function does not return a value.
	func _init(definition: UnitDefinition, unit_slot_index: int, equipped_item_definition: ItemDefinition = null) -> void:
		# Dot syntax reads exported properties from the UnitDefinition Resource.
		unit_name = definition.display_name
		team = definition.team
		max_hp = definition.max_hp
		damage = definition.damage
		armor = definition.armor
		action_interval = definition.action_interval
		slot_index = unit_slot_index
		equipped_item = equipped_item_definition

		if equipped_item != null:
			max_hp = max(1, max_hp + equipped_item.max_hp_modifier)
			damage = max(1, damage + equipped_item.damage_modifier)
			armor = max(0, armor + equipped_item.armor_modifier)
			action_interval = max(1, action_interval + equipped_item.action_interval_modifier)

		hp = max_hp
		next_action_time = action_interval

	# `-> bool` means callers should expect this function to return true or false.
	func is_alive() -> bool:
		# Comparison operators like `>` produce a boolean result.
		return hp > 0


# `Array[String]` is a typed array: this function promises to return an array
# whose entries are strings.
func run_demo_battle() -> Array[String]:
	# Calling a function with `()` runs it and gives back its return value.
	var units := _create_demo_units()
	# `: Array[String]` explicitly types the variable; `[]` creates an empty array.
	var log: Array[String] = []
	var actions_taken := 0

	# Dot syntax calls a method on an object. `append(...)` adds one item to the
	# end of the array.
	log.append("Phase 3 demo battle")
	log.append("Random seed: none yet. This fight is deterministic because there are no random rolls.")
	log.append("Tie-breaker: if two units are ready at the same time, earlier roster position acts first.")
	log.append("Unit definitions: loaded from Resource files in res://resources/units/.")
	log.append("Item definitions: loaded from Resource files in res://resources/items/.")
	log.append("")
	_append_gear_summary(log, units)
	log.append("")
	_append_roster(log, units)
	log.append("")
	log.append("Combat log:")

	# `while` repeats the indented block as long as its condition stays true.
	# `and` combines two boolean checks, so both teams must still have units alive.
	while _team_has_living_unit(units, TEAM_ALLY) and _team_has_living_unit(units, TEAM_ENEMY):
		# `if` runs its indented block only when the condition is true.
		if actions_taken >= MAX_ACTIONS:
			# `%` formats values into a string. `%d` is a placeholder for an integer.
			log.append("Battle stopped after %d actions to avoid an infinite fight." % MAX_ACTIONS)
			# `break` exits the nearest loop immediately.
			break

		# `var actor: UnitState` declares a variable with an explicit custom type.
		var actor: UnitState = _find_next_actor(units)
		var target: UnitState = _find_frontmost_target(units, _opposing_team(actor.team))
		var current_time := actor.next_action_time
		var damage_taken: int = max(1, actor.damage - target.armor)
		var previous_hp := target.hp

		target.hp = max(0, target.hp - damage_taken)
		actions_taken += 1

		# Parentheses can wrap a long function call over several lines. The array
		# after `%` supplies values for each placeholder in order.
		log.append(
			"t=%03d | %s attacks %s for %d damage. HP: %d -> %d"
			% [current_time, actor.unit_name, target.unit_name, damage_taken, previous_hp, target.hp]
		)

		# `not` flips a boolean value, so this means "if the target is not alive."
		if not target.is_alive():
			log.append("      %s is defeated." % target.unit_name)

		# `+=` is shorthand for assigning the old value plus something else.
		actor.next_action_time += actor.action_interval

	log.append("")
	log.append(_build_result_line(units, actions_taken))
	return log


func _create_demo_units() -> Array:
	var units: Array = []
	# `for ... in ...` loops over each value in a collection. `DEMO_UNIT_DEFINITIONS.size()`
	# returns an integer, and Godot treats that as the range `0` through `size - 1`.
	for index in DEMO_UNIT_DEFINITIONS.size():
		units.append(UnitState.new(DEMO_UNIT_DEFINITIONS[index], index, DEMO_EQUIPPED_ITEMS[index]))
	return units


func _append_gear_summary(log: Array[String], units: Array) -> void:
	log.append("Equipped gear:")
	for unit: UnitState in units:
		if unit.equipped_item == null:
			log.append("  %s: none" % unit.unit_name)
		else:
			log.append("  %s: %s" % [unit.unit_name, _describe_item(unit.equipped_item)])


func _append_roster(log: Array[String], units: Array) -> void:
	log.append("Roster:")
	# This loop uses an inline array literal so the roster prints allies first,
	# then enemies.
	for team in [TEAM_ALLY, TEAM_ENEMY]:
		log.append("  %s" % team)
		# `for unit: UnitState in units` adds a type hint to each loop variable.
		for unit: UnitState in units:
			if unit.team == team:
				log.append(
					"    %s | HP %d | damage %d | armor %d | interval %d | item %s"
					% [unit.unit_name, unit.max_hp, unit.damage, unit.armor, unit.action_interval, _item_name_or_none(unit)]
				)


func _find_next_actor(units: Array) -> UnitState:
	# `null` means "no object/value yet." This lets the first living unit become
	# the temporary best candidate.
	var next_actor: UnitState = null
	for unit: UnitState in units:
		if not unit.is_alive():
			# `continue` skips the rest of this loop iteration and moves to the
			# next unit.
			continue

		if next_actor == null:
			next_actor = unit
		# `elif` means "else if": only checked when earlier `if`/`elif` branches
		# in the same chain did not run.
		elif unit.next_action_time < next_actor.next_action_time:
			next_actor = unit
		elif unit.next_action_time == next_actor.next_action_time and unit.slot_index < next_actor.slot_index:
			next_actor = unit

	return next_actor


func _find_frontmost_target(units: Array, target_team: String) -> UnitState:
	for unit: UnitState in units:
		# `==` checks equality. This condition finds the first living unit on the
		# requested team, which is our current "frontmost" targeting rule.
		if unit.team == target_team and unit.is_alive():
			return unit

	return null


func _team_has_living_unit(units: Array, team: String) -> bool:
	for unit: UnitState in units:
		if unit.team == team and unit.is_alive():
			# Returning from inside a loop ends the function immediately.
			return true

	return false


func _opposing_team(team: String) -> String:
	if team == TEAM_ALLY:
		return TEAM_ENEMY

	# This fallback return runs when the earlier `if` did not return.
	return TEAM_ALLY


func _item_name_or_none(unit: UnitState) -> String:
	if unit.equipped_item == null:
		return "none"

	return unit.equipped_item.display_name


func _describe_item(item: ItemDefinition) -> String:
	return "%s [%s] (%s)" % [item.display_name, item.slot, _describe_item_modifiers(item)]


func _describe_item_modifiers(item: ItemDefinition) -> String:
	var parts: Array[String] = []
	_append_modifier_text(parts, "HP", item.max_hp_modifier)
	_append_modifier_text(parts, "damage", item.damage_modifier)
	_append_modifier_text(parts, "armor", item.armor_modifier)
	_append_modifier_text(parts, "interval", item.action_interval_modifier)

	if parts.is_empty():
		return "no stat changes"

	return _join_text_parts(parts, ", ")


func _append_modifier_text(parts: Array[String], label: String, amount: int) -> void:
	if amount == 0:
		return

	if amount > 0:
		parts.append("%s +%d" % [label, amount])
	else:
		parts.append("%s %d" % [label, amount])


func _join_text_parts(parts: Array[String], separator: String) -> String:
	var text := ""
	for part in parts:
		if not text.is_empty():
			text += separator
		text += part

	return text


func _build_result_line(units: Array, actions_taken: int) -> String:
	if _team_has_living_unit(units, TEAM_ALLY) and not _team_has_living_unit(units, TEAM_ENEMY):
		return "Result: Allies win after %d actions." % actions_taken

	if _team_has_living_unit(units, TEAM_ENEMY) and not _team_has_living_unit(units, TEAM_ALLY):
		return "Result: Enemies win after %d actions." % actions_taken

	return "Result: No winner after %d actions." % actions_taken
