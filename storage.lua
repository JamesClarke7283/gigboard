-- Function to save a gig listing with incremental IDs
function gigboard.save_gig_listing(gig_data)
    -- Retrieve the current gig count and increment it for the new ID
    local gig_count = gigboard.storage:get_int("gig_count") or 0
    local new_gig_id = gig_count + 1
    gigboard.storage:set_int("gig_count", new_gig_id)

    -- Set gig ID
    gig_data.id = new_gig_id

    -- Save the new gig data
    gigboard.storage:set_string("gig_"..new_gig_id, minetest.serialize(gig_data))

    -- Update player's gig list
    local player_gigs = minetest.deserialize(gigboard.storage:get_string(gig_data.author.."_gigs")) or {}
    table.insert(player_gigs, new_gig_id)
    gigboard.storage:set_string(gig_data.author.."_gigs", minetest.serialize(player_gigs))
end


-- Function to retrieve all gig listings of a certain type
function gigboard.get_gig_listings(gig_type)
    -- This function should be updated to only retrieve gigs of the specified type
    local gig_count = gigboard.storage:get_int("gig_count") or 0
    local gig_list = {}
    for i = 1, gig_count do
        local gig_data_string = gigboard.storage:get_string("gig_"..i)
        if gig_data_string ~= "" then
            local gig = minetest.deserialize(gig_data_string)
            if gig.type == gig_type then
                table.insert(gig_list, gig)
            end
        end
    end
    return gig_list
end

-- Function to retrieve a specific job listing
function gigboard.get_gig_listing(gig_id)
    local gig_data_string = gigboard.storage:get_string("gig_"..gig_id)
    if gig_data_string and gig_data_string ~= "" then
        return minetest.deserialize(gig_data_string)
    end
    return nil
end

-- Function to delete a job listing
function gigboard.delete_gig_listing(gig_id)
    -- Clear the job data
    gigboard.storage:set_string("gig_"..gig_id, "")
    -- Remove the job ID from the author's job list
    local gig = gigboard.get_job_listing(gig_id)
    if gig then
        local player_gigs = gigboard.get_player_jobs(job.author)
        for i, id in ipairs(player_gigs) do
            if id == gig_id then
                table.remove(player_gigs, i)
                break
            end
        end
        gigboard.storage:set_string(gig.author.."_gigs", minetest.serialize(player_gigs))
    end
end


