extends Resource
class_name CampaignDefinition

@export var campaign_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var starting_scenario_ids: Array[String] = []
@export var scenario_nodes: Array[CampaignScenarioNodeDefinition] = []
@export var starting_roster_ids: Array[String] = []
@export var starting_unlocks: Array[String] = []
