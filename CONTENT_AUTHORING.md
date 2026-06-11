# Content Authoring Workflow

The Godot Inspector is the primary authoring tool for core content. Content Resources live under `clockwork-company/resources/`.

## Fastest Test Loop

1. Create or duplicate the Resources needed by the content.
2. Put a completed `ScenarioDefinition` `.tres` file in `clockwork-company/resources/scenarios/`.
3. Run the project.
4. Select the scenario marked `practice` and press the practice button.

Every scenario in the scenario resource directory is discovered automatically for practice. Adding it to a campaign is a separate, explicit step.

Before testing in the UI, run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_content.ps1
```

This reports common authoring mistakes such as missing references, duplicate scenario ids, unsupported effect combinations, wrong item slots, and unreachable campaign nodes.

## Resource Recipes

### Unit

Create a `UnitDefinition`, then assign:

- an `AncestryDefinition`
- one or more `JobProgressDefinition` entries
- a `UnitLoadoutDefinition`

The loadout selects the current job, learned features, equipment, and tactics. Inspector reference pickers are typed so they only accept the appropriate Resource category. Content validation additionally checks that weapon, armor, helmet, and trinket references use the matching item slot.

### Job

Create a `JobDefinition`, then optionally assign:

- `SkillDefinition`
- `PassiveDefinition`
- `ReactionDefinition`
- default `TacticDefinition`

These definitions expose only the currently implemented vocabulary. An `Apply Status` skill must reference a `StatusDefinition`.

Use an `Effects Only` skill with one or more `Skill Used` effects to author cleanse/dispel, team buffs, temporary debuffs, or broad status application without adding resolver code.

### Scenario

Create enemy units, place them in an `EncounterDefinition`, and place one or more encounters in a `ScenarioDefinition`. A scenario id must be unique.

Saving the scenario under `resources/scenarios/` makes it immediately available for practice. To make it part of campaign progression, add a `CampaignScenarioNodeDefinition` to the campaign and author its unlock links.

### Triggered Effects

Add one or more `EffectDefinition` Resources to an item or scenario rule. Item effects treat `Self`, `Allied Units`, and `Enemy Units` relative to the equipped unit. Scenario rules have no owner, so use event-relative or team targets instead of `Self`.

| Trigger | Effect | Target |
| --- | --- | --- |
| Battle Start | Gain Armor, Apply Status | Self |
| Attack | Bonus Damage | Attack Target |
| Hit | Reduce Target Armor | Attack Target |
| Damaged, HP Below Threshold | Heal Self, Increase Max HP | Self |
| Kill | Heal Self | Self |
| Death | Damage Killer | Killer |

The shared authoring vocabulary is available on every supported trigger:

- `Apply Status`: applies a referenced status to event-relative, team-wide, or deterministic-random targets.
- `Remove Status`: removes one deterministic-random matching status by polarity, or a referenced specific status type.
- `Modify Stat`: temporarily modifies max HP, physical damage, magic damage, armor, or action interval for a configured number of the target's completed turns.

Supported shared triggers include battle start, turn start/completion, skill use, attack, hit, damaged, kill, death, status application/removal, and reaction triggering. A shared effect can fire at most once within one causal event chain, preventing it from recursively triggering itself forever.

Conditions can narrow these triggers. Unsupported combinations and unavailable targets fail content validation instead of silently doing nothing.

### Scenario Hook Effect

Add `EffectDefinition` Resources to a `ScenarioRuleDefinition.effects` array. The rule is active in every encounter of a scenario that references it.

For example, `Ash-Choked Rites` is authored as a Battle Start `Apply Status` effect targeting `All Units`; it no longer requires a hard-coded scenario-rule ID.

## Current Boundary

Jobs, units, equipment, encounters, scenarios, campaigns, tactics, temporary stat modifiers, status application/removal, and combinations of existing mechanics can be created without code.

Creating a genuinely new kind of mechanic still requires adding a small resolver implementation and then exposing that new option to Resources. Combat events and hook requests provide the integration points for doing that without rewriting the simulation; see `COMBAT_EVENTS.md`.
