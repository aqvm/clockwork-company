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
- `statuses` (`Array[Dictionary]`, optional)
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

## `statuses[]` keys

Required:
- `id` (`String`): stable reference used by skills and effects.

Optional fields:
- `display_name` (`String`)
- `polarity` (`String enum`): `Boon`, `Ailment`
- `status_type` (`String enum`): `Confusion`, `Reconstitution`, `Regeneration`, `Bleed`, `Burning`, `Numb`, `Frost`, `Shock`, `Elemental Fusion`, `Ward`, `Rot`, `Renewal`
- `stacking_rule` (`String enum`): `Ignore`, `Refresh`, `Intensify`
- `default_duration_turns` (`int`, default `3`): affected owner turns used by status applications unless the skill/effect sets `override_status_duration`.
- `default_is_permanent` (`bool`, default `false`): when true, status applications are permanent unless the skill/effect sets `override_status_duration`.
- `stack_cap_enabled` (`bool`, default `true`): when false, an `Intensify` status can accumulate without a maximum.
- `max_stacks` (`int`, minimum `1`)
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `amount` (`int`, minimum `0`): flat amount used by statuses such as Bleed.
- `amount_percent` (`int`, 1-100): percentage used by statuses such as Reconstitution, Frost, and Elemental Fusion's physical amplification.
- `propagation_percent` (`int`, 1-100): percentage of incoming pre-shield magic damage propagated by Shock and Elemental Fusion.
- `elapses_naturally` (`bool`, default `true`): when false, owner turns do not reduce finite duration; explicit removal is required.
- `description` (`String`)

Current status behavior:
- Statuses are battle-local, keep one runtime instance per status identity, and reset between encounters.
- Applications are finite by default. Finite duration counts owner turns on which the status was active at turn start.
- `Ignore` rejects reapplication.
- `Refresh` keeps one stack and refreshes duration to the longer existing/incoming duration.
- `Intensify` adds one stack and refreshes duration to the longer existing/incoming duration. It stops at `max_stacks` only when `stack_cap_enabled` is true.
- Sources can explicitly apply a permanent status; Burned Chapel's scenario rule does this for Confusion.
- `Confusion` skips the first otherwise-valid tactic each turn.
- `Reconstitution` intensifies to three stacks. At turn start it restores 50%/75%/100% of damage received since the previous turn at 1/2/3 stacks, rounded down, then consumes one stack only if HP was restored. Consuming the final stack removes the boon.
- `Bleed` intensifies to five stacks and deals its authored `amount` per stack after the afflicted unit completes an action. It does not expire naturally.
- `Numb` prevents the afflicted unit's reactions from triggering.
- `Frost` is uncapped. The next physical damage request against the afflicted unit gains the authored `amount_percent` of its post-armor physical damage per stack, rounded up, then Frost is removed. Nonphysical damage does not consume it.
- `Shock` is uncapped and does not elapse naturally. When incoming magic damage can propagate at least 1 damage, Shock consumes one stack and arcs its authored `propagation_percent`, rounded down, to at most three other living allies. It uses incoming pre-Energy-Shield magic damage capped by the target's pre-hit HP plus Energy Shield, so overkill does not inflate arcs. Recipients prioritize highest combined Shock and Elemental Fusion stacks, then lowest Energy Shield, then stable roster order. Arc damage is magic damage, preserves the original source, and can recursively discharge conductive ailments.
- `Elemental Fusion` is an uncapped composite ailment. It deals authored `amount` action damage per stack and consumes one stack like Burning; amplifies physical damage by `amount_percent` per stack and is removed like Frost; and propagates `propagation_percent` of incoming magic damage while consuming one stack like Shock.
- `Burning` is uncapped. It deals its authored `amount` per stack after the afflicted unit completes an action, then loses one stack. Healing or protecting a Burning unit immediately Scorches the supporter, delaying their next action by 2 per current Burn stack. Scorched is a named timeline consequence/event, not a status.
- `Ward` consumes one stack to prevent an incoming ailment.
- `Rot` reduces maximum HP by its authored `amount` per stack whenever actual healing lands.
- `Renewal` heals its authored `amount` per stack whenever an ailment is removed from its unit.

