extends TabContainer

const NumberUtil := preload("res://scripts/number_util.gd")
const BedCatalog := preload("res://data/bed_catalog.gd")
const WeaponCatalog := preload("res://data/weapon_catalog.gd")
const HelperCatalog := preload("res://data/helper_catalog.gd")
const SkillCatalog := preload("res://data/skill_catalog.gd")
const WorldCatalog := preload("res://data/world_catalog.gd")
const QuestCatalog := preload("res://data/quest_catalog.gd")
const AchievementCatalog := preload("res://data/achievement_catalog.gd")
const TreeCatalog := preload("res://data/tree_catalog.gd")
const ContentCatalog := preload("res://data/content_catalog.gd")

var _rows: Dictionary = {}
var _prestige_armed: bool = false


func _ready() -> void:
	_apply_shop_theme()
	_build_tabs()
	GameManager.gold_changed.connect(func(_g: float) -> void: _refresh())
	GameManager.upgrades_changed.connect(_refresh)
	GameManager.stats_changed.connect(_refresh)
	GameManager.skill_state_changed.connect(_refresh)
	GameManager.stage_changed.connect(func(_s: int) -> void: _refresh())
	GameManager.combat_paused_changed.connect(func(_p: bool) -> void: _refresh())
	_refresh()


func select_tab_index(index: int) -> void:
	current_tab = clampi(index, 0, maxi(0, get_tab_count() - 1))


func _tab_index(tab_name: String) -> int:
	for i in get_tab_count():
		if get_tab_control(i).name == tab_name:
			return i
	return 0


func _process(_delta: float) -> void:
	if get_tab_count() == 0:
		return
	var page := get_tab_control(current_tab)
	if page and page.name == "SKILLS":
		_refresh_skills()


func _build_tabs() -> void:
	_make_scroll_tab("BED")
	_make_scroll_tab("WEAPONS")
	_make_scroll_tab("HELPERS")
	_make_scroll_tab("SKILLS")
	_make_scroll_tab("WORLDS")
	_make_scroll_tab("ACHIEVEMENTS")
	_make_scroll_tab("PRESTIGE")
	if get_tab_count() > 0:
		set_tab_title(0, "COMBAT")
	set_tab_title(_tab_index("BED"), "BED")
	set_tab_title(_tab_index("WEAPONS"), "WEAPONS")
	set_tab_title(_tab_index("HELPERS"), "HELPERS")
	set_tab_title(_tab_index("SKILLS"), "SKILLS")
	set_tab_title(_tab_index("WORLDS"), "WORLDS")
	set_tab_title(_tab_index("ACHIEVEMENTS"), "TROPHIES")
	set_tab_title(_tab_index("PRESTIGE"), "PRESTIGE")


func _make_scroll_tab(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = title
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _shop_panel_style())
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	scroll.resized.connect(func() -> void:
		list.custom_minimum_size.x = maxf(120.0, scroll.size.x - 12.0)
	)
	return list


