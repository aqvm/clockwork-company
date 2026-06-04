extends RefCounted
class_name CombatEventSchema

const EVENT_TEXT := "text"
const EVENT_BATTLE_START := "battle_start"
const EVENT_TURN_START := "turn_start"
const EVENT_TACTIC_SELECTED := "tactic_selected"
const EVENT_TACTIC_SKIPPED := "tactic_skipped"
const EVENT_TACTIC_FALLBACK := "tactic_fallback"
const EVENT_ATTACK := "attack"
const EVENT_DAMAGE := "damage"
const EVENT_HEAL := "heal"
const EVENT_GUARD := "guard"
const EVENT_GUARD_EXPIRE := "guard_expire"
const EVENT_DEFEAT := "defeat"
const EVENT_JOB_EFFECT := "job_effect"
const EVENT_ANCESTRY_FEATURE := "ancestry_feature"
const EVENT_ITEM_TRIGGER := "item_trigger"
const EVENT_RESULT := "result"

const REQUIRED_KEYS := {
	EVENT_TEXT: [],
	EVENT_BATTLE_START: [],
	EVENT_TURN_START: ["actor_id", "actor"],
	EVENT_TACTIC_SELECTED: ["actor_id", "actor", "action", "target_id", "target"],
	EVENT_TACTIC_SKIPPED: ["actor_id", "actor", "reason"],
	EVENT_TACTIC_FALLBACK: ["actor_id", "actor", "target_id", "target"],
	EVENT_ATTACK: ["actor_id", "actor", "target_id", "target"],
	EVENT_DAMAGE: ["actor_id", "actor", "target_id", "target", "amount", "previous_hp", "new_hp"],
	EVENT_HEAL: ["actor_id", "actor", "target_id", "target", "amount", "previous_hp", "new_hp"],
	EVENT_GUARD: ["actor_id", "actor", "guard_armor", "new_total_armor"],
	EVENT_GUARD_EXPIRE: ["actor_id", "actor", "previous_armor", "new_armor"],
	EVENT_DEFEAT: ["target_id", "target"],
	EVENT_JOB_EFFECT: ["actor_id", "actor", "effect"],
	EVENT_ANCESTRY_FEATURE: ["actor_id", "actor", "feature"],
	EVENT_ITEM_TRIGGER: ["actor_id", "actor", "item", "trigger", "effect"],
	EVENT_RESULT: ["result_text"],
}


static func required_keys(event_type: String) -> Array:
	return REQUIRED_KEYS.get(event_type, [])


static func is_known_event_type(event_type: String) -> bool:
	return REQUIRED_KEYS.has(event_type)
