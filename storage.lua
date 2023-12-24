-- Function to save a job listing with incremental IDs
function gigboard.save_gig_listing(job_data)
    -- Retrieve the current job count and increment it for the new ID
    local job_count = gigboard.storage:get_int("job_count") or 0
    local new_job_id = job_count + 1
    gigboard.storage:set_int("job_count", new_job_id)

    -- Set job ID
    job_data.id = new_job_id

    -- Save the new job data
    gigboard.storage:set_string("gig_"..new_job_id, minetest.serialize(job_data))

    -- Update player's job list
    local player_jobs = minetest.deserialize(gigboard.storage:get_string(job_data.author.."_jobs")) or {}
    table.insert(player_jobs, new_job_id)
    gigboard.storage:set_string(job_data.author.."_gigs", minetest.serialize(player_jobs))
end

-- Function to retrieve all gig listings of a certain type
function gigboard.get_gig_listings(gig_type)
    -- This function should be updated to only retrieve gigs of the specified type
    local job_count = gigboard.storage:get_int("job_count") or 0
    local gig_list = {}
    for i = 1, job_count do
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
function gigboard.get_gig_listing(job_id)
    local job_data_string = gigboard.storage:get_string("gig_"..job_id)
    if job_data_string and job_data_string ~= "" then
        return minetest.deserialize(job_data_string)
    end
    return nil
end

-- Function to delete a job listing
function gigboard.delete_gig_listing(job_id)
    -- Clear the job data
    gigboard.storage:set_string("gig_"..job_id, "")
    -- Remove the job ID from the author's job list
    local job = gigboard.get_job_listing(job_id)
    if job then
        local player_jobs = gigboard.get_player_jobs(job.author)
        for i, id in ipairs(player_jobs) do
            if id == job_id then
                table.remove(player_jobs, i)
                break
            end
        end
        gigboard.storage:set_string(job.author.."_gigs", minetest.serialize(player_jobs))
    end
end


