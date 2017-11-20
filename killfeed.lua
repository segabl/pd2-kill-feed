if not KillFeed then

  _G.KillFeed = {}
  KillFeed.mod_path = ModPath
  KillFeed.save_path = SavePath
  KillFeed.kill_infos = {}
  KillFeed.unit_information = {}
  KillFeed.assist_information = {}
  KillFeed.localized_text = {}
  KillFeed.unit_names = {
    spooc = { default = "Cloaker" },
    tank_green = { default = "Bulldozer" },
    tank_black = { default = "Blackdozer" },
    tank_skull = { default = "Skulldozer" },
    tank_medic = { default = "Medic Bulldozer" },
    tank_mini = { default = "Minigun Bulldozer" },
    tank_hw = { default = "Headless Titandozer" },
    swat_van_turret_module = { default = "SWAT Turret" },
    ceiling_turret_module = { default = "Ceiling Turret" },
    ceiling_turret_module_no_idle = { default = "Ceiling Turret" },
    mobster_boss = { default = "The Commissar" },
    chavez_boss = { default = "Chavez" },
    hector_boss = { default = "Hector Morales" },
    hector_boss_no_armor = { default = "Hector Morales" },
    drug_lord_boss = { default = "Ernesto Sosa" },
    drug_lord_boss_stealth = { default = "Ernesto Sosa" },
    old_hoxton_mission = { default = "Hoxton" },
    spa_vip = { default = "Charon" },
    phalanx_vip = { default = "Neville Winters" },
    phalanx_minion = { default = "Phalanx Shield" },
    bank_manager = { default = "Bank Manager", dah = "Ralph Garnet" }
  }
  KillFeed.settings = {
    x_align = 1,
    y_align = 1,
    x_pos = 0.03,
    y_pos = 0.15,
    style = 1,
    font_size = tweak_data.menu.pd2_small_font_size,
    max_shown = 5,
    lifetime = 3,
    fade_in_time = 0.25,
    fade_out_time = 0.25,
    show_player_kills = true,
    show_crew_kills = true,
    show_team_ai_kills = true,
    show_npc_kills = true,
    show_assists = true,
    special_kills_only = false,
    update_rate = 1 / 30,
    assist_time = 4
  }
  KillFeed.color = {
    default = Color.white,
    special = Color(tweak_data.contour.character.dangerous_color:unpack()),
    text = Color.white:with_alpha(0.8),
    skull = Color.yellow
  }
  
  local KillInfo = class()
  KillFeed.KillInfo = KillInfo

  function KillInfo:init(attacker_info, target_info, assist_info, status)
    self._panel = KillFeed._panel:panel({
      alpha = 0,
      layer = 100,
      h = KillFeed.settings.font_size
    })
    
    local w = 0
    if KillFeed.settings.style == 1 or KillFeed.settings.style == 2 then
      local show_assist = assist_info and assist_info.name ~= attacker_info.name
      local kill_text, assist_text
      if KillFeed.settings.style == 1 then
        assist_text = "+"
        kill_text = attacker_info.name .. (show_assist and (assist_text .. assist_info.name) or "") .. "  " .. target_info.name
      elseif KillFeed.settings.style == 2 then
        assist_text = " " .. KillFeed:get_localized_text("KillFeed_text_and") .. " "
        kill_text = attacker_info.name .. (show_assist and (assist_text .. assist_info.name) or "") .. " " .. KillFeed:get_localized_text("KillFeed_text_" .. status, show_assist) .. " " .. target_info.name
      end
      local text = self._panel:text({
        text = kill_text,
        font = tweak_data.menu.pd2_large_font,
        font_size = KillFeed.settings.font_size,
        color = KillFeed.settings.style == 1 and KillFeed.color.skull or KillFeed.color.text
      })
      local _, _, tw, th = text:text_rect()
      w = tw
      
      local l = utf8.len(kill_text)
      text:set_range_color(0, attacker_info.name_len, attacker_info.color)
      text:set_range_color(l - target_info.name_len, l, target_info.color)
      if show_assist then
        l = utf8.len(assist_text)
        text:set_range_color(attacker_info.name_len, attacker_info.name_len + l, KillFeed.color.text)
        text:set_range_color(attacker_info.name_len + l, attacker_info.name_len + l + assist_info.name_len, assist_info.color)
      end
    end
    
    self._panel:set_w(w)
    
    if KillFeed.settings.x_align == 1 then
      self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
    elseif KillFeed.settings.x_align == 2 then
      self._panel:set_center(KillFeed._panel:w() * KillFeed.settings.x_pos)
    else
      self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
    end
    
    local offset = #KillFeed.kill_infos
    if KillFeed.settings.y_align == 1 then
      self._panel:set_top(KillFeed._panel:h() * KillFeed.settings.y_pos + (offset - 1) * KillFeed.settings.font_size)
    else
      self._panel:set_bottom(KillFeed._panel:h() * KillFeed.settings.y_pos - (offset + 1) * KillFeed.settings.font_size)
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
      self._panel:set_top(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos + offset * KillFeed.settings.font_size) - pos) / 2)
    else
      self._panel:set_bottom(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos - offset * KillFeed.settings.font_size) - pos) / 2)
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
  
  function KillFeed:init()
    local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
    self:load()
    self._ws = managers.hud._workspace
    self._panel = self._panel or hud and hud.panel or self._ws:panel({name = "KillFeed" })
    self._current_level_id = managers.job and managers.job:current_level_id() or ""
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
    local key = text .. (plural and "_pl" or "")
    if not self.localized_text[key] then
      self.localized_text[key] = managers.localization:text(key)
    end
    return self.localized_text[key]
  end
  
  function KillFeed:get_name_by_tweak_data_id(tweak)
    if not tweak then
      return
    end
    if not self.unit_names[tweak] then
      self.unit_names[tweak] = { [self._current_level_id] = tweak:pretty(true):gsub("Swat", "SWAT"):gsub("Fbi", "FBI") }
    end
    return self.unit_names[tweak][self._current_level_id] or self.unit_names[tweak].default
  end
  
  function KillFeed:get_unit_information(unit)
    if not alive(unit) then
      return
    end
    local unit_key = unit:key()
    local info = self.unit_information[unit_key]
    if info then
      return self.unit_information[unit_key]
    end
    local unit_base = unit:base()
    
    if alive(unit_base._thrower_unit) then
      unit = unit_base._thrower_unit
      unit_base = unit:base()
    end
    
    local tweak = unit_base._tweak_table or unit_base._tweak_table_id
    
    local gstate = managers.groupai:state()
    local cm = managers.criminals
    
    local owner = unit_base._owner or unit_base.get_owner and unit_base:get_owner() or unit_base.kpr_minion_owner_peer_id and cm:character_unit_by_peer_id(unit_base.kpr_minion_owner_peer_id)
    local owner_base = alive(owner) and owner:base()
    
    local name, unit_type
    if unit_base.is_husk_player or unit_base.is_local_player then
      unit_type = unit_base.is_local_player and "player" or "crew"
      name = unit:network():peer():name()
    elseif gstate:is_unit_team_AI(unit) then
      unit_type = "team_ai"
      name = unit_base:nick_name()
    else
      unit_type = "npc"
      if Keepers and unit_base.kpr_minion_owner_peer_id then
        name = Keepers:GetJokerNameByPeer(unit_base.kpr_minion_owner_peer_id)
      end
      if not name or name == "" then
        name = self:get_name_by_tweak_data_id(unit_base._stats_name or tweak)
        if name and owner_base and (owner_base.is_husk_player or owner_base.is_local_player) then
          name = owner:network():peer():name() .. "'s " .. name
        end
      end
    end
    
    if not name then
      return
    end
    
    local is_special = tweak and (tweak_data.character[tweak] and tweak_data.character[tweak].priority_shout or (tweak:find("_boss") or tweak:find("_turret")))
    local color_id = alive(owner) and cm:character_color_id_by_unit(owner) or alive(unit) and cm:character_color_id_by_unit(unit)
    local color = is_special and KillFeed.color.special or color_id and color_id < #tweak_data.chat_colors and tweak_data.chat_colors[color_id] or KillFeed.color.default
    
    local information = {
      name = name,
      name_len = utf8.len(name),
      color = color,
      type = unit_type,
      is_special = is_special
    }
    self.unit_information[unit_key] = information
    return information
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
    return self:get_unit_information(most_damage_unit)
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

  function KillFeed:add_kill(damage_info, target, status)
    local target_info = self:get_unit_information(target)
    if not target_info or self.settings.special_kills_only and not target_info.is_special then
      return
    end
    local attacker_info = self:get_unit_information(damage_info.attacker_unit)
    if not attacker_info or not self.settings["show_" .. attacker_info.type .. "_kills"] then
      return
    end
    KillInfo:new(attacker_info, target_info, self.settings.show_assists and self:get_assist_information(target, damage_info.attacker_unit), status or "kill")
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
        KillInfo:new({ name = "Dallas", name_len = 6, color = tweak_data.chat_colors[1] }, { name = "Bulldozer", name_len = 9, color = self.color.special }, self.settings.show_assists and { name = "Wolf", name_len = 4, color = tweak_data.chat_colors[2] }, "kill")
        KillInfo:new({ name = "FBI Heavy SWAT", name_len = 14, color = self.color.default }, { name = "Wolf's Sentry Gun", name_len = 17, color = tweak_data.chat_colors[2] }, nil, "destroy")
      else
        for i, info in ipairs(self.kill_infos) do
          info:update_x()
        end
      end
    end
  end
  
  function KillFeed:save()
    local file = io.open(self.save_path .. "kill_feed.txt", "w+")
    if file then
      file:write(json.encode(self.settings))
      file:close()
    end
  end

  function KillFeed:load()
    local file = io.open(self.save_path .. "kill_feed.txt", "r")
    if file then
      local data = json.decode(file:read("*all")) or {}
      file:close()
      for k, v in pairs(data) do
        self.settings[k] = v
      end
    end
  end

