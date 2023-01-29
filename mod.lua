if not HopLib then
	return
end

if not KillFeed then

	_G.KillFeed = {}
	KillFeed.mod_path = ModPath
	KillFeed.save_path = SavePath
	KillFeed.kill_infos = {}
	KillFeed.assist_information = {}
	KillFeed.settings = {
		x_align = 1,
		y_align = 1,
		x_pos = 0.03,
		y_pos = 0.15,
		style = 1,
		font_size = tweak_data.menu.pd2_small_font_size,
		spacing = 0,
		max_shown = 5,
		lifetime = 3,
		fade_in_time = 0.25,
		fade_out_time = 0.25,
		show_local_player_kills = true,
		show_remote_player_kills = true,
		show_team_ai_kills = true,
		show_joker_kills = true,
		show_sentry_kills = true,
		show_npc_kills = true,
		show_assists = true,
		special_kills_only = false,
		update_rate = 1 / 30,
		assist_time = 4
	}
	KillFeed.colors = {
		default = Color.white,
		special = Color(tweak_data.contour.character.dangerous_color:unpack()),
		text = Color.white:with_alpha(0.8),
		skull = Color.yellow
	}

	local icon_paths = { SavePath .. "kill_feed_icon.png", SavePath .. "kill_feed_icon.dds", SavePath .. "kill_feed_icon.texture" }
	for _, path in pairs(icon_paths) do
		if io.file_is_readable(path) then
			KillFeed.custom_icon_path = "guis/textures/kill_feed_icon"
			HopLib:load_assets({{ ext = Idstring("texture"), path = KillFeed.custom_icon_path, file = path }})
			break
		end
	end

	local KillInfo = class()
	KillFeed.KillInfo = KillInfo

	function KillInfo:init(attacker_info, target_info, assist_info, status, damage_info)
		self._panel = KillFeed._panel:panel({
			alpha = 0,
			layer = 100,
		})

		local w, h = 0, KillFeed.settings.font_size

		local attacker_name, attacker_color, target_name, target_color, assist_name, assist_color

		attacker_name = attacker_info:nickname()
		attacker_color = (attacker_info:is_special() or attacker_info:is_boss()) and KillFeed.colors.special or attacker_info:color_id() and attacker_info:color_id() < #tweak_data.chat_colors and tweak_data.chat_colors[attacker_info:color_id()]

		target_name = target_info:nickname()
		target_color = (target_info:is_special() or target_info:is_boss()) and KillFeed.colors.special or target_info:color_id() and target_info:color_id() < #tweak_data.chat_colors and tweak_data.chat_colors[target_info:color_id()]

		if assist_info then
			assist_name = assist_info:nickname()
			assist_color = (assist_info:is_special() or assist_info:is_boss()) and KillFeed.colors.special or assist_info:color_id() and assist_info:color_id() < #tweak_data.chat_colors and tweak_data.chat_colors[assist_info:color_id()]
		end

		self._panel_h_add = KillFeed.settings.spacing

		local show_assist = assist_info and assist_name ~= attacker_name
		local font = WFHud and WFHud.fonts.default_no_shadow or tweak_data.menu.pd2_large_font

		if KillFeed.settings.style == 1 then
			local attacker_str = attacker_name .. (show_assist and ("+" .. assist_name) or "")

			local attacker_text = self._panel:text({
				text = attacker_str,
				font = font,
				font_size = KillFeed.settings.font_size,
				color = KillFeed.colors.text
			})
			local _, _, tw = attacker_text:text_rect()
			w = tw

			local la = utf8.len(attacker_name)
			attacker_text:set_range_color(0, la, attacker_color or KillFeed.colors.default)
			if show_assist then
				attacker_text:set_range_color(la + 1, utf8.len(attacker_str), assist_color or KillFeed.colors.default)
			end

			local skull = self._panel:bitmap({
				texture = KillFeed.custom_icon_path or "guis/textures/pd2/risklevel_blackscreen",
				color = not KillFeed.custom_icon_path and KillFeed.colors.skull,
				x = w
			})
			skull:set_size((skull:texture_width() / skull:texture_height()) * h, h)
			skull:set_center_y(h * 0.5)
			w = w + skull:w()

			local target_text = self._panel:text({
				text = target_name,
				font = font,
				font_size = KillFeed.settings.font_size,
				color = target_color or KillFeed.colors.default,
				x = w
			})
			local _, _, tw = target_text:text_rect()
			w = w + tw
		elseif KillFeed.settings.style >= 2 and KillFeed.settings.style <= 4 then
			local kill_text, assist_text
			if KillFeed.settings.style == 2 then
				assist_text = " " .. KillFeed:get_localized_text("KillFeed_text_and") .. " "
				kill_text = attacker_name .. (show_assist and (assist_text .. assist_name) or "") .. " " .. KillFeed:get_localized_text("KillFeed_text_" .. status, show_assist) .. " " .. target_name
			elseif KillFeed.settings.style == 3 then
				local slang = KillFeed.killtexts and table.random(KillFeed.killtexts) or "killed"
				assist_text = " " .. KillFeed:get_localized_text("KillFeed_text_and") .. " "
				kill_text = attacker_name .. (show_assist and (assist_text .. assist_name) or "") .. " " .. slang .. " " .. target_name
			elseif KillFeed.settings.style == 4 then
				show_assist = false
				kill_text = attacker_name .. " [" .. self:_get_weapon_name(damage_info) .. "] " .. target_name
			end
			local text = self._panel:text({
				text = kill_text,
				font = font,
				font_size = KillFeed.settings.font_size,
				color = KillFeed.settings.style == 1 and KillFeed.colors.skull or KillFeed.colors.text
			})
			local _, _, tw = text:text_rect()
			w = tw

			local l = utf8.len(kill_text)
			local la = utf8.len(attacker_name)
			text:set_range_color(0, la, attacker_color or KillFeed.colors.default)
			text:set_range_color(l - utf8.len(target_name), l, target_color or KillFeed.colors.default)
			if show_assist then
				l = utf8.len(assist_text)
				text:set_range_color(la, la + l, KillFeed.colors.text)
				text:set_range_color(la + l, la + l + utf8.len(assist_name), assist_color or KillFeed.colors.default)
			end
		elseif KillFeed.settings.style == 5 then
			self._panel_h_add = self._panel_h_add - h

			h = KillFeed.settings.font_size * 2
			local text = self._panel:text({
				text = attacker_name,
				font = font,
				font_size = KillFeed.settings.font_size,
				color = attacker_color or KillFeed.colors.default,
				vertical = "center",
				h = h
			})
			local _, _, tw = text:text_rect()
			w = w + tw

			local weapon_icon = self:_get_weapon_icon(damage_info)
			if weapon_icon then
				local bitmap = self._panel:bitmap({
					texture = weapon_icon[1],
					x = w,
				})
				local bw, bh = bitmap:texture_width(), bitmap:texture_height()
				if weapon_icon[2] then
					bitmap:set_texture_rect(bw, 0, -bw, bh)
				end
				bw = bw * (h / bh)
				bitmap:set_size(bw, h)
				w = w + bw
			else
				local bitmap = self._panel:bitmap({
					texture = "guis/textures/pd2/risklevel_blackscreen",
					alpha = 0.5,
					x = w + 8,
					w = h * 0.75,
					h = h * 0.75
				})
				bitmap:set_center_y(h * 0.5)
				w = w + bitmap:w() + 16
			end

			text = self._panel:text({
				x = w,
				text = target_name,
				font = font,
				font_size = KillFeed.settings.font_size,
				color = target_color or KillFeed.colors.default,
				vertical = "center",
				h = h
			})
			_, _, tw = text:text_rect()
			w = w + tw
		end

		self._panel:set_size(w, h)

		if KillFeed.settings.x_align == 1 then
			self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
		elseif KillFeed.settings.x_align == 2 then
			self._panel:set_center(KillFeed._panel:w() * KillFeed.settings.x_pos)
		else
			self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
		end

		local offset = #KillFeed.kill_infos
		if KillFeed.settings.y_align == 1 then
			self._panel:set_top(KillFeed._panel:h() * KillFeed.settings.y_pos + (offset - 1) * (self._panel:h() + self._panel_h_add))
		else
			self._panel:set_bottom(KillFeed._panel:h() * KillFeed.settings.y_pos - (offset + 1) * (self._panel:h() + self._panel_h_add))
		end

		self._created_t = KillFeed._t
		self._lifetime = KillFeed.settings.lifetime + KillFeed.settings.fade_in_time + KillFeed.settings.fade_out_time
		table.insert(KillFeed.kill_infos, self)
	end

	function KillInfo:update(t, offset)
		if self.dead then
			return
		end
		local f = (t - self._created_t) / self._lifetime
		if f > 1 then
			self.dead = true
			return
		end
		self._panel:set_alpha(math.min(f / (KillFeed.settings.fade_in_time / self._lifetime), (1 - f) / (KillFeed.settings.fade_out_time / self._lifetime), 1))

		local pos = KillFeed.settings.y_align == 1 and self._panel:top() or self._panel:bottom()
		if KillFeed.settings.y_align == 1 then
			self._panel:set_top(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos + offset * (self._panel:h() + self._panel_h_add)) - pos) / 2)
		else
			self._panel:set_bottom(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos - offset * (self._panel:h() + self._panel_h_add)) - pos) / 2)
		end
	end

	function KillInfo:update_x()
		if KillFeed.settings.x_align == 1 then
			self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
		elseif KillFeed.settings.x_align == 2 then
			self._panel:set_center(KillFeed._panel:w() * KillFeed.settings.x_pos)
		else
			self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
		end
	end

	function KillInfo:destroy(pos)
		KillFeed._panel:remove(self._panel)
		if pos then
			table.remove(KillFeed.kill_infos, pos)
		end
	end

	local cached_weapon_names = {}
	function KillInfo:_get_weapon_name(damage_info)
		local id, data = self:_get_weapon_data(damage_info)
		if not id then
			return "???"
		end

		if not cached_weapon_names[id] then
			local loc_id = data and (data.name_id or data.text_id)
			if loc_id and managers.localization:exists(loc_id) then
				local name = managers.localization:text(loc_id)
				if type(data.categories) == "table" then
					for _, v in pairs(data.categories) do
						name = name:gsub("%s*" .. managers.localization:text("menu_" .. v) .. "s?$", "")
					end
				end
				name = name:gsub("%s*Sniper Rifles?$", ""):gsub("%s*Rifles?$", ""):gsub("%s*Light Machine Guns?$", ""):gsub("%s*SMGs?$", "")
				cached_weapon_names[id] = name
			else
				cached_weapon_names[id] = id:pretty(true)
			end
		end

		return cached_weapon_names[id]
	end

	local cached_weapon_icons = {}
	function KillInfo:_get_weapon_icon(damage_info)
		local id, data = self:_get_weapon_data(damage_info)
		if not id or not data then
			return
		end

		if cached_weapon_icons[id] == nil then
			local weapon_type = data.throwable and "grenades/" or data.expire_t and "melee_weapons/" or (data.use_function_name or data.FIRE_RANGE) and "deployables/" or "weapons/"
			local guis_catalog = "guis/"
			local folder = data.texture_bundle_folder or data.dlc
			if folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(folder) .. "/"
			end

			local texture_name = data.texture_name or tostring(id)
			local texture_path = guis_catalog .. "textures/pd2/blackmarket/icons/" .. weapon_type .. texture_name
			cached_weapon_icons[id] = { DB:has(Idstring("texture"), texture_path) and texture_path or false, weapon_type == "weapons/" }
		end

		return cached_weapon_icons[id]
	end

	local weapon_mapping = {
		ak47 = "ak74",
		ak47_ass = "ak74",
		akmsu_smg = "akmsu",
		asval_smg = "asval",
		ben = "benelli",
		beretta92 = "b92fs",
		c45 = "glock_17",
		g17 = "glock_17",
		heavy_snp = "g3",
		m14 = "new_m14",
		m14_sniper = "g3",
		m4 = "new_m4",
		m4_yellow = "new_m4",
		mac11 = "mac10",
		mini = "m134",
		mossberg = "huntsman",
		mp5 = "new_mp5",
		mp5_tactical = "new_mp5",
		raging_bull = "new_raging_bull",
		rpk_lmg = "rpk",
		scar_murky = "scar",
		sg417 = "contraband",
		sr2_smg = "sr2",
		svd_snp = "siltstone",
		svdsil_snp = "siltstone",
		ump = "schakal",
		x_c45 = "x_g17",
		flamethrower = "flamethrower_mk2",
		baton = "oldbaton",
		knife_1 = "x46",
		environment_fire = "fire"
	}
	function KillInfo:_get_weapon_data(damage_info)
		if not damage_info then
			return
		end
		local variant = damage_info.variant

		if variant == "melee" then
			if damage_info.name_id then
				return damage_info.name_id, tweak_data.blackmarket.melee_weapons[damage_info.name_id]
			end
			local melee_weapon_data = damage_info.attacker_unit:inventory() and damage_info.attacker_unit:inventory()._melee_weapon_data
			if melee_weapon_data then
				return melee_weapon_data.name_id, melee_weapon_data
			end
			if damage_info.attacker_unit:base().melee_weapon then
				local id = damage_info.attacker_unit:base():melee_weapon()
				id = weapon_mapping[id] or id
				return id, tweak_data.blackmarket.melee_weapons[id]
			end
		end

		local weapon_unit = damage_info.weapon_unit
		if not alive(weapon_unit) and damage_info.attacker_unit:inventory() then
			if variant == "bullet" or variant == "graze" then
				weapon_unit = damage_info.attacker_unit:inventory():equipped_unit()
			else
				return variant
			end
		end

		local weapon_base = alive(weapon_unit) and weapon_unit:base()
		weapon_base = weapon_base and alive(weapon_base._weapon_unit) and weapon_base._weapon_unit:base() or weapon_base
		if not weapon_base or not weapon_base.get_name_id then
			return variant
		end

		local id = weapon_base._player_name_id or weapon_base:get_name_id():gsub("_npc$", ""):gsub("_crew$", "")
		id = weapon_mapping[id] or id
		return id, tweak_data.weapon[id] or tweak_data.blackmarket.projectiles[id] or tweak_data.equipments[id] or weapon_base
	end

	function KillFeed:init()
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		self:load()
		self._ws = managers.hud._workspace
		self._panel = self._panel or hud and hud.panel or self._ws:panel({name = "KillFeed" })
	end

	function KillFeed:update(t, dt)
		self._t = t
		if self._update_t and t < self._update_t + self.settings.update_rate then
			return
		end
		if #self.kill_infos > 0 and self.kill_infos[1].dead then
			self.kill_infos[1]:destroy(1)
		end
		for i, info in ipairs(self.kill_infos) do
			info:update(t, i - 1)
		end
		self._update_t = t
	end

	function KillFeed:get_localized_text(text, plural)
		return managers.localization:text(text .. (plural and "_pl" or ""))
	end

	function KillFeed:get_assist_information(unit, killer)
		if not alive(unit) or not alive(killer) then
			return
		end
		local entry = self.assist_information[unit:key()]
		if not entry then
			return
		end
		local killer_key = killer:key()
		local most_damage = 0
		local most_damage_unit
		local t = self._t or 0
		for k, v in pairs(entry) do
			if k ~= killer_key and v.damage > most_damage and v.t + self.settings.assist_time > t then
				most_damage_unit = v.unit
				most_damage = v.damage
			end
		end
		return HopLib:unit_info_manager():get_info(most_damage_unit)
	end

	function KillFeed:set_assist_information(unit, attacker, damage)
		if not alive(unit) or not alive(attacker) then
			return
		end
		local unit_key = unit:key()
		local attacker_key = attacker:key()
		self.assist_information[unit_key] = self.assist_information[unit_key] or {}
		local entry = self.assist_information[unit_key]
		entry[attacker_key] = entry[attacker_key] or { unit = attacker, damage = 0 }
		entry[attacker_key].damage = entry[attacker_key].damage + damage
		entry[attacker_key].t = self._t or 0
	end

	function KillFeed:add_kill(damage_info, target)
		local target_info = HopLib:unit_info_manager():get_info(target)
		if not target_info or self.settings.special_kills_only and not target_info:is_special() and not target_info:is_boss() then
			return
		end
		if not alive(damage_info.attacker_unit) or not damage_info.attacker_unit:base() then
			return
		end
		local attacker_unit = damage_info.attacker_unit:base().thrower_unit and damage_info.attacker_unit:base():thrower_unit() or damage_info.attacker_unit
		local attacker_info = HopLib:unit_info_manager():get_info(attacker_unit)
		if not attacker_info or not self.settings["show_" .. attacker_info:type() .. "_kills"] then
			return
		end
		local target_type = target_info:type()
		local status = (target_type == "sentry" or target_type == "vehicle") and "destroy" or "kill"
		KillInfo:new(attacker_info, target_info, self.settings.show_assists and self:get_assist_information(target, attacker_unit), status, damage_info)
		if #self.kill_infos > self.settings.max_shown then
			self.kill_infos[1]:destroy(1)
		end
	end

	function KillFeed:chk_create_sample_kill(recreate)
		if self._panel then
			if recreate then
				for _, info in ipairs(self.kill_infos) do
					info:destroy()
				end
				self.kill_infos = {}
			end
			if #self.kill_infos == 0 or recreate then
				local function fake_unit_info(n, c, s)
					return {
						nickname = function () return n end,
						color_id = function () return c end,
						is_special = function () return s end,
						is_boss = function () end
					}
				end
				if self.settings.show_local_player_kills then
					KillInfo:new(fake_unit_info(managers.network.account:username(), 1), fake_unit_info("Bulldozer", nil, true), self.settings.show_assists and fake_unit_info("Wolf", 2), "kill")
				end
				if self.settings.show_remote_player_kills then
					KillInfo:new(fake_unit_info("Shiny Hoppip", 3), fake_unit_info("FBI Heavy SWAT"), nil, "kill")
				end
				if self.settings.show_team_ai_kills then
					KillInfo:new(fake_unit_info("Wolf", 2), fake_unit_info("SWAT Turret", nil, true), nil, "destroy")
				end
				if self.settings.show_joker_kills then
					KillInfo:new(fake_unit_info("Hoxton's FBI SWAT", 4), fake_unit_info("Cop"), nil, "kill")
				end
				if self.settings.show_sentry_kills then
					KillInfo:new(fake_unit_info("Wolf's Sentry Gun", 2), fake_unit_info("Taser", nil, true), nil, "kill")
				end
				if self.settings.show_npc_kills then
					KillInfo:new(fake_unit_info("FBI Heavy SWAT"), fake_unit_info("Wolf's Sentry Gun", 2), nil, "destroy")
				end
			else
				for i, info in ipairs(self.kill_infos) do
					info:update_x()
				end
			end
		end
	end

	function KillFeed:save()
		io.save_as_json(self.settings, self.save_path .. "kill_feed.txt")
	end

	function KillFeed:load()
		local save_path = self.save_path .. "kill_feed.txt"
		local data = io.file_is_readable(save_path) and io.load_as_json(save_path) or {}
		table.replace(self.settings, data, true)
	end

	Hooks:Add("HopLibOnUnitDamaged", "HopLibOnUnitDamagedKillFeed", function (unit, damage_info)
		if unit:character_damage():dead() then
			KillFeed:add_kill(damage_info, unit)
		elseif KillFeed.settings.show_assists and alive(damage_info.attacker_unit) and type(damage_info.damage) == "number" then
			KillFeed:set_assist_information(unit, damage_info.attacker_unit, damage_info.damage)
		end
	end)

