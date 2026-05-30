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
const TRIGGER_NONE := "None"
const TRIGGER_BATTLE_START := "Battle Start"
const TRIGGER_ATTACK := "Attack"
const TRIGGER_HIT := "Hit"
const TRIGGER_KILL := "Kill"
const TRIGGER_DEATH := "Death"
const EFFECT_NONE := "None"
const EFFECT_GAIN_ARMOR := "Gain Armor"
const EFFECT_BONUS_DAMAGE := "Bonus Damage"
const EFFECT_REDUCE_TARGET_ARMOR := "Reduce Target Armor"
const EFFECT_HEAL_SELF := "Heal Self"
const EFFECT_DAMAGE_KILLER := "Damage Killer"
const CONDITION_ALWAYS := "Always"
const CONDITION_SELF_HP_BELOW_HALF := "Self HP Below Half"
const CONDITION_ALLY_HP_BELOW_HALF := "Ally HP Below Half"
const CONDITION_ENEMY_ALIVE := "Enemy Alive"
const ACTION_ATTACK := "Attack"
const ACTION_HEAL := "Heal"
const ACTION_GUARD := "Guard"
const TARGET_SELF := "Self"
const TARGET_LOWEST_HP_ALLY := "Lowest HP Ally"
const TARGET_FRONTMOST_ENEMY := "Frontmost Enemy"
const HEAL_AMOUNT := 5
const GUARD_ARMOR_AMOUNT := 2
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


class CombatLogEntry:
	var id := 0
	var parent_id := -1
	var time := -1
	var text := ""
	var child_ids: Array[int] = []

	func _init(entry_id: int, entry_text: String, entry_time: int = -1, entry_parent_id: int = -1) -> void:
		id = entry_id
		text = entry_text
		time = entry_time
		parent_id = entry_parent_id
		child_ids = []


class CombatLog:
	const NO_TIME := -1
	const NO_PARENT := -1
	const CHILD_INDENT := "      "

	var entries: Array[CombatLogEntry] = []
	var root_ids: Array[int] = []
	var next_id := 0

	func add(text: String) -> int:
		return _add_entry(text, NO_TIME, NO_PARENT)

	func add_at_time(time: int, text: String) -> int:
		return _add_entry(text, time, NO_PARENT)

	func add_child(parent_id: int, text: String) -> int:
		return _add_entry(text, NO_TIME, parent_id)

	func to_lines() -> Array[String]:
		var lines: Array[String] = []
		for entry_id in root_ids:
			_append_entry_lines(lines, entry_id, 0)
		return lines

	func _add_entry(text: String, time: int, parent_id: int) -> int:
		var entry_id := next_id
		next_id += 1

		var entry := CombatLogEntry.new(entry_id, text, time, parent_id)
		entries.append(entry)

		if parent_id == NO_PARENT:
			root_ids.append(entry_id)
		else:
			entries[parent_id].child_ids.append(entry_id)

		return entry_id

	func _append_entry_lines(lines: Array[String], entry_id: int, depth: int) -> void:
		var entry := entries[entry_id]
		lines.append(_format_entry(entry, depth))
		for child_id in entry.child_ids:
			_append_entry_lines(lines, child_id, depth + 1)

	func _format_entry(entry: CombatLogEntry, depth: int) -> String:
		if entry.text.is_empty():
			return ""

		var indentation := ""
		for count in depth:
			indentation += CHILD_INDENT

		if entry.time == NO_TIME:
			return "%s%s" % [indentation, entry.text]

		return "%st=%03d | %s" % [indentation, entry.time, entry.text]


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
	var tactics: Array = []
	var guard_armor := 0

	# `func` declares a function. `_init` is Godot's constructor hook, called
	# when code uses `UnitState.new(...)`. The text after `:` gives parameter
	# types, and `-> void` means this function does not return a value.
	func _init(
		definition: UnitDefinition,
		unit_slot_index: int,
		equipped_item_definition: ItemDefinition = null,
		tactic_definitions: Array = []
	) -> void:
		# Dot syntax reads exported properties from the UnitDefinition Resource.
		unit_name = definition.display_name
		team = definition.team
		max_hp = definition.max_hp
		damage = definition.damage
		armor = definition.armor
		action_interval = definition.action_interval
		slot_index = unit_slot_index
		equipped_item = equipped_item_definition
		tactics = tactic_definitions

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

	func total_armor() -> int:
		return armor + guard_armor


