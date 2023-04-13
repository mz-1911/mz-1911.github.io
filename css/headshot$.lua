--[[
█     ▄███▄   ██   █  █▀ ▄███▄   ██▄   
█     █▀   ▀  █ █  █▄█   █▀   ▀  █  █  
█     ██▄▄    █▄▄█ █▀▄   ██▄▄    █   █ 
███▄  █▄   ▄▀ █  █ █  █  █▄   ▄▀ █  █  
    ▀ ▀███▀      █   █   ▀███▀   ███▀  
                █   ▀                  
               ▀                       
███ ▀▄    ▄                            
█  █  █  █                             
█ ▀ ▄  ▀█                              
█  ▄▀  █                               
███  ▄▀                                
                                       
                                       
   ▄   ▄█   ▄▀    ▄▀  ██               
    █  ██ ▄▀    ▄▀    █ █              
██   █ ██ █ ▀▄  █ ▀▄  █▄▄█             
█ █  █ ▐█ █   █ █   █ █  █             
█  █ █  ▐  ███   ███     █             
█   ██                  █              
                       ▀               
█▀▄▀█ ██      ▄                        
█ █ █ █ █      █                       
█ ▄ █ █▄▄█ ██   █                      
█   █ █  █ █ █  █                      
   █     █ █  █ █                      
  ▀     █  █   ██                      
       ▀
--]]

--Most of this shit is terribly made, and you will lose some FPS with certain features.
--[+] NIGGA MAN #1 [+]
--[+] CHICO MAN #1 [+]



local client_find_sig, client_is_alive, client_choked_commands, engine_execute_client_cmd, engine_get_player_info, engine_get_local_player, engine_get_player_for_user_id, entity_list_get_client_entity, callbacks_register, exploits_process_ticks = client.find_sig, client.is_alive, client.choked_commands, engine.execute_client_cmd, engine.get_player_info, engine.get_local_player, engine.get_player_for_user_id, entity_list.get_client_entity, callbacks.register, exploits.process_ticks
local bit_band = bit.band
--local math.cos, math.max, math.min, math.sqrt, math.abs, math.floor, math.sin, math.pi, math.random = math.cos, math.max, math.min, math.sqrt, math.abs, math.floor, math.sin, math.pi, math.random
local string_sub = string.sub
local ui_get, ui_get_rage = ui.get, ui.get_rage
local cvar_find_var = cvar.find_var
local table_insert = table.insert
--local global_vars.curtime, global_vars.frametime, global_vars.realtime, global_vars.interval_per_tick, global_vars.tickcount, global_vars.max_clients = global_vars.curtime. global_vars.frametime, global_vars.realtime, global_vars.interval_per_tick, global_vars.tickcount, global_vars.max_clients
local small_verdana = render.create_font("Verdana", 16, 800, bit.bor(font_flags.dropshadow, font_flags.antialias))
local small_fonts = render.create_font("Small Fonts", 8, 500, font_flags.outline)
local verdana = render.create_font("Verdana", 26, 800, bit.bor(font_flags.dropshadow, font_flags.antialias))

local dmg = ui_get("Rage", "Aimbot", "General", "Minimum damage override key")
local ovr = ui_get("Rage", "Aimbot", "General", "Anti-aim resolver override key")
local baim = ui_get_rage("Accuracy", "Force body aim key")
local freestanding = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Freestanding")
local ping_spike = ui_get("Misc", "General", "General", "Ping spike key")

local dt = ui_get("Rage", "Aimbot", "Accuracy", "Double tap key") 
local menu_color = ui_get("Profile", "General", "Global settings", "Menu accent color")
local silent_aim = ui_get("Rage", "Aimbot", "General", "Silent aim")
local rage_hc = ui_get_rage("Accuracy", "Hitchance")
local fake_walk = ui_get("Misc", "General", "Movement", "Slow walk key")

local fake = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Fake yaw jitter")
local yaw = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Yaw")

local jitter_distance = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Jitter distance")

