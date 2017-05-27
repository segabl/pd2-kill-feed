if not KillFeed then

  _G.KillFeed = {} 
  KillFeed.mod_path = ModPath
  KillFeed.save_path = SavePath
  KillFeed.kill_infos = {}
  KillFeed.unit_information = {}
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
    special_kills_only = false
  }
  KillFeed.unit_names = {
    spooc = "Cloaker",
    tank = "Bulldozer"
  }
  
  local KillInfo = class()
  KillFeed.KillInfo = KillInfo

  function KillInfo:init(offset, attacker_name, attacker_color, target_name, target_color, is_local, status)
    attacker_color = attacker_color or Color.white
    target_color = target_color or Color.white
    status = status or "kill"
    
    self._panel = KillFeed._panel:panel({
      name = "panel",
      alpha = 0,
      x = KillFeed._panel:w() * KillFeed.settings.x_pos,
      y = KillFeed._panel:h() * KillFeed.settings.y_pos + (offset - 1) * KillFeed.settings.font_size
    })
    if KillFeed.settings.style == 1 then
      kill_text = attacker_name .. "  " .. target_name
    else
      kill_text = attacker_name .. " " .. managers.localization:text("KillFeed_text_" .. status) .. " " .. target_name
    end
    local text = self._panel:text({
      name = "text",
      text = kill_text,
      font = tweak_data.menu.pd2_large_font,
      font_size = math.floor(KillFeed.settings.font_size),
      color = KillFeed.settings.style == 1 and Color.yellow or Color.white:with_alpha(0.8)
    })
    
    text:set_range_color(0, utf8.len(attacker_name), attacker_color)
    text:set_range_color(utf8.len(kill_text) - utf8.len(target_name), utf8.len(kill_text), target_color)
    
    local _, _, w, h = text:text_rect()
    self._panel:set_size(w, h)
    if KillFeed.settings.x_align == 1 then
      self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
    elseif KillFeed.settings.x_align == 2 then
      self._panel:set_center(KillFeed._panel:w() * KillFeed.settings.x_pos)
    else
      self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
    end
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
    if KillFeed.settings.x_align == 1 then
      self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
    elseif KillFeed.settings.x_align == 2 then
      self._panel:set_center_x(KillFeed._panel:w() * KillFeed.settings.x_pos)
    else
      self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
    end
    if KillFeed.settings.y_align == 1 then
      self._panel:set_top(self._panel:top() + ((KillFeed._panel:h() * KillFeed.settings.y_pos + offset * KillFeed.settings.font_size) - self._panel:top()) / 2)
    else
      self._panel:set_bottom(self._panel:bottom() + ((KillFeed._panel:h() * KillFeed.settings.y_pos - offset * KillFeed.settings.font_size) - self._panel:bottom()) / 2)
    end
    
  end

  function KillInfo:destroy()
    KillFeed._panel:remove(self._panel)
  end
  
  function KillFeed:init()
    self:load()
    self._ws = managers.hud._workspace
    self._panel = self._panel or self._ws:panel({
      name = "KillFeed"
    })
  end

  function KillFeed:update(t, dt)
    self._t = t
    if self._update_t and t < self._update_t + 0.03 then
      return
    end
    if #self.kill_infos > 0 and self.kill_infos[1].dead or #self.kill_infos > self.settings.max_shown then
      self.kill_infos[1]:destroy()
      table.remove(self.kill_infos, 1)
    end
    for i, info in ipairs(self.kill_infos) do
      info:update(t, i - 1)
    end
    self._update_t = t
  end
  
  function KillFeed:get_unit_information(unit)
    if not alive(unit) then
      return
    end
    local info = self.unit_information[unit:key()]
    if info then
      return self.unit_information[unit:key()]
    end
    local unit_base = unit:base()
    if unit_base then
      local thrower = unit_base._thrower_unit
      unit = thrower or unit
      unit_base = alive(unit) and unit:base() or unit_base
    end
    
    local tweak = unit_base._tweak_table or unit_base._tweak_table_id
    
    local owner = unit_base._owner or unit_base.get_owner and unit_base:get_owner() or unit_base.kpr_minion_owner_peer_id and managers.criminals:character_unit_by_peer_id(unit_base.kpr_minion_owner_peer_id)
    local owner_base = alive(owner) and owner:base()

    local name = "unknown"
    local unit_type = "npc"
    if unit_base.is_husk_player or unit_base.is_local_player then
      unit_type = unit_base.is_local_player and "player" or "crew"
      name = unit:network():peer():name()
    elseif managers.groupai:state():is_unit_team_AI(unit) then
      unit_type = "team_ai"
      name = unit_base:nick_name()
    elseif managers.groupai:state():is_enemy_converted_to_criminal(unit) then
      if Keepers and Keepers.GetJokerNameByPeer then
        name = Keepers:GetJokerNameByPeer(unit_base.kpr_minion_owner_peer_id)
      else
        name = "Joker"
        if owner_base and (owner_base.is_husk_player or owner_base.is_local_player) then
          name = owner:network():peer():name() .. "'s " .. name
        end
      end
    elseif type(tweak) == "string" then
      name = self.unit_names[tweak] or string.capitalize(tweak:gsub("_", " ")):gsub("Swat", "SWAT"):gsub("Fbi", "FBI")
      if not self.unit_names[tweak] then
        self.unit_names[tweak] = name
      end
      if owner_base and (owner_base.is_husk_player or owner_base.is_local_player) then
        name = owner:network():peer():name() .. "'s " .. name
      end
    end
    
    local is_special = tweak and tweak_data.character[tweak] and tweak_data.character[tweak].priority_shout
    local color_id = alive(owner) and managers.criminals:character_color_id_by_unit(owner) or alive(unit) and managers.criminals:character_color_id_by_unit(unit)
    local color = is_special and Color(tweak_data.contour.character.dangerous_color:unpack()) or color_id and color_id < #tweak_data.chat_colors and tweak_data.chat_colors[color_id]
    
    self.unit_information[unit:key()] = { name = name, color = color, type = unit_type, is_special = is_special }
    return self.unit_information[unit:key()]
  end
  
  function KillFeed:add_kill(attacker, target, status)
    local attacker_info = self:get_unit_information(attacker)
    if not attacker_info then
      return
    end
    local target_info = self:get_unit_information(target)
    if not target_info then
      return
    end
    if self.settings["show_" .. attacker_info.type .. "_kills"] and (target_info.is_special or not self.settings.special_kills_only) then
      KillInfo:new(#self.kill_infos, attacker_info.name, attacker_info.color, target_info.name, target_info.color, attacker_info.type == "player" or target_info.type == "player", status)
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
      if  #self.kill_infos == 0 or recreate then
        KillInfo:new(#self.kill_infos, "Player", tweak_data.chat_colors[1], "Cop", Color.white, true, "kill")
        KillInfo:new(#self.kill_infos, "Taser", Color(tweak_data.contour.character.dangerous_color:unpack()), "Player's Sentry Gun", tweak_data.chat_colors[1], true, "destroy")
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
    local data
    if file then
      data = json.decode(file:read("*all"))
      file:close()
    end
    for k, v in pairs(data or {}) do
      self.settings[k] = v
    end
  end

end

if RequiredScript == "lib/managers/hudmanager" then

  local init_finalize_original = HUDManager.init_finalize
  function HUDManager:init_finalize(...)
    local result = init_finalize_original(self, ...)
    KillFeed:init()
  end

  local update_original = HUDManager.update
  function HUDManager:update(...)
    update_original(self, ...)
    KillFeed:update(...)
  end

end

if RequiredScript == "lib/units/enemies/cop/copdamage" then

  local die_original = CopDamage.die
  function CopDamage:die(damage_info, ...)
    if not self._dead then
      KillFeed:add_kill(damage_info.attacker_unit, self._unit)
    end
    return die_original(self, damage_info, ...)
  end

end

if RequiredScript == "lib/units/civilians/civiliandamage" then

  local _on_damage_received_original = CivilianDamage._on_damage_received
  function CivilianDamage:_on_damage_received(damage_info, ...)
    local result = _on_damage_received_original(self, damage_info, ...)
    if self._dead then
      KillFeed:add_kill(damage_info.attacker_unit, self._unit)
    end
    return result
  end

end

if RequiredScript == "lib/units/equipment/sentry_gun/sentrygundamage" then

  local die_original = SentryGunDamage.die
  function SentryGunDamage:die(attacker_unit, ...)
    if not self._dead then
      KillFeed:add_kill(attacker_unit, self._unit, "destroy")
    end
    return die_original(self, attacker_unit, ...)
  end
  
end

if RequiredScript == "lib/units/beings/player/playerdamage" then

  
end

if RequiredScript == "lib/managers/menumanager" then

  Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitPlayerKillFeed", function(loc)
    loc:load_localization_file(KillFeed.mod_path .. "loc/english.txt")
    for _, filename in pairs(file.GetFiles(KillFeed.mod_path .. "loc/")) do
      local str = filename:match('^(.*).txt$')
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
      KillFeed:chk_create_sample_kill()
      KillFeed:save()
    end

    MenuCallbackHandler.KillFeed_value = function(self, item)
      KillFeed.settings[item:name()] = item:value()
      KillFeed:chk_create_sample_kill(item:name() == "style")
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
      id = "special_kills_only",
      title = "KillFeed_menu_special_kills_only_name",
      callback = "KillFeed_toggle",
      value = KillFeed.settings.special_kills_only,
      menu_id = menu_id_main,
      priority = 68
    })
    
  end)

  Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerKillFeed", function(menu_manager, nodes)
    nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { area_bg = "half" })
    MenuHelper:AddMenuItem(MenuHelper:GetMenu("lua_mod_options_menu"), menu_id_main, "KillFeed_menu_main_name", "KillFeed_menu_main_desc")
  end)
  
end