## `ancestries[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `min_max_hp` / `max_max_hp` (`int`): future deterministic generation range for starting max HP.
- `min_physical_damage` / `max_physical_damage` (`int`): future generation range for starting physical damage.
- `min_magic_damage` / `max_magic_damage` (`int`): future generation range for starting magic damage.
- `min_armor` / `max_armor` (`int`): future generation range for starting armor.
- `min_action_speed` / `max_action_speed` (`int`): future generation range for starting action speed.
- `max_hp_growth` (`int`): baseline HP growth applied once per total unit job level.
- `physical_damage_growth` (`int`): baseline physical growth applied once per total unit job level.
- `magic_damage_growth` (`int`): baseline magic growth applied once per total unit job level.
- `armor_growth` (`int`): baseline armor growth applied once per total unit job level.
- `action_speed_growth` (`int`): baseline action speed adjustment applied once per total unit job level. Positive is faster.
- `forbid_weapon` (`bool`): default `false`; when `true`, this ancestry cannot equip weapons.
- `forbid_armor` (`bool`): default `false`; when `true`, this ancestry cannot equip armor.
- `forbid_helmet` (`bool`): default `false`; when `true`, this ancestry cannot equip helmets.
- `forbid_trinket` (`bool`): default `false`; when `true`, this ancestry cannot equip trinkets.
- `feature` (`Dictionary`): always-on ancestry feature payload. See `ancestries[].feature` below.
- `notes` (`String`)

Current behavior:
- Existing units keep explicit authored stats. The min/max ranges are scaffolding for future unit creation, not randomization during combat.
- Ancestry growth stacks with job growth when a unit has job levels.
- Ancestry features are always active, regardless of current job or equipped learned abilities.

## `ancestries[].feature` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `trigger` (`String enum`): `Battle Start`, `Attack`, `Kill`, `Damaged`, `HP Below Threshold`
- `condition` (`String enum`): `Always`, `Self HP Below Percent`
- `feature_type` (`String enum`): `Gain Armor`, `Bonus Damage`, `Heal Self`, `Damage Attacker`, `Increase Own Action Speed`, `Gain Physical Damage`
- `amount` (`int`)
- `threshold_percent` (`int`, 1-100)
- `cooldown_turns` (`int`): unit-turn cooldown after the feature fires. `0` means no cooldown.
- `notes` (`String`)

Currently implemented ancestry feature behavior:
- `Battle Start` + `Gain Armor`
- `Attack` + `Bonus Damage`; a `magic` tag makes the bonus magic damage, otherwise physical.
- `Kill` + `Increase Own Action Speed` or `Gain Physical Damage`
- `Damaged` or `HP Below Threshold` + `Gain Armor`, `Heal Self`, or `Damage Attacker`

Reserved but not implemented:
- Equipment-slot capacity rules. The Typhon-born two-helmet idea is documented in its Resource notes but currently represented by a battle-start feature.

## `items[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs for future conditions, filtering, and content organization. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `slot` (`String enum`): `Weapon`, `Armor`, `Helmet`, `Trinket`
- `max_hp_modifier` (`int`)
- `physical_damage_modifier` (`int`)
- `magic_damage_modifier` (`int`)
- `armor_modifier` (`int`)
- `action_speed_modifier` (`int`)
- `effects` (`Array[Dictionary]`): declarative authored effects. See `items[].effects[]` below.

Item effects must be authored in `effects[]`. The old top-level `trigger`, `effect`, and `effect_amount` item fields have been removed.

