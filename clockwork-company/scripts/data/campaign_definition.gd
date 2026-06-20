@tool
extends Resource
class_name CampaignDefinition

## Stable id used by saves and campaign lookup.
@export var campaign_id := ""
## Player-facing campaign name.
@export var display_name := ""
## Campaign summary shown in planning and tooltips.
@export_multiline var description := ""
## Scenario ids available at the start of a new campaign run.
@export var starting_scenario_ids: Array[String] = []
## Scenario graph nodes. Each node wraps one scenario plus unlock/completion consequences.
@export var scenario_nodes: Array[CampaignScenarioNodeDefinition] = []
## Unit ids included in the starting campaign roster.
@export var starting_roster_ids: Array[String] = []
## Content unlock ids granted at campaign start.
@export var starting_unlocks: Array[String] = []