end


if RequiredScript == "lib/managers/hudmanager" then

  local init_finalize_original = HUDManager.init_finalize
  function HUDManager:init_finalize(...)
    local result = init_finalize_original(self, ...)
    KillFeed:init()
    return result
  end

  local update_original = HUDManager.update
  function HUDManager:update(...)
    update_original(self, ...)
    KillFeed:update(...)
  end

end


if RequiredScript == "lib/units/enemies/cop/copdamage" then

  local convert_to_criminal_original = CopDamage.convert_to_criminal
  function CopDamage:convert_to_criminal(...)
    local unit_key = self._unit:key()
    KillFeed.assist_information[unit_key] = nil
    KillFeed.unit_information[unit_key] = nil
    return convert_to_criminal_original(self, ...)
  end

  local _on_damage_received_original = CopDamage._on_damage_received
  function CopDamage:_on_damage_received(damage_info, ...)
    if self._dead then
      if not self._kill_feed_shown then
        KillFeed:add_kill(damage_info, self._unit)
        self._kill_feed_shown = true
      end
    elseif KillFeed.settings.show_assists and alive(damage_info.attacker_unit) and type(damage_info.damage) == "number" then
      KillFeed:set_assist_information(self._unit, damage_info.attacker_unit, damage_info.damage)
    end
    return _on_damage_received_original(self, damage_info, ...)
  end

