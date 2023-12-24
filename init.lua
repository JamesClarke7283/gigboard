
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

-- Define gigboard_admin privilege
minetest.register_privilege("gigboard_admin", {
    description = "Privilege for administrating Gigboard mod",
    give_to_singleplayer = false,
})

-- Here is where we handle the form submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local player_name = player:get_player_name()

    if formname == "gigboard:main" then
        if fields.view_gigs then
            gigboard.show_gig_listings_formspec(player_name)
        elseif fields.post_gig then
            gigboard.show_post_gig_formspec(player_name)
        elseif fields.view_profiles then
            gigboard.show_profiles_formspec(player_name)
        elseif fields.view_my_profile then
            gigboard.show_player_profile(player_name, player_name)
        elseif fields.add_category then
            gigboard.show_add_category_formspec(player_name)
        end  -- This ends the "gigboard:main" if block
    elseif formname == "gigboard:post_gig" and fields.post_gig then
        gigboard.post_gig(player_name, fields.title, fields.description, fields.fee, fields.category, fields.gig_type)
    elseif formname == "gigboard:add_category" then
        gigboard.handle_add_category_submission(player_name, fields)
    elseif formname == "gigboard:listings" then
        if fields.gig_list then
            local event = minetest.explode_textlist_event(fields.gig_list)
            if event.type == "CHG" then
                local selected_gig = gigboard.get_gig_listing(event.index)
                if selected_gig then
                    minetest.log("action", "Selected gig: " .. minetest.serialize(selected_gig))
                    gigboard.show_gig_details(player_name, selected_gig)
                else
                    minetest.log("error", "Gig not found for index: " .. tostring(event.index))
                end
            end
        end
    elseif formname:find("gigboard:gig_details_") then
        local gig_id = formname:match("gigboard:gig_details_(%d+)")
        gig_id = tonumber(gig_id)
        local gig = gigboard.get_gig_listing(gig_id)
        if gig_id and fields.apply then
            gigboard.apply_for_gig(player_name, gig_id)
        elseif fields.edit_gig then
            if gig and (player_name == gig.author or minetest.check_player_privs(player_name, {gigboard_admin=true})) then
                -- Call function to show edit form for the gig
                gigboard.show_edit_gig_form(player_name, gig)
            end
        elseif fields.delete_gig then
            if gig and (player_name == gig.author or minetest.check_player_privs(player_name, {gigboard_admin=true})) then
                -- Delete the gig
                gigboard.delete_gig_listing(gig_id)
                gigboard.send_notification(player_name, "Gig deleted successfully.")
                -- Show the updated gig listings
                gigboard.show_gig_listings_formspec(player_name)
            end
        elseif fields.back then
            gigboard.show_gig_listings_formspec(player_name)
        end
    elseif formname:find("gigboard:edit_gig_") and fields.submit_edit then
            local gig_id = formname:match("gigboard:edit_gig_(%d+)")
            local gig = gigboard.get_gig_listing(tonumber(gig_id))
            if gig and (player_name == gig.author or minetest.check_player_privs(player_name, {gigboard_admin=true})) then
                -- Update the gig with the new details provided in the fields
                gig.title = fields.title or gig.title
                gig.description = fields.description or gig.description
                gig.fee = tonumber(fields.fee) or gig.fee
                gig.category = fields.category or gig.category
                gigboard.save_gig_listing(gig)
                gigboard.send_notification(player_name, "Gig updated successfully.")
                -- Show the updated gig listings
                gigboard.show_gig_listings_formspec(player_name)
            end
    elseif formname:find("gigboard:player_profile_") and fields.add_review then
        local target_player_name = formname:match("gigboard:player_profile_(.+)")
        if target_player_name then
            gigboard.show_add_review_form(player_name, target_player_name)
        end  -- This ends the "add_review" if block
    end  -- This ends the outermost if-elseif chain
end)  -- This ends the function



-- Register callback for when a player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    -- Check if profile already exists
    if not gigboard.get_player_profile(player_name) then
        gigboard.create_default_profile(player_name)
    end
end)
