# Content-Authorable Job Design

This document tests proposed jobs against the current authored skill, passive,
reaction, status, and shared-effect vocabulary. It records concrete recipes and
reusable resolver gaps without treating unimplemented concepts as commitments.

## Design Rules

- Prefer jobs that combine shared effects instead of adding job-id branches.
- Keep one skill, passive, reaction, and default tactic per job for the current
  progression scaffold.
- Treat deterministic-random results as random for authored combat content.
- Add a resolver capability only when a concept cannot be expressed accurately
  with existing event facts, conditions, targets, and effects.

## Pyromancer

Identity: builds persistent Burn pressure while turning hostile ailments back
onto their source.

### Authorable Recipe

- Skill: `Effects Only`, targeting the frontmost enemy.
  - One or more `Skill Used` + `Apply Status` effects apply Burning to
    `Event Target`.
  - Multiple effects create separately explained pulses. One effect with
    `status_stacks > 1` creates one larger application.
- Passive: Burn immunity.
  - `Status Application Requested`
  - `Requested Status Matches` Burning
  - `Self`
  - `Prevent Request`
- Reaction: replace an incoming ailment with a deterministic-random boon, then
  double the attempted source's existing Burning.
  - Reaction trigger: `Status Application Requested`
  - Reaction condition: `Requested Status Is Ailment`
  - `prevents_triggering_request = true`
  - Explicit `replacement_statuses` boon pool
  - `Reaction Triggered` + `Apply Status` Burning to `Event Target`
  - Amount source: `Target Status Stacks`
- Bridge action, `Hot on Their Heels`: temporarily reduce an ally's action
  interval by its total ailment stacks. A non-stacking ailment contributes one;
  an intensified ailment contributes its current stack count.

### Important Interaction

Burn immunity prevents the request before the reaction resolver sees it.
Therefore incoming Burning does not also trigger the replacement reaction. This
is coherent and avoids rewarding the Pyromancer twice for its explicit
immunity, but it should be stated in the ability text.

### Resolver Gap

None required for the current concept, including `Hot on Their Heels`.

## Cryomancer

Identity: sets up physical burst with Frost, suppresses reactions with Numb, and
slows the enemy team as Frost accumulates.

### Authorable Recipe

- Skill: `Effects Only`, targeting the frontmost enemy.
  - `Skill Used` + `Apply Status` Frost to `Event Target`
  - `Skill Used` + `Apply Status` Numb to `Event Target`
- Passive: dynamically slow all enemies based on total enemy Frost.
  - `Battle State Changed`
  - `Modify Stat` targeting `Enemy Units`
  - Stat: `Action Interval`
  - Mode: `Dynamic Percent`, direction `Increase`
  - Amount source: `Total Status Stacks On Selected Group`
  - Amount group: `Enemy Units`, amount status: Frost
- Reaction: retaliate against physical attackers with Frost.
  - Reaction trigger: `Physically Damaged`
  - Reaction type: `Effects Only`
  - `Reaction Triggered` + `Apply Status` Frost to `Event Target`
- Bridge action, `Cold Blood`: apply Bleed equal to an enemy's current Frost,
  then consume all Frost from that enemy.

### Resolver Gap

None required for the current concept, including `Cold Blood`.

## Enthalpyst

Identity: reflects hostile temperature effects and converts dangerous Frost
build-up into a physical-damage response.

### Intended Recipe

- Action: apply one Burning and one Frost to an enemy.
- Bridge action, `Chimney Effect`: gather all Burning from the enemy team onto
  one target enemy.
- Passive: when an external source applies Burn or Frost to the Enthalpyst,
  mirror the stacks actually added back to that source.
  - One `Externally Sourced Status Applied` effect for Burning and one for Frost
  - `Applied Status Matches`
  - `Apply Status` to `Event Source`
  - Amount source: `Applied Status Stacks`
- Reaction: when an enemy reaches 10 Frost, hit it with physical damage to
  trigger and shatter that Frost.
  - Reaction trigger: `Enemy Status Threshold Reached`
  - Referenced status: Frost
  - Status stack threshold: `10`
  - Reaction type: `Effects Only`
  - `Reaction Triggered` + `Deal Damage` to `Event Target`
  - Damage type: `Physical`

### Important Interaction

The reaction fires immediately when a Frost application leaves an enemy at or
above 10 stacks. The physical reaction hit passes through armor, receives
Frost's normal amplification, and then shatters Frost.

If armor reduces the reaction's initial post-armor physical damage to zero,
Frost does not amplify or shatter. The reaction's fixed damage should therefore
be balanced high enough to threaten intended targets. Reading the Enthalpyst's
physical-damage stat instead would require a new reusable amount source.

Balance watchpoint: Frost currently amplifies physical damage after armor has
already reduced it. If armor proves too strong a counter to Frost, consider
calculating the Frost burst before armor mitigation and applying armor to the
combined physical result instead. This is an alternative damage-ordering rule
to test, not a current design decision.