end

if RequiredScript == "lib/managers/hudmanager" then

	Hooks:PostHook(HUDManager, "init_finalize", "init_finalize_killfeed", function ()
		KillFeed:init()
	end)

	Hooks:PostHook(HUDManager, "update", "update_killfeed", function (self, ...)
		KillFeed:update(...)
	end)

elseif RequiredScript == "lib/managers/menumanager" then

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitKillFeed", function(loc)

		local language = HopLib:load_localization(KillFeed.mod_path .. "loc/", loc)

		local kt_saved = KillFeed.save_path .. "killtexts.txt"
		local kt_loc = KillFeed.mod_path .. "data/killtexts_" .. language .. ".txt"
		local killtexts_file = io.file_is_readable(kt_saved) and kt_saved or io.file_is_readable(kt_loc) and kt_loc or KillFeed.mod_path .. "data/killtexts_english.txt"
		local file = io.open(killtexts_file)
		if file then
			KillFeed.killtexts = json.decode(file:read("*all")) or {}
			file:close()
		end
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusKillFeed", function(menu_manager, nodes)
		local menu_id_main = "KillFeedMenu"

		KillFeed:load()

		MenuHelper:NewMenu(menu_id_main)

		MenuCallbackHandler.KillFeed_toggle = function(self, item)
			KillFeed.settings[item:name()] = (item:value() == "on")
			KillFeed:chk_create_sample_kill(item:name():find("^show_"))
			KillFeed:save()
		end

		MenuCallbackHandler.KillFeed_value = function(self, item)
			KillFeed.settings[item:name()] = item:value()
			KillFeed:chk_create_sample_kill(item:name() == "style" or item:name() == "x_align" or item:name() == "y_align")
			KillFeed:save()
		end

		MenuCallbackHandler.KillFeed_value_rounded = function(self, item)
			item:set_value(math.floor(item:value()))
			KillFeed.settings[item:name()] = item:value()
			KillFeed:chk_create_sample_kill(item:name() == "font_size" or item:name() == "spacing")
			KillFeed:save()
		end

		MenuHelper:AddMultipleChoice({
			id = "x_align",
			title = "KillFeed_menu_x_align_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.x_align,
			items = { "KillFeed_menu_align_left", "KillFeed_menu_align_center", "KillFeed_menu_align_right" },
			menu_id = menu_id_main,
			priority = 99
		})
		MenuHelper:AddMultipleChoice({
			id = "y_align",
			title = "KillFeed_menu_y_align_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.y_align,
			items = { "KillFeed_menu_align_top", "KillFeed_menu_align_bottom" },
			menu_id = menu_id_main,
			priority = 98
		})

		MenuHelper:AddSlider({
			id = "x_pos",
			title = "KillFeed_menu_x_pos_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.x_pos,
			min = 0,
			max = 1,
			step = 0.01,
			show_value = true,
			menu_id = menu_id_main,
			priority = 97
		})
		MenuHelper:AddSlider({
			id = "y_pos",
			title = "KillFeed_menu_y_pos_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.y_pos,
			min = 0,
			max = 1,
			step = 0.01,
			show_value = true,
			menu_id = menu_id_main,
			priority = 96
		})

		MenuHelper:AddDivider({
			id = "divider",
			size = 24,
			menu_id = menu_id_main,
			priority = 89
		})
		MenuHelper:AddMultipleChoice({
			id = "style",
			title = "KillFeed_menu_style_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.style,
			items = { "KillFeed_menu_style_icon", "KillFeed_menu_style_text", "KillFeed_menu_style_slang", "KillFeed_menu_style_weapon", "KillFeed_menu_style_w_icon" },
			menu_id = menu_id_main,
			priority = 88
		})
		MenuHelper:AddSlider({
			id = "font_size",
			title = "KillFeed_menu_font_size_name",
			callback = "KillFeed_value_rounded",
			value = KillFeed.settings.font_size,
			min = math.floor(tweak_data.menu.pd2_small_font_size * 0.5),
			max = tweak_data.menu.pd2_small_font_size * 2,
			step = 1,
			show_value = true,
			menu_id = menu_id_main,
			priority = 87
		})
		MenuHelper:AddSlider({
			id = "spacing",
			title = "KillFeed_menu_spacing_name",
			callback = "KillFeed_value_rounded",
			value = KillFeed.settings.spacing,
			min = 0,
			max = 64,
			step = 4,
			show_value = true,
			menu_id = menu_id_main,
			priority = 86
		})
		MenuHelper:AddSlider({
			id = "max_shown",
			title = "KillFeed_menu_max_shown_name",
			callback = "KillFeed_value_rounded",
			value = KillFeed.settings.max_shown,
			min = 1,
			max = 50,
			step = 1,
			show_value = true,
			menu_id = menu_id_main,
			priority = 85
		})
		MenuHelper:AddSlider({
			id = "lifetime",
			title = "KillFeed_menu_lifetime_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.lifetime,
			min = 1,
			max = 10,
			step = 0.1,
			show_value = true,
			menu_id = menu_id_main,
			priority = 84
		})
		MenuHelper:AddSlider({
			id = "fade_in_time",
			title = "KillFeed_menu_fade_in_time_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.fade_in_time,
			min = 0,
			max = 2,
			step = 0.05,
			show_value = true,
			menu_id = menu_id_main,
			priority = 83
		})
		MenuHelper:AddSlider({
			id = "fade_out_time",
			title = "KillFeed_menu_fade_out_time_name",
			callback = "KillFeed_value",
			value = KillFeed.settings.fade_out_time,
			min = 0,
			max = 2,
			step = 0.05,
			show_value = true,
			menu_id = menu_id_main,
			priority = 82
		})

		MenuHelper:AddDivider({
			id = "divider",
			size = 24,
			menu_id = menu_id_main,
			priority = 79
		})
		MenuHelper:AddToggle({
			id = "show_local_player_kills",
			title = "KillFeed_menu_show_player_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_local_player_kills,
			menu_id = menu_id_main,
			priority = 78
		})
		MenuHelper:AddToggle({
			id = "show_remote_player_kills",
			title = "KillFeed_menu_show_crew_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_remote_player_kills,
			menu_id = menu_id_main,
			priority = 77
		})
		MenuHelper:AddToggle({
			id = "show_team_ai_kills",
			title = "KillFeed_menu_show_team_ai_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_team_ai_kills,
			menu_id = menu_id_main,
			priority = 76
		})
		MenuHelper:AddToggle({
			id = "show_sentry_kills",
			title = "KillFeed_menu_show_sentry_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_sentry_kills,
			menu_id = menu_id_main,
			priority = 75
		})
		MenuHelper:AddToggle({
			id = "show_joker_kills",
			title = "KillFeed_menu_show_joker_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_joker_kills,
			menu_id = menu_id_main,
			priority = 74
		})
		MenuHelper:AddToggle({
			id = "show_npc_kills",
			title = "KillFeed_menu_show_npc_kills_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_npc_kills,
			menu_id = menu_id_main,
			priority = 73
		})

		MenuHelper:AddDivider({
			id = "divider",
			size = 24,
			menu_id = menu_id_main,
			priority = 69
		})
		MenuHelper:AddToggle({
			id = "show_assists",
			title = "KillFeed_menu_show_assists_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.show_assists,
			menu_id = menu_id_main,
			priority = 68
		})
		MenuHelper:AddToggle({
			id = "special_kills_only",
			title = "KillFeed_menu_special_kills_only_name",
			callback = "KillFeed_toggle",
			value = KillFeed.settings.special_kills_only,
			menu_id = menu_id_main,
			priority = 67
		})

		nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { area_bg = "half" })
		MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "KillFeed_menu_main_name", "KillFeed_menu_main_desc")
	end)

end
