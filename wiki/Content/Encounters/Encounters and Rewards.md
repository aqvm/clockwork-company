---
type: index
category: encounter
state: implemented
aliases:
  - Encounters
  - Rewards
tags:
  - encounter
  - reward
  - content
---

# Encounters and Rewards

Encounters are fixed authored enemy parties built from normal units, jobs, gear, loadouts, ancestries, and tactics. Rewards are curated offers that point to normal item Resources.

Enemy parties should demonstrate coherent buildcraft and teach readable matchup lessons. They do not use a separate monster-only ruleset.

Scenario rewards should mostly be gear choices because equipment is the primary between-scenario buildcraft lever.

## Current Catalog

- Encounters: `clockwork-company/resources/encounters/`
- Rewards: `clockwork-company/resources/rewards/`
- Scenarios that compose them: [[Scenarios]]

## Implementation

- `clockwork-company/scripts/data/encounter_definition.gd`
- `clockwork-company/scripts/data/reward_definition.gd`
- `clockwork-company/scripts/run/run_state.gd`
