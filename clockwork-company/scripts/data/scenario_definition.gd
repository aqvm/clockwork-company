@tool
extends Resource
class_name ScenarioDefinition

## Stable id used by campaigns, unlocks, saves, and JSON references. Must be unique.
@export var scenario_id := ""
## Player-facing scenario name.
@export var display_name := ""
## Short scenario summary shown in planning and tooltips.
@export_multiline var description := ""
## Story text shown before the scenario begins.
@export_multiline var story_intro := ""
## Story text shown after the scenario is completed.
@export_multiline var story_outro := ""
## Maximum deployed party size for this scenario.
@export_range(1, 6, 1) var party_size := 3
## Ordered encounters fought during this scenario.
@export var encounters: Array[EncounterDefinition] = []
## Scenario-wide rules active in every encounter.
@export var scenario_rules: Array[ScenarioRuleDefinition] = []
## Scenario tier used by campaign progression and reward pacing.
@export_range(1, 5, 1) var tier := 1
## Lower recommended total/job level for planning display.
@export_range(1, 99, 1) var recommended_level_min := 1
## Upper recommended total/job level for planning display.
@export_range(1, 99, 1) var recommended_level_max := 1
## Shared TagDefinition resources for filtering and content organization.
@export var tags: Array[Resource] = []
## Rewards offered on completion.
@export var rewards: Array[RewardDefinition] = []
## Content unlock ids granted on completion.
@export var content_unlocks: Array[String] = []
