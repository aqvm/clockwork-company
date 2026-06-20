@tool
extends Resource
class_name TagDefinition

## Stable mechanical id for this tag. Use lowercase snake_case and compare by this id, not display text.
@export var tag_id := "":
	set(value):
		tag_id = String(value).strip_edges().to_lower()
		if display_name.is_empty():
			resource_name = tag_id

## Human-facing tag label shown in the Inspector and tooltips. The resource name mirrors this value when present.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value if not value.is_empty() else tag_id

## Optional authoring note describing when to use this tag.
@export_multiline var description := ""


func _to_string() -> String:
	if not display_name.is_empty():
		return display_name
	if not tag_id.is_empty():
		return tag_id
	return "TagDefinition"
