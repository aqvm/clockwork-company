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
- A job owns growth, equipment forbids, skill, passive, reaction, and default tactic.
- An apply-status skill/effect references a `StatusDefinition`.
- Scenario rules should be broad, visible, and deterministic.
- Unsupported combinations should fail clearly rather than silently approximating behavior.

## Detailed Reference

See [[CONTENT_AUTHORING]] for Resource recipes and current shared-effect combinations.

## Primary Files

- `clockwork-company/scripts/data/`
- `clockwork-company/resources/`
- `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