### Resolver Gap

None required for the current concept. `Event Source Is Not Owner` supports the
mirror passive, while `Gather Status` supports `Chimney Effect`.

## Paladin

Identity: hybrid damage, selective ailment conversion, and sustained party
recovery.

### Authorable Recipe

- Skill: `Attack` with `attack_damage_type = Split Evenly`.
- Passive: maintain Reconstitution on the party.
  - `Battle State Changed`
  - `Maintain Status Aura`
  - Target: `Allied Units`
  - Status: Reconstitution
- Reaction: convert one selected incoming ailment into a
  deterministic-random boon.
  - Reaction trigger: `Status Application Requested`
  - Reaction condition: `Requested Status Matches`
  - Referenced status: the selected ailment
  - `prevents_triggering_request = true`
  - Explicit `replacement_statuses` boon pool
- Bridge action, `Spiritual Barrier`: once per battle, grant one ally a large
  amount of battle-long armor for each unique boon currently on that ally.

### Important Interaction

The maintained Reconstitution source is restored after consumption or removal
while the Paladin lives. Independently applied Reconstitution remains compatible
with the aura's maintained contribution.

### Resolver Gap

None required for the current concept, including `Spiritual Barrier`. Use
`Grant Battle Armor` with `Target Unique Boons`, a large authored multiplier,
and `once_per_battle`.

## Bog Priest

Identity: redistributes wasted healing while corrupting both enemy recovery and
allies who receive excessive care.

### Intended Recipe

- Skill: heal an ally for an authored percentage of that ally's maximum HP.
  - `Effects Only`, targeting the lowest-HP ally
  - `Skill Used` + `Heal` to `Event Target`
  - Amount source: `Target Max HP`
  - `amount_multiplier` / `amount_divisor` express the authored proportion
- Reaction: when an enemy would be healed, prevent that healing, apply Rot, and
  heal it for 1 instead.
  - Reaction trigger: `Enemy Healing Requested`
  - Reaction type: `Effects Only`
  - Cooldown: `3`
  - Prevent the triggering healing request
  - `Reaction Triggered` + `Apply Status` Rot to `Event Target`
  - `Reaction Triggered` + `Heal` 1 to `Event Target`
- Passive: when the Bog Priest overheals another ally, heal a deterministic-
  random damaged ally for the overhealed amount, then apply Rot to the original
  target.
  - Trigger: `Ally Overhealed`
  - `Heal` a `Random Damaged Allied Unit`
  - Amount source: `Overhealing`
  - `Apply Status` Rot to `Event Target`
- Bridge action: heal all allies by the total maximum HP currently missing from
  enemies because of Rot, then remove Rot from all enemies and restore that
  missing maximum HP as empty HP.

### Important Interactions

The replacement reaction should mark its cooldown before its authored 1-point
heal resolves. That prevents the replacement heal from replacing itself even
when healing an enemy Bog Priest.

The shared triggered-effect causal-root guard already prevents the passive's
redistributed heal from triggering the same passive again. No Bog-Priest-
specific recursion rule is required.

The passive applies Rot only when positive overhealing occurred. It does not
punish ordinary healing that restores all of its attempted amount.

### Resolver Gap

None required for the current concept or bridge action. `Ally Overhealed` specifically requires
the owner to have caused positive overhealing on another allied unit. `Random
Damaged Allied Unit` selects from the owner's full team category and can select
the owner.

## Bruiser

Identity: develops high HP through job growth, intercepts attacks aimed at
allies, and turns repeated physical punishment into accelerating tempo.

### Intended Recipe

- Growth: strong maximum-HP growth bias. The Bruiser does not need a passive
  that simply multiplies HP.
- Action: strike an enemy twice, then delay its next action by an authored
  timeline amount.
- Reaction: when an enemy attack would target another allied unit, redirect the
  attack to the Bruiser.
  - Cooldown: `4`
  - Must not trigger when the Bruiser was already the target.
  - Redirection occurs before attack logs, attack effects, damage requests, and
    hit effects select their target.
- Passive: whenever the Bruiser takes physical damage, temporarily reduce its
  action interval.
  - Repeated physical hits can stack the acceleration.
  - The Bruiser's action interval cannot fall below half its finalized
    pre-effect action interval.
  - Decide whether gained acceleration also moves the Bruiser's already
    scheduled next action earlier. Current interval modifiers only affect later
    scheduling, so they do not immediately punish attacks landing before the
    Bruiser's next turn.
- Bridge action: deal physical damage proportional to the target's remaining
  HP.
  - Intended as an early-fight pressure tool that helps allied half-HP or
    execution tactics become active.
  - Exact proportion, minimum damage, armor interaction, and whether it can
    deliver a killing blow remain balance decisions.

### Important Interactions