# `Array[String]` is a typed array: this function promises to return an array
# whose entries are strings.
func run_demo_battle() -> Array[String]:
	# Calling a function with `()` runs it and gives back its return value.
	var units := _create_demo_units()
	var log := CombatLog.new()
	var actions_taken := 0

	# Root log entries appear at the left edge; child entries render indented
	# below the parent entry they explain.
	log.add("Phase 5 demo battle")
	log.add("Random seed: none yet. This fight is deterministic because there are no random rolls.")
	log.add("Tie-breaker: if two units are ready at the same time, earlier roster position acts first.")
	log.add("Unit definitions: loaded from Resource files in res://resources/units/.")
	log.add("Item definitions: loaded from Resource files in res://resources/items/.")
	log.add("Tactics: fixed demo priority lists using condition -> action -> target rules.")
	log.add("")
	_append_gear_summary(log, units)
	log.add("")
	_append_tactics_summary(log, units)
	log.add("")
	_apply_battle_start_item_effects(log, units)
	log.add("")
	_append_roster(log, units)
	log.add("")
	log.add("Combat log:")

	# `while` repeats the indented block as long as its condition stays true.
	# `and` combines two boolean checks, so both teams must still have units alive.
	while _team_has_living_unit(units, TEAM_ALLY) and _team_has_living_unit(units, TEAM_ENEMY):
		# `if` runs its indented block only when the condition is true.
		if actions_taken >= MAX_ACTIONS:
			# `%` formats values into a string. `%d` is a placeholder for an integer.
			log.add("Battle stopped after %d actions to avoid an infinite fight." % MAX_ACTIONS)
			# `break` exits the nearest loop immediately.
			break

		# `var actor: UnitState` declares a variable with an explicit custom type.
		var actor: UnitState = _find_next_actor(units)
		var current_time := actor.next_action_time
		var turn_entry_id := log.add_at_time(current_time, "%s takes a turn." % actor.unit_name)

		_clear_guard_if_needed(log, turn_entry_id, actor)
		_take_tactical_action(log, turn_entry_id, actor, units)
		actions_taken += 1

		# `+=` is shorthand for assigning the old value plus something else.
		actor.next_action_time += actor.action_interval

	log.add("")
	log.add(_build_result_line(units, actions_taken))
	return log.to_lines()


func _create_demo_units() -> Array:
	var units: Array = []
	var demo_tactics := _create_demo_tactics()
	# `for ... in ...` loops over each value in a collection. `DEMO_UNIT_DEFINITIONS.size()`
	# returns an integer, and Godot treats that as the range `0` through `size - 1`.
	for index in DEMO_UNIT_DEFINITIONS.size():
		units.append(UnitState.new(DEMO_UNIT_DEFINITIONS[index], index, DEMO_EQUIPPED_ITEMS[index], demo_tactics[index]))
	return units


