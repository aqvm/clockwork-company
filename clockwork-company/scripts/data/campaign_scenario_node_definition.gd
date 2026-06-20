@tool
extends Resource
class_name CampaignScenarioNodeDefinition

## Scenario represented by this campaign graph node.
@export var scenario: ScenarioDefinition = null
## Scenario ids unlocked when this node's scenario is completed.
@export var unlock_scenario_ids_on_completion: Array[String] = []
## Content unlock ids granted when this node's scenario is completed.
@export var content_unlocks_on_completion: Array[String] = []
## If true, completing this node marks the campaign complete.
@export var completes_campaign := false
