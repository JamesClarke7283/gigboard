
-- Gigboard Mod Initialization
gigboard = {}
local modpath = minetest.get_modpath("gigboard")

-- Gigboard Mod Initialization
gigboard.storage = minetest.get_mod_storage()

-- Load components
dofile(modpath.."/config.lua")
dofile(modpath.."/api.lua")
dofile(modpath.."/storage.lua")
dofile(modpath.."/forms.lua")
dofile(modpath.."/utils.lua")
-- Removed the duplicate config.lua load here

-- Register /gigboard command
minetest.register_chatcommand("gigboard", {
    description = "Open the Gigboard interface",
    func = function(name)
        gigboard.show_main_formspec(name)
    end,
})

-- Here is where we handle the form submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local player_name = player:get_player_name()

    if formname == "gigboard:main" then
        if fields.view_gigs then
            gigboard.show_gig_listings_formspec(player_name, "job")
        elseif fields.post_gig then
            gigboard.show_post_gig_formspec(player_name)
        elseif fields.view_profiles then
            gigboard.show_profiles_formspec(player_name)
        elseif fields.view_my_profile then
            gigboard.show_player_profile(player_name, player_name)
        elseif fields.add_category then
            gigboard.show_add_category_formspec(player_name)
        end
    elseif formname == "gigboard:add_category" then
        gigboard.handle_add_category_submission(player_name, fields)
    else
        -- Check if handle_forms is defined before calling it
        if gigboard.handle_forms then
            gigboard.handle_forms(player, formname, fields)
        else
            -- Handle the case where handle_forms is not defined
            -- You can log an error, do nothing, or handle it in some other way
            minetest.log("error", "gigboard.handle_forms is not defined.")
        end
    end
end)


-- Register callback for when a player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    -- Check if profile already exists
    if not gigboard.get_player_profile(player_name) then
        gigboard.create_default_profile(player_name)
    end
end)
