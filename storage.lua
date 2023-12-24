
-- Function to save or update a gig listing
function gigboard.save_gig_listing(gig_data)
    if gig_data.id then
        -- Update existing gig
        gigboard.storage:set_string("gigboard_gig_"..gig_data.id, minetest.serialize(gig_data))
        minetest.log("action", "[GIGBOARD] Updated gig: " .. minetest.serialize(gig_data))
    else
        -- Save new gig
        local gig_count = gigboard.storage:get_int("gigboard_gig_count") or 0
        local new_gig_id = gig_count + 1
        gigboard.storage:set_int("gigboard_gig_count", new_gig_id)

        -- Set gig ID
        gig_data.id = new_gig_id

        -- Save the new gig data
        gigboard.storage:set_string("gigboard_gig_"..new_gig_id, minetest.serialize(gig_data))

        -- Update player's gig list
        local player_gigs = minetest.deserialize(gigboard.storage:get_string("gigboard_"..gig_data.author.."_gigs")) or {}
        table.insert(player_gigs, new_gig_id)
        gigboard.storage:set_string("gigboard_"..gig_data.author.."_gigs", minetest.serialize(player_gigs))
        minetest.log("action", "[GIGBOARD] Saved new gig: " .. minetest.serialize(gig_data))
    end
end



-- Function to retrieve all gig listings
function gigboard.get_gig_listings()
    local gig_count = gigboard.storage:get_int("gigboard_gig_count") or 0
    local gig_list = {}
    for i = 1, gig_count do
        local gig_data_string = gigboard.storage:get_string("gigboard_gig_"..i)
        if gig_data_string ~= "" then
            local gig = minetest.deserialize(gig_data_string)
            if gig then
                table.insert(gig_list, gig)
            end
        end
    end
    -- Debug print
    minetest.log("action","Retrieved gig list: " .. minetest.serialize(gig_list))
    return gig_list
end



-- Function to retrieve a specific job listing
function gigboard.get_gig_listing(gig_id)
    local gig_data_string = gigboard.storage:get_string("gigboard_gig_"..gig_id)
    if gig_data_string and gig_data_string ~= "" then
        return minetest.deserialize(gig_data_string)
    end
    return nil
end

-- Function to delete a job listing
function gigboard.delete_gig_listing(gig_id)
    gigboard.storage:set_string("gigboard_gig_"..gig_id, "") -- Clear the gig data
    local gig = gigboard.get_gig_listing(gig_id)
    if gig then
        local player_gigs = gigboard.get_player_gigs(gig.author) or {}
        for i, id in ipairs(player_gigs) do
            if id == gig_id then
                table.remove(player_gigs, i)
                break
            end
        end
        gigboard.storage:set_string("gigboard_"..gig.author.."_gigs", minetest.serialize(player_gigs))
    end
end

-- Function to retrieve all player profiles from mod storage
function gigboard.get_all_profiles()
    -- Assume each profile is stored in mod storage with a key "profile_<playername>"
    local profiles = {}
    local storage_keys = gigboard.storage:to_table().fields -- This gets all keys in the storage
    for key, _ in pairs(storage_keys) do
        if key:find("^gigboard_profile_") then
            local profile_data = gigboard.storage:get_string(key)
            if profile_data and profile_data ~= "" then
                local profile = minetest.deserialize(profile_data)
                table.insert(profiles, profile)
            end
        end
    end
    return profiles
end


-- Function to add a new category to the gigboard
function gigboard.add_category(category_name)
    local categories = gigboard.get_all_categories() or {}
    if not categories[category_name] then
        categories[category_name] = true
        gigboard.storage:set_string("gigboard_categories", minetest.serialize(categories))
        return true
    end
    return false
end

-- Function to retrieve all categories
function gigboard.get_all_categories()
    local categories_string = gigboard.storage:get_string("gigboard_categories")
    if categories_string and categories_string ~= "" then
        return minetest.deserialize(categories_string)
    end
    return {}
end

-- Function to get applications related to a player - either gigs they've applied to, or gigs they've posted that have applicants
function gigboard.get_player_applications(player_name)
    -- Retrieve all gigs from the storage
    local all_gigs = gigboard.get_gig_listings()
    -- This will store the application info relevant to the player
    local player_applications = {}

    -- Check if the player is an admin
    local is_admin = minetest.check_player_privs(player_name, {gigboard_admin=true})

    -- Iterate over each gig to check for applications
    for _, gig in ipairs(all_gigs) do
        if is_admin or gig.author == player_name then
            -- If the player is the author or an admin, add all the applicants of this gig
            if gig.applicants then
                for _, applicant in ipairs(gig.applicants) do
                    table.insert(player_applications, {
                        gig_id = gig.id,
                        gig_title = gig.title,
                        applicant = applicant,
                        status = (gig.approved_applicant == applicant) and "approved" or "applied"
                    })
                end
            end
        elseif not is_admin then
            -- If the player is not the author and not an admin, check if they have applied for this gig
            for _, applicant in ipairs(gig.applicants or {}) do
                if applicant == player_name then
                    table.insert(player_applications, {
                        gig_id = gig.id,
                        gig_title = gig.title,
                        status = (gig.approved_applicant == player_name) and "approved" or "applied"
                    })
                    break
                end
            end
        end
    end

    -- Return the list of applications related to the player
    return player_applications
end

