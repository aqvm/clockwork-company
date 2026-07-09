---
type: content
category: status
state: implemented
tags:
  - status
  - ailment
  - magic
  - damage
---

# Shock

**Polarity:** [[Ailments|Ailment]]
**State:** Implemented
**Stacking:** Uncapped `Intensify`
**Natural expiry:** No

When incoming magic damage against the afflicted unit can produce an arc of at
least 1 damage, Shock consumes one stack. Up to three other living allies each
receive magic damage equal to 25% of the incoming magic damage, rounded down.
Shock damage can recursively discharge Shock on its recipients.

## Damage Basis

Shock propagates incoming magical energy rather than actual HP loss. Its basis
is measured before Energy Shield absorption, capped by the afflicted unit's
pre-hit HP plus Energy Shield so overkill cannot inflate the cascade.

Each arc then resolves as ordinary magic damage against its recipient. Energy
Shield can absorb it, and the original attacker remains its source for damage
attribution and defeat effects.

## Targeting

Each discharge excludes the currently discharging unit and selects at most
three other living allies. Candidates resolve deterministically by:

1. Highest combined Shock and [[Elemental Fusion]] stacks.
2. Lowest current Energy Shield.
3. Stable roster order.

Later discharges may arc back to an earlier conductor. A stack is consumed
before its child arcs resolve, so every recursive discharge spends a distinct
stack. If 25% rounds down to zero or no other ally is alive, Shock does not
discharge or consume a stack.

## Tactical Role

Shock is the AOE-native ailment. Spreading it creates conductive networks;
concentrating it on a few units supports decaying ping-pong cascades. The
three-recipient cap ensures each generation propagates at most 75% of its
incoming energy before mitigation and rounding.

## Sources

- `clockwork-company/resources/statuses/shock.tres`
- `clockwork-company/scripts/combat/rules/combat_hook_resolver.gd`
- `clockwork-company/scripts/tools/status_mechanics_check.gd`
