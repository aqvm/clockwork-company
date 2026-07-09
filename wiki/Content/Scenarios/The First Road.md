---
type: content
category: campaign
state: implemented
tags:
  - campaign
  - scenario
  - content
---

# The First Road

The First Road is the current sample campaign: a linear chain of four contracts that gradually introduces combat concepts.

## Progression

1. [[Roadside Ambush]] begins unlocked.
2. Completing it unlocks [[Burned Chapel]].
3. Completing Burned Chapel unlocks [[Iron Tollgate]].
4. Completing Iron Tollgate unlocks [[Clocktower Claim]].
5. Completing Clocktower Claim completes the campaign.

## Starting State

- **Roster:** Template Pyromancer, Template Bruiser, Template Bard
- **Starting unlocks:** clean-slate jobs

Campaign progress stores attempts, completions, scenario/content unlocks, completion state, and durable roster state. Active scenario runs are not saved.

## Implementation

- `clockwork-company/resources/campaigns/first_road_campaign.tres`
- `clockwork-company/scripts/campaign/campaign_manager.gd`
- `clockwork-company/scripts/campaign/campaign_roster_state.gd`

## Related

- [[Scenarios and Campaigns]]
- [[Jobs and Progression]]