## `items[].effects[]` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs used by tag conditions and future content tools. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `trigger` (`String enum`): `Battle Start`, `Battle State Changed`, `Turn Start`, `Turn Complete`, `Action Completed`, `Skill Used`, `Skill Completed`, `Attack`, `Consecutive Attack`, `Enemy Attack Targeted`, `Hit`, `Kill`, `Death`, `Ailment Damaged`, `Damaged`, `Physically Damaged`, `Magically Damaged`, `HP Below Threshold`, `Damage Requested`, `Healing Requested`, `Healing Received`, `Ally Overhealed`, `Reaction Requested`, `Status Application Requested`, `Status Removal Requested`, `Status Applied`, `Owner Applied Ailment`, `Externally Sourced Status Applied`, `Enemy Status Applied`, `Status Removed`, `Reaction Triggered`
- `condition` (`String enum`): `Always`, `Event Source Is Not Owner`, `Owner Is Unarmed`, `Event Count At Least`, `Self HP Below Percent`, `Target Has Tag`, `Target Missing Tag`, `Target Status Stacks At Least`, `Target Pending Status Damage At Least HP`, `Owner Counter At Least`, `Target Counter At Least`, `Requested Status Matches`, `Applied Status Matches`
- `target_selector` (`String enum`): `Self`, `Event Source`, `Event Target`, `Attack Target`, `Attacker`, `Killer`, `All Units`, `Allied Units`, `Enemy Units`, `Lowest HP Allied Unit`, `Random Allied Unit`, `Random Damaged Allied Unit`, `Random Enemy Unit`, `Most Ailmented Enemy Unit`
- `effect_type` (`String enum`): `Gain Armor`, `Bonus Damage`, `Reduce Target Armor`, `Heal Self`, `Damage Killer`, `Increase Max HP`, `Apply Status`, `Maintain Status Aura`, `Replace Requested Status`, `Remove Status`, `Consume Status`, `Detonate Status`, `Gather Status`, `Transfer Statuses`, `Fuse Elemental Ailments`, `Transfer Defeated Ailments`, `Restore Max HP Lost To Status`, `Deal Damage`, `Heal`, `Grant Armor`, `Grant Battle Armor`, `Grant Energy Shield`, `Disable Armor`, `Delay Action`, `Apply Haste`, `Increase Action Speed For Battle`, `Fortify Damage`, `Redirect Enemy Attacks`, `Add Attack Damage`, `Modify Stat`, `Modify Counter`, `Reset Counter`, `Seal Next Attack`, `Prevent Request`, `Execute Target`, `Begin Enemy Action Healing`, `Prepare Base Attack`
- `status_id` (`String`): references a `statuses[].id`; required by status-specific effects and conditions, including `Apply Status`, `Specific Status` removal, and `Fuse Elemental Ailments`.
- `condition_status_id` (`String`): status matched by `Applied Status Matches`, independently of any status applied by the effect.
- `amount_status_id` (`String`): optional status read by status-based amount formulas. Falls back to `status_id`.
- `replacement_status_ids` (`Array[String]`): explicit deterministic-random boon pool used by `Replace Requested Status`.
- `override_status_duration` (`bool`, default inferred): when true, this effect uses `status_duration_turns` / `status_is_permanent` instead of the referenced status defaults. If omitted, JSON infers true when either duration field is present.
- `status_duration_turns` (`int`, default `3`): affected owner turns before expiration when `override_status_duration` is true.
- `status_is_permanent` (`bool`, default `false`): when true and `override_status_duration` is true, ignores `status_duration_turns`.
- `status_stacks` (`int`, default `1`): fixed number of stacks applied by `Apply Status`.
- `status_stack_threshold` (`int`, default `1`): used by stack-count conditions.
- `status_polarity` (`String enum`): `Any`, `Boon`, `Ailment`; filters `Remove Status` and `Transfer Statuses`.
- `status_removal_mode` (`String enum`): `Random Matching`, `Specific Status`.
- `modified_stat` (`String enum`): `Max HP`, `Physical Damage`, `Magic Damage`, `Armor`, `Action Speed`.
- `modifier_mode` (`String enum`): `Temporary Flat`, `Dynamic Percent`. Dynamic modifiers replace their previous contribution whenever `Battle State Changed` reevaluates them.
- `modifier_direction` (`String enum`): `Increase`, `Decrease`; controls the sign of temporary and dynamic modifiers.
- `modifier_duration_turns` (`int`, default `1`): target completed actions before a temporary modifier or `Apply Haste` contribution expires.
- `amount_source` (`String enum`): `Fixed`, `Target Current HP`, `Target Max HP`, `Target Max HP Times Event Status Stacks`, `Target Recent Damage`, `Target Damage Taken Within Interval`, `Total Allied Magic Damage Taken Within Interval`, `Target Predicted Next Action Damage`, `Target Ailment Stacks`, `Target Unique Boons`, `Target Status Stacks`, `Event Target Status Stacks`, `Defeated Target Status Stacks`, `Applied Status Stacks`, `Total Status Stacks On Selected Group`, `Total Status Max HP Loss On Selected Group`, `Target Pending Status Damage`, `Target Action Speed`, `Event Amount`, `Overhealing`, `Overhealing Diminishing`, `Owner Counter`, `Target Counter`.
- `amount_rounding` (`String enum`): `Floor`, `Ceil`; controls formula rounding after multiplier and divisor scaling.
- `amount_target_selector` (`String enum`): `Self`, `All Units`, `Allied Units`, `Enemy Units`; selects the units aggregated by `Total Status Stacks On Selected Group`.
- `counter_name` (`String`): required by counter sources, `Modify Counter`, `Reset Counter`, and `Overhealing Diminishing`.
- `counter_threshold` (`int`, default `1`): used by counter-threshold conditions and `Event Count At Least`.
- `amount_multiplier` / `amount_divisor` (`int`, minimum `1`): scale the selected amount source after it is read. `Fuse Elemental Ailments` also uses `amount_divisor` as its stack-conversion divisor and rounds up.
- `interval_time` (`int`, minimum `1`, default `10`): inclusive discrete timeline interval used by interval-based damage amount sources.
- `amount` (`int`)
- `damage_type` (`String enum`): `Magic`, `Physical`. Physical authored damage passes through armor and physical-damage hooks such as Frost.
- `threshold_percent` (`int`, 1-100): used by HP threshold conditions and `Execute Target`.
- `max_action_speed_percent` (`int`, default `200`): maximum percentage of finalized encounter-start speed allowed by `Apply Haste`.
- `once_per_battle` (`bool`)
- `ignore_events_from_same_effect_source` (`bool`, default `false`): prevents an effect from responding to events produced by the same named authored source.
- `repeat_within_event_chain` (`bool`, default `false`): allows the effect to respond separately to multiple matching events in one causal chain. Use narrowly for mechanics such as responding to every hit of a multi-hit attack.

