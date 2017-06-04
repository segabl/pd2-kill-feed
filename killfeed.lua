if not KillFeed then

  _G.KillFeed = {} 
  KillFeed.mod_path = ModPath
  KillFeed.save_path = SavePath
  KillFeed.kill_infos = {}
  KillFeed.unit_information = {}
  KillFeed.assist_information = {}
  KillFeed.localized_text = {}
  KillFeed.weapon_texture = {
    default = {},
    melee = {},
    throwable = {}
  }
  KillFeed.unit_name = {
    spooc = "Cloaker",
    tank = "Bulldozer"
  }
  KillFeed.npc_weapon_translation = {
    beretta92 = "b92fs",
    c45 = "glock_17",
    raging_bull = "new_raging_bull",
    m4 = "new_m4",
    ak47 = "ak74",
    mossberg = "huntsman",
    mp5 = "new_mp5",
    mp5_tactical = "new_mp5",
    mac11 = "mac10",
    m14_sniper_npc = "g3",
    ump = "schakal",
    scar_murky = "scar",
    rpk_lmg = "rpk",
    svd_snp = "siltstone",
    akmsu_smg = "akmsu",
    asval_smg = "asval",
    sr2_smg = "sr2",
    ak47_ass = "ak74",
    x_c45 = "x_g17",
    sg417 = "contraband",
    svdsil_snp = "siltstone",
    ben = "benelli"
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
    show_assists = false,
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

  function KillInfo:init(attacker_info, target_info, assist_info, status, weapon_texture)
    self._panel = KillFeed._panel:panel({
      alpha = 0
    })
    
    local w = 0
    if KillFeed.settings.style == 1 or KillFeed.settings.style == 2 then
      -- style 1 and 2
      local kill_text
      if KillFeed.settings.style == 1 then
        kill_text = attacker_info.name .. (assist_info and ("+" .. assist_info.name) or "") .. "  " .. target_info.name
      elseif KillFeed.settings.style == 2 then
        kill_text = attacker_info.name .. (assist_info and ("+" .. assist_info.name) or "") .. " " .. KillFeed:get_localized_text("KillFeed_text_" .. status) .. " " .. target_info.name
      end
      local text = self._panel:text({
        text = kill_text,
        font = tweak_data.menu.pd2_large_font,
        font_size = KillFeed.settings.font_size,
        color = KillFeed.settings.style == 1 and KillFeed.color.skull or KillFeed.color.text
      })
      local _, _, tw, th = text:text_rect()
      w = tw
      
      local len = utf8.len
      text:set_range_color(0, len(attacker_info.name), attacker_info.color)
      text:set_range_color(len(kill_text) - len(target_info.name), len(kill_text), target_info.color)
      if assist_info then
        local l = 1
        text:set_range_color(len(attacker_info.name), len(attacker_info.name) + l, KillFeed.color.text)
        text:set_range_color(len(attacker_info.name) + l, len(attacker_info.name) + l + len(assist_info.name), assist_info.color)
      end
    elseif KillFeed.settings.style == 3 then
      -- style 3 (with weapon icons)
      local kill_text = attacker_info.name .. (assist_info and ("+" .. assist_info.name) or "")
      local text = self._panel:text({
        text = kill_text,
        font = tweak_data.menu.pd2_large_font,
        font_size = KillFeed.settings.font_size,
        color = attacker_info.color,
        y = KillFeed.settings.font_size * 0.25
      })
      local _, _, tw, th = text:text_rect()
      w = w + tw + 4
      
      local len = utf8.len
      if assist_info then
        local l = 1
        text:set_range_color(len(attacker_info.name), len(attacker_info.name) + l, KillFeed.color.text)
        text:set_range_color(len(attacker_info.name) + l, len(attacker_info.name) + l + len(assist_info.name), assist_info.color)
      end
      
      local image = self._panel:bitmap({
        texture = weapon_texture,
        x = w,
        scale_x = -1
      })
      local new_w = (image:texture_width() / image:texture_height()) * KillFeed.settings.font_size * 1.5
      image:set_size(new_w, KillFeed.settings.font_size * 1.5)
      w = w + new_w + 4
      
      local text = self._panel:text({
        text = target_info.name,
        font = tweak_data.menu.pd2_large_font,
        font_size = KillFeed.settings.font_size,
        color = target_info.color,
        x = w,
        y = KillFeed.settings.font_size * 0.25
      })
      local _, _, tw, th = text:text_rect()
      w = w + tw
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

  function KillInfo:destroy(pos)
    KillFeed._panel:remove(self._panel)
    if pos then
      table.remove(KillFeed.kill_infos, pos)
    end
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
    if self._update_t and t < self._update_t + self.settings.update_rate then
      return
    end
    if #self.kill_infos > 0 and self.kill_infos[1].dead or #self.kill_infos > self.settings.max_shown then
      self.kill_infos[1]:destroy(1)
    end
    for i, info in ipairs(self.kill_infos) do
      info:update(t, i - 1)
    end
    self._update_t = t
  end
  
  function KillFeed:get_localized_text(text)
    if not self.localized_text[text] then
      self.localized_text[text] = managers.localization:text(text)
    end
    return self.localized_text[text]
  end
  
  function KillFeed:get_name_by_tweak_data_id(tweak)
    if not tweak then
      return
    end
    if not self.unit_name[tweak] then
      self.unit_name[tweak] = string.capitalize(tweak:gsub("_", " ")):gsub("Swat", "SWAT"):gsub("Fbi", "FBI")
    end
    return self.unit_name[tweak]
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

    unit = alive(unit_base._thrower_unit) and unit_base._thrower_unit or unit
    unit_base = alive(unit) and unit:base() or unit_base
    
    local tweak = unit_base._tweak_table or unit_base._tweak_table_id
    
    local gstate = managers.groupai:state()
    local cm = managers.criminals
    
    local owner = unit_base._owner or unit_base.get_owner and unit_base:get_owner() or unit_base.kpr_minion_owner_peer_id and cm:character_unit_by_peer_id(unit_base.kpr_minion_owner_peer_id)
    local owner_base = alive(owner) and owner:base()

    local name
    local unit_type = "npc"
    if unit_base.is_husk_player or unit_base.is_local_player then
      unit_type = unit_base.is_local_player and "player" or "crew"
      name = unit:network():peer():name()
    elseif gstate:is_unit_team_AI(unit) then
      unit_type = "team_ai"
      name = unit_base:nick_name()
    elseif gstate:is_enemy_converted_to_criminal(unit) then
      if Keepers and Keepers.GetJokerNameByPeer then
        name = Keepers:GetJokerNameByPeer(unit_base.kpr_minion_owner_peer_id)
      else
        name = self:get_name_by_tweak_data_id(tweak)
        if name and owner_base and (owner_base.is_husk_player or owner_base.is_local_player) then
          name = owner:network():peer():name() .. "'s " .. name
        end
      end
    else
      name = self:get_name_by_tweak_data_id(tweak)
      if name and owner_base and (owner_base.is_husk_player or owner_base.is_local_player) then
        name = owner:network():peer():name() .. "'s " .. name
      end
    end
    
    if not name then
      return
    end
    
    local is_special = tweak and tweak_data.character[tweak] and tweak_data.character[tweak].priority_shout
    local color_id = alive(owner) and cm:character_color_id_by_unit(owner) or alive(unit) and cm:character_color_id_by_unit(unit)
    local color = is_special and KillFeed.color.special or color_id and color_id < #tweak_data.chat_colors and tweak_data.chat_colors[color_id] or KillFeed.color.default
    
    local information = { 
      name = name,
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

  function KillFeed:estimated_weapon(unit, variant)
    local unit_inventory = unit:inventory()
    local unit_base = unit:base()
    if not unit_inventory then
      return
    end
    local weapon_type, weapon_id
    if variant == "bullet" then
      local weapon = unit_inventory.equipped_unit and unit_inventory:equipped_unit()
      weapon_type = "default"
      weapon_id = weapon and weapon:base()._name_id
    elseif variant == "melee" then
      weapon_type = "melee"
      weapon_id = unit_base.is_husk_player and unit:network():peer():melee_id()
    end
    return weapon_type, weapon_id
  end
  
  function KillFeed:get_weapon_texture(damage_info)
    local weapon = damage_info.weapon_unit
    local weapon_base = alive(weapon) and weapon:base() or {}
    local n = {
      default = weapon_base._name_id or weapon_base._weapon_id,
      melee = damage_info.variant == "melee" and damage_info.name_id,
      throwable = weapon_base._tweak_projectile_entry
    }
    local weapon_type = n.default and "default" or n.melee and "melee" or n.throwable and "throwable"
    local weapon_id = weapon_type and n[weapon_type]
    if not weapon_id then
      weapon_type, weapon_id = self:estimated_weapon(damage_info.attacker_unit, damage_info.variant)
      if not weapon_id then
        return "guis/textures/pd2/endscreen/what_is_this"
      end
    end
    weapon_id = weapon_id:gsub("_crew$", ""):gsub("_npc$", "")
    weapon_id = self.npc_weapon_translation[weapon_id] or weapon_id
    if not self.weapon_texture[weapon_type][weapon_id] then
      if weapon_type == "default" then
        self.weapon_texture[weapon_type][weapon_id] = managers.blackmarket:get_weapon_icon_path(weapon_id) or "guis/textures/pd2/endscreen/what_is_this"
      elseif weapon_type == "melee" then
        local guis_catalog = "guis/"
        local bundle_folder = tweak_data.blackmarket.melee_weapons[weapon_id] and tweak_data.blackmarket.melee_weapons[weapon_id].texture_bundle_folder
        if bundle_folder then
          guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        self.weapon_texture[weapon_type][weapon_id] = guis_catalog .. "textures/pd2/blackmarket/icons/melee_weapons/" .. tostring(weapon_id)
      elseif weapon_type == "throwable" then
        local guis_catalog = "guis/"
        local bundle_folder = tweak_data.blackmarket.projectiles[weapon_id] and tweak_data.blackmarket.projectiles[weapon_id].texture_bundle_folder
        if bundle_folder then
          guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
        end
        self.weapon_texture[weapon_type][weapon_id] = guis_catalog .. "textures/pd2/blackmarket/icons/grenades/" .. tostring(weapon_id)
      end
    end
    return self.weapon_texture[weapon_type][weapon_id]
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
    local assist_info = self.settings.show_assists and self:get_assist_information(target, damage_info.attacker_unit)
    KillInfo:new(attacker_info, target_info, assist_info, status or "kill", KillFeed.settings.style == 3 and self:get_weapon_texture(damage_info))
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
        KillInfo:new({ name = "Dallas", color = tweak_data.chat_colors[1] }, { name = "Bulldozer", color = self.color.special }, self.settings.show_assists and { name = "Wolf", color = tweak_data.chat_colors[2] }, "kill", managers.blackmarket:get_weapon_icon_path("new_m4"))
        KillInfo:new({ name = "FBI Heavy SWAT", color = self.color.default }, { name = "Wolf's Sentry Gun", color = tweak_data.chat_colors[2] }, nil, "destroy", managers.blackmarket:get_weapon_icon_path("new_m4"))
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
      items = { "KillFeed_menu_style_icon", "KillFeed_menu_style_text", "KillFeed_menu_style_weapons" },
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
    MenuHelper:AddMenuItem(MenuHelper:GetMenu("lua_mod_options_menu"), menu_id_main, "KillFeed_menu_main_name", "KillFeed_menu_main_desc")
  end)
  
end