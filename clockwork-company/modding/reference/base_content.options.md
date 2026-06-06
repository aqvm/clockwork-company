# JSON Content Options (Comprehensive)

This file documents every currently supported key, enum, and keyword for JSON content packs consumed by `res://scripts/modding/json_content_loader.gd`.

Keep this document and adjacent JSON examples updated whenever:
- a data field is added/removed/renamed
- an enum value changes
- validation rules change
- loader merge behavior changes

## Top-level keys

- `pack_id` (`String`, optional): human-readable identifier for the pack.
- `pack_version` (`int`, optional): pack author version.
- `ancestries` (`Array[Dictionary]`, optional)
- `items` (`Array[Dictionary]`, optional)
- `jobs` (`Array[Dictionary]`, optional)
- `tactics` (`Array[Dictionary]`, optional)
- `loadouts` (`Array[Dictionary]`, optional)
- `units` (`Array[Dictionary]`, optional)
- `demo_roster` (`Array[String]`, optional): ordered list of unit ids for the demo fight.

Unknown top-level keys are ignored by the current loader.

## Merge behavior

- Pack entries are merged by `id`.
- Later JSON files in `res://mods/` override earlier/base values key-by-key.
- Omitting a field preserves the previous value for that id.
- `demo_roster`, if present, fully replaces previous roster order.

## `ancestries[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `min_max_hp` / `max_max_hp` (`int`): future deterministic generation range for starting max HP.
- `min_physical_damage` / `max_physical_damage` (`int`): future generation range for starting physical damage.
- `min_magic_damage` / `max_magic_damage` (`int`): future generation range for starting magic damage.
- `min_armor` / `max_armor` (`int`): future generation range for starting armor.
- `min_action_interval` / `max_action_interval` (`int`): future generation range for starting action interval.
- `max_hp_growth` (`int`): baseline HP growth applied once per total unit job level.
- `physical_damage_growth` (`int`): baseline physical growth applied once per total unit job level.
- `magic_damage_growth` (`int`): baseline magic growth applied once per total unit job level.
- `armor_growth` (`int`): baseline armor growth applied once per total unit job level.
- `action_interval_growth` (`int`): baseline action interval adjustment applied once per total unit job level. Negative is faster.
- `feature` (`Dictionary`): always-on ancestry feature payload. See `ancestries[].feature` below.
- `notes` (`String`)

Current behavior:
- Existing units keep explicit authored stats. The min/max ranges are scaffolding for future unit creation, not randomization during combat.
- Ancestry growth stacks with job growth when a unit has job levels.
- Ancestry features are always active, regardless of current job or equipped learned abilities.

## `ancestries[].feature` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `trigger` (`String enum`): `Battle Start`, `Attack`, `Kill`, `Damaged`, `HP Below Threshold`
- `condition` (`String enum`): `Always`, `Self HP Below Percent`
- `feature_type` (`String enum`): `Gain Armor`, `Bonus Damage`, `Heal Self`, `Damage Attacker`, `Hasten Self`, `Gain Physical Damage`
- `amount` (`int`)
- `threshold_percent` (`int`, 1-100)
- `cooldown_turns` (`int`): unit-turn cooldown after the feature fires. `0` means no cooldown.
- `notes` (`String`)

Currently implemented ancestry feature behavior:
- `Battle Start` + `Gain Armor`
- `Attack` + `Bonus Damage`; a `magic` tag makes the bonus magic damage, otherwise physical.
- `Kill` + `Hasten Self` or `Gain Physical Damage`
- `Damaged` or `HP Below Threshold` + `Gain Armor`, `Heal Self`, or `Damage Attacker`

Reserved but not implemented:
- Equipment-slot capacity rules. The Typhon-born two-helmet idea is documented in its Resource notes but currently represented by a battle-start feature.

## `items[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`): freeform labels for future conditions, filtering, and content organization.
- `slot` (`String enum`): `Weapon`, `Armor`, `Helmet`, `Trinket`
- `max_hp_modifier` (`int`)
- `physical_damage_modifier` (`int`)
- `magic_damage_modifier` (`int`)
- `armor_modifier` (`int`)
- `action_interval_modifier` (`int`)
- `effects` (`Array[Dictionary]`): declarative authored effects. See `items[].effects[]` below.