Currently implemented item effect combinations:
- `Battle Start` + `Gain Armor`
- `Battle Start` + `Apply Status` targeting `Self`
- `Attack` + `Bonus Damage`
- `Hit` + `Reduce Target Armor`
- `Kill` + `Heal Self`
- `Death` + `Damage Killer`
- `Damaged` or `HP Below Threshold` + `Heal Self` or `Increase Max HP`
- Shared resolver effects on any trigger that supplies the selected target: status application/removal/consumption/detonation, direct damage/healing, temporary stat modifiers, counters, and request prevention.
- `Battle State Changed` reevaluates after battle start, status application/removal/consumption, and unit defeat. It supports keyed `Dynamic Percent` modifiers that replace rather than stack their prior contribution.
- `Maintain Status Aura` grants its status to the selected living units while its owner lives, restores it after removal, and removes only its own contribution when the owner dies. Independently gained copies remain.
- `Replace Requested Status` prevents a matching status-application request and grants one deterministic-random boon from its explicit replacement pool.
- `Gather Status` removes the referenced status from the selected amount group and reapplies the total gathered stacks to each effect target.
- `Transfer Statuses` moves every status matching `status_polarity` from `amount_target_selector` to each effect target, preserving stacks and duration. The destination is excluded from the source group.
- `Fuse Elemental Ailments` removes all Burning, Shock, and Frost from each effect target, totals the removed stacks, divides by authored `amount_divisor`, rounds up, and applies that many stacks of the referenced `Elemental Fusion` status.
- `Transfer Defeated Ailments` requires `Reaction Triggered` + `Most Ailmented Enemy Unit`. It reapplies every ailment carried by the defeated event target to the selected living enemy, preserving stacks, remaining duration, permanence, and source name. Moved stacks are marked as transfers rather than new applications.
- `Restore Max HP Lost To Status` removes the referenced status and restores maximum HP recorded as lost to that status. Restored maximum HP remains empty.
- `Grant Armor` adds temporary guard armor that expires through the normal guard-armor lifecycle.
- `Grant Battle Armor` adds battle-local armor that lasts for the encounter and participates in ordinary armor reduction.
- `Grant Energy Shield` adds to an uncapped combat-long pool. Energy Shield absorbs magic damage before HP; physical damage bypasses it.
- `Disable Armor` makes every stored, temporary, and battle-local armor contribution provide zero mitigation for the rest of the battle.
- `Delay Action` increases the target's next scheduled action time.
- `Apply Haste` grants temporary Haste, raising action speed and proportionally shortening remaining time until the next action. It stacks only to `max_action_speed_percent` of encounter-start speed and expires after `modifier_duration_turns` completed actions.
- `Increase Action Speed For Battle` permanently raises action speed and proportionally shortens remaining time for the encounter. It is not temporary Haste.
- Every action-speed increase obeys the global cap of 200% of encounter-start speed. Slows do not lower this cap.
- `Fortify Damage` prevents incoming damage, pools it, and distributes the complete pool across the target's next `modifier_duration_turns` completed actions. Deferred ticks cannot be deferred again.
- `Redirect Enemy Attacks` makes enemy attacks aimed at another allied unit target the selected unit until it completes `modifier_duration_turns` actions.
- `Add Attack Damage` adds flat damage to the pending complete attack before armor mitigation. `Owner Is Unarmed` checks the runtime equipment that actually entered combat.
- `Consecutive Attack` observes every complete attack against the same target. `Event Count At Least` can gate `Seal Next Attack`, which cancels the target's next complete attack and resets the source's streak.
- `Enemy Attack Targeted` observes the authoritative target after redirection and before the complete attack resolves.
- `Execute Target` requires `Hit` + `Attack Target`. It immediately defeats a living target at or below `threshold_percent` maximum HP only when that hit dealt positive physical HP damage.
- `Begin Enemy Action Healing` opens a window on `Self` using the effect's amount formula. The owner heals that fixed amount after each enemy scheduled turn completed until the owner's next scheduled turn begins.
- `Prepare Base Attack` stores one prepared strike on `Self`. It is consumed before the next enemy scheduled turn begins and uses one complete normal base-attack resolution; defeating the acting enemy cancels that turn.
- `Lowest HP Allied Unit` selects the living allied unit with the lowest current HP and can select the owner.
- `Target Ailment Stacks` counts every current ailment stack. `Target Unique Boons` counts distinct boon status types rather than stacks.
- `Target Current HP` supports effects proportional to the target's remaining HP.
- `Total Status Max HP Loss On Selected Group` totals maximum HP loss recorded by the referenced status across the selected amount group.
- `Damaged`, `Physically Damaged`, and `Magically Damaged` inspect actual dealt damage. A mixed-damage event can satisfy all three.
- `Enemy Status Applied` observes statuses gained by opposing units. `Applied Status Stacks` is the number of stacks actually added, excluding refreshes and stacks blocked by caps.
- `Owner Applied Ailment` observes positive ailment stacks newly applied by the effect owner. It excludes moved/transferred stacks, allowing `Applied Status Stacks` to reward new applications without repeatedly rewarding the same stacks.
- `Most Ailmented Enemy Unit` selects the living enemy with the most total ailment stacks, then lowest current HP, then stable roster order.
- `Ailment Damaged` observes positive HP damage tagged as caused by an ailment. Absorbed or prevented damage does not qualify. Rot qualifies only when its maximum-HP reduction also lowers current HP.
- `Target Recent Damage` reads actual HP damage from the target's current unfinished action window plus its immediately preceding completed-action window.
- `Target Damage Taken Within Interval` reads actual HP loss suffered by the target since `current_time - interval_time`, inclusive.
- `Total Allied Magic Damage Taken Within Interval` totals actual magic HP loss suffered by the effect owner's team over the same inclusive interval. Prevented damage, Energy Shield absorption, and overkill do not inflate it.
- `Target Predicted Next Action Damage` isolates the current combat state, executes the target's deterministic next action, and totals actual HP damage sourced by that target. Prediction does not mutate real combat and nested prediction resolves as zero.
- Defeat events preserve status snapshots. `Defeated Target Status Stacks` reads those snapshots after the defeated unit can no longer act.
- `Externally Sourced Status Applied` observes statuses gained by the effect owner from any other unit, allowing `Applied Status Matches` to narrow the observed status.
- `Ally Overhealed` observes positive overhealing caused by the effect owner on another allied unit. `Random Damaged Allied Unit` selects from all damaged living units on the owner's team, including the owner.
- `Prevent Request` works with damage, healing, reaction, status-application, and status-removal request triggers.

