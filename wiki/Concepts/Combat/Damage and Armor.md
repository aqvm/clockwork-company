---
type: concept
state: implemented
tags:
  - combat
  - damage
  - armor
---

# Damage and Armor

Damage is split into physical and magic components.

## Current Formula

- Physical component: `max(1, physical damage - total armor)` when physical damage is present
- Magic component: magic damage, currently ignoring armor
- Total damage: at least 1 when a positive damage request resolves

Total armor combines base battle armor and temporary guard armor.

## Armor Vocabulary

- **Base battle armor:** persistent armor for the current battle.
- **Temporary guard armor:** short-lived protection, normally removed at the owner's next turn.
- Armor reduction consumes base battle armor first, then temporary guard armor if reduction remains or no base armor exists.
- Armor cannot currently reduce a physical component to zero because of the minimum-damage rule.

Named armor statuses are intentionally avoided unless a future mechanic needs status interactions. [[Ward]] is status protection, not armor.

## Related Mechanics

- [[Frost]] amplifies the next positive post-armor physical damage.
- Energy Shield is a battle-long pool that absorbs only magic damage.
- Fortified defers damage into later direct-damage ticks.
- [[Rot]] can cause actual HP loss by reducing maximum HP.

## Implementation

- `clockwork-company/scripts/combat/combat_simulator.gd`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `clockwork-company/scripts/combat/runtime/unit_state.gd`
