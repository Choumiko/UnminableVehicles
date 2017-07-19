local prefix = "unminable_vehicles_"
data:extend({
    {
        type = "bool-setting",
        name = prefix .. "make_unminable",
        setting_type = "runtime-global",
        default_value = false,
        order = "unminable_vehicles-a"
    },
    {
        type = "bool-setting",
        name = prefix .. "teleport_players",
        setting_type = "runtime-global",
        default_value = true,
        order = "unminable_vehicles-b"
    },
    {
        type = "bool-setting",
        name = prefix .. "prevent_rotation",
        setting_type = "runtime-global",
        default_value = true,
        order = "unminable_vehicles-c"
    },
    {
        type = "bool-setting",
        name = prefix .. "allow_shooting",
        setting_type = "runtime-global",
        default_value = false,
        order = "unminable_vehicles-d"
    },
})
