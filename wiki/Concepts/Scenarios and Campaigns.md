---
type: concept
state: implemented
tags:
  - scenario
  - campaign
  - progression
---

# Scenarios and Campaigns

Scenarios are short handcrafted sequences of encounters. Campaigns are thin progression wrappers around scenarios, not management simulations.

## Scenario Rules

- Three encounters is the normal scenario length.
- A scenario owns story text, party size, encounters, visible rules, rewards, tags, and content unlock IDs.
- Scenario rules should express broad visible battlefield conditions, not hidden stat patches.
- Roster, gear, tactics, jobs, and learned assignments lock once a scenario starts.
- Surviving units reset battle-local state between encounters.
- Defeated allies remain knocked out for the rest of that scenario.

## Campaign Rules

- Campaigns track attempted/completed/unlocked scenarios, content unlocks, completion, durable roster, job progress, equipment, and inventory.
- Failed attempts grant knowledge only and do not commit rewards or progression.
- Successful scenarios commit roster changes and award progression.
- Practice scenarios do not write durable campaign state.
- Battle-local statuses, HP damage, cooldowns, and temporary armor do not persist.

## Implementation

- `clockwork-company/scripts/data/scenario_definition.gd`
- `clockwork-company/scripts/run/run_state.gd`
- `clockwork-company/scripts/scenario/scenario_runner.gd`
- `clockwork-company/scripts/campaign/campaign_manager.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`

## Related

- [[Scenarios]]
- [[Design Principles]]
