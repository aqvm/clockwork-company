extends RefCounted
class_name ContentEffectSupport


static func support_error(effect: Dictionary) -> String:
	var trigger := String(effect.get("trigger", ""))
	var effect_type := String(effect.get("effect_type", ""))
	var target := String(effect.get("target_selector", ""))
	if ["Apply Status", "Remove Status", "Modify Stat"].has(effect_type) and trigger in ["Kill", "Death"] and target in ["Self", "Event Target"]:
		return "%s is defeated during %s and cannot receive %s" % [target, trigger, effect_type]
	if trigger == "Battle Start" and ["Event Source", "Event Target", "Attack Target", "Attacker", "Killer"].has(target):
		return "%s has no target during Battle Start" % target
	if target == "Attack Target" and not ["Attack", "Hit"].has(trigger):
		return "Attack Target is only available for Attack and Hit"
	if target == "Attacker" and not ["Damaged", "Physically Damaged", "Magically Damaged", "HP Below Threshold"].has(trigger):
		return "Attacker is only available for damage-received triggers"
	if target == "Killer" and trigger != "Death":
		return "Killer is only available for Death"
	if effect_type == "Apply Status" and String(effect.get("status_id", "")).is_empty():
		return "Apply Status requires status_id"
	if effect_type == "Maintain Status Aura" and String(effect.get("status_id", "")).is_empty():
		return "Maintain Status Aura requires status_id"
	if effect_type == "Maintain Status Aura" and trigger != "Battle State Changed":
		return "Maintain Status Aura requires Battle State Changed"
	if effect_type == "Replace Requested Status":
		if trigger != "Status Application Requested":
			return "Replace Requested Status requires Status Application Requested"
		if effect.get("replacement_status_ids", []).is_empty():
			return "Replace Requested Status requires replacement_status_ids"
	if effect_type in ["Consume Status", "Detonate Status", "Gather Status", "Fuse Elemental Ailments", "Restore Max HP Lost To Status"] and String(effect.get("status_id", "")).is_empty():
		return "%s requires status_id" % effect_type
	if effect_type == "Transfer Defeated Ailments" and (trigger != "Reaction Triggered" or target != "Most Ailmented Enemy Unit"):
		return "Transfer Defeated Ailments requires Reaction Triggered + Most Ailmented Enemy Unit"
	if effect_type == "Remove Status" and effect.get("status_removal_mode", "Random Matching") == "Specific Status" and String(effect.get("status_id", "")).is_empty():
		return "Specific Status removal requires status_id"
	if effect_type == "Modify Stat" and int(effect.get("amount", 0)) == 0 and effect.get("amount_source", "Fixed") == "Fixed":
		return "Modify Stat requires a non-zero amount"
	if effect.get("modifier_mode", "Temporary Flat") == "Dynamic Percent" and trigger != "Battle State Changed":
		return "Dynamic Percent modifiers require Battle State Changed"
	if effect_type == "Prevent Request" and not trigger in ["Damage Requested", "Healing Requested", "Reaction Requested", "Status Application Requested", "Status Removal Requested"]:
		return "Prevent Request requires a request trigger"
	if effect_type == "Execute Target" and (trigger != "Hit" or target != "Attack Target"):
		return "Execute Target requires Hit + Attack Target"
	if effect_type == "Begin Enemy Action Healing" and target != "Self":
		return "Begin Enemy Action Healing requires Self"
	if effect_type == "Prepare Base Attack" and target != "Self":
		return "Prepare Base Attack requires Self"
	if effect.get("condition", "") == "Requested Status Matches" and not trigger in ["Status Application Requested", "Status Removal Requested"]:
		return "Requested Status Matches requires a status request trigger"
	if effect.get("condition", "") == "Applied Status Matches" and not trigger in ["Status Applied", "Owner Applied Ailment", "Externally Sourced Status Applied", "Enemy Status Applied"]:
		return "Applied Status Matches requires a status-applied trigger"
	if effect_type in ["Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Fuse Elemental Ailments", "Transfer Defeated Ailments", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Apply Haste", "Increase Action Speed For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request", "Execute Target", "Begin Enemy Action Healing", "Prepare Base Attack"]:
		return ""
	if trigger == "Battle Start" and effect_type == "Gain Armor" and target == "Self":
		return ""
	if trigger == "Battle Start" and effect_type == "Apply Status" and target == "Self":
		return ""
	if trigger == "Attack" and effect_type == "Bonus Damage" and target == "Attack Target":
		return ""
	if trigger == "Hit" and effect_type == "Reduce Target Armor" and target == "Attack Target":
		return ""
	if (trigger == "Damaged" or trigger == "HP Below Threshold") and (effect_type == "Heal Self" or effect_type == "Increase Max HP") and target == "Self":
		return ""
	if trigger == "Kill" and effect_type == "Heal Self" and target == "Self":
		return ""
	if trigger == "Death" and effect_type == "Damage Killer" and target == "Killer":
		return ""
	return "%s + %s + %s is not supported" % [trigger, effect_type, target]
