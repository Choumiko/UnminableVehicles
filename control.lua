local Position = require 'stdlib/area/position'
local types = {car = true, locomotive = true, ["cargo-wagon"] = true}

local function init_global()
    global = global or {}
    global.teleported_players = global.teleported_players or {}
end
local events = {}
local function conditional_events()
    if settings.global["unminable_vehicles_teleport_players"].value then
        script.on_event(defines.events.on_player_mined_entity, events.on_player_mined_entity)
    else
        script.on_event(defines.events.on_player_mined_entity, nil)
    end
    if table_size(global.teleported_players) > 0 then
        log("registered events")
        script.on_event(defines.events.on_tick, events.on_tick)
        script.on_event(defines.events.on_player_died, events.on_player_died)
    else
        log("unregistered events")
        script.on_event(defines.events.on_tick, nil)
        script.on_event(defines.events.on_player_died, nil)
    end
end

events.on_player_mined_entity = function(event)
    if types[event.entity.type] then
        local player = game.players[event.player_index]
        local position = player.surface.find_non_colliding_position("player", {x=0,y=0}, 10, 0.2)
        local text = "%s mined a vehicle!"
        if position then
            if player.teleport(position) then
                text = text .. " Somehow he got teleported to spawn."
            end
        else
            player.force.print(string.format("Couldn't teleport %s", player.name))
        end
        player.force.print(string.format(text, player.name))
        player.force.print(string.format("The vehicle makes %s so heavy that he can't move. Lets put him out of this misery", player.name))
        global.teleported_players[player.index] = player.position
        conditional_events()
    end
end

events.on_player_died = function(event)
    local index = event.player_index
    if global.teleported_players[index] then
        global.teleported_players[index] = nil
        conditional_events()
    end
end

events.on_tick = function(_)
    if table_size(global.teleported_players) > 0 then
        for index, position in pairs(global.teleported_players) do
            if Position.distance(position, game.players[index].position) > 0 then
                game.players[index].teleport(position)
            end
        end
    end
end

local function update_vehicles(unminable)
    local _, err = pcall(function()
        for _, surface in pairs(game.surfaces) do
            for type, _ in pairs(types) do
                for _, vehicle in pairs(surface.find_entities_filtered{type = type}) do
                    vehicle.minable = unminable
                end
            end
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured, see log")
        log(serpent.block(err))
    end
end

script.on_init(function()
    init_global()
    conditional_events()
    update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
end)

script.on_load(function()
    local _, err = pcall(function()
        conditional_events()
    end)
    if err then
        log(serpent.block(err))
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local _, err = pcall(function()
        if event.setting == "unminable_vehicles_teleport_players" then
            script.on_event(defines.events.on_tick, nil)
        end
        if event.setting == "unminable_vehicles_make_unminable" then
            update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured, see log")
        log(serpent.block(err))
    end
end)
