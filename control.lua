local types = {car = true, locomotive = true, ["cargo-wagon"] = true, ["fluid-wagon"] = true, ["artillery-wagon"] = true}

local function init_global()
    local _, err = pcall(function()
        global = global or {}
        global.teleported_players = global.teleported_players or {}
        global.teleport_location = global.teleport_location or { x = 0, y = 0}
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

local events = {}

local function conditional_events()
    local _, err = pcall(function()
        local unminable = settings.global["unminable_vehicles_make_unminable"].value
        if settings.global["unminable_vehicles_teleport_players"].value then
            script.on_event(defines.events.on_player_mined_entity, events.on_player_mined_entity)
        else
            script.on_event(defines.events.on_player_mined_entity, nil)
        end

        if settings.global["unminable_vehicles_prevent_rotation"].value then
            script.on_event(defines.events.on_player_rotated_entity, events.on_player_rotated_entity)
        else
            script.on_event(defines.events.on_player_rotated_entity, nil)
        end

        if unminable then
            script.on_event(defines.events.on_built_entity, events.on_built_entity)
            script.on_event(defines.events.script_raised_built, events.script_raised_built)
        else
            script.on_event(defines.events.on_built_entity, nil)
            script.on_event(defines.events.script_raised_built, nil)
        end

        if table_size(global.teleported_players) > 0 then
            --log("Registered events")
            script.on_event(defines.events.on_tick, events.on_tick)
            script.on_event(defines.events.on_player_died, events.on_player_died)
            script.on_event(defines.events.on_player_cursor_stack_changed, events.on_cursor_stack_changed)
            script.on_event(defines.events.on_player_driving_changed_state, events.on_player_driving_changed_state)
        else
            --log("Unregistered events")
            script.on_event(defines.events.on_tick, nil)
            script.on_event(defines.events.on_player_died, nil)
            script.on_event(defines.events.on_player_cursor_stack_changed, nil)
            script.on_event(defines.events.on_player_driving_changed_state, nil)
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

local function teleport_player(player)
    local position = player.surface.find_non_colliding_position("character", global.teleport_location, 10, 0.2)

    return player.teleport(position)
end

local function print_message(force, msg)
    force.print(msg)
    if remote.interfaces.ChatToFile and remote.interfaces.ChatToFile.chat then --luacheck: ignore
        remote.call("ChatToFile", "chat", msg)
    end
end

events.on_player_mined_entity = function(event)
    local _, err = pcall(function()
        if types[event.entity.type] then
            local player = game.players[event.player_index]
            if player.vehicle and player.vehicle.valid then
                player.driving = false
            end
            local text = "%s mined a vehicle!"
            if teleport_player(player) then
                text = text .. " Somehow he got teleported to spawn."
            else
                local t = string.format("Couldn't teleport %s", player.name)
                print_message(player.force, t)
            end
            print_message(player.force, string.format(text, player.name))
            print_message(player.force, string.format("The vehicle makes %s so heavy that he can't move. Lets put him out of this misery", player.name))
            global.teleported_players[player.index] = player.position
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.on_player_rotated_entity = function(event)
    local _, err = pcall(function()
        if event.entity.type == "locomotive" then
            local player = game.players[event.player_index]
            local text = "%s rotated a locomotive!"
            if teleport_player(player) then
                text = text .. " Somehow he got teleported to spawn."
            else
                print_message(player.force, string.format("Couldn't teleport %s", player.name))
            end
            print_message(player.force, string.format(text, player.name))
            print_message(player.force, string.format("For mysterious reasons he can't move. Lets put him out of this misery", player.name))
            global.teleported_players[player.index] = player.position
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.on_built_entity = function(event)
    local _, err = pcall(function()
        if types[event.created_entity.type] then
            event.created_entity.minable = false
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.script_raised_built = function(event)
    events.on_built_entity({created_entity = event.entity})
end

events.on_player_died = function(event)
    local _, err = pcall(function()
        local index = event.player_index
        if global.teleported_players[index] then
            global.teleported_players[index] = nil
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.on_tick = function(_)
    local _, err = pcall(function()
        if table_size(global.teleported_players) > 0 then
            for index, position in pairs(global.teleported_players) do
                local player = game.players[index]
                local player_pos = player.position
                local axbx = position.x - player_pos.x
                local ayby = position.y - player_pos.y
                if axbx * axbx + ayby * ayby > 0 then
                    player.walking_state = {walking = false, direction = player.walking_state.direction}
                end
                player.mining_state = {state = false}
                if not settings.global["unminable_vehicles_allow_shooting"].value then
                    player.shooting_state = {state = false, position = player.shooting_state.position}
                end
            end
        else
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.on_cursor_stack_changed = function(event)
    local _, err = pcall(function()
        if table_size(global.teleported_players) > 0 and global.teleported_players[event.player_index] then
            local player = game.players[event.player_index]
            if player.cursor_stack.valid_for_read then
                player.print("You can't build while waiting for punishment.")
                player.clear_cursor()
            end
        else
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

events.on_player_driving_changed_state = function(event)
    local _, err = pcall(function()
        local player = game.players[event.player_index]
        if global.teleported_players[player.index] and player.vehicle  and player.vehicle.valid then
            print_message(player.force, string.format("Oh come on %s, trying to get into a vehicle while waiting for punishment? Don't be a chicken!", player.name))
            player.vehicle.passenger = nil
            teleport_player(player)
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
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
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end

script.on_init(function()
    local _, err = pcall(function()
        init_global()
        conditional_events()
        update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end)

script.on_load(function()
    local _, err = pcall(function()
        conditional_events()
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end)

script.on_configuration_changed(function()
    local _, err = pcall(function()
        init_global()
        conditional_events()
        update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local _, err = pcall(function()
        if event.setting == "unminable_vehicles_teleport_players" then
            if not settings.global["unminable_vehicles_teleport_players"].value then
                global.teleported_players = {}
            end
            conditional_events()
        end
        if event.setting == "unminable_vehicles_prevent_rotation" then
            conditional_events()
        end
        if event.setting == "unminable_vehicles_make_unminable" then
            update_vehicles( not settings.global["unminable_vehicles_make_unminable"].value )
            conditional_events()
        end
    end)
    if err then
        log("Unminable vehicles: Error occured")
        log(serpent.block(err))
    end
end)

local function set_teleport_location(event)
    local player = game.players[event.player_index]
    if player.admin then
        global.teleport_location = game.player.position
        local player_pos = player.position
        player.force.print("Set teleport location to {" .. player_pos.x .. ", " .. player_pos.y .. "}")
    else
        player.print("Need to be admin to set the teleport location")
    end
end

local function clear_teleported_players(event)
    local player = game.players[event.player_index]
    if player.admin or table_size(game.connected_players) == 1 then
        global.teleported_players = {}
    end
end

commands.add_command("unminable_vehicles_set_teleport", "Set the teleport location to your current position. Admin only", set_teleport_location)
commands.add_command("unminable_vehicles_enable_movement", "Reenables movement for stuck players. Admin only", clear_teleported_players)