local lby_breaker = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Fake body")

local manual = {
    left = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Manual left key"),
    right = ui_get("Rage", "Anti-aim", "Anti-aimbot", "Manual right key")
}

local foot_shadows_cvar = cvar_find_var("cl_foot_contact_shadows")
local right_hand_cvar = cvar_find_var("cl_righthand")
local cl_mute_enemy_team = cvar.find_var("cl_mute_enemy_team")
local fps_max = cvar.find_var("fps_max")

local lerp = function (a, b, percentage) return a + (b - a) * percentage end
local table_lerp = function(a, b, percentage) local result = {} for i=1, #a do result[i] = lerp(a[i], b[i], percentage) end return result end
local in_sine = function(t, b, c, d) return -c * math.cos(t / d * (math.pi / 2)) + c + b end
local normalize_yaw = function(yaw) while yaw > 180 do yaw = yaw - 3 end while yaw < -180 do yaw = yaw + 360 end return yaw end
local angle_vector = function(x, y) local sy, cy, sp, cp = math.rad(y), math.rad(y), math.rad(x), math.rad(x) return math.cos(cp) * math.cos(cy), math.cos(cp) * math.sin(sy), -math.sin(sp) end

local is_enemy = function(local_player, player)
    local local_team = local_player:get_prop('DT_CSPlayer', 'm_iTeamNum'):get_int()
    local enemy_team = player:get_prop('DT_CSPlayer', 'm_iTeamNum'):get_int()

    return local_team ~= enemy_team
end

local get_difference = function(cmd, local_player)
    local lby = local_player:get_prop('DT_CSPlayer', 'm_flLowerBodyYawTarget'):get_float()
    local difference = lby - cmd.viewangles.y

    return math.abs(difference)     
end

local get_weapon = function(local_player)
    local weapon_index = entity_list_get_client_entity(local_player:get_prop('DT_BaseCombatCharacter', 'm_hActiveWeapon'))
    local weapon = weapon_index:get_prop('DT_BaseCombatWeapon', 'm_iItemDefinitionIndex'):get_int()

    return weapon
end

local left_hand_weapon = function(local_player)
    local weapon = get_weapon(local_player)
    local is_knife

    if weapon == 42 or weapon == 59 or weapon >= 500 then -- dont know how to get classname Lole
        is_knife = true
    end

    right_hand_cvar:set_value_int(is_knife and 0 or 1)
end

local lby_update = 999
local update_time = 0
local delta = 0

local get_update_time = function(local_player)    
    local breaking = false
    local current_server_time = global_vars.interval_per_tick * global_vars.tickcount
    local base_velocity = local_player:get_prop('DT_CSPlayer', 'm_vecVelocity[0]'):get_vector()
    local velocity_non_sqrt = base_velocity.x ^ 2 + base_velocity.y ^ 2
    local velocity = math.sqrt(velocity_non_sqrt)

    if velocity > 0.1 then
        -- moving
        
        lby_update = current_server_time + 0.22
    else
        breaking = true
        if current_server_time >= lby_update then
            lby_update = current_server_time + 1.1
        end

        if delta <= 1 then
            lby_update = current_server_time + 1.1
        end
    end

    return lby_update - current_server_time, breaking
end

local function vmt_entry(instance, index, type)
    return ffi.cast(type, (ffi.cast("void***", instance)[0])[index])
end

local function vcall(index, typestring)
    local t = ffi.typeof(typestring)
    return function(instance, ...)
        if instance then
            return vmt_entry(instance, index, t)(instance, ...)
        end
    end
end

local function find_sig(mdlname, pattern, typename, offset, deref_count)
	local raw_match = client.find_sig(mdlname, pattern) or error("signature not found", 2)
	local match = ffi.cast("uintptr_t", raw_match)

	if offset ~= nil and offset ~= 0 then
		match = match + offset
	end

	if deref_count ~= nil then
		for i = 1, deref_count do
			match = ffi.cast("uintptr_t*", match)[0]
			if match == nil then
				return error("signature not found", 2)
			end
		end
	end

	return ffi.cast(typename, match)
