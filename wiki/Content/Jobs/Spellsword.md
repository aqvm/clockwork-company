---
type: content
category: job
state: implemented
design_maturity: prototype
tags: [job, spellblade, developed-recruit]
---
# Spellsword

> [!warning] Runnable developed-recruit prototype, not a final job design.

Spellsword is the first developed-recruit job example. Its standalone feature Resources let the job and authored loadout share provenance-aware learned abilities.

- **Skill:** `Sparkblade`, attack with +2 amount.
- **Passive:** `Sword Memory`, +1 attack damage with a 1-turn cooldown.
- **Reaction:** `Ward Flare`, gain 4 armor below half HP, 4-turn cooldown.

Despite its name, `Ward Flare` does not apply [[Ward]].

Implementation:

- `clockwork-company/resources/jobs/spellsword.tres`
- `clockwork-company/resources/job_features/spellsword/`
