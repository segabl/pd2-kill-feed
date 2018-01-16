if not HopLib then
  return
end

if not KillFeed then

  _G.KillFeed = {}
  KillFeed.mod_path = ModPath
  KillFeed.save_path = SavePath
  KillFeed.kill_infos = {}
  KillFeed.assist_information = {}
  KillFeed.localized_text = {}
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
  
  local KillInfo = class()
  KillFeed.KillInfo = KillInfo

  function KillInfo:init(attacker_info, target_info, assist_info, status)
    self._panel = KillFeed._panel:panel({
      alpha = 0,
      layer = 100,
    })
    
    local w = 0
    
    local attacker_name, attacker_color, target_name, target_color, assist_name, assist_color
    
    attacker_name = attacker_info:nickname()
    attacker_color = attacker_info._is_special and KillFeed.colors.special or attacker_info._color_id and attacker_info._color_id < #tweak_data.chat_colors and tweak_data.chat_colors[attacker_info._color_id]
    
    target_name = target_info:nickname()
    target_color = target_info._is_special and KillFeed.colors.special or target_info._color_id and target_info._color_id < #tweak_data.chat_colors and tweak_data.chat_colors[target_info._color_id]
    
    if assist_info then
      assist_name = assist_info:nickname()
      assist_color = assist_info._is_special and KillFeed.colors.special or assist_info._color_id and assist_info._color_id < #tweak_data.chat_colors and tweak_data.chat_colors[assist_info._color_id]
    end
    
    if KillFeed.settings.style >= 1 and KillFeed.settings.style <= 3 then
      local show_assist = assist_info and assist_name ~= attacker_name
      local kill_text, assist_text
      if KillFeed.settings.style == 1 then
        assist_text = "+"
        kill_text = attacker_name .. (show_assist and (assist_text .. assist_name) or "") .. "  " .. target_name
      elseif KillFeed.settings.style == 2 then
        assist_text = " " .. KillFeed:get_localized_text("KillFeed_text_and") .. " "
        kill_text = attacker_name .. (show_assist and (assist_text .. assist_name) or "") .. " " .. KillFeed:get_localized_text("KillFeed_text_" .. status, show_assist) .. " " .. target_name
      elseif KillFeed.settings.style == 3 then
        local slang = KillFeed.killtexts and table.random(KillFeed.killtexts) or "killed"
        assist_text = " " .. KillFeed:get_localized_text("KillFeed_text_and") .. " "
        kill_text = attacker_name .. (show_assist and (assist_text .. assist_name) or "") .. " " .. slang .. " " .. target_name
      end
      local text = self._panel:text({
        text = kill_text,
        font = tweak_data.menu.pd2_large_font,
        font_size = KillFeed.settings.font_size,
        color = KillFeed.settings.style == 1 and KillFeed.colors.skull or KillFeed.colors.text
      })
      local _, _, tw, th = text:text_rect()
      w = tw
      
      local utf8_len = utf8.len
      local l = utf8_len(kill_text)
      local la = utf8_len(attacker_name)
      text:set_range_color(0, la, attacker_color or KillFeed.colors.default)
      text:set_range_color(l - utf8_len(target_name), l, target_color or KillFeed.colors.default)
      if show_assist then
        l = utf8.len(assist_text)
        text:set_range_color(la, la + l, KillFeed.colors.text)
        text:set_range_color(la + l, la + l + utf8_len(assist_name), assist_color or KillFeed.colors.default)
      end
    end
    
    self._panel:set_size(w, KillFeed.settings.font_size)
    
    if KillFeed.settings.x_align == 1 then
      self._panel:set_left(KillFeed._panel:w() * KillFeed.settings.x_pos)
    elseif KillFeed.settings.x_align == 2 then
      self._panel:set_center(KillFeed._panel:w() * KillFeed.settings.x_pos)
    else
      self._panel:set_right(KillFeed._panel:w() * KillFeed.settings.x_pos)
    end
    
    local offset = #KillFeed.kill_infos
    if KillFeed.settings.y_align == 1 then
      self._panel:set_top(KillFeed._panel:h() * KillFeed.settings.y_pos + (offset - 1) * self._panel:h())
    else
      self._panel:set_bottom(KillFeed._panel:h() * KillFeed.settings.y_pos - (offset + 1) * self._panel:h())
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
      self._panel:set_top(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos + offset * self._panel:h()) - pos) / 2)
    else
      self._panel:set_bottom(pos + ((KillFeed._panel:h() * KillFeed.settings.y_pos - offset * self._panel:h()) - pos) / 2)
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

  function KillFeed:add_kill(damage_info, target, status)
    local target_info = HopLib:unit_info_manager():get_info(target)
    target_info = target_info and target_info:user()
    if not target_info or self.settings.special_kills_only and not target_info._is_special then
      return
    end
    local attacker_info = HopLib:unit_info_manager():get_user_info(damage_info.attacker_unit)
    if not attacker_info or not self.settings["show_" .. (attacker_info._sub_type or attacker_info._type) .. "_kills"] then
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
        local function fake_unit_info(name, color_id, is_special)
          return { nickname = function () return name end, _color_id = color_id, _is_special = is_special }
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
    local fname = self.save_path .. "killtexts.json"
    if not io.file_is_readable(fname) then
      fname = self.mod_path .. "killtexts.json"
    end
    file = io.open(fname)
    if file then
      self.killtexts = json.decode(file:read("*all")) or {}
      file:close()
    end
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


if RequiredScript == "lib/managers/menumanager" then

  Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitKillFeed", function(loc)
    local loaded = false
    if Idstring("english"):key() ~= SystemInfo:language():key() then
      for _, filename in pairs(file.GetFiles(KillFeed.mod_path .. "loc/") or {}) do
        local str = filename:match("^(.*).txt$")
        if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
          loc:load_localization_file(KillFeed.mod_path .. "loc/" .. filename)
          loaded = true
          break
        end
      end
    end
    if not loaded then
      local file = KillFeed.mod_path .. "loc/" .. BLT.Localization:get_language().language .. ".txt"
      if io.file_is_readable(file) then
        loc:load_localization_file(file)
      end
    end
    loc:load_localization_file(KillFeed.mod_path .. "loc/english.txt", false)
  end)

  local menu_id_main = "KillFeedMenu"
  Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenusKillFeed", function(menu_manager, nodes)
    MenuHelper:NewMenu(menu_id_main)
  end)

  Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenusKillFeed", function(menu_manager, nodes)
    
    KillFeed:load()
    
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
      items = { "KillFeed_menu_style_icon", "KillFeed_menu_style_text", "KillFeed_menu_style_slang" },
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
    
  end)

  Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerKillFeed", function(menu_manager, nodes)
    nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { area_bg = "half" })
    MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "KillFeed_menu_main_name", "KillFeed_menu_main_desc")
  end)
  
end