end

local FindHudElement = find_sig("client.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28", "void***(__thiscall*)(void*, const char*)")
local pHudChat = FindHudElement(find_sig("client.dll", "A1 ? ? ? ? A8 01 74 57 ", "void*", 1, 1), "CHudChat")

local ChatPrintf = vcall(26, "void(__cdecl*)(void*, int, int, const char*, ...)")

ui.add_label('--- [ H E A D S H O T $ . L U A ] ---')

local master = ui.add_checkbox("Master switch")
local filter_console = ui.add_checkbox("Filter console")
local killsay = ui.add_checkbox("Killsay")
local killsay_reply = ui.add_checkbox("Killsay reply")
local killsay_bar_color = ui.add_cog("Killsay reply timer", true, false)
local clantag_spammer = ui.add_checkbox("Clantag spammer") 
local clantag_picker = ui.add_dropdown("Clantag", {"Default", "AIMWARE.net", "cantresolve.us", "Invisble scoreboard", "Pandora beta"})
local visuals = ui.add_multi_dropdown("Indicators", {"Default indicator", "Keybind indicator", "LBY indicator", "Manual indicator", "Spectator list"})
local accent_color = ui.add_cog("Accent color for indicator", true, false)
local primary_color = ui.add_cog("Primary color for indicator", true, false)
local inactive_color = ui.add_cog("Inactive color for keybind", true, false)
local lby_timer = ui.add_checkbox("LBY timer")
local foot_shadows = ui.add_checkbox("Remove foot shadows")
local silent_aim_disabler = ui.add_checkbox("Disable silent on awp/scout")
local reveal_chat = ui.add_checkbox("Reveal enemy team chat")
local knife_lefthand = ui.add_checkbox("Knife on lefthand")

ui.add_label('--- [ H E A D S H O T $ . L U A ] ---')

local set_clantag_sig = client_find_sig("engine.dll", "53 56 57 8B DA 8B F9 FF 15")
local set_clantag = ffi.cast("int(__fastcall*)(const char*, const char*)", set_clantag_sig)

local tag_last_change = 0
local tag = {
    [1] = {
        "HEADSHOT$.LUA  ",
        "EADSHOT$.LUA  H",
        "ADSHOT$.LUA  HE",
        "DSHOT$.LUA  HEA",
        "SHOT$.LUA  HEAD",
        "HOT$.LUA  HEADS",
        "OT$.LUA  HEADSH",
        "T$.LUA  HEADSHO",
        "$.LUA  HEADSHOT",
        ".LUA  HEADSHOT$",
        "LUA  HEADSHOT$.",
        "UA  HEADSHOT$.L",
        "A  HEADSHOT$.LU",
        "  HEADSHOT$.LUA",
        "HEADSHOT$.LUA", 
    },

    [2] = {
        "AIMWARE.net  ",
        "IMWARE.net  A",
        "MWARE.net  AI",
        "WARE.net  AIM",
        "ARE.net  AIMW",
        "RE.net  AIMWA",
        "E.net  AIMWAR",
        ".net  AIMWARE",
        "net  AIMWARE.",
        "et  AIMWARE.n",
        "t  AIMWARE.ne",
        "  AIMWARE.net",
        " AIMWARE.net ",
        "AIMWARE.net  ",
    },

    [3] = {
        '>cantresolve.us',
        '>cantresolve.u',
        '>cantresolve.',
        '>cantresolve',
        '>cantresolv',
        '>cantresol',
        '>cantreso',
        '>cantres',
        '>cantre',
        '>cantr',
        '>cant',
        '>can',
        '>ca',
        '>c',
        '>',
        '>s',
        '>us',
        '>.us',
        '>e.us',
        '>ve.us',
        '>lve.us',
        '>olve.us',
        '>esolve.us',
        '>resolve.us',
        '>tresolve.us',
        '>ntresolve.us',
        '>antresolve.us',
        '>cantresolve.us',
    },

    [4] = {"\n"},
    [5] = {
        'pandora beta',
        'pandora beta',
        'pandora beta',
        'pandora beta',
        'pandora beta',
        'pandora beta',
        'pandora bet',
        'pandora be',
        'pandora b',
        'pandora ',
        'pandora b',
        'pandora be',
        'pandora bet',
        'pandora beta',
    },
} 