end


if RequiredScript == "lib/units/civilians/civiliandamage" then

  local _on_damage_received_original = CivilianDamage._on_damage_received
  function CivilianDamage:_on_damage_received(damage_info, ...)
    if self._dead then
      if not self._kill_feed_shown then
        KillFeed:add_kill(damage_info, self._unit)
        self._kill_feed_shown = true
      end
    elseif KillFeed.settings.show_assists and alive(damage_info.attacker_unit) and type(damage_info.damage) == "number" then
      KillFeed:set_assist_information(self._unit, damage_info.attacker_unit, damage_info.damage)
    end
    return _on_damage_received_original(self, damage_info, ...)
  end

end


if RequiredScript == "lib/units/equipment/sentry_gun/sentrygundamage" then

  local _apply_damage_original = SentryGunDamage._apply_damage
  function SentryGunDamage:_apply_damage(damage, dmg_shield, dmg_body, is_local, attacker_unit, ...)
    local result = _apply_damage_original(self, damage, dmg_shield, dmg_body, is_local, attacker_unit, ...)
    if self._dead then
      if not self._kill_feed_shown then
        KillFeed:add_kill({ attacker_unit = attacker_unit }, self._unit, "destroy")
        self._kill_feed_shown = true
      end
    elseif KillFeed.settings.show_assists and alive(attacker_unit) and type(damage) == "number" then
      KillFeed:set_assist_information(self._unit, attacker_unit, damage)
    end
    return result
  end
  
end


if RequiredScript == "lib/managers/menumanager" then

  Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitKillFeed", function(loc)
    loc:load_localization_file(KillFeed.mod_path .. "loc/english.txt")
    for _, filename in pairs(file.GetFiles(KillFeed.mod_path .. "loc/") or {}) do
      local str = filename:match("^(.*).txt$")
      if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
        loc:load_localization_file(KillFeed.mod_path .. "loc/" .. filename)
        break
      end
    end
  end)

  local menu_id_main = "KillFeedMenu"
  Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenusKillFeed", function(menu_manager, nodes)
    MenuHelper:NewMenu(menu_id_main)
  end)

  Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenusKillFeed", function(menu_manager, nodes)
    
    KillFeed:load()
    
    MenuCallbackHandler.KillFeed_toggle = function(self, item)
      KillFeed.settings[item:name()] = (item:value() == "on")
      KillFeed:chk_create_sample_kill(item:name() == "show_assists")
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
      KillFeed:chk_create_sample_kill(item:name() == "font_size")
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
      items = { "KillFeed_menu_style_icon", "KillFeed_menu_style_text" },
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
      id = "show_player_kills",
      title = "KillFeed_menu_show_player_kills_name",
      callback = "KillFeed_toggle",
      value = KillFeed.settings.show_player_kills,
      menu_id = menu_id_main,
      priority = 78
    })
    MenuHelper:AddToggle({
      id = "show_crew_kills",
      title = "KillFeed_menu_show_crew_kills_name",
      callback = "KillFeed_toggle",
      value = KillFeed.settings.show_crew_kills,
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
      id = "show_npc_kills",
      title = "KillFeed_menu_show_npc_kills_name",
      callback = "KillFeed_toggle",
      value = KillFeed.settings.show_npc_kills,
      menu_id = menu_id_main,
      priority = 75
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
    
  end)

  Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerKillFeed", function(menu_manager, nodes)
    nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { area_bg = "half" })
    MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "KillFeed_menu_main_name", "KillFeed_menu_main_desc")
  end)
  
end