Unsupported trigger/effect/target combinations are rejected during content validation rather than accepted as inert content.

Deterministic-random selectors and `Random Matching` removal use combat event order, so identical combats make identical choices. Shared effects are limited to one activation per causal event chain to prevent recursive loops.

## `jobs[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `max_hp_growth` (`int`): permanent HP gained per level in this job.
- `physical_damage_growth` (`int`): permanent physical damage gained per level in this job.
- `magic_damage_growth` (`int`): permanent magic damage gained per level in this job.
- `armor_growth` (`int`): permanent armor gained per level in this job.
- `action_speed_growth` (`int`): permanent action speed adjustment per level. Positive is faster.
- `forbid_weapon` (`bool`): default `false`; when `true`, assigned weapon items are skipped.
- `forbid_armor` (`bool`): default `false`; when `true`, assigned armor items are skipped.
- `forbid_helmet` (`bool`): default `false`; when `true`, assigned helmet items are skipped.
- `forbid_trinket` (`bool`): default `false`; when `true`, assigned trinket items are skipped.
- `skill` (`Dictionary`): current job active skill payload. See `jobs[].skill` below.
- `secondary_skill` (`Dictionary`): optional current-job bridge skill payload. It uses the same fields as `jobs[].skill` and is selected by `Secondary Skill` tactics.
- `passive` (`Dictionary`): current job passive payload. See `jobs[].passive` below.
- `reaction` (`Dictionary`): current job reaction payload. See `jobs[].reaction` below.
- `default_tactic` (`Dictionary`): tactic automatically appended while this is the unit's current job. See `jobs[].default_tactic` below.
- Job unlock timing is fixed: level 1 chooses skill or reaction, level 2 unlocks the passive, and level 3 unlocks the remaining skill or reaction. A job's secondary skill unlocks with its normal skill and is not a separate learned assignment.