func _shop_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.13, 0.18, 0.94)
	style.border_color = Color(0.91, 0.76, 0.42, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 22.0
	style.content_margin_top = 20.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 20.0
	return style


func _apply_shop_theme() -> void:
	var gold := Color(0.91, 0.76, 0.42)
	var cream := Color(0.96, 0.93, 0.82)
	var muted := Color(0.72, 0.7, 0.64)
	var shop_theme := Theme.new()
	var selected := _tab_style(Color(0.14, 0.16, 0.22, 1), gold, true)
	var unselected := _tab_style(Color(0.08, 0.09, 0.12, 0.96), Color(0.42, 0.4, 0.34, 0.7), false)
	var hovered := _tab_style(Color(0.18, 0.17, 0.14, 1), Color(0.91, 0.76, 0.42, 0.85), false)
	for control_type in ["TabContainer", "TabBar"]:
		shop_theme.set_stylebox("tab_selected", control_type, selected)
		shop_theme.set_stylebox("tab_unselected", control_type, unselected)
		shop_theme.set_stylebox("tab_hovered", control_type, hovered)
		shop_theme.set_stylebox("tab_disabled", control_type, unselected)
		shop_theme.set_stylebox("tab_focus", control_type, selected)
		shop_theme.set_stylebox("tabbar_background", control_type, _flat(Color(0.07, 0.08, 0.11, 1), Color(0, 0, 0, 0), 0, 0))
		shop_theme.set_color("font_selected_color", control_type, gold)
		shop_theme.set_color("font_unselected_color", control_type, muted)
		shop_theme.set_color("font_hovered_color", control_type, cream)
		shop_theme.set_color("font_disabled_color", control_type, Color(0.45, 0.45, 0.48))
		shop_theme.set_font_size("font_size", control_type, 13)
	shop_theme.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	var tab_btn_hover := _flat(Color(0.26, 0.22, 0.14, 1), gold, 1, 6)
	var tab_btn_pressed := _flat(Color(0.36, 0.28, 0.14, 1), gold, 1, 6)
	for style_name in ["button_highlight", "increment", "decrement", "increment_highlight", "decrement_highlight"]:
		shop_theme.set_stylebox(style_name, "TabBar", tab_btn_hover)
	for style_name in ["button_pressed", "increment_pressed", "decrement_pressed"]:
		shop_theme.set_stylebox(style_name, "TabBar", tab_btn_pressed)
	shop_theme.set_stylebox("normal", "Button", _flat(Color(0.18, 0.16, 0.12, 1), Color(0.91, 0.76, 0.42, 0.75), 1, 6))
	shop_theme.set_stylebox("hover", "Button", _flat(Color(0.28, 0.23, 0.14, 1), gold, 1, 6))
	shop_theme.set_stylebox("pressed", "Button", _flat(Color(0.4, 0.32, 0.16, 1), gold, 1, 6))
	shop_theme.set_stylebox("disabled", "Button", _flat(Color(0.12, 0.13, 0.16, 1), Color(0.35, 0.36, 0.4, 0.7), 1, 6))
	shop_theme.set_stylebox("focus", "Button", _flat(Color(0.18, 0.16, 0.12, 1), gold, 1, 6))
	shop_theme.set_color("font_color", "Button", cream)
	shop_theme.set_color("font_hover_color", "Button", gold)
	shop_theme.set_color("font_pressed_color", "Button", Color(1, 0.95, 0.8))
	shop_theme.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.52))
	shop_theme.set_color("font_focus_color", "Button", cream)
	shop_theme.set_font_size("font_size", "Button", 16)
	theme = shop_theme


