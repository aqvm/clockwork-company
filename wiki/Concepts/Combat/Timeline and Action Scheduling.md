---
type: concept
state: implemented
aliases:
  - Timeline
  - Action Scheduling
tags:
  - combat
  - timeline
---

# Timeline and Action Scheduling

The timeline is the discrete-event clock that decides when units act.

## Current Rules

- Higher action speed means faster actions. `10` is the readable baseline.
- Action speed and timeline times are integers.
- The scheduler privately derives `action_delay = ceil(100 / action_speed)`.
- Every unit starts scheduled at its derived action delay.
- The lowest next action time acts next; roster order breaks ties.
- After acting, a unit schedules its next action using its current derived delay.
- Timeline delay moves the next action later.
- Flat growth, items, and stat modifiers add or subtract action speed directly.
- Haste raises action speed; slows lower it.
- Speed changes proportionally rescale remaining time until the next action, rounded up.
- Haste cannot raise a unit above twice its finalized encounter-start speed. Slows do not lower that cap.
- Integer delay quantization means adjacent speed values can share a delay; doubling speed doubles frequency exactly when the division is exact and approximately at rounding boundaries.

`Stun` and `Scorched` are named timeline consequences, not [[Statuses]]. Stun does not wait for the delayed unit to complete a turn before ending.

## Implementation

- `clockwork-company/scripts/combat/runtime/turn_scheduler.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
- `clockwork-company/scripts/combat/rules/triggered_effect_resolver.gd`
