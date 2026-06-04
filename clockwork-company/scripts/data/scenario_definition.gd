extends Resource
class_name ScenarioDefinition

@export var scenario_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export_multiline var story_intro := ""
@export_multiline var story_outro := ""
@export_range(1, 6, 1) var party_size := 3
@export var encounters: Array[Resource] = []
@export var scenario_rules: Array[Resource] = []
@export_range(1, 99, 1) var recommended_level_min := 1
@export_range(1, 99, 1) var recommended_level_max := 1
@export var tags: Array[String] = []
@export var rewards: Array[Resource] = []
@export var content_unlocks: Array[String] = []