Equipment note:
- Equipment is allowed by default. Use `forbid_weapon`, `forbid_armor`, `forbid_helmet`, and `forbid_trinket` only when a job concept explicitly forbids a category.
- Shields currently live inside `Weapon` or `Armor` item concepts. There is no offhand or one-hand/two-hand rules layer yet.

## `jobs[].skill` and `jobs[].secondary_skill` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `action` (`String enum`): `Attack`, `Heal`, `Guard`, `Apply Status`, `Effects Only`
- `default_target` (`String enum`): `Self`, `Lowest HP Ally`, `Frontmost Enemy`
- `attack_damage_type` (`String enum`): `Physical`, `Magic`, `Split Evenly`. Split attacks divide the physical base damage plus skill bonus evenly, assigning the odd point to physical damage.
- `attack_count` (`int`, minimum `1`, default `1`): number of complete attacks performed by an `Attack` skill. Each attack independently resolves targeting requests, attack/hit effects, damage, reactions, and defeat.
- `status_id` (`String`): required when `action` is `Apply Status`; references a `statuses[].id`.
- `override_status_duration` (`bool`, default inferred): when true, this skill uses `status_duration_turns` / `status_is_permanent` instead of the referenced status defaults. If omitted, JSON infers true when either duration field is present.
- `status_duration_turns` (`int`, default `3`): affected owner turns before expiration when `override_status_duration` is true.
- `status_is_permanent` (`bool`, default `false`): when true and `override_status_duration` is true, ignores `status_duration_turns`.
- `amount_modifier` (`int`): added to the base action amount when the skill is used.
- `cooldown_turns` (`int`, default `0`): owner-turn cooldown started when the skill is used. Tactics skip skills that are still cooling down.
- `effects` (`Array[Dictionary]`): shared effects using `Skill Used` or `Skill Completed`. `Skill Completed` resolves after the skill action and is useful for post-attack consequences. `Effects Only` requires at least one effect.

Currently implemented skill actions:
- `Attack`: performs a normal attack with `amount_modifier` as bonus damage and the authored `attack_damage_type`. Armor applies only to its physical component.
- `Heal`: performs a normal heal with `amount_modifier` as bonus healing.
- `Guard`: performs a normal guard with `amount_modifier` as bonus temporary armor.
- `Apply Status`: applies the referenced authored boon or ailment to the tactic-selected target.
- `Effects Only`: resolves the skill's shared effects without also attacking, healing, or guarding.

