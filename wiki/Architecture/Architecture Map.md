---
type: architecture
state: implemented
tags:
  - architecture
  - index
---

# Architecture Map

## Layers

- [[Combat Simulation]] owns deterministic battle resolution.
- [[Combat Event Pipeline]] owns request/fact causality and responder ordering.
- [[Data Definitions and Runtime State]] explains authored Resources versus battle-local state.
- [[Presentation and Replay]] displays already-resolved combat without owning rules.
- [[Scenarios and Campaigns]] wrap combat with mission and durable progression state.
- [[Content Authoring]] and [[Modding Pipeline]] describe the two authoring paths.

## Primary Owners

- Combat orchestration: `clockwork-company/scripts/combat/combat_simulator.gd`
- Runtime unit state: `clockwork-company/scripts/combat/runtime/unit_state.gd`
- Scheduling: `clockwork-company/scripts/combat/runtime/turn_scheduler.gd`
- Event causality: `clockwork-company/scripts/combat/runtime/combat_context.gd`
- Central hooks: `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- Shared authored effects: `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
- Scenario run: `clockwork-company/scripts/run/run_state.gd`
- Campaign progression: `clockwork-company/scripts/campaign/campaign_manager.gd`
- Durable roster: `clockwork-company/scripts/campaign/campaign_roster_state.gd`
- Workbench coordination: `clockwork-company/scripts/ui/combat_test_scene.gd`
- JSON content bridge: `clockwork-company/scripts/modding/json_content_loader.gd`

For the detailed ownership inventory, see [[ARCHITECTURE]].