Item effects must be authored in `effects[]`. The old top-level `trigger`, `effect`, and `effect_amount` item fields have been removed.

## `items[].effects[]` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`): effect labels used by tag conditions and future content tools.
- `trigger` (`String enum`): `Battle Start`, `Attack`, `Hit`, `Kill`, `Death`, `Damaged`, `HP Below Threshold`, `Every N Ticks`
- `condition` (`String enum`): `Always`, `Self HP Below Percent`, `Target Has Tag`, `Target Missing Tag`
- `target_selector` (`String enum`): `Self`, `Attack Target`, `Attacker`, `Killer`, `All Allies`, `All Enemies`, `Adjacent Allies`
- `effect_type` (`String enum`): `Gain Armor`, `Bonus Damage`, `Reduce Target Armor`, `Heal`, `Heal Self`, `Damage`, `Damage Killer`, `Increase Max HP`
- `amount` (`int`)
- `threshold_percent` (`int`, 1-100): used by `Self HP Below Percent` and `HP Below Threshold`.
- `interval_ticks` (`int`): reserved for `Every N Ticks`.
- `once_per_battle` (`bool`)

Currently implemented item effect combinations:
- `Battle Start` + `Gain Armor`
- `Attack` + `Bonus Damage`
- `Hit` + `Reduce Target Armor`
- `Kill` + `Heal` or `Heal Self`
- `Death` + `Damage Killer`
- `Damaged` or `HP Below Threshold` + `Heal`, `Heal Self`, or `Increase Max HP`

Reserved but not fully implemented yet:
- `Every N Ticks` needs periodic scheduler support.
- `Adjacent Allies` needs formation/adjacency support.
- `All Allies`, `All Enemies`, and direct `Damage` need multi-target/effect application support.

## `jobs[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `max_hp_growth` (`int`): permanent HP gained per level in this job.
- `physical_damage_growth` (`int`): permanent physical damage gained per level in this job.
- `magic_damage_growth` (`int`): permanent magic damage gained per level in this job.
- `armor_growth` (`int`): permanent armor gained per level in this job.
- `action_interval_growth` (`int`): permanent action interval adjustment per level. Negative is faster.
- `forbid_weapon` (`bool`): default `false`; when `true`, assigned weapon items are skipped.
- `forbid_armor` (`bool`): default `false`; when `true`, assigned armor items are skipped.
- `forbid_helmet` (`bool`): default `false`; when `true`, assigned helmet items are skipped.
- `forbid_trinket` (`bool`): default `false`; when `true`, assigned trinket items are skipped.
- `skill` (`Dictionary`): current job active skill payload. See `jobs[].skill` below.
- `passive` (`Dictionary`): current job passive payload. See `jobs[].passive` below.
- `reaction` (`Dictionary`): current job reaction payload. See `jobs[].reaction` below.
- `default_tactic` (`Dictionary`): tactic automatically appended while this is the unit's current job. See `jobs[].default_tactic` below.
- Job unlock timing is fixed: level 1 chooses skill or reaction, level 2 unlocks the passive, and level 3 unlocks the remaining skill or reaction.

Equipment note:
- Equipment is allowed by default. Use `forbid_weapon`, `forbid_armor`, `forbid_helmet`, and `forbid_trinket` only when a job concept explicitly forbids a category.
- Shields currently live inside `Weapon` or `Armor` item concepts. There is no offhand or one-hand/two-hand rules layer yet.

## `jobs[].skill` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `action` (`String enum`): `Attack`, `Heal`, `Guard`
- `default_target` (`String enum`): `Self`, `Lowest HP Ally`, `Frontmost Enemy`
- `amount_modifier` (`int`): added to the base action amount when the skill is used.

Currently implemented skill actions:
- `Attack`: performs a normal attack with `amount_modifier` as bonus damage.
- `Heal`: performs a normal heal with `amount_modifier` as bonus healing.
- `Guard`: performs a normal guard with `amount_modifier` as bonus temporary armor.

## `jobs[].passive` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `passive_type` (`String enum`): `None`, `Attack Damage Bonus`, `Heal Bonus`, `Guard Armor Bonus`
- `amount` (`int`)
- `cooldown_turns` (`int`): unit-turn cooldown after the passive fires. `0` means no cooldown.