## `jobs[].passive` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `passive_type` (`String enum`): `None`, `Attack Damage Bonus`, `Heal Bonus`, `Guard Armor Bonus`, `Forecast`, `Extend Allied Buff Duration`
- `Extend Allied Buff Duration` uses `amount` as a percentage. The strongest living allied copy applies once to finite naturally-elapsing Boons, positive temporary stat modifiers, and temporary Haste from any source. It does not alter transferred existing durations or battle-long action-speed increases.
- `amount` (`int`)
- `cooldown_turns` (`int`): unit-turn cooldown after the passive fires. `0` means no cooldown.
- `effects` (`Array[Dictionary]`): shared triggered effects using the same vocabulary as item effects.

`Forecast` is a capability rather than an automatic passive effect. It makes tactics with `foretell_enabled: true` available while equipped.

## `jobs[].reaction` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `trigger` (`String enum`): `Damaged`, `Physically Damaged`, `Magically Damaged`, `Ally Magically Damaged`, `HP Below Threshold`, `Lethal Physical Attack Requested`, `Attack Targets Another Ally`, `Status Application Requested`, `Ally Ailment Applied`, `Enemy Healing Requested`, `Enemy Status Threshold Reached`, `Enemy Died With Status`, `Enemy Died With Ailments`
- `condition` (`String enum`): `Always`, `Self HP Below Percent`, `Self Status Stacks At Least`, `Requested Status Is Ailment`, `Requested Status Matches`
- `reaction_type` (`String enum`): `Gain Armor`, `Heal Self`, `Damage Attacker`, `Effects Only`
- `amount` (`int`)
- `threshold_percent` (`int`, 1-100): used by `Self HP Below Percent` and `HP Below Threshold`.
- `status_id` / `status_stack_threshold`: required by `Self Status Stacks At Least`.
- `prevents_triggering_request` (`bool`, default `false`): when true, a supported request reaction prevents the incoming request.
- `replacement_status_ids` (`Array[String]`): explicit deterministic-random boon pool granted when a request-preventing reaction fires.
- `cooldown_turns` (`int`): unit-turn cooldown after the reaction fires. `0` means no cooldown.
- `effects` (`Array[Dictionary]`): shared effects normally authored with the `Reaction Triggered` trigger.

Currently implemented reaction timing:
- Reactions are checked after a unit survives attack damage and item damaged effects.
- `Damaged` reacts to any actual damage, while `Physically Damaged` and `Magically Damaged` require a positive dealt component of that type.
- `HP Below Threshold` fires only when damage crosses from above `threshold_percent` maximum HP to at or below it.
- `Enemy Status Threshold Reached` checks whenever an enemy gains the reaction's referenced status and fires while that enemy has at least `status_stack_threshold` stacks.
- `Ally Ailment Applied` fires after an ailment successfully applies to any living ally, including the reaction owner. Prevented applications do not fire it.
- `Ally Magically Damaged` fires after any living ally, including the reaction owner, suffers positive magic HP damage.
- `Enemy Died With Status` checks the defeated enemy's preserved status snapshot and requires the reaction's referenced status.
- `Enemy Died With Ailments` checks that the defeated enemy carried at least one ailment stack. Its reaction payload preserves the full defeat snapshot for `Transfer Defeated Ailments`.
- `Enemy Healing Requested` checks before an opposing unit receives healing. Request-preventing reactions can replace that heal through their `Reaction Triggered` effects.
- `Lethal Physical Attack Requested` checks the final pending attack damage after armor and request modifiers. Its `Reaction Triggered` effects inherit the pending damage amount, and request prevention cancels that damage.
- `Attack Targets Another Ally` checks before an enemy attack target becomes authoritative and redirects that attack to the reacting unit. It does not fire when the reacting unit was already targeted.
- An `Attack Targets Another Ally` reaction may use `Effects Only` without nested effects because the redirection is the reaction's result.
- A ready `Status Application Requested` reaction observes the incoming status application by default. Its `Reaction Triggered` effects can target the attempted applier through `Event Target`.
- Set `prevents_triggering_request` to true when the reaction should replace and prevent the incoming status application.
- A request-preventing reaction with `replacement_status_ids` atomically grants one boon from that pool. `Requested Status Matches` uses `status_id` to select the ailment being replaced.
- `Gain Armor` grants temporary guard armor.
- `Heal Self` heals the reacting unit.
- `Damage Attacker` damages the attacker and can defeat them.

