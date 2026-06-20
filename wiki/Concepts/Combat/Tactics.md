---
type: concept
state: implemented
tags:
  - combat
  - tactics
  - planning
---

# Tactics

Tactics are priority-ordered authored rules in the form `condition -> action -> target`. The player authors behavior before combat instead of issuing commands during it.

## Current Rules

- Tactics evaluate top to bottom.
- The first true condition with an available action and valid target wins.
- Supported actions include attack, heal, guard, `Job Skill`, `Secondary Skill`, `Assigned Skill`, apply status, and effects-only content where authored.
- If no tactic matches, the unit attacks the frontmost living enemy.
- The current job's default tactic is appended at combat initialization and is not part of the editable loadout list.
- Campaign planning can add, remove, reorder, and edit authored tactic copies.
- Every selected tactic explains itself in the combat log.

[[Confusion]] skips the first otherwise-valid tactic each turn. [[Foretell]] optionally evaluates a normal tactic against one deterministic future baseline.

## Implementation

- `clockwork-company/scripts/data/tactic_definition.gd`
- `clockwork-company/scripts/combat/rules/tactic_resolver.gd`
- `clockwork-company/scripts/combat/rules/targeting_rules.gd`
- `clockwork-company/scripts/tools/tactic_authoring_check.gd`