## `jobs[].reaction` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `trigger` (`String enum`): `Damaged`, `HP Below Threshold`
- `condition` (`String enum`): `Always`, `Self HP Below Percent`
- `reaction_type` (`String enum`): `Gain Armor`, `Heal Self`, `Damage Attacker`
- `amount` (`int`)
- `threshold_percent` (`int`, 1-100): used by `Self HP Below Percent` and `HP Below Threshold`.
- `cooldown_turns` (`int`): unit-turn cooldown after the reaction fires. `0` means no cooldown.

Currently implemented reaction timing:
- Reactions are checked after a unit survives attack damage and item damaged effects.
- `Gain Armor` grants temporary guard armor.
- `Heal Self` heals the reacting unit.
- `Damage Attacker` damages the attacker and can defeat them.

## `jobs[].default_tactic` keys

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `condition` (`String enum`): `Always`, `Self HP Below Half`, `Ally HP Below Half`, `Enemy Alive`
- `action` (`String enum`): `Attack`, `Heal`, `Guard`, `Job Skill`
- `target` (`String enum`): `Self`, `Lowest HP Ally`, `Frontmost Enemy`

## `tactics[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `condition` (`String enum`): `Always`, `Self HP Below Half`, `Ally HP Below Half`, `Enemy Alive`
- `action` (`String enum`): `Attack`, `Heal`, `Guard`, `Job Skill`
- `target` (`String enum`): `Self`, `Lowest HP Ally`, `Frontmost Enemy`

## `loadouts[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `current_job_id` (`String` or empty string)
- `equipped_skill` (`Dictionary`): optional learned/equipped active skill override. If omitted or empty, the current job's skill is used.
- `equipped_passive` (`Dictionary`): optional learned/equipped passive override. If omitted or empty, the current job's passive is used.
- `equipped_reaction` (`Dictionary`): optional learned/equipped reaction override. If omitted or empty, the current job's reaction is used.
- `weapon_id` (`String` or empty string)
- `armor_id` (`String` or empty string)
- `helmet_id` (`String` or empty string)
- `trinket_id` (`String` or empty string)
- `tactic_ids` (`Array[String]`)

Reference rules:
- Non-empty `current_job_id` must reference an existing job id.
- Non-empty `weapon_id`/`armor_id`/`helmet_id`/`trinket_id` must reference existing item ids.
- Every `tactic_id` must reference an existing tactic id.

Equipped ability notes:
- `equipped_skill`, `equipped_passive`, and `equipped_reaction` use the same dictionary fields as `jobs[].skill`, `jobs[].passive`, and `jobs[].reaction`.
- These fields model a later learned-ability system without requiring progression UI yet.
- A loadout that equips a skill from another job should include a tactic that uses `Job Skill` with an appropriate target.

## `units[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `team` (`String enum`): `Allies`, `Enemies`
- `ancestry_id` (`String` or empty string)
- `max_hp` (`int`)
- `physical_damage` (`int`)
- `magic_damage` (`int`)
- `armor` (`int`)
- `action_interval` (`int`)
- `job_progress` (`Array[Dictionary]`): one unit's per-job levels and permanent unlocks. See `units[].job_progress[]` below.
- `loadout_id` (`String` or empty string)

Reference rules:
- Non-empty `ancestry_id` must reference an existing ancestry id.
- Non-empty `loadout_id` must reference an existing loadout id.

## `units[].job_progress[]` keys

Optional fields:
- `job_id` (`String`): must reference an existing job id.
- `level` (`int`, 0-3)
- `skill_unlocked` (`bool`)
- `passive_unlocked` (`bool`)
- `reaction_unlocked` (`bool`)
- `pending_unlock_choice` (`bool`): whether the unit must choose this job's skill or reaction before starting another campaign scenario.

Current progression behavior:
- A completed campaign scenario grants one level to one surviving deployed unit tied for the lowest total unit level.
- The recipient levels their current job. A job can reach level 3 and a unit can currently reach total level 5.
- A scenario tier prevents the scenario from advancing a unit beyond that tier.
- Failed and practice scenarios grant no levels.
- Unlocks are currently automatic based on the current job's configured unlock levels.

## Validation behavior

The loader currently validates:
- enum membership for all known enum fields
- reference existence across ids
- `demo_roster` ids exist in final merged units

Invalid data fails fast via `assert(...)` during load.