func _create_demo_tactics() -> Array:
	return [
		[
			_create_tactic(CONDITION_ENEMY_ALIVE, ACTION_GUARD, TARGET_SELF),
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
		[
			_create_tactic(CONDITION_ALLY_HP_BELOW_HALF, ACTION_HEAL, TARGET_LOWEST_HP_ALLY),
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
		[
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
		[
			_create_tactic(CONDITION_ENEMY_ALIVE, ACTION_GUARD, TARGET_SELF),
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
		[
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
		[
			_create_tactic(CONDITION_ALLY_HP_BELOW_HALF, ACTION_HEAL, TARGET_LOWEST_HP_ALLY),
			_create_tactic(CONDITION_ALWAYS, ACTION_ATTACK, TARGET_FRONTMOST_ENEMY),
		],
	]


func _create_tactic(condition: String, action: String, target: String) -> TacticDefinition:
	var tactic := TacticDefinition.new()
	tactic.condition = condition
	tactic.action = action
	tactic.target = target
	return tactic


func _append_gear_summary(log: CombatLog, units: Array) -> void:
	var gear_entry_id := log.add("Equipped gear:")
	for unit: UnitState in units:
		if unit.equipped_item == null:
			log.add_child(gear_entry_id, "%s: none" % unit.unit_name)
		else:
			log.add_child(gear_entry_id, "%s: %s" % [unit.unit_name, _describe_item(unit.equipped_item)])


func _append_tactics_summary(log: CombatLog, units: Array) -> void:
	var tactics_entry_id := log.add("Demo tactics:")
	for unit: UnitState in units:
		var tactic_texts: Array[String] = []
		for tactic: TacticDefinition in unit.tactics:
			tactic_texts.append(_describe_tactic(tactic))
		log.add_child(tactics_entry_id, "%s: %s" % [unit.unit_name, _join_text_parts(tactic_texts, "; ")])


func _apply_battle_start_item_effects(log: CombatLog, units: Array) -> void:
	var battle_start_entry_id := log.add("Battle start item effects:")
	var any_effects := false
	for unit: UnitState in units:
		if not _item_has_trigger(unit.equipped_item, TRIGGER_BATTLE_START):
			continue

		any_effects = true
		if unit.equipped_item.effect == EFFECT_GAIN_ARMOR:
			unit.armor = max(0, unit.armor + unit.equipped_item.effect_amount)
			log.add_child(
				battle_start_entry_id,
				"%s triggers %s: gains %d armor for this battle."
				% [unit.unit_name, unit.equipped_item.display_name, unit.equipped_item.effect_amount]
			)
		else:
			log.add_child(battle_start_entry_id, _unsupported_effect_text(unit, TRIGGER_BATTLE_START))

	if not any_effects:
		log.add_child(battle_start_entry_id, "none")


func _apply_attack_item_effects(log: CombatLog, parent_entry_id: int, actor: UnitState, target: UnitState) -> int:
	if not _item_has_trigger(actor.equipped_item, TRIGGER_ATTACK):
		return 0

	if actor.equipped_item.effect == EFFECT_BONUS_DAMAGE:
		log.add_child(
			parent_entry_id,
			"%s triggers %s on attack: +%d damage against %s."
			% [actor.unit_name, actor.equipped_item.display_name, actor.equipped_item.effect_amount, target.unit_name]
		)
		return actor.equipped_item.effect_amount

	log.add_child(parent_entry_id, _unsupported_effect_text(actor, TRIGGER_ATTACK))
	return 0


func _apply_hit_item_effects(log: CombatLog, parent_entry_id: int, actor: UnitState, target: UnitState) -> void:
	if not _item_has_trigger(actor.equipped_item, TRIGGER_HIT):
		return

	if actor.equipped_item.effect == EFFECT_REDUCE_TARGET_ARMOR:
		_reduce_target_armor(log, parent_entry_id, actor, target)
		return

	log.add_child(parent_entry_id, _unsupported_effect_text(actor, TRIGGER_HIT))


func _reduce_target_armor(log: CombatLog, parent_entry_id: int, actor: UnitState, target: UnitState) -> void:
	var previous_base_armor := target.armor
	var previous_guard_armor := target.guard_armor
	var remaining_reduction := actor.equipped_item.effect_amount

	if target.armor > 0:
		var base_reduction: int = min(target.armor, remaining_reduction)
		target.armor -= base_reduction
		remaining_reduction -= base_reduction

	if remaining_reduction > 0 and target.guard_armor > 0:
		var guard_reduction: int = min(target.guard_armor, remaining_reduction)
		target.guard_armor -= guard_reduction

	log.add_child(
		parent_entry_id,
		"%s triggers %s on hit: %s base armor %d -> %d, temporary armor %d -> %d."
		% [
			actor.unit_name,
			actor.equipped_item.display_name,
			target.unit_name,
			previous_base_armor,
			target.armor,
			previous_guard_armor,
			target.guard_armor,
		]
	)


func _apply_kill_item_effects(log: CombatLog, parent_entry_id: int, actor: UnitState) -> void:
	if not _item_has_trigger(actor.equipped_item, TRIGGER_KILL):
		return

	if actor.equipped_item.effect == EFFECT_HEAL_SELF:
		var previous_hp := actor.hp
		actor.hp = min(actor.max_hp, actor.hp + actor.equipped_item.effect_amount)
		log.add_child(
			parent_entry_id,
			"%s triggers %s on kill: heals %d -> %d HP."
			% [actor.unit_name, actor.equipped_item.display_name, previous_hp, actor.hp]
		)
		return

	log.add_child(parent_entry_id, _unsupported_effect_text(actor, TRIGGER_KILL))


func _apply_death_item_effects(log: CombatLog, parent_entry_id: int, defeated_unit: UnitState, killer: UnitState) -> void:
	if not _item_has_trigger(defeated_unit.equipped_item, TRIGGER_DEATH):
		return

	if defeated_unit.equipped_item.effect == EFFECT_DAMAGE_KILLER:
		var previous_hp := killer.hp
		killer.hp = max(0, killer.hp - defeated_unit.equipped_item.effect_amount)
		log.add_child(
			parent_entry_id,
			"%s triggers %s on death: %s HP %d -> %d."
			% [defeated_unit.unit_name, defeated_unit.equipped_item.display_name, killer.unit_name, previous_hp, killer.hp]
		)
		if not killer.is_alive():
			log.add_child(parent_entry_id, "%s is defeated by the death effect." % killer.unit_name)
		return

	log.add_child(parent_entry_id, _unsupported_effect_text(defeated_unit, TRIGGER_DEATH))


func _append_roster(log: CombatLog, units: Array) -> void:
	var roster_entry_id := log.add("Roster:")
	# This loop uses an inline array literal so the roster prints allies first,
	# then enemies.
	for team in [TEAM_ALLY, TEAM_ENEMY]:
		var team_entry_id := log.add_child(roster_entry_id, "%s" % team)
		# `for unit: UnitState in units` adds a type hint to each loop variable.
		for unit: UnitState in units:
			if unit.team == team:
				log.add_child(
					team_entry_id,
					"%s | HP %d | damage %d | armor %d | interval %d | item %s | tactics %d"
					% [unit.unit_name, unit.max_hp, unit.damage, unit.total_armor(), unit.action_interval, _item_name_or_none(unit), unit.tactics.size()]
				)


func _take_tactical_action(log: CombatLog, turn_entry_id: int, actor: UnitState, units: Array) -> void:
	for tactic: TacticDefinition in actor.tactics:
		if not _condition_matches(tactic.condition, actor, units):
			continue

		var target := _find_tactic_target(tactic.target, actor, units)
		if target == null:
			log.add_child(turn_entry_id, "Tactic skipped: %s. No valid target." % _describe_tactic(tactic))
			continue

		log.add_child(
			turn_entry_id,
			"Tactic selected: %s. Condition true; target is %s."
			% [_describe_tactic(tactic), target.unit_name]
		)
		_resolve_tactic_action(log, turn_entry_id, actor, target, tactic.action)
		return

	var fallback_target := _find_frontmost_target(units, _opposing_team(actor.team))
	log.add_child(turn_entry_id, "No tactic matched; default attack used against %s." % fallback_target.unit_name)
	_resolve_attack(log, turn_entry_id, actor, fallback_target)


func _resolve_tactic_action(
	log: CombatLog,
	turn_entry_id: int,
	actor: UnitState,
	target: UnitState,
	action: String
) -> void:
	if action == ACTION_HEAL:
		_resolve_heal(log, turn_entry_id, actor, target)
		return

	if action == ACTION_GUARD:
		_resolve_guard(log, turn_entry_id, actor)
		return

	_resolve_attack(log, turn_entry_id, actor, target)


func _resolve_attack(log: CombatLog, turn_entry_id: int, actor: UnitState, target: UnitState) -> void:
	var attack_entry_id := log.add_child(turn_entry_id, "%s attacks %s." % [actor.unit_name, target.unit_name])
	var bonus_damage := _apply_attack_item_effects(log, attack_entry_id, actor, target)
	var target_armor := target.total_armor()
	var damage_taken: int = max(1, actor.damage + bonus_damage - target_armor)
	var previous_hp := target.hp

	target.hp = max(0, target.hp - damage_taken)

	log.add_child(
		attack_entry_id,
		"Damage dealt: %d. %s armor: %d. HP: %d -> %d."
		% [damage_taken, target.unit_name, target_armor, previous_hp, target.hp]
	)

	if target.is_alive():
		_apply_hit_item_effects(log, attack_entry_id, actor, target)

	# `not` flips a boolean value, so this means "if the target is not alive."
	if not target.is_alive():
		log.add_child(attack_entry_id, "%s is defeated." % target.unit_name)
		_apply_kill_item_effects(log, attack_entry_id, actor)
		_apply_death_item_effects(log, attack_entry_id, target, actor)


func _resolve_heal(log: CombatLog, turn_entry_id: int, actor: UnitState, target: UnitState) -> void:
	var previous_hp := target.hp
	target.hp = min(target.max_hp, target.hp + HEAL_AMOUNT)
	log.add_child(
		turn_entry_id,
		"%s heals %s for %d HP. HP: %d -> %d."
		% [actor.unit_name, target.unit_name, target.hp - previous_hp, previous_hp, target.hp]
	)


func _resolve_guard(log: CombatLog, turn_entry_id: int, actor: UnitState) -> void:
	actor.guard_armor = GUARD_ARMOR_AMOUNT
	log.add_child(
		turn_entry_id,
		"%s guards: temporary armor +%d until their next turn. Armor is now %d."
		% [actor.unit_name, actor.guard_armor, actor.total_armor()]
	)


func _clear_guard_if_needed(log: CombatLog, turn_entry_id: int, actor: UnitState) -> void:
	if actor.guard_armor == 0:
		return

	var previous_armor := actor.total_armor()
	log.add_child(
		turn_entry_id,
		"%s's guard expires: armor %d -> %d."
		% [actor.unit_name, previous_armor, actor.armor]
	)
	actor.guard_armor = 0


func _condition_matches(condition: String, actor: UnitState, units: Array) -> bool:
	if condition == CONDITION_ALWAYS:
		return true

	if condition == CONDITION_SELF_HP_BELOW_HALF:
		return _is_below_half_hp(actor)

	if condition == CONDITION_ALLY_HP_BELOW_HALF:
		return _find_lowest_hp_ally_below_half(units, actor.team) != null

	if condition == CONDITION_ENEMY_ALIVE:
		return _team_has_living_unit(units, _opposing_team(actor.team))

	return false


func _find_tactic_target(target_rule: String, actor: UnitState, units: Array) -> UnitState:
	if target_rule == TARGET_SELF:
		return actor

	if target_rule == TARGET_LOWEST_HP_ALLY:
		return _find_lowest_hp_ally_below_half(units, actor.team)

	if target_rule == TARGET_FRONTMOST_ENEMY:
		return _find_frontmost_target(units, _opposing_team(actor.team))

	return null


func _find_lowest_hp_ally_below_half(units: Array, team: String) -> UnitState:
	var lowest_ally: UnitState = null
	for unit: UnitState in units:
		if unit.team != team or not unit.is_alive() or not _is_below_half_hp(unit):
			continue

		if lowest_ally == null:
			lowest_ally = unit
		elif unit.hp < lowest_ally.hp:
			lowest_ally = unit
		elif unit.hp == lowest_ally.hp and unit.slot_index < lowest_ally.slot_index:
			lowest_ally = unit

	return lowest_ally


func _is_below_half_hp(unit: UnitState) -> bool:
	return unit.hp * 2 < unit.max_hp


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
	return "%s [%s] (%s; %s)" % [item.display_name, item.slot, _describe_item_modifiers(item), _describe_item_effect(item)]


func _describe_tactic(tactic: TacticDefinition) -> String:
	return "%s -> %s -> %s" % [tactic.condition, tactic.action, tactic.target]


func _describe_item_modifiers(item: ItemDefinition) -> String:
	var parts: Array[String] = []
	_append_modifier_text(parts, "HP", item.max_hp_modifier)
	_append_modifier_text(parts, "damage", item.damage_modifier)
	_append_modifier_text(parts, "armor", item.armor_modifier)
	_append_modifier_text(parts, "interval", item.action_interval_modifier)

	if parts.is_empty():
		return "no stat changes"

	return _join_text_parts(parts, ", ")


func _describe_item_effect(item: ItemDefinition) -> String:
	if item.trigger == TRIGGER_NONE or item.effect == EFFECT_NONE or item.effect_amount == 0:
		return "no triggered effect"

	return "%s -> %s %d" % [item.trigger, item.effect, item.effect_amount]


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


func _item_has_trigger(item: ItemDefinition, trigger: String) -> bool:
	return item != null and item.trigger == trigger and item.effect != EFFECT_NONE and item.effect_amount != 0


func _unsupported_effect_text(unit: UnitState, trigger: String) -> String:
	return "%s triggers %s on %s, but that effect is not implemented yet." % [
		unit.unit_name,
		unit.equipped_item.display_name,
		trigger.to_lower()
	]


func _build_result_line(units: Array, actions_taken: int) -> String:
	if _team_has_living_unit(units, TEAM_ALLY) and not _team_has_living_unit(units, TEAM_ENEMY):
		return "Result: Allies win after %d actions." % actions_taken

	if _team_has_living_unit(units, TEAM_ENEMY) and not _team_has_living_unit(units, TEAM_ALLY):
		return "Result: Enemies win after %d actions." % actions_taken

	return "Result: No winner after %d actions." % actions_taken
