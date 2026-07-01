---
type: architecture
state: implemented
tags:
  - architecture
  - ui
  - replay
---

# Presentation and Replay

Presentation displays combat that the deterministic simulator has already resolved. It must not own or alter combat rules.

The scenario workbench supports scenario inspection, planning, explicit fight start, readable setup text, timed log replay, structured event grouping, lightweight unit visualization, and pinned/nested Resource tooltips.

The same workbench also hosts a developer-facing Combat Lab. `CombatLabState` owns cloned allied/enemy unit definitions, equipment edits, authored ancestry/job/feature/tactic assignments, stat edits, assembly operations, and JSON setup fixture save/load. `CombatLabPanel` presents catalog selection, setup name/notes, saved setup selection, ordered party controls, per-slot item selectors, authored Resource dropdowns, stat fields, and tactic template controls. Lab battles are resolved by `CombatSimulator` and handed to `CombatReplayPanel` as ordinary battle reports; replay finishing does not mutate campaign or run progression.

Replay uses structured events for grouping and emphasis, while simulator-authored snapshots are authoritative for displayed unit state such as HP, timing, defeat, and statuses. Battle reports also include simulator-authored contribution summaries built from structured combat events, and the workbench displays them after resolved scenario, campaign, debug, and Combat Lab battles.

The main workbench scene should stay a coordinator. Persisted mod UI settings live in `ModSettingsStore`; replay, Combat Lab, contribution panels, tooltips, and planning controls each own their presentation-specific state.

## Primary Owners

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/mod_settings_store.gd`
- `clockwork-company/scripts/devtools/combat_lab_state.gd`
- `clockwork-company/scripts/ui/combat_lab_panel.gd`
- `clockwork-company/scripts/combat/battle_contribution_summary.gd`
- `clockwork-company/scripts/ui/battle_contribution_panel.gd`
- `clockwork-company/scripts/ui/combat_replay_panel.gd`
- `clockwork-company/scripts/ui/unit_status_dot.gd`
- `clockwork-company/scripts/ui/resource_tooltip_builder.gd`
- `clockwork-company/scripts/ui/tooltip_presenter.gd`
- `clockwork-company/scripts/ui/combat_log_rich_text_formatter.gd`

## Related

- [[Combat Simulation]]
- [[Combat Event Pipeline]]
- [[ARCHITECTURE]]
