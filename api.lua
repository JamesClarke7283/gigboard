-- Function to post a new gig (job or service)
function gigboard.post_gig(player_name, title, description, fee, category, gig_type)
    -- Determine the maximum number of gigs allowed
    local max_gigs = gig_type == "job" and gigboard.config.max_jobs_per_player or gigboard.config.max_services_per_player
    local open_gigs = gigboard.get_open_gigs(player_name, gig_type)
    
    if #open_gigs < max_gigs then
        local gig_data = {
            author = player_name,
            title = title,
            description = description,
            fee = fee,
            status = "open",
            category = category,
            type = gig_type -- 'job' or 'service'
        }
        gigboard.save_gig_listing(gig_data)
        gigboard.send_notification(player_name, gig_type:sub(1,1):upper()..gig_type:sub(2).." posted successfully.")
    else
        gigboard.send_notification(player_name, "You have reached the maximum number of open "..gig_type.."s.")
    end
end

-- Function to retrieve open gigs posted by a player
function gigboard.get_open_gigs(player_name, gig_type)
    local all_gigs = gigboard.get_player_gigs(player_name, gig_type)
    local open_gigs = {}
    for _, gig_id in ipairs(all_gigs) do
        local gig = gigboard.get_gig_listing(gig_id)
        if gig and gig.status == "open" and gig.type == gig_type then
            table.insert(open_gigs, gig_id)
        end
    end
    return open_gigs
end


-- Function to retrieve jobs posted by a player
function gigboard.get_player_gigs(player_name)
    return gigboard.storage:get_string(player_name.."_gigs") -- Assuming JSON format
end

-- Function to complete a job
function gigboard.complete_gig(gig_id)
    local gig = gigboard.get_gig_listing(gig_id)
    if gig and gig.status == "open" then
        gig.status = "completed"
        gigboard.save_gig_listing(gig)
        if gig.type == "job" then
            -- Transfer funds for jobs only
            local balance = emeraldbank.get_emeralds(gig.author)
            if balance >= gig.fee then
                emeraldbank.transfer_emeralds(gig.author, gig.approved_applicant, gig.fee)
                gigboard.send_notification(gig.author, "Payment transferred to " .. gig.approved_applicant)
            else
                gigboard.send_notification(gig.author, "Insufficient balance to complete the payment.")
            end
        else
            gigboard.send_notification(gig.author, "Service marked as completed.")
        end
    else
        gigboard.send_notification(gig.author, "Gig not found or already completed.")
    end
end


-- Function to retrieve a specific job listing
function gigboard.get_gig_listing(job_id)
    -- Retrieve specific job data from storage
    return gigboard.storage:get_string("gig_"..job_id) -- Assuming JSON format
end

-- Function for a player to apply for a job
function gigboard.apply_for_job(player_name, job_id)
    local job = gigboard.get_job_listing(job_id)
    if job and job.status == "open" then
        job.applicants = job.applicants or {}
        if not gigboard.has_applied(job, player_name) then
            table.insert(job.applicants, player_name)
            gigboard.save_job_listing(job)
            gigboard.send_notification(player_name, "Applied for job successfully.")
        else
            gigboard.send_notification(player_name, "Already applied for this job.")
        end
    else
        gigboard.send_notification(player_name, "Job is not available.")
    end
end

-- Function for admin to manage job listings
function gigboard.admin_manage_job(job_id, action, new_data)
    local job = gigboard.get_job_listing(job_id)
    if not job then
        return false, "Job not found."
    end

    if action == "delete" then
        gigboard.delete_job_listing(job_id)
        return true, "Job deleted successfully."
    elseif action == "edit" then
        for key, value in pairs(new_data) do
            job[key] = value
        end
        gigboard.save_job_listing(job)
        return true, "Job edited successfully."
    end

    return false, "Invalid action."
end

-- Function to delete a job listing
function gigboard.delete_job_listing(job_id)
    gigboard.storage:set_string("gig_"..job_id, "") -- Clear the job data
end


-- Helper function to check if a player has already applied for a job
function gigboard.has_applied(job, player_name)
    for _, applicant in ipairs(job.applicants or {}) do
        if applicant == player_name then
            return true
        end
    end
    return false
end

-- Function to retrieve player profile
function gigboard.get_player_profile(player_name)
    local profile_string = gigboard.storage:get_string("profile_"..player_name)
    if profile_string and profile_string ~= "" then
        return minetest.deserialize(profile_string)
    else
        return {name = player_name, reviews = {}, jobs_completed = 0, services_offered = {}}
    end
end

-- Function to save player profile
function gigboard.save_player_profile(player_name, profile_data)
    gigboard.storage:set_string("profile_"..player_name, minetest.serialize(profile_data))
end

-- Function to add a review
function gigboard.add_review(reviewer_name, target_player_name, rating, comment)
    local profile = gigboard.get_player_profile(target_player_name)
    table.insert(profile.reviews, {
        reviewer = reviewer_name,
        rating = rating,
        comment = comment,
        timestamp = os.time()
    })
    gigboard.save_player_profile(target_player_name, profile)
end

-- Function to delete a review
function gigboard.delete_review(target_player_name, reviewer_name)
    local profile = gigboard.get_player_profile(target_player_name)
    for i, review in ipairs(profile.reviews) do
        if review.reviewer == reviewer_name then
            table.remove(profile.reviews, i)
            break
        end
    end
    gigboard.save_player_profile(target_player_name, profile)
