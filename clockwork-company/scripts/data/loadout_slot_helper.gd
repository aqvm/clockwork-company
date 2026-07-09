extends RefCounted

const EQUIPMENT_SLOTS := ["Weapon", "Armor", "Helmet", "Trinket"]


static func can_equip_item(unit: UnitDefinition, item: ItemDefinition) -> bool:
	if unit == null or item == null:
		return false
	var property_name := "forbid_%s" % item.slot.to_lower()
	var job_forbids := unit.loadout != null and unit.loadout.current_job != null and bool(unit.loadout.current_job.get(property_name))
	var ancestry_forbids := unit.ancestry != null and bool(unit.ancestry.get(property_name))
	return not (job_forbids or ancestry_forbids)


static func loadout_item(loadout: UnitLoadoutDefinition, slot: String) -> ItemDefinition:
	if loadout == null:
		return null
	if slot == "Weapon":
		return loadout.weapon
	if slot == "Armor":
		return loadout.armor
	if slot == "Helmet":
		return loadout.helmet
	if slot == "Trinket":
		return loadout.trinket
	return null


static func set_loadout_item(loadout: UnitLoadoutDefinition, slot: String, item: ItemDefinition) -> void:
	if loadout == null:
		return
	if slot == "Weapon":
		loadout.weapon = item
	elif slot == "Armor":
		loadout.armor = item
	elif slot == "Helmet":
		loadout.helmet = item
	elif slot == "Trinket":
		loadout.trinket = item


static func item_name_or_none(item: ItemDefinition) -> String:
	return item.display_name if item != null else "none"