## `jobs[].default_tactic` keys

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `condition` (`String enum`): `Always`, `Self HP Below Half`, `Ally HP Below Half`, `Enemy Alive`, `Target Has Status`, `Target Status Stacks At Least`, `Target Pending Status Damage At Least HP`, `Target Slower Than Self`
- `action` (`String enum`): `Attack`, `Heal`, `Guard`, `Job Skill`, `Secondary Skill`, `Assigned Skill`
- `target` (`String enum`): `Self`, `Lowest HP Ally`, `Lowest HP Ally With Status`, `Frontmost Enemy`
- `status_id` / `status_stack_threshold`: used by status-aware conditions.
- `foretell_enabled` (`Boolean`, default `false`)

## `tactics[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `condition` (`String enum`): `Always`, `Self HP Below Half`, `Ally HP Below Half`, `Enemy Alive`, `Target Has Status`, `Target Status Stacks At Least`, `Target Pending Status Damage At Least HP`, `Target Slower Than Self`
- `action` (`String enum`): `Attack`, `Heal`, `Guard`, `Job Skill`, `Secondary Skill`, `Assigned Skill`
- `target` (`String enum`): `Self`, `Lowest HP Ally`, `Lowest HP Ally With Status`, `Frontmost Enemy`
- `status_id` / `status_stack_threshold`: used by status-aware conditions.
- `foretell_enabled` (`Boolean`, default `false`)

Foretell tactics require an equipped `Forecast` passive. Foretell follows one deterministic baseline where all Foretell toggles are ignored and tactics evaluate normally, selects the first future state where the tactic's normal condition is true, evaluates its normal target there, and ends before the actor's next turn.

## `loadouts[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `current_job_id` (`String` or empty string)
- `equipped_skill_job_id` (`String` or empty string): source job for the assigned cross-job skill.
- `equipped_passive_job_id` (`String` or empty string): source job for the assigned learned passive.
- `equipped_reaction_job_id` (`String` or empty string): source job for the assigned learned reaction.
- `weapon_id` (`String` or empty string)
- `armor_id` (`String` or empty string)
- `helmet_id` (`String` or empty string)
- `trinket_id` (`String` or empty string)
- `tactic_ids` (`Array[String]`)

Reference rules:
- Non-empty `current_job_id` must reference an existing job id.
- Non-empty assigned feature job ids must reference existing job ids.
- Non-empty `weapon_id`/`armor_id`/`helmet_id`/`trinket_id` must reference existing item ids.
- Every `tactic_id` must reference an existing tactic id.

Equipped ability notes:
- Assigned feature job ids identify provenance; the unit must also have the corresponding permanent unlock in `job_progress`.
- `Job Skill` uses the unlocked skill from the current job.
- `Secondary Skill` uses the unlocked secondary skill from the current job.
- `Assigned Skill` uses the separately equipped unlocked skill from a different job.
- A loadout that equips a skill from another job should include an `Assigned Skill` tactic with an appropriate target.

## `units[]` keys

Required:
- `id` (`String`)

Optional fields:
- `display_name` (`String`)
- `tooltip_text` (`String`): optional player-facing prose shown at the top of resource tooltips.
- `tags` (`Array[String]`): canonical tag IDs. Resource-authored content uses shared `TagDefinition` resources for the same IDs.
- `team` (`String enum`): `Allies`, `Enemies`
- `ancestry_id` (`String` or empty string)
- `max_hp` (`int`)
- `physical_damage` (`int`)
- `magic_damage` (`int`)
- `armor` (`int`)
- `action_speed` (`int`)
- Higher action speed is faster. Combat derives integer action delay as `ceil(100 / action_speed)`.
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
Legacy action-interval field names are explicit validation errors; packs must migrate to action-speed fields.