func _tab_style(bg: Color, border: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 0 if selected else 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _flat(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _list(tab_name: String) -> VBoxContainer:
	return get_node("%s/Scroll/List" % tab_name) as VBoxContainer


func _refresh() -> void:
	_refresh_bed()
	_refresh_weapons()
	_refresh_helpers()
	_refresh_skills()
	_refresh_worlds()
	_refresh_achievements()
	_refresh_prestige()


func _refresh_bed() -> void:
	var list := _list("BED")
	_clear_if_needed(list, "bed")
	var current := GameManager.get_bed()
	var nxt := BedCatalog.next(GameManager.bed_level)
	_label(list, "bed_name", String(current["name"]), 24, Color(0.91, 0.76, 0.42))
	_label(list, "bed_gold", "Gold: +%s" % NumberUtil.format_percent(float(current["gold_mult"]) - 1.0), 16, Color(0.75, 0.86, 0.62))
	_label(list, "bed_auto", "Auto Damage: +%s" % NumberUtil.format_percent(float(current["auto_mult"]) - 1.0), 16, Color(0.75, 0.86, 0.62))
	if nxt.is_empty():
		_label(list, "bed_next", "Max comfort achieved.", 16, Color(0.78, 0.8, 0.84))
		_button(list, "bed_buy", "MAXED", true, func() -> void: pass)
	else:
		_label(list, "bed_next", "Next: %s" % String(nxt["name"]), 16, Color(0.78, 0.8, 0.84))
		var cost := float(nxt["cost"])
		_button(list, "bed_buy", "UPGRADE  %s Gold" % NumberUtil.format(cost), GameManager.gold < cost, GameManager.upgrade_bed)


func _refresh_weapons() -> void:
	var list := _list("WEAPONS")
	_clear_if_needed(list, "weapons")
	for weapon in WeaponCatalog.all():
		var id := String(weapon["id"])
		var level := int(GameManager.weapon_levels.get(id, 0))
		var unlocked_stage := int(weapon["unlock_stage"])
		var box := _box(list, "w_%s" % id)
		_label(box, "w_%s_name" % id, String(weapon["name"]), 20, Color(0.96, 0.93, 0.82))
		_label(box, "w_%s_desc" % id, String(weapon["description"]), 14, Color(0.78, 0.8, 0.84))
		if level <= 0 and GameManager.stage < unlocked_stage:
			_label(box, "w_%s_lv" % id, "Unlocks at stage %s" % unlocked_stage, 15, Color(0.7, 0.7, 0.72))
			continue
		_label(box, "w_%s_lv" % id, "Level %s  |  Damage +%s" % [level, NumberUtil.format_int(float(weapon["damage_per_level"]) * float(maxi(level, 1)))], 15, Color(0.75, 0.86, 0.62))
		var cost := GameManager.get_weapon_upgrade_cost(id)
		var buy_text := "UNLOCK  %s" % NumberUtil.format(cost) if level <= 0 else "UPGRADE  %s" % NumberUtil.format(cost)
		_button(box, "w_%s_buy" % id, buy_text, GameManager.gold < cost, GameManager.unlock_or_upgrade_weapon.bind(id))
		if level > 0:
			var equipped := GameManager.equipped_weapon == id
			_button(box, "w_%s_eq" % id, "EQUIPPED" if equipped else "EQUIP", equipped, GameManager.equip_weapon.bind(id))


func _refresh_helpers() -> void:
	var list := _list("HELPERS")
	_clear_if_needed(list, "helpers")
	for helper in HelperCatalog.all():
		var id := String(helper["id"])
		var box := _box(list, "h_%s" % id)
		var level := GameManager.get_helper_level(id)
		_label(box, "h_%s_name" % id, String(helper["name"]), 20, Color(0.96, 0.93, 0.82))
		_label(box, "h_%s_desc" % id, String(helper["description"]), 14, Color(0.78, 0.8, 0.84))
		var extra := "Level %s" % level
		match String(helper["role"]):
			"dps", "ranged_dps", "magic_dps":
				extra += "  |  DPS %s" % NumberUtil.format_int(GameManager.get_helper_dps(id))
			"heal":
				extra += "  |  Comfort regen"
			"weapon":
				extra += "  |  Weapon +%s" % NumberUtil.format_percent(level * float(helper["base_value"]))
			"gold":
				extra += "  |  Gold +%s" % NumberUtil.format_percent(level * float(helper["base_value"]))
		_label(box, "h_%s_lv" % id, extra, 15, Color(0.75, 0.86, 0.62))
		var cost := GameManager.get_helper_cost(id)
		_button(box, "h_%s_buy" % id, "HIRE / UPGRADE  %s" % NumberUtil.format(cost), GameManager.gold < cost, GameManager.buy_helper.bind(id))


func _refresh_skills() -> void:
	var list := _list("SKILLS")
	_clear_if_needed(list, "skills")
	_label(list, "skill_hint", "Q W E R T  to cast", 14, Color(0.7, 0.72, 0.78))
	for skill in SkillCatalog.all():
		var id := String(skill["id"])
		var box := _box(list, "s_%s" % id)
		_label(box, "s_%s_name" % id, String(skill["name"]), 20, Color(0.96, 0.93, 0.82))
		_label(box, "s_%s_desc" % id, String(skill["description"]), 14, Color(0.78, 0.8, 0.84))
		var unlock := int(skill["unlock_stage"])
		var ready := GameManager.is_skill_ready(id)
		var cd := GameManager.get_skill_cooldown(id)
		var paused := GameManager.is_combat_paused()
		var text := "USE"
		var disabled := not ready or paused
		if GameManager.stage < unlock:
			text = "Stage %s" % unlock
			disabled = true
		elif paused:
			text = "DOWN"
			disabled = true
		elif cd > 0.0:
			text = "CD %ss" % str(int(ceil(cd)))
			disabled = true
		_button(box, "s_%s_use" % id, text, disabled, GameManager.try_skill.bind(id))


func _refresh_worlds() -> void:
	var list := _list("WORLDS")
	_clear_if_needed(list, "worlds")
	var current := GameManager.get_world()
	for world in WorldCatalog.all():
		var box := _box(list, "world_%s" % str(world["id"]))
		var unlocked := WorldCatalog.is_unlocked(GameManager.highest_stage, world)
		var here := int(world["id"]) == int(current["id"])
		var title := "WORLD %s — %s" % [str(world["id"]), String(world["name"])]
		if here:
			title += "  (HERE)"
		_label(box, "world_%s_name" % str(world["id"]), title, 18, Color(0.91, 0.76, 0.42) if here else Color(0.96, 0.93, 0.82))
		var body := "Stages %s-%s" % [str(world["stage_start"]), str(world["stage_end"])]
		if not unlocked:
			body = "Locked until stage %s" % str(world["stage_start"])
		_label(box, "world_%s_info" % str(world["id"]), body, 14, Color(0.78, 0.8, 0.84))


func _refresh_achievements() -> void:
	var list := _list("ACHIEVEMENTS")
	_clear_if_needed(list, "ach")
	_label(list, "q_title", "QUESTS", 20, Color(0.91, 0.76, 0.42))
	for quest in QuestCatalog.all():
		var id := String(quest["id"])
		var box := _box(list, "q_%s" % id)
		_label(box, "q_%s_name" % id, String(quest["name"]), 18, Color(0.96, 0.93, 0.82))
		_label(box, "q_%s_desc" % id, String(quest["description"]), 14, Color(0.78, 0.8, 0.84))
		var claimed := GameManager.claimed_quests.has(id) and not bool(quest.get("repeatable", false))
		if claimed:
			_label(box, "q_%s_pr" % id, "Completed", 15, Color(0.75, 0.86, 0.62))
			if _rows.has("q_%s_claim" % id):
				_rows["q_%s_claim" % id].visible = false
		else:
			_label(box, "q_%s_pr" % id, GameManager.quest_progress_text(id), 15, Color(0.75, 0.86, 0.62))
			var can_claim := GameManager.is_quest_complete(id)
			var claim_btn := _button(box, "q_%s_claim" % id, "CLAIM", not can_claim, GameManager.claim_quest.bind(id))
			claim_btn.visible = true
	_label(list, "a_title", "ACHIEVEMENTS", 20, Color(0.91, 0.76, 0.42))
	for item in AchievementCatalog.all():
		var id := String(item["id"])
		var box := _box(list, "a_%s" % id)
		var unlocked := GameManager.unlocked_achievements.has(id)
		_label(box, "a_%s_name" % id, String(item["name"]), 18, Color(0.91, 0.76, 0.42) if unlocked else Color(0.7, 0.7, 0.72))
		_label(box, "a_%s_desc" % id, String(item["description"]), 14, Color(0.78, 0.8, 0.84))
		_label(box, "a_%s_st" % id, "UNLOCKED" if unlocked else "Locked", 14, Color(0.75, 0.86, 0.62) if unlocked else Color(0.6, 0.6, 0.62))


func _refresh_prestige() -> void:
	var list := _list("PRESTIGE")
	_clear_if_needed(list, "prestige")
	_label(list, "pt_tokens", "Lazy Tokens: %s" % str(GameManager.lazy_tokens), 22, Color(0.91, 0.76, 0.42))
	_label(list, "pt_count", "Prestiges: %s" % str(GameManager.prestige_count), 16, Color(0.78, 0.8, 0.84))
	if GameManager.can_prestige():
		_label(list, "pt_reward", "Reset for %s Lazy Tokens" % str(GameManager.get_prestige_token_reward()), 16, Color(0.75, 0.86, 0.62))
		var text := "CONFIRM PRESTIGE" if _prestige_armed else "PRESTIGE"
		_button(list, "pt_go", text, false, _on_prestige_pressed)
	else:
		_prestige_armed = false
		_label(list, "pt_reward", "Reach stage %s to prestige." % str(int(GameManager.BALANCE.prestige_unlock_stage)), 16, Color(0.78, 0.8, 0.84))
		_button(list, "pt_go", "LOCKED", true, func() -> void: pass)
	_label(list, "pt_shop", "PERMANENT SHOP", 20, Color(0.91, 0.76, 0.42))
	for item in ContentCatalog.shop():
		var id := String(item["id"])
		var level := int(GameManager.prestige_levels.get(id, 0))
		var cost := int(item.get("base_cost", 1)) + level
		var box := _box(list, "ps_%s" % id)
		_label(box, "ps_%s_name" % id, "%s  (Lv %s)" % [String(item["name"]), str(level)], 16, Color(0.96, 0.93, 0.82))
		_button(box, "ps_%s_buy" % id, "BUY  %s tokens" % str(cost), GameManager.lazy_tokens < cost, GameManager.buy_prestige_upgrade.bind(id))
	_label(list, "pt_tree", "LAZY TREE", 20, Color(0.91, 0.76, 0.42))
	var branch := ""
	for node in TreeCatalog.all():
		var node_branch := String(node["branch"])
		if node_branch != branch:
			branch = node_branch
			_label(list, "pt_br_%s" % branch, branch, 18, Color(0.75, 0.86, 0.62))
		_refresh_tree_node(list, node)


func _refresh_tree_node(list: VBoxContainer, node: Dictionary) -> void:
	var id := String(node["id"])
	var owned := GameManager.tree_nodes.has(id)
	var box := _box(list, "tn_%s" % id)
	_label(box, "tn_%s_name" % id, String(node["name"]), 16, Color(0.96, 0.93, 0.82))
	_label(box, "tn_%s_desc" % id, String(node["description"]), 13, Color(0.78, 0.8, 0.84))
	if owned:
		_button(box, "tn_%s_buy" % id, "OWNED", true, func() -> void: pass)
		return
	var locked := false
	for req in node.get("requires", []):
		if not GameManager.tree_nodes.has(req):
			locked = true
	if GameManager.highest_stage < int(node.get("min_highest_stage", 0)):
		locked = true
	if GameManager.prestige_count < int(node.get("min_prestige", 0)):
		locked = true
	var cost := int(node.get("cost", 1))
	var text := "LOCKED" if locked else "BUY  %s tokens" % str(cost)
	_button(box, "tn_%s_buy" % id, text, locked or GameManager.lazy_tokens < cost, GameManager.buy_tree_node.bind(id))


func _on_prestige_pressed() -> void:
	if _prestige_armed:
		_prestige_armed = false
		GameManager.do_prestige()
	else:
		_prestige_armed = true
		_refresh_prestige()


func _clear_if_needed(list: VBoxContainer, key: String) -> void:
	if list.get_child_count() == 0:
		_rows[key] = true


func _box(parent: Control, id: String) -> VBoxContainer:
	if _rows.has(id):
		return _rows[id]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)
	_rows[id] = box
	return box


func _label(parent: Control, id: String, text: String, size: int, color: Color) -> Label:
	var label: Label
	if _rows.has(id):
		label = _rows[id]
	else:
		label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(label)
		_rows[id] = label
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(parent: Control, id: String, text: String, disabled: bool, callback: Callable) -> Button:
	var button: Button
	if _rows.has(id):
		button = _rows[id]
	else:
		button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(callback)
		parent.add_child(button)
		_rows[id] = button
	button.text = text
	button.disabled = disabled
	return button
