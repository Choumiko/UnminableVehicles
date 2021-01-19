local types = {"car", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon", "spider-vehicle"}
local rotatable_types = {
    locomotive = true,
    ["artillery-wagon"] = true,
}

local vehicle_filters = {
    {filter = "rolling-stock"},
    {filter = "vehicle"}
}

local function init_global()
    local _, err = pcall(function()
        global = global or {}
        global.teleported_players = global.teleported_players or {}
        global.teleport_location = global.teleport_location or { x = 0, y = 0}
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

local function replace_mining_results(event)
    local buffer = event.buffer
    local items = event.entity.prototype.items_to_place_this
    local item
    local return_amount = settings.global["unminable_vehicles_mine_ingredients"].value
    if return_amount == 0 then return end
    for i = 1, #buffer do
        for _, v in pairs(items) do
            if buffer[i].name == v.name then
                item = v.name
                break
            end
        end
    end
    local recipes = game.get_filtered_recipe_prototypes{{filter = "has-product-item", elem_filters = {{filter = "name", name = item}}}}
    for _, recipe in pairs(recipes) do
        local ingredients = recipe.ingredients
        if #ingredients > 0 then
            buffer.remove{name = item, count = 1}
            for _, ingredient in pairs(ingredients) do
                if ingredient.type == "item" then
                    buffer.insert{name = ingredient.name, count = math.ceil(ingredient.amount * return_amount)}
                end
            end
            break
        end
    end
end

local events = {}

local function conditional_events()
    local _, err = pcall(function()
        if settings.global["unminable_vehicles_prevent_rotation"].value then
            script.on_event(defines.events.on_player_rotated_entity, events.on_player_rotated_entity)
        else
            script.on_event(defines.events.on_player_rotated_entity, nil)
        end

        if settings.global["unminable_vehicles_make_unminable"].value then
            script.on_event(defines.events.on_built_entity, events.on_built_entity, vehicle_filters)
            script.on_event(defines.events.on_robot_built_entity, events.on_built_entity, vehicle_filters)
            script.on_event(defines.events.script_raised_built, events.script_raised_built, vehicle_filters)

            script.on_event(defines.events.on_player_mined_entity, nil)
            script.on_event(defines.events.on_robot_mined_entity, nil)
        else
            script.on_event(defines.events.on_built_entity, nil)
            script.on_event(defines.events.on_robot_built_entity, nil)
            script.on_event(defines.events.script_raised_built, nil)

            script.on_event(defines.events.on_player_mined_entity, events.on_player_mined_entity, vehicle_filters)
            script.on_event(defines.events.on_robot_mined_entity, replace_mining_results, vehicle_filters)
        end

        if table_size(global.teleported_players) > 0 then
            script.on_event(defines.events.on_tick, events.on_tick)
            script.on_event(defines.events.on_player_died, events.on_player_died)
            script.on_event(defines.events.on_player_cursor_stack_changed, events.on_cursor_stack_changed)
            script.on_event(defines.events.on_player_driving_changed_state, events.on_player_driving_changed_state)
        else
            script.on_event(defines.events.on_tick, nil)
            script.on_event(defines.events.on_player_died, nil)
            script.on_event(defines.events.on_player_cursor_stack_changed, nil)
            script.on_event(defines.events.on_player_driving_changed_state, nil)
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

local function teleport_player(player, text, text2)
    if not settings.global["unminable_vehicles_teleport_players"].value then return end
    local position = player.surface.find_non_colliding_position("character", global.teleport_location, 10, 0.2)
    if not position then
        position = player.force.get_spawn_position(player.surface)
        global.teleport_location = position or global.teleport_location
    end
    local force_print= player.force.print
    if not position then
        force_print("No valid position to teleport to found.")
    else

    end
    local result = player.teleport(position)
    if text then
        force_print(text)
    end
    if result then
        if text then
            force_print("Somehow they got teleported to spawn.")
        end
    else
        force_print("Couldn't teleport " .. player.name)
    end
    if table_size(game.connected_players) == 1 then
        global.teleported_players = {}
    else
        if text2 then
            force_print(text2)
        end
        global.teleported_players[player.index] = player.position
    end
    conditional_events()
end

events.on_player_mined_entity = function(event)
    local _, err = pcall(function()
        local player = game.get_player(event.player_index)
        if player.vehicle and player.vehicle.valid then
            player.driving = false
        end
        replace_mining_results(event)
        teleport_player(
            player,
            player.name .. " mined a vehicle!",
            "The vehicle makes " .. player.name .. " so heavy that they can't move. Lets put them out of this misery"
        )
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

events.on_player_rotated_entity = function(event)
    local _, err = pcall(function()
        if rotatable_types[event.entity.type] then
            local player = game.get_player(event.player_index)
            teleport_player(
                player,
                {"", player.name, " rotated a ", event.entity.localised_name, "!"},
                "For mysterious reasons they can't move. Lets put them out of this misery"
            )
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

events.on_built_entity = function(event)
    event.created_entity.minable = false
end

events.script_raised_built = function(event)
    event.entity.minable = false
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
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

events.on_tick = function(_)
    local _, err = pcall(function()
        if table_size(global.teleported_players) > 0 then
            for index, position in pairs(global.teleported_players) do
                local player = game.get_player(index)
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
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

events.on_cursor_stack_changed = function(event)
    local _, err = pcall(function()
        if table_size(global.teleported_players) > 0 and global.teleported_players[event.player_index] then
            local player = game.get_player(event.player_index)
            if player.cursor_stack.valid_for_read then
                player.print("You can't build while waiting for punishment.")
                player.clear_cursor()
            end
        else
            conditional_events()
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

events.on_player_driving_changed_state = function(event)
    local _, err = pcall(function()
        local player = game.get_player(event.player_index)
        if global.teleported_players[player.index] and player.vehicle and player.vehicle.valid then
            player.vehicle.passenger = nil
            teleport_player(player, "Oh come on " .. player.name .. ", trying to get into a vehicle while waiting for punishment? Don't be a chicken!")
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

local function update_vehicles(unminable)
    local _, err = pcall(function()
        for _, surface in pairs(game.surfaces) do
            for _, vehicle in pairs(surface.find_entities_filtered{type = types}) do
                vehicle.minable = unminable
            end
        end
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end

script.on_init(function()
    local _, err = pcall(function()
        init_global()
        conditional_events()
        update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end)

script.on_load(function()
    local _, err = pcall(function()
        conditional_events()
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end)

script.on_configuration_changed(function()
    local _, err = pcall(function()
        init_global()
        conditional_events()
        update_vehicles(not settings.global["unminable_vehicles_make_unminable"].value)
    end)
    if err then
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
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
        game.print("Unminable vehicles: Error occured")
        game.print(serpent.block(err))
    end
end)

local function set_teleport_location(event)
    local player = game.get_player(event.player_index)
    if player.admin then
        global.teleport_location = game.player.position
        local player_pos = player.position
        player.force.print("Set teleport location to {" .. player_pos.x .. ", " .. player_pos.y .. "}")
    else
        player.print("Need to be admin to set the teleport location")
    end
end

local function clear_teleported_players(event)
    local player = game.get_player(event.player_index)
    if player.admin or table_size(game.connected_players) == 1 then
        global.teleported_players = {}
        conditional_events()
    end
end

commands.add_command("unminable_vehicles_set_teleport", "Set the teleport location to your current position. Admin only", set_teleport_location)
commands.add_command("unminable_vehicles_enable_movement", "Reenables movement for stuck players. Admin only", clear_teleported_players)
