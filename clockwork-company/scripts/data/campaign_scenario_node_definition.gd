extends Resource
class_name CampaignScenarioNodeDefinition

@export var scenario: Resource = null
@export var unlock_scenario_ids_on_completion: Array[String] = []
@export var content_unlocks_on_completion: Array[String] = []
@export var completes_campaign := false
