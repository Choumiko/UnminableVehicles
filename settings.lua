local prefix = "unminable_vehicles_"
data:extend({
    {
        type = "bool-setting",
        name = prefix .. "make_unminable",
        setting_type = "runtime-global",
        default_value = false,
        order = "a"
    },
    {
        type = "double-setting",
        name = prefix .. "mine_ingredients",
        setting_type = "runtime-global",
        default_value = 0,
        minimum_value = 0,
        maximum_value = 1,
        order = "b"
    },
    {
        type = "bool-setting",
        name = prefix .. "teleport_players",
        setting_type = "runtime-global",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = prefix .. "prevent_rotation",
        setting_type = "runtime-global",
        default_value = true,
        order = "d"
    },
    {
        type = "bool-setting",
        name = prefix .. "allow_shooting",
        setting_type = "runtime-global",
        default_value = false,
        order = "e"
    },
})
