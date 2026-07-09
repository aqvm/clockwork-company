---
type: concept
state: implemented
tags:
  - combat
  - simulation
---

# Combat Simulation

Combat is a deterministic discrete-event simulation. The simulator resolves the complete fight before [[Presentation and Replay]] reveals it.

## Current Model

- Every unit starts with `next_action_time = ceil(100 / action_speed)`.
- The living unit with the lowest next action time acts next.
- Ties use roster order.
- The acting unit evaluates [[Tactics]] in priority order.
- If nothing matches, it attacks the frontmost living enemy.
- The action resolves through the [[Combat Event Pipeline]].
- The unit schedules its next action.
- Combat ends when one team has no living units.

The simulator currently has no random rolls. Authored deterministic-random selections derive from stable combat event order.

## Boundaries

- Definitions remain separate from [[Data Definitions and Runtime State|runtime state]].
- Combat does not depend on frames, animations, UI, or player input.
- Logs and structured events explain causality.
- `CombatReportBuilder` owns setup summaries and snapshot dictionaries for battle reports.
- Scenario and campaign systems choose combat inputs but do not change core rules.

## Implementation

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/combat_report_builder.gd`
- `clockwork-company/scripts/combat/runtime/turn_scheduler.gd`
- `clockwork-company/scripts/combat/runtime/combat_context.gd`
- `clockwork-company/scripts/tools/combat_event_pipeline_check.gd`
