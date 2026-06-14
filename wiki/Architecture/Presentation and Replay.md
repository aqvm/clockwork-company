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

Replay uses structured events for grouping and emphasis, while simulator-authored snapshots are authoritative for displayed unit state such as HP, timing, defeat, and statuses.

## Primary Owners

- `clockwork-company/scripts/ui/combat_test_scene.gd`
- `clockwork-company/scripts/ui/combat_replay_panel.gd`
- `clockwork-company/scripts/ui/unit_status_dot.gd`
- `clockwork-company/scripts/ui/resource_tooltip_builder.gd`
- `clockwork-company/scripts/ui/tooltip_presenter.gd`
- `clockwork-company/scripts/ui/combat_log_rich_text_formatter.gd`

## Related

- [[Combat Simulation]]
- [[Combat Event Pipeline]]
- [[ARCHITECTURE]]