local last_killsay_time = 0
local killsay_index = 1

local should_do_killsay = false

local wait_time = 0.0
local killsay_list = {
    "1",
    "LMAO",
    "rofl",
    "get fucked nn",
    "? XD",
    "ns",
    "sit shit bot",
    "u are so shit",
    "shoot next time ?XD",
    "?HAHAHAHA",
    " u retard ))",
    "iq",
    "baited",
    "moron",
    "so shit",
    "morons",
    "by aimware",
  --  "izi",
  --  "IZI",
  --  "so fkn EZ",
    "bots",
    "ezzz",
    "LAL",
    "sit",
    "hs",
    "hh",
    "cry",
    "nice animfix",
  --  "grab a straw coz you suck",
   -- "dump my 979",
    "HHHHHHHH",

    -- keep these last
    "zap",
    "kobe",
    "fire is hot XD"
}

local reply_list = {
    "lol ur literally talking so much",
    "stfu who cares LOL",
    "i asked",
    "hdf",
    "stfu dog",
    "stop talking",
    "newfag",
    "that's crazy",
    "cool story bro",
    "stfu nice uid LOL",
    "still talking?xD",
    "feed your own ego im busy",
    "HAHHAHA KEEP crying shi t bot",
}
 
local x, y = render.get_screen()
local c_x, c_y = x / 2, y / 2

local main_text = "headshot$.lua"
local death_alpha = global_vars.curtime

local indicator_tbl = {
    ["DMG"] = dmg,
    ["BAIM"] = baim,
    ["PING"] = ping_spike,
    ["DT"] = dt,
}

local last_kill_index = 0

local last_say_time = 1
local last_reply_time = 0
local should_reply = false
local last_reply = 1
local can_reply = false

callbacks_register("player_death", function(e)
    local attacker = engine_get_player_for_user_id(e:get_int("attacker"))
    local userid = engine_get_player_for_user_id(e:get_int("userid"))

    local local_player = entity_list_get_client_entity(engine_get_local_player())

    if local_player:index() == userid then
        return -- suicide deathsay fix trolle
    end

    if attacker == local_player:index() and is_enemy(local_player, entity_list_get_client_entity(userid) ) then
        death_alpha = global_vars.curtime + 0.8

        last_kill_index = userid

        should_do_killsay = true
        can_reply = true
        last_killsay_time = 0

        killsay_index = killsay_index + 1

        if (killsay_index > table.getn(killsay_list) - 3) then
            killsay_index = 1;
        end

        print("weapon: " .. e:get_string("weapon"))

        if e:get_string("weapon") == "taser" then
            killsay_index = table.getn(killsay_list) - 2 -- zap
        end

        if e:get_string("weapon") == "hegrenade" then
            killsay_index = table.getn(killsay_list) - 1 -- kobe
        end

        if e:get_string("weapon") == "inferno" then
            killsay_index = table.getn(killsay_list) -- fire is hot
        end

        wait_time = math.random(10, 25) / 10 -- mega troll
        last_killsay_time = global_vars.curtime
    end
end)

local charge_bar_time = 0
local reply_bar_time = 0

function bool_to_int(a)
    if a then return 1 end;

    return 0
end

