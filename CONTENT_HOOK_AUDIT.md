# Content Hook Audit

Audit date: 2026-06-05

This audit checks whether current mechanics can be authored, applied, inspected, explained, persisted, validated, and represented in JSON where those hooks are relevant. It is a snapshot of the small implemented vocabulary, not a requirement to make every future system generic now.

## Ownership Map

| Surface | Authoring | Runtime application | Inspection and explanation |
| --- | --- | --- | --- |
| Tactics | `TacticDefinition` Resources and JSON tactics | `TacticResolver` chooses condition/action/target; `CombatSimulator` resolves the action | Unit detail/tooltips show ordered tactics; structured selected/skipped/fallback events explain decisions |
| Item stats and effects | `ItemDefinition` and nested `EffectDefinition` Resources; JSON items/effects | `UnitState` applies allowed flat stats; `ItemEffectResolver` handles supported trigger/effect pairs | Planning preview, item/effect tooltips, setup logs, and item-trigger combat events |
| Job skills, passives, and reactions | `JobDefinition` with nested ability Resources; JSON jobs | `UnitState`, `CombatSimulator`, and `JobEffectResolver` | Unit detail/tooltips and job-effect combat events |
| Ancestry growth and features | `AncestryDefinition` with one feature Resource; JSON ancestries | `UnitState` applies growth; `AncestryFeatureResolver` applies supported hooks | Unit detail/tooltips, setup logs, and ancestry-feature combat events |
| Enemy builds | Normal unit/loadout/job/item/tactic/ancestry Resources and JSON units | Same `UnitState` and simulator paths as allies | Scenario/encounter traversal, unit detail/tooltips, setup logs, replay |
| Scenario rules | `ScenarioRuleDefinition` Resources referenced by scenarios | `StatusResolver` implements Burned Chapel's broad Confusion rule; Iron Tollgate remains an authoring note | Scenario detail, Resource tooltips, battle-start logs, and replay runtime tooltips expose the rule |
| Statuses | `StatusDefinition` Resources and JSON statuses; skills and declarative item effects reference authored statuses | `StatusResolver` applies statuses and resolves Reconstitution; `TacticResolver` enforces Confusion's selection pressure | Status events, battle-start/tactic logs, replay snapshots, Resource tooltips, and runtime unit tooltips expose current statuses |
| Combat state | Simulator-owned `UnitState`, structured events, and snapshots | `CombatSimulator` is authoritative | Logs explain rule outcomes; replay snapshots expose HP, timing, alive state, statuses, and stable ids |

## Cross-Cutting Findings

### Authoring and JSON

- The implemented tactic, item-effect, job-ability, ancestry-feature, unit, loadout, and progression shapes can be authored as inspectable Resources.
- JSON reference packs cover the same core definitions and document their fields in adjacent `*.options.md` files.
- Resolver support is intentionally narrower than some exported `EffectDefinition` enum combinations. Unsupported item trigger/effect pairs explain themselves in the combat log instead of silently applying a different rule.
- Scenario rules are deliberately data-first. A new mechanical rule should be broad, visible, deterministic, and implemented through a focused resolver path only when a scenario needs it.

### Application and Response

- Tactics, jobs, ancestry features, and item effects use focused resolver scripts instead of unrelated UI or run-flow code.
- Enemy mechanics use the same content vocabulary as allied builds, so the player can inspect and eventually reuse the ideas that defeated them.
- Current response hooks are the small existing buildcraft vocabulary: armor, physical versus magic damage, healing, guard, action timing, targeting priorities, tags, and equipment/job tradeoffs.
- Status application now has focused skill and battle-start item-effect hooks with finite owner-turn duration by default, explicit permanent application, and authored ignore/refresh/intensify stacking. Broader triggers, independent layered instances, purge rules, and targeting vocabulary should wait for focused content that needs them.

### Logs, Replay, and Tooltips

- Combat logs and structured events explain tactic choices, damage/healing, item triggers, job effects, ancestry features, guard, and defeat.
- Resource tooltips cover current authored mechanic definitions and nested Resource relationships.
- Replay snapshots intentionally remain small. They expose current statuses for runtime tooltips, but not temporary armor, ability cooldowns, or cast state; add those only when a concrete replay visual needs them.
- Unsupported item-effect combinations are visible in log text, but repository validation does not yet reject or summarize unsupported combinations.

### Persistence and Validation

- Campaign persistence carries unit definitions, current loadouts, job progress flags, equipped gear, and inventory through the current small save shape.
- Active battle state, scenario-local knockouts, temporary armor, cooldowns, and statuses correctly remain outside durable campaign saves.
- Learned-ability provenance and assignment rules use per-job progress plus loadout assignment slots. Ordered tactic-list editing exists; broader ability catalogs are not modeled yet.
- `tools/check_content.ps1` validates scenario/campaign references, graph reachability, rewards, rules, starting roster ids, learned-feature assignment provenance/unlocks, JSON loading, and JSON sidecar presence.
- Mechanics Resources rely mainly on typed exported enums and loader checks. A future focused validation pass can reject unsupported trigger/effect combinations once the intended supported matrix is stable enough to enforce.

## Audit Decisions

- Do not add a generic mechanic registry or scenario-rule DSL.
- Keep resolver ownership split by mechanic source: tactics, items, jobs, and ancestry features.
- Keep scenario rules visible even when they are authoring notes.
- Keep current unsupported-combination log messages; they are useful during content iteration.
- Treat player-facing unlock choice/equipment as a design-and-UI task, not a small boolean toggle.
- Extend snapshots, validation, save data, and JSON docs in the same patch whenever a concrete mechanic expands those contracts.

## Focused Follow-Ups

The audit does not add new systems. Existing backlog items already cover the meaningful gaps:

- add independent layered status instances, purge, or broader application hooks only when focused content needs them
- extend replay snapshots only when richer visuals need additional authoritative state
- update JSON sidecars and repository-level modding docs whenever mechanic schemas or keywords change
- strengthen mechanics-content validation once unsupported versus intentionally placeholder combinations become stable enough to enforce
