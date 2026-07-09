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
- Combat report assembly: `clockwork-company/scripts/combat/combat_report_builder.gd`
- Runtime unit state: `clockwork-company/scripts/combat/runtime/unit_state.gd`
- Runtime clone isolation: `clockwork-company/scripts/combat/runtime/unit_state_clone_helper.gd`
- Scheduling: `clockwork-company/scripts/combat/runtime/turn_scheduler.gd`
- Event causality: `clockwork-company/scripts/combat/runtime/combat_context.gd`
- Central hooks: `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- Shared authored effects: `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
- Shared effect targeting/formulas: `clockwork-company/scripts/combat/rules/triggered_effect_targeting.gd`, `clockwork-company/scripts/combat/rules/triggered_effect_amounts.gd`
- Scenario run: `clockwork-company/scripts/run/run_state.gd`
- Campaign progression: `clockwork-company/scripts/campaign/campaign_manager.gd`
- Durable roster: `clockwork-company/scripts/campaign/campaign_roster_state.gd`
- Workbench coordination: `clockwork-company/scripts/ui/combat_test_scene.gd`
- Workbench persisted mod settings: `clockwork-company/scripts/ui/mod_settings_store.gd`
- Workbench combat-log tooltip lookup: `clockwork-company/scripts/ui/combat_log_tooltip_lookup.gd`
- Workbench preview text composition: `clockwork-company/scripts/ui/combat_preview_text_builder.gd`
- Combat Lab assembly state: `clockwork-company/scripts/devtools/combat_lab_state.gd`
- Combat Lab setup storage: `clockwork-company/scripts/devtools/combat_lab_setup_store.gd`
- Combat Lab presentation: `clockwork-company/scripts/ui/combat_lab_panel.gd`
- Combat Lab setup fixtures: `clockwork-company/devtools/combat_lab_setups/`
- Shared loadout slot rules: `clockwork-company/scripts/data/loadout_slot_helper.gd`
- JSON content bridge: `clockwork-company/scripts/modding/json_content_loader.gd`
- JSON content merge/build/diagnostics/validation/schema/result: `clockwork-company/scripts/modding/content_merger.gd`, `clockwork-company/scripts/modding/content_resource_builder.gd`, `clockwork-company/scripts/modding/content_resource_values.gd`, `clockwork-company/scripts/modding/content_issue_collector.gd`, `clockwork-company/scripts/modding/content_validator.gd`, `clockwork-company/scripts/modding/content_effect_support.gd`, `clockwork-company/scripts/data/content_schema.gd`, `clockwork-company/scripts/modding/content_load_result.gd`

For the detailed ownership inventory, see [[ARCHITECTURE]].