The physical-damage speed passive intentionally punishes rapid, low-damage
attackers. Its half-interval floor prevents repeated hits from creating
unbounded acceleration while preserving that matchup identity.

Stun is a named timeline delay, not a turn-duration status. A unit does not need
to complete a turn before the delay can end.

The double strike should be two real attack resolutions. Each strike should
independently interact with armor, attack/hit effects, damage reactions, and
defeat. The second strike should not occur if the first defeats the target.

### Resolver Gaps

None required for the current concept. Use:

- `attack_count = 2` plus a `Skill Completed` `Delay Action` effect
- `Attack Targets Another Ally` for interception
- a `Physically Damaged` `Hasten Action` effect with a 50% floor, two or three
  completed-action duration, and `repeat_within_event_chain = true`
- `Target Current HP` for the bridge action

## Resolver Gap Priority

1. Consider an `Owner Physical Damage` amount source only if fixed physical
   reaction damage proves too brittle against armor.
2. Do not add broader source taxonomies, arbitrary boolean expressions, or
   custom per-job resolver branches for these concepts.

## Monk

Identity: an unarmed support attacker who absorbs allied burdens, recovers
through untouched discipline, and seals repeated opponents' attacks.

### Intended Recipe

- Restriction: forbid weapons.
- Unarmed bonus: `Attack` + `Add Attack Damage`, conditioned by
  `Owner Is Unarmed`.
- Action: attack an enemy, then apply Regeneration to the
  `Lowest HP Allied Unit`.
- Bridge action: `Transfer Statuses` with Ailment polarity from
  `Allied Units` to `Self`.
- Reaction: increment a named counter on `Action Completed`, reset it on
  `Enemy Attack Targeted`, and heal plus reset when the counter reaches 3.
- Passive: on `Consecutive Attack` count 3, `Seal Next Attack` on the event
  target.

### Important Interactions

Each complete attack increments the consecutive-target streak. The Bruiser's
two-hit attack therefore reaches the Monk seal after two uses: two attacks on
the first use, then the first attack of the second use. The seal prevents the
enemy's next complete attack, not a non-attack action.

The untouched-action reaction resets only when the Monk is the authoritative
target after redirection. Prevented damage and zero damage still count as
being attacked; an attack redirected away from the Monk does not.

## The Spike

Identity: an armorless retaliation tank who protects allies by becoming the
most dangerous target to attack.

### Intended Recipe

- Passive:
  - `Battle Start` + `Disable Armor` on `Self`.
  - `Physically Damaged` + fixed `Deal Damage` to `Event Source`.
- Reaction:
  - `Lethal Physical Attack Requested`, `Effects Only`, request-preventing,
    with an authored cooldown.
  - `Reaction Triggered` + `Deal Damage` to `Event Target`, using
    `Event Amount`.
- Action: attack an enemy, then `Fortify Damage` on `Self` for 2 or 3
  completed actions.
- Bridge action: `Redirect Enemy Attacks` to `Self` for 2 completed actions,
  with `cooldown_turns = 4`.

### Important Interactions

Fortified takes precedence over the lethal reaction because it prevents and
defers the pending damage before lethality is checked. Deferred damage is
direct damage and cannot be deferred again.

The lethal reaction only observes physical damage from a complete attack.
Physical damage from authored effects does not trigger it. The reflected
amount is the final pending damage after armor and request modifiers.

Temporary forced interception takes precedence over ordinary
`Attack Targets Another Ally` reactions and expires according to the Spike's
completed actions.

## Sanguinist

Identity: deliberately accepts ailments and converts actual HP loss into
tempo, recovery, and magic protection.

### Intended Recipe

- Action: apply Bleed independently to an enemy and `Self`.
- Passive: `Ailment Damaged` + `Hasten Action For Battle` on `Self` for a
  fixed amount per positive ailment-damage event.
- Reaction:
  - `Enemy Died With Status`, referencing Bleed.
  - `Reaction Triggered` + `Heal` on `Self`.
  - Amount source: `Target Max HP Times Event Status Stacks`, multiplied by 2,
    divided by 100, with `Ceil` rounding.
- Bridge action:
  - Target through `Lowest HP Ally With Status`, referencing Bleed.
  - `Grant Energy Shield` using `Target Recent Damage`.

### Important Interactions

Every action-interval decrease obeys the global floor of half the unit's
encounter-start interval. A future explicit floor-changing mechanic may allow
specific units to exceed that general limit.

`Ailment Damaged` requires positive actual HP loss. Energy Shield absorption,
Fortified deferral, and other prevention do not qualify. Rot qualifies only
when reducing maximum HP also lowers current HP.

Energy Shield is an uncapped combat-long pool. It absorbs only magic damage;
physical damage bypasses it. Repeated grants add together.

`Target Recent Damage` includes damage from the target's current unfinished
action window and the immediately preceding completed-action window. The
bleeding-ally selector includes the acting unit and returns no target when no
living ally has the referenced status.
