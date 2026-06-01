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

## `items[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`): freeform labels for future conditions, filtering, and content organization.
- `slot` (`String enum`): `Weapon`, `Armor`, `Trinket`
- `max_hp_modifier` (`int`)
- `damage_modifier` (`int`)
- `armor_modifier` (`int`)
- `action_interval_modifier` (`int`)
- `effects` (`Array[Dictionary]`): declarative authored effects. See `items[].effects[]` below.
- `trigger` (`String enum`): `None`, `Battle Start`, `Attack`, `Hit`, `Kill`, `Death`
- `effect` (`String enum`): `None`, `Gain Armor`, `Bonus Damage`, `Reduce Target Armor`, `Heal Self`, `Damage Killer`
- `effect_amount` (`int`)

Compatibility note:
- `trigger`, `effect`, and `effect_amount` are the legacy one-effect item fields.
- Prefer `effects` for new content.
- If an item has matching authored `effects`, the resolver uses those for that trigger. If no authored effect matches a trigger, the legacy fields still work as fallback.

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
- `max_hp_modifier` (`int`)
- `damage_modifier` (`int`)
- `armor_modifier` (`int`)
- `action_interval_modifier` (`int`)
- `can_equip_weapon` (`bool`)
- `can_equip_armor` (`bool`)
- `can_equip_trinket` (`bool`)
- `job_effect` (`String enum`): `None`, `Guard Training`, `First Aid`, `Sharpened Edge`

## `tactics[]` keys

Required:
- `id` (`String`)

Optional fields:
- `tags` (`Array[String]`)
- `condition` (`String enum`): `Always`, `Self HP Below Half`, `Ally HP Below Half`, `Enemy Alive`
- `action` (`String enum`): `Attack`, `Heal`, `Guard`
- `target` (`String enum`): `Self`, `Lowest HP Ally`, `Frontmost Enemy`

## `loadouts[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `current_job_id` (`String` or empty string)
- `weapon_id` (`String` or empty string)
- `armor_id` (`String` or empty string)
- `trinket_id` (`String` or empty string)
- `tactic_ids` (`Array[String]`)

Reference rules:
- Non-empty `current_job_id` must reference an existing job id.
- Non-empty `weapon_id`/`armor_id`/`trinket_id` must reference existing item ids.
- Every `tactic_id` must reference an existing tactic id.

## `units[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tags` (`Array[String]`)
- `team` (`String enum`): `Allies`, `Enemies`
- `max_hp` (`int`)
- `damage` (`int`)
- `armor` (`int`)
- `action_interval` (`int`)
- `loadout_id` (`String` or empty string)

Reference rules:
- Non-empty `loadout_id` must reference an existing loadout id.

## Validation behavior

The loader currently validates:
- enum membership for all known enum fields
- reference existence across ids
- `demo_roster` ids exist in final merged units

Invalid data fails fast via `assert(...)` during load.
