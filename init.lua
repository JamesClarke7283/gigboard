
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

-- Register clear_gigboard command
minetest.register_chatcommand("clear_gigboard", {
    description = "Clears all gigboard data",
    privs = {gigboard_admin=true},
    func = function(player_name)
        if gigboard.clear_all_data() then
            return true, "All gigboard data has been cleared."
        else
            return false, "Failed to clear gigboard data."
        end
    end,
})


-- Register /gigboard command
minetest.register_chatcommand("gigboard", {
    description = "Open the Gigboard interface",
    func = function(name)
        gigboard.show_main_menu(name)
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

    if fields.back or fields.btn_back_to_main then
        -- Use a single Back button handler and check formname to decide where to go back
        if formname == "gigboard:post_gig" or formname == "gigboard:add_category" or
           formname == "gigboard:edit_gig" or formname == "gigboard:view_profiles" or
           formname:find("gigboard:player_profile_") or formname == "gigboard:listings" or formname == "gigboard:applications" or formname:find("gigboard:application_details_") then
            gigboard.show_main_menu(player_name)
        elseif formname:find("gigboard:gig_details_") then
            gigboard.show_gig_listings_formspec(player_name)
        end
        return true
    end

    -- Back navigation logic for the "Edit Gig" formspec
    if fields.btn_cancel_edit then
        gigboard.show_gig_listings_formspec(player_name)
        return true
    end

    -- Submission handling for the "Edit Gig" formspec
    if formname:find("gigboard:edit_gig_") and fields.btn_submit_changes then
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
        return true
    end

    if formname == "gigboard:main" then
        if fields.btn_view_applications then
            gigboard.show_applications_formspec(player_name)
        elseif fields.view_gigs then
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
        -- Validate fields
        local fee = tonumber(fields.fee)
        local title = fields.title
        local description = fields.description
        local category = fields.category
        local gig_type = fields.gig_type

        if not title or title == "" or not description or description == "" then
            gigboard.send_notification(player_name, "Title and description cannot be empty.")
            return
        end

        if not fee or fee <= 0 then
            gigboard.send_notification(player_name, "Invalid fee amount.")
            return
        end

        -- Call gigboard.post_gig with validated values
        gigboard.post_gig(player_name, title, description, fee, category, gig_type)
        gigboard.show_main_menu(player_name)
    elseif formname == "gigboard:add_category" then
        gigboard.handle_add_category_submission(player_name, fields)
        gigboard.show_main_menu(player_name)
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
        local is_admin = minetest.check_player_privs(player_name, {gigboard_admin=true})
    
        if fields.apply then
            -- Allow admins to apply for their own gigs for testing purposes
            if gig and gig.status == "open" and (is_admin or gig.author ~= player_name) then
                gigboard.apply_for_gig(player_name, gig_id)
            else
                gigboard.send_notification(player_name, "Cannot apply for this gig.")
            end
        elseif fields.edit_gig then
            -- Allow admins to edit their own gigs for testing purposes
            if gig and (is_admin or player_name == gig.author) then
                gigboard.show_edit_gig_form(player_name, gig)
            else
                gigboard.send_notification(player_name, "You do not have permission to edit this gig.")
            end
        elseif fields.delete_gig then
            -- Allow admins to delete their own gigs for testing purposes
            if gig and (is_admin or player_name == gig.author) then
                gigboard.delete_gig_listing(gig_id)
                gigboard.send_notification(player_name, "Gig deleted successfully.")
                gigboard.show_gig_listings_formspec(player_name)
            else
                gigboard.send_notification(player_name, "You do not have permission to delete this gig.")
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
    elseif formname == "gigboard:applications" then
            if fields.applications_list then
                local event = minetest.explode_textlist_event(fields.applications_list)
                if event.type == "CHG" then
                    local selected_application = gigboard.get_player_applications(player_name)[event.index]
                    if selected_application then
                        -- Add a function to show detailed application with approve/complete buttons
                        gigboard.show_application_details_formspec(player_name, selected_application.gig_id)
                    else
                        gigboard.send_notification(player_name, "Application not found.")
                    end
                end
            elseif fields.approve or fields.complete then
                -- Call the function to handle approval and completion actions
                local gig_id = formname:match("gigboard:application_details_(%d+)")
                gigboard.handle_application_details(player_name, tonumber(gig_id), fields)
            end
    -- Inside minetest.register_on_player_receive_fields
    elseif formname:find("gigboard:application_details_") then
    local gig_id = formname:match("gigboard:application_details_(%d+)")
    gig_id = tonumber(gig_id)

    if fields.approve then
        -- Handle the approval of the application
        gigboard.handle_application_details(player_name, gig_id, fields)
        gigboard.send_notification(player_name, "Application approved.")
        gigboard.show_gig_listings_formspec(player_name)
    elseif fields.complete then
        -- Handle the completion of the gig
        gigboard.handle_application_details(player_name, gig_id, fields)
        gigboard.send_notification(player_name, "Gig completed.")
        gigboard.show_gig_listings_formspec(player_name)
    end

    return true  -- Important to return true to indicate that the fields have been handled
end

end)  -- This ends the function



-- Register callback for when a player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    -- Check if profile already exists
    if not gigboard.get_player_profile(player_name) then
        gigboard.create_default_profile(player_name)
    end
end)
