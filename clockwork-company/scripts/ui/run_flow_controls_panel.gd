extends HBoxContainer
class_name RunFlowControlsPanel

signal run_requested
signal mods_menu_requested
signal palette_requested
signal save_campaign_requested
signal load_campaign_requested
signal loss_test_requested
signal phase7_run_requested
signal reward_requested(index: int)
signal continue_requested
signal equipment_requested(index: int)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared

const MAX_EQUIPMENT_BUTTONS := 12
const DEBUG_CONTROL_FONT_SIZE := 12

@onready var run_button: Button = %RunButton
@onready var mods_menu_button: Button = %ModsMenuButton

var reward_buttons: Array[Button] = []
var equipment_buttons: Array[Button] = []
var continue_button: Button = null
var loss_test_button: Button = null
var phase7_run_button: Button = null
var palette_button: Button = null
var save_campaign_button: Button = null
var load_campaign_button: Button = null


func _ready() -> void:
	run_button.pressed.connect(func(): run_requested.emit())
	mods_menu_button.pressed.connect(func(): mods_menu_requested.emit())
	_add_extra_controls()


func show_palette_button(is_colorblind_enabled: bool) -> void:
	palette_button.text = "Palette: Colorblind" if is_colorblind_enabled else "Palette: Default"


func show_mod_pack_count(enabled_count: int, available_count: int) -> void:
	if available_count <= 0:
		mods_menu_button.disabled = true
		mods_menu_button.text = "Mods (none)"
		return
	mods_menu_button.disabled = false
	mods_menu_button.text = "Mods (%d/%d)" % [enabled_count, available_count]


func show_run_button(text: String, is_disabled: bool) -> void:
	run_button.text = text
	run_button.disabled = is_disabled


func set_campaign_buttons_disabled(is_disabled: bool) -> void:
	save_campaign_button.disabled = is_disabled
	load_campaign_button.disabled = is_disabled


func set_debug_buttons_disabled(is_disabled: bool) -> void:
	loss_test_button.disabled = is_disabled
	phase7_run_button.disabled = is_disabled


func show_reward_options(options: Array, is_disabled: bool) -> void:
	for index in reward_buttons.size():
		var reward_button := reward_buttons[index]
		var has_option: bool = index < options.size()
		reward_button.visible = has_option
		reward_button.disabled = is_disabled or not has_option
		if has_option:
			var option: Dictionary = options[index]
			reward_button.text = String(option["label"])
			_bind_resource_tooltip(reward_button, option.get("resource", null))


func show_continue_button(is_visible: bool, text: String, is_disabled: bool) -> void:
	continue_button.visible = is_visible
	continue_button.disabled = is_disabled
	if is_visible:
		continue_button.text = text


func show_equipment_options(options: Array, is_disabled: bool) -> void:
	for index in equipment_buttons.size():
		var equipment_button := equipment_buttons[index]
		var has_option: bool = index < options.size()
		equipment_button.visible = has_option
		equipment_button.disabled = is_disabled or not has_option
		if has_option:
			var option: Dictionary = options[index]
			equipment_button.text = String(option["label"])


func mods_button_rect() -> Rect2:
	return mods_menu_button.get_global_rect()


func _add_extra_controls() -> void:
	palette_button = Button.new()
	palette_button.text = "Palette: Default"
	palette_button.pressed.connect(func(): palette_requested.emit())
	add_child(palette_button)

	save_campaign_button = Button.new()
	save_campaign_button.text = "Save Campaign"
	save_campaign_button.pressed.connect(func(): save_campaign_requested.emit())
	add_child(save_campaign_button)

	load_campaign_button = Button.new()
	load_campaign_button.text = "Load Campaign"
	load_campaign_button.pressed.connect(func(): load_campaign_requested.emit())
	add_child(load_campaign_button)

	var debug_label := Label.new()
	debug_label.text = "Debug harness"
	debug_label.modulate = Color(0.65, 0.65, 0.65)
	debug_label.add_theme_font_size_override("font_size", DEBUG_CONTROL_FONT_SIZE)
	add_child(debug_label)

	loss_test_button = Button.new()
	loss_test_button.text = "Loss Test"
	_style_debug_button(loss_test_button)
	loss_test_button.pressed.connect(func(): loss_test_requested.emit())
	add_child(loss_test_button)

	phase7_run_button = Button.new()
	phase7_run_button.text = "Phase 7 Run"
	_style_debug_button(phase7_run_button)
	phase7_run_button.pressed.connect(func(): phase7_run_requested.emit())
	add_child(phase7_run_button)

	for index in 3:
		var reward_button := Button.new()
		reward_button.visible = false
		reward_button.pressed.connect(_on_reward_button_pressed.bind(index))
		add_child(reward_button)
		reward_buttons.append(reward_button)

	continue_button = Button.new()
	continue_button.text = "Continue to Next Fight"
	continue_button.visible = false
	continue_button.pressed.connect(func(): continue_requested.emit())
	add_child(continue_button)

	for index in MAX_EQUIPMENT_BUTTONS:
		var equipment_button := Button.new()
		equipment_button.visible = false
		equipment_button.pressed.connect(_on_equipment_button_pressed.bind(index))
		add_child(equipment_button)
		equipment_buttons.append(equipment_button)


func _style_debug_button(button: Button) -> void:
	button.flat = true
	button.modulate = Color(0.75, 0.75, 0.75)
	button.add_theme_font_size_override("font_size", DEBUG_CONTROL_FONT_SIZE)


func _on_reward_button_pressed(index: int) -> void:
	reward_requested.emit(index)


func _on_equipment_button_pressed(index: int) -> void:
	equipment_requested.emit(index)


func _bind_resource_tooltip(control: Control, resource) -> void:
	control.set_meta("tooltip_resource", resource)
	if control.has_meta("resource_tooltip_bound"):
		return
	control.set_meta("resource_tooltip_bound", true)
	control.mouse_entered.connect(_on_resource_tooltip_entered.bind(control))
	control.mouse_exited.connect(func(): tooltip_cleared.emit())


func _on_resource_tooltip_entered(source: Control) -> void:
	var resource = source.get_meta("tooltip_resource", null)
	if resource is Resource:
		resource_tooltip_requested.emit(source, resource)
