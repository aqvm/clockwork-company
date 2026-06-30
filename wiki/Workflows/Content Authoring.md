---
type: workflow
state: implemented
aliases:
  - Authoring Content
tags:
  - workflow
  - content
---

# Content Authoring

Base game content is authored `.tres`-first for Godot editor ergonomics. Mods use validated JSON packs with equivalent supported vocabulary.

## Fast Path

1. Copy the nearest existing Resource of the same family.
2. Make the smallest content change.
3. Reference existing Resources instead of duplicating definitions.
4. Use shared `EffectDefinition` vocabulary before adding resolver code.
5. Run the narrowest relevant check.
6. Update canonical wiki documentation only if durable behavior/design changed.

## Boundaries

- A unit combines ancestry, explicit stats, job progress, and a loadout.
- A loadout combines current job, learned assignments, gear, and tactics.
- A job owns growth, equipment forbids, primary skill, optional secondary skill, passive, reaction, and default tactic.
- An apply-status skill/effect references a `StatusDefinition`.
- Resource-authored tags should reference shared `TagDefinition` files from `res://resources/tags/`; JSON-authored tags remain canonical string IDs that map to the same IDs.
- Scenario rules should be broad, visible, and deterministic.
- Unsupported combinations should fail clearly rather than silently approximating behavior.

## Inspector Ergonomics

Core data Resources use conditional Inspector visibility and property tooltips to keep authoring focused. Changing fields such as skill action, effect type, trigger, condition, amount source, reaction trigger, or tactic condition reveals only the dependent fields that can affect that selection.

Hidden fields may still exist on older Resources and can remain serialized if they were previously set. Content validation is still the authoritative safety net for unsupported combinations, missing references, or stale hidden values.

Gameplay Resources that appear in hover tooltips should fill `tooltip_text` with one or two player-facing sentences before relying on mechanical fields. The tooltip builder displays that prose first, then appends structured details such as tags, triggers, targets, stats, and effects.

For bespoke jobs, prefer standalone feature Resources under `res://resources/job_features/<Job Name>/` and reference them from the job. This keeps skills, passives, reactions, and shared effects reusable and easier to inspect than nested subresources.

## Detailed Reference

See [[CONTENT_AUTHORING]] for Resource recipes and current shared-effect combinations.

## Primary Files

- `clockwork-company/scripts/data/`
- `clockwork-company/resources/`
- `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