callbacks.register("player_say", function(e)
    local speaker_index = engine_get_player_for_user_id(e:get_int("userid"))

    if reveal_chat:get() then
        local player = entity_list_get_client_entity(speaker_index)
        if player then
            local player_info = engine_get_player_info(speaker_index)
            local team = player:get_prop('DT_CSPlayer', 'm_iTeamNum'):get_int()
            local prefix = ""

            -- t side
            if team == 2 then
                prefix = " \x09"
            -- ct side
            elseif team == 3 then
                prefix = " \x0B"
            end

            if (player:get_prop('DT_CSPlayer', 'm_iHealth'):get_int() <= 0) then
                prefix = prefix .. "*DEAD* "
            end

            if is_enemy(entity_list_get_client_entity(engine_get_local_player()), player ) then
                ChatPrintf(pHudChat, 0, 0, prefix .. player_info.name .. " : " .. "\x01" .. e:get_string("text") )
            end
        end
    end
    
    if not killsay_reply:get() or not master:get() then
        return
    end

    if not can_reply then
        return
    end
   
    print("spoke: " .. speaker_index .. " last kill: " .. last_kill_index )

    if speaker_index == last_kill_index then
        do_reply = true

        last_reply_time = global_vars.realtime
        last_reply = last_reply+1

        if (last_reply > table.getn(reply_list)) then
            last_reply = 1
        end
    end
end)

local already_set = false
local toggled_check_console = false
local toggled_check_foot = false

local spam_tag = function()
    if clantag_spammer:get() then
        already_set = false 
        if math.floor(global_vars.curtime * 2) ~= tag_last_change then
            local index = math.floor(global_vars.curtime * 2) % table.getn(tag[clantag_picker:get() + 1 ]);
            if index == 0 then 
                index = 1 
            end

            set_clantag(tag[clantag_picker:get() + 1 ][index], tag[clantag_picker:get() + 1][index])

            tag_last_change = math.floor(global_vars.curtime * 2);
        end
    else
        if not already_set then
            set_clantag('', '')
            already_set = true
        end
    end
end

