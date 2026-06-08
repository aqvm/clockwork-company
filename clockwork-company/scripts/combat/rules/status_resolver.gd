extends RefCounted
class_name StatusResolver

const STATUS_CONFUSION := "Confusion"
const RULE_ASH_CHAPEL_CONFUSION := "ash_chapel_confusion"


static func apply_scenario_rule_statuses(log, units: Array, scenario_rules: Array, battle_start_entry_id: int) -> void:
	for rule in scenario_rules:
		if rule == null or String(rule.rule_id) != RULE_ASH_CHAPEL_CONFUSION:
			continue
		for unit in units:
			unit.add_status(STATUS_CONFUSION)
			log.add_child(battle_start_entry_id, "%s gains Confusion from %s." % [unit.unit_name, rule.display_name])