end

-- Function to edit a review
function gigboard.edit_review(reviewer_name, target_player_name, new_rating, new_comment)
    local profile = gigboard.get_player_profile(target_player_name)
    for _, review in ipairs(profile.reviews) do
        if review.reviewer == reviewer_name then
            review.rating = new_rating
            review.comment = new_comment
            review.timestamp = os.time() -- update timestamp
            break
        end
    end
    gigboard.save_player_profile(target_player_name, profile)
end

-- Callback function when a player submits a job application form
function gigboard.on_receive_job_application_form(player_name, form_name, fields)
    if fields.apply_job then
        local job_id = string.match(form_name, "gigboard:apply_job_(%d+)")
        if job_id then
            gigboard.apply_for_job(player_name, tonumber(job_id))
        end
    end
end

minetest.register_on_player_receive_fields(gigboard.on_receive_job_application_form)

-- Function to handle job application form submission
function gigboard.handle_job_application_form(player_name, form_name, fields)
    if form_name:find("gigboard:apply_job_") and fields.apply then
        local job_id = form_name:match("gigboard:apply_job_(%d+)")
        gigboard.apply_for_job(player_name, tonumber(job_id))
        gigboard.send_notification(player_name, "Application submitted.")
    end
end

-- Function to handle review form submission
function gigboard.handle_review_form(player_name, form_name, fields)
    if form_name:find("gigboard:add_review_") and fields.submit_review then
        local target_player_name = form_name:match("gigboard:add_review_(%w+)")
        local rating = tonumber(fields.rating) or 0
        local comment = fields.comment or ""
        gigboard.add_review(player_name, target_player_name, rating, comment)
        gigboard.send_notification(player_name, "Review added.")
    end
end

minetest.register_on_player_receive_fields(function(player, form_name, fields)
    gigboard.handle_job_application_form(player:get_player_name(), form_name, fields)
    gigboard.handle_review_form(player:get_player_name(), form_name, fields)
end)

-- Function to approve an applicant for a job
function gigboard.approve_applicant(gig_id, applicant_name)
    local gig = gigboard.get_gig_listing(gig_id)
    if gig and gig.status == "open" then
        gig.approved_applicant = applicant_name
        gigboard.save_gig_listing(gig)
        gigboard.send_notification(applicant_name, "Approved for gig: " .. gig.title)
    else
        gigboard.send_notification(applicant_name, "Gig is not available or already taken.")
    end
end

-- Function to complete a job and transfer funds
function gigboard.complete_job_with_transfer(job_id)
    local job = gigboard.get_job_listing(job_id)
    if job and job.status == "open" and job.approved_applicant then
        local balance = emeraldbank.get_emeralds(job.author)
        if balance >= job.fee then
            emeraldbank.transfer_emeralds(job.author, job.approved_applicant, job.fee)
            job.status = "completed"
            gigboard.save_job_listing(job)
            gigboard.send_notification(job.author, "Job completed and payment transferred to " .. job.approved_applicant)
        else
            gigboard.send_notification(job.author, "Insufficient balance to complete the payment.")
        end
    else
        gigboard.send_notification(job.author, "Job not found, already completed, or no approved applicant.")
    end
end

-- Function to cancel a job
function gigboard.cancel_job(job_id)
    local job = gigboard.get_job_listing(job_id)
    if job and job.status == "open" then
        job.status = "cancelled"
        gigboard.save_job_listing(job)
        gigboard.send_notification(job.author, "Job cancelled successfully.")
    else
        gigboard.send_notification(job.author, "Job cannot be cancelled (not found or not open).")
    end
end

-- Function to get applicant details for a job
function gigboard.get_applicant_details(job_id)
    local job = gigboard.get_job_listing(job_id)
    local applicant_details = {}
    if job and job.applicants then
        for _, applicant_name in ipairs(job.applicants) do
            local profile = gigboard.get_player_profile(applicant_name)
            table.insert(applicant_details, {name = applicant_name, profile = profile})
        end
    end
    return applicant_details
end

-- Function to update job status
function gigboard.update_job_status(job_id, new_status)
    local job = gigboard.get_job_listing(job_id)
    if job then
        job.status = new_status
        gigboard.save_job_listing(job)
        gigboard.send_notification(job.author, "Job status updated to " .. new_status .. ".")
    else
        gigboard.send_notification(job.author, "Job not found.")
    end
end

-- Function to list jobs by category
function gigboard.list_gigs_by_category(category)
    local job_count = gigboard.storage:get_int("job_count") or 0
    local filtered_jobs = {}
    for i = 1, job_count do
        local job_data_string = gigboard.storage:get_string("gig_"..i)
        if job_data_string ~= "" then
            local job = minetest.deserialize(job_data_string)
            if job.category == category then
                table.insert(filtered_jobs, job)
            end
        end
    end
    return filtered_jobs
end

function gigboard.get_unique_categories()
    local categories = {}
    local unique_categories = {}
    local all_jobs = gigboard.get_job_listings()

    for _, job in ipairs(all_jobs) do
        if job.status == "open" and not categories[job.category] then
            categories[job.category] = true
            table.insert(unique_categories, job.category)
        end
    end

    return unique_categories
end