local standing = false
local scan_pos = {}
callbacks_register("paint", function()
    local local_player = entity_list_get_client_entity(engine_get_local_player())

    if not master:get() then
        return
    end

    if cl_mute_enemy_team:get_bool() ~= reveal_chat:get() then
        cl_mute_enemy_team:set_value_int(bool_to_int(reveal_chat:get()))
    end

    spam_tag()

    if local_player == nil then
        return
    end

    if visuals:get("Spectator list") then    
        local current_spectating = entity_list_get_client_entity(local_player:get_prop('DT_BasePlayer', 'm_hObserverTarget'))
        local freecam = local_player:get_prop('DT_CSPlayer', 'm_iObserverMode'):get_int() == 6

        local max_players = global_vars.max_clients
        local valid_indexes = {0}
    
        for i = 1, max_players do
            local player = entity_list_get_client_entity(i)
            local player_index = player:index()

            if player_index ~= -1 and (player:get_prop("DT_CSPlayer", "m_iHealth"):get_int() <= 0 and not player:dormant()) and not freecam then
                -- after filtering out all invalid players we can push valid players back
                -- coz their indexes will be different yk
                table_insert(valid_indexes, player_index)      
            end
        end
    
        for i = 1, #valid_indexes do
            local player = entity_list_get_client_entity(valid_indexes[i])
            local player_info = engine_get_player_info(valid_indexes[i])
            
            local spectate_color = color.new(255,255,255,50)
            local m_hObserverTarget = entity_list_get_client_entity(player:get_prop('DT_BasePlayer', 'm_hObserverTarget')):index()

            if m_hObserverTarget == current_spectating:index() or m_hObserverTarget == local_player:index() then
                spectate_color = menu_color:get_color()
            end
            
            local list_text_size = {render.get_text_size(player_info.name)}
            render.text(x - list_text_size[1] - 12, 10 + (i * list_text_size[2]), player_info.name, spectate_color)
        end
    end

    if killsay:get() then
        if should_do_killsay then 
            if last_killsay_time ~= 0 then
                if (global_vars.curtime - last_killsay_time) > wait_time then
                    if (client_is_alive()) then
                        engine_execute_client_cmd("say " .. killsay_list[killsay_index])
                    else
                        engine_execute_client_cmd("say baited")
                    end
                    last_say_time = global_vars.realtime
                    should_do_killsay = false
                end
            end 
        end

        if can_reply then
            if last_reply_time ~= 0 then
                if (global_vars.realtime - last_reply_time) > 20 then
                    print("reply timer expired")
                    can_reply = false
                    do_reply = false
                end

                if (global_vars.realtime - last_reply_time) > 2.5 and can_reply and do_reply then
                    engine_execute_client_cmd("say " .. reply_list[last_reply])
                    do_reply = false
                end
            end
        end
    end

    if not client_is_alive() then
        return
    end

    local colors = {
        primary = primary_color:get_color(),
        accent = accent_color:get_color(),
        inactive = inactive_color:get_color(),
        killsay = killsay_bar_color:get_color(),
    }

    if global_vars.curtime >= death_alpha then
        death_alpha = global_vars.curtime -- random troll fix
    end

    local shifted_ticks = exploits_process_ticks()

    local color_lerp = table_lerp({colors.primary:r(), colors.primary:g(),colors.primary:b(), colors.primary:a()}, {colors.accent:r(), colors.accent:g(),colors.accent:b(), colors.accent:a()}, death_alpha - global_vars.curtime)
    local lerped_color = color.new(color_lerp[1],color_lerp[2], color_lerp[3], color_lerp[4])

    local main_text_size = small_verdana:get_size(main_text)
    
    local indicator_pos = {
        charge_bar_anim = 0,
        reply_bar_anim = 0,
    }

    if visuals:get("Default indicator") then
        small_verdana:text(c_x - main_text_size / 2, c_y + 25, lerped_color, main_text)

        local frametime = global_vars.frametime * 7
        charge_bar_time = math.max(0, math.min(1, (charge_bar_time + (shifted_ticks / 14 ~= 0 and frametime or -frametime))))
        indicator_pos.charge_bar_anim = in_sine(charge_bar_time, 0, 1, 1)

        local rect_size = main_text_size + 10
        render.rectangle_filled(c_x - (shifted_ticks / 14) * rect_size / 2, c_y + 41 + indicator_pos.charge_bar_anim, (shifted_ticks / 14) * rect_size, 2, colors.accent)  
        
        local expired = (global_vars.realtime - last_reply_time) > 20
        if last_reply_time ~= 0 then
            reply_bar_time = math.max(0, math.min(1, (reply_bar_time + (((global_vars.realtime - last_reply_time) / 20 ~= 0 and not expired) and frametime or -frametime))))
        end
    
        indicator_pos.reply_bar_anim = in_sine(reply_bar_time, 0, 1, 1)
    
        if last_reply_time ~= 0 and not expired then
            local remaining_width = ((global_vars.realtime - last_reply_time) / 20) * rect_size
            if remaining_width > rect_size then remaining_width = rect_size end
    
            local reply_width = ((1.5) / 20) * rect_size    
            render.rectangle_filled(c_x - rect_size/2, c_y + 41 + indicator_pos.reply_bar_anim + (5 * indicator_pos.charge_bar_anim), remaining_width, 2, killsay_bar_color:get_color())
        end
    end

    local total_anim_amt = indicator_pos.charge_bar_anim + indicator_pos.reply_bar_anim

    local index = 0
    if visuals:get("Keybind indicator") then
        for string, trigger in pairs(indicator_tbl) do
            index = index + 1
            local color = trigger ~= false and trigger:get_key() and colors.accent or colors.inactive

            if string == "DT" then
                color = (trigger ~= false and trigger:get_key() and exploits_process_ticks() == 14) and colors.accent or (trigger ~= false and trigger:get_key() and exploits_process_ticks() < 14) and color.new(255, 0, 0, colors.accent:a()) or colors.inactive
            end

            local string_size = {small_fonts:get_size(string)}
            small_fonts:text(c_x - (string_size[1] / 2), c_y + (index * 8) + 33 + (total_anim_amt * 5), color, string)
        end
    end

    if visuals:get("Manual indicator") then
        local pulse = math.sin(math.abs(-math.pi + (global_vars.curtime * (1 / 0.45)) % (math.pi * 2))) * colors.accent:a()

        render.triangle_filled(vector2d.new( c_x  - 74, c_y ), vector2d.new( c_x  - 54, c_y + 10), vector2d.new( c_x  - 54, c_y - 10), color.new(manual.left:get_key() and colors.accent:r() or 50, manual.left:get_key() and colors.accent:g() or 50, manual.left:get_key() and colors.accent:b() or 50, manual.left:get_key() and pulse or 0)) -- right
        render.triangle_filled(vector2d.new( c_x  + 75, c_y ), vector2d.new( c_x  + 55, c_y + 10), vector2d.new( c_x  + 55, c_y - 10), color.new(manual.right:get_key() and colors.accent:r() or 50, manual.right:get_key() and colors.accent:g() or 50, manual.right:get_key() and colors.accent:b() or 50, manual.right:get_key() and pulse or 0)) -- left
    end

    if silent_aim_disabler:get() then
        local lp_wep = entity_list_get_client_entity(local_player:get_prop("DT_BaseCombatCharacter", "m_hActiveWeapon"))
        silent_aim:set( not (lp_wep:class_id() == 238 or lp_wep:class_id() == 205) )
    end

    if filter_console:get() and not toggled_check then
        engine.execute_client_cmd('developer 1;con_filter_enable 1;con_filter_text "balls";con_filter_text_out "cum"')

        toggled_check = true
    elseif not filter_console:get() then
        toggled_check = true

        if toggled_check then
            engine.execute_client_cmd('developer 0;con_filter_enable 0')

            toggled_check = false
        end
    end

    if foot_shadows:get() then
        if foot_shadows_cvar:get_int() ~= 0 then
            foot_shadows_cvar:set_value_int(0)
        end

    elseif not foot_shadows:get() then
        toggled_check_foot = true

        if toggled_check_foot then
            foot_shadows_cvar:set_value_int(1)

            toggled_check_foot = false
        end
    end
    
    if visuals:get("LBY indicator") then
        local lby_check = delta >= 45 and standing and lby_breaker:get()

        verdana:text(15, y - 100, color.new(lby_check and colors.accent:r() or colors.inactive:r(), lby_check and colors.accent:g() or colors.inactive:g(), lby_check and colors.accent:b() or colors.inactive:b(), lby_check and colors.accent:a() or colors.inactive:a()), "LBY")
        if lby_check and update_time <= 1.1 and lby_timer:get() then
            local lby_size = {verdana:get_size("LBY")}
            local rect_bar = update_time / 1.1

            render.rectangle(15, y - 100 + lby_size[2] - 1, lby_size[1], 4, color.new(0, 0, 0, 100))
            render.rectangle(16, y - 100 + lby_size[2], lby_size[1] * rect_bar, 2, colors.accent)
        end
    end

    if knife_lefthand:get() then
        left_hand_weapon(local_player)
    end
end)

local last_moving_prevent = false
callbacks_register("post_move", function(cmd)
    local local_player = entity_list_get_client_entity(engine_get_local_player())
    if local_player == nil or not client_is_alive() or not master:get() then
        return
    end
end)

callbacks.register("post_move", on_post_move)

callbacks_register("player_connect_full", function(e)
    fps_max:set_value_int(0)

    if not filter_console:get() then
        return
    end

    if engine_get_player_for_user_id(e:get_int("userid")) == engine_get_local_player() then
        engine_execute_client_cmd("ignorerad")
    end
end)

callbacks_register("player_spawn", function(e)
    if engine_get_player_for_user_id(e:get_int("userid")) == entity_list_get_client_entity(engine_get_local_player()):index() then
        death_alpha = global_vars.curtime -- fix rainbow mode lole
    end
end)