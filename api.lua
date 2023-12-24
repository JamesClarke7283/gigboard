
function gigboard.post_gig(player_name, title, description, fee, category, gig_type)
    local max_gigs = gigboard.config.max_gigs_per_player
    local open_gigs = gigboard.get_open_gigs(player_name, gig_type)
    local balance = emeraldbank.get_emeralds(player_name) 
    
    if tonumber(fee) and tonumber(fee) > 0 and balance >= tonumber(fee) then
        if #open_gigs < max_gigs then
            local gig_data = {
                author = player_name,
                title = title,
                description = description,
                fee = fee,
                status = "open",
                category = category,
                type = gig_type,
                applicants = {},
                approved_applicants = {}
            }
            gigboard.save_gig_listing(gig_data)
            gigboard.send_notification(player_name, gig_type:sub(1,1):upper()..gig_type:sub(2).." posted successfully.")
        else
            gigboard.send_notification(player_name, "You have reached the maximum number of open gigs.")
        end
    else
        gigboard.send_notification(player_name, "Invalid fee amount or insufficient balance.")
    end
end



-- Function to retrieve open gigs posted by a player
function gigboard.get_open_gigs(player_name, gig_type)
    local all_gigs = gigboard.get_player_gigs(player_name) -- This should already be a table
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
    local gigs_string = gigboard.storage:get_string("gigboard_"..player_name.."_gigs")
    return gigs_string and gigs_string ~= "" and minetest.deserialize(gigs_string) or {}
end



-- Function to complete a job and transfer funds
function gigboard.complete_gig(gig_id, completed_by_player_name)
    local gig = gigboard.get_gig_listing(gig_id)
    if gig and gig.status == "open" then
        local is_applicant_approved = false
        for _, approved_applicant in ipairs(gig.approved_applicants or {}) do
            if approved_applicant == completed_by_player_name then
                is_applicant_approved = true
                break
            end
        end

        if not is_applicant_approved then
            gigboard.send_notification(gig.author, "The player completing the gig is not an approved applicant.")
            return false
        end

        -- Prevent self-transfer
        if gig.author == completed_by_player_name then
            gigboard.send_notification(gig.author, "Cannot transfer funds to yourself.")
            return false
        end

        -- Track completion status
        gig.completion_confirmation = gig.completion_confirmation or {}
        gig.completion_confirmation[gig.author] = gig.completion_confirmation[gig.author] or false
        gig.completion_confirmation[completed_by_player_name] = true

        -- Check if both parties have marked the gig as complete
        if gig.completion_confirmation[gig.author] and gig.completion_confirmation[completed_by_player_name] then
            gig.status = "completed"
            gigboard.save_gig_listing(gig)

            -- Transfer logic
            local author_player = minetest.get_player_by_name(gig.author)
            local completed_by_player = minetest.get_player_by_name(completed_by_player_name)

            if author_player and completed_by_player then
                local balance = emeraldbank.get_emeralds(gig.author)
                if balance >= gig.fee then
                    emeraldbank.transfer_emeralds(author_player, completed_by_player, gig.fee)
                    gigboard.send_notification(gig.author, "Payment transferred to " .. completed_by_player_name)
                else
                    gigboard.send_notification(gig.author, "Insufficient balance to complete the payment to " .. completed_by_player_name)
                    return false
                end
            else
                gigboard.send_notification(gig.author, "Error: Author or applicant player object not found.")
                return false
            end
        else
            gigboard.send_notification(gig.author, "Waiting for the other party to mark the gig as complete.")
            gigboard.save_gig_listing(gig)
            return false
        end
    else
        gigboard.send_notification(gig.author, "Gig not found or already completed.")
        return false
    end
end






-- Function to retrieve a specific job listing
function gigboard.get_gig_listing(job_id)
    -- Retrieve specific job data from storage
    return gigboard.storage:get_string("gigboard_gig_"..job_id) -- Assuming JSON format
end

-- Function for a player to apply for a gig (job or service)
function gigboard.apply_for_gig(player_name, gig_id)
    local gig = gigboard.get_gig_listing(gig_id)
    if gig then
        local is_admin = minetest.check_player_privs(player_name, {gigboard_admin=true})
        -- Allow admins to apply for their own gigs for testing purposes
        if gig.author == player_name and not is_admin then
            gigboard.send_notification(player_name, "You cannot apply for your own " .. gig.type .. ".")
            return
        end
        
        if gig.status == "open" then
            gig.applicants = gig.applicants or {}
            if not gigboard.has_applied(gig, player_name) then
                table.insert(gig.applicants, player_name)
                gigboard.save_gig_listing(gig)
                local application_type = gig.type == "job" and "Job" or "Service"
                gigboard.send_notification(player_name, "Applied for " .. application_type .. " successfully.")
            else
                gigboard.send_notification(player_name, "Already applied for this " .. gig.type .. ".")
            end
        else
            gigboard.send_notification(player_name, gig.type:sub(1,1):upper()..gig.type:sub(2) .. " is not available.")
        end
    else
        gigboard.send_notification(player_name, "Gig not found.")
    end
end


-- Function for admin to manage job listings
function gigboard.admin_manage_gig(gig_id, action, new_data)
    local gig = gigboard.get_gig_listing(gig_id)
    if not gig then
        return false, "Gig not found."
    end

    if action == "delete" then
        gigboard.delete_gig_listing(gig_id)
        return true, "Gig deleted successfully."
    elseif action == "edit" then
        for key, value in pairs(new_data) do
            gig[key] = value
        end
        gigboard.save_gig_listing(gig)
        return true, "Gig edited successfully."
    end

    return false, "Invalid action."
end

-- Function to delete a job listing
function gigboard.delete_gig_listing(gig_id)
    gigboard.storage:set_string("gigboard_gig_"..gig_id, "") -- Clear the job data
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
    local profile_string = gigboard.storage:get_string("gigboard_profile_"..player_name)
    if profile_string and profile_string ~= "" then
        local profile = minetest.deserialize(profile_string)
        -- Initialize reviews as a table if it's nil
        profile.reviews = profile.reviews or {}
        return profile
    else
        -- If no profile is found, return a default structure with an empty reviews table
        return {name = player_name, reviews = {}, gigs_completed = 0, services_offered = {}}
    end
end



-- Function to save player profile into mod storage
function gigboard.save_player_profile(player_name, profile_data)
    local key = "gigboard_profile_"..player_name
    gigboard.storage:set_string(key, minetest.serialize(profile_data))
end


-- Function to add a review
-- Function to add a review
function gigboard.add_review(reviewer_name, target_player_name, rating, comment)
    local is_admin = minetest.check_player_privs(reviewer_name, {gigboard_admin=true})
    -- Allow admins to review themselves for testing purposes
    if reviewer_name == target_player_name and not is_admin then
        gigboard.send_notification(reviewer_name, "You cannot review yourself.")
        return
    end

    local profile = gigboard.get_player_profile(target_player_name)
    table.insert(profile.reviews, {
        reviewer = reviewer_name,
        rating = rating,
        comment = comment,
        timestamp = os.time()
    })
    gigboard.save_player_profile(target_player_name, profile)
    gigboard.send_notification(reviewer_name, "Review added.")
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

-- Function to handle application actions
function gigboard.handle_application_action(player_name, gig_id, action)
    local gig = gigboard.get_gig_listing(gig_id)
    if not gig then
        gigboard.send_notification(player_name, "Gig not found.")
        return
    end

    if action == "approve" then
        gig.approved_applicant = player_name
        gigboard.send_notification(player_name, "You have approved the application for: " .. gig.title)
    elseif action == "deny" then
        gig.approved_applicant = nil -- Assuming you have a field to track approval
        gigboard.send_notification(player_name, "You have denied the application for: " .. gig.title)
    elseif action == "confirm" then
        gig.status = "completed"
        gigboard.complete_gig_with_transfer(gig_id) -- This function will need to be implemented as well
    end

    gigboard.save_gig_listing(gig)
end



-- Function to handle job application form submission
function gigboard.handle_job_application_form(player_name, form_name, fields)
    if form_name:find("gigboard:apply_job_") and fields.apply then
        local job_id = form_name:match("gigboard:apply_job_(%d+)")
        gigboard.apply_for_job(player_name, tonumber(job_id))
        gigboard.send_notification(player_name, "Application submitted.")
    end
end

-- Function to transfer funds between players
function gigboard.transfer_funds(source_player, target_player, amount)
    local balance = emeraldbank.get_emeralds(source_player) -- You'll need to implement this function
    if balance >= amount then
        emeraldbank.transfer_emeralds(source_player, target_player, amount) -- And this one too
        gigboard.send_notification(source_player, "Payment of " .. amount .. " emeralds transferred to " .. target_player)
        gigboard.send_notification(target_player, "Received payment of " .. amount .. " emeralds from " .. source_player)
    else
        gigboard.send_notification(source_player, "Insufficient balance to complete the payment.")
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

function gigboard.approve_applicant(gig_id, applicant_name)
    local gig = gigboard.get_gig_listing(gig_id)
    if gig and gig.status == "open" then
        gig.approved_applicants = gig.approved_applicants or {}
        if not gigboard.has_approved(gig, applicant_name) then
            table.insert(gig.approved_applicants, applicant_name)
            gigboard.save_gig_listing(gig)
            local application_type = gig.type == "job" and "Job" or "Service"
            gigboard.send_notification(applicant_name, "Approved for " .. application_type .. ": " .. gig.title)
        else
            gigboard.send_notification(applicant_name, "Applicant already approved.")
        end
    else
        gigboard.send_notification(applicant_name, "Gig is not available or already taken.")
    end
end


-- Helper function to check if an applicant has already been approved for a gig
function gigboard.has_approved(gig, applicant_name)
    for _, approved in ipairs(gig.approved_applicants or {}) do
        if approved == applicant_name then
            return true
        end
    end
    return false
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
    local job_count = gigboard.storage:get_int("gigboard_gig_count") or 0
    local filtered_jobs = {}
    for i = 1, job_count do
        local job_data_string = gigboard.storage:get_string("gigboard_gig_"..i)
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
    local all_gigs = gigboard.get_gig_listings()

    for _, gig in ipairs(all_gigs) do
        if gig.status == "open" and not categories[gig.category] then
            categories[gig.category] = true
            table.insert(unique_categories, gig.category)
        end
    end

    return unique_categories
end

-- Function to initialize a default profile for new players
function gigboard.create_default_profile(player_name)
    local default_profile = {
        name = player_name,
        reviews = {},
        gigs_completed = 0,
        services_offered = {}
    }
    gigboard.save_player_profile(player_name, default_profile)
end

function gigboard.handle_application_details(player_name, gig_id, fields)
    local gig = gigboard.get_gig_listing(gig_id)
    if not gig then
        gigboard.send_notification(player_name, "Gig not found.")
        return
    end
    local applicant_to_approve = nil
    -- Check for approval actions
    for field_name, _ in pairs(fields) do
        if field_name:find("approve_") then
            applicant_to_approve = field_name:match("approve_(.+)")
            if gig.status == "open" and not gigboard.has_approved(gig, applicant_to_approve) then
                gig.approved_applicants = gig.approved_applicants or {}
                table.insert(gig.approved_applicants, applicant_to_approve)
                gigboard.save_gig_listing(gig)
                gigboard.send_notification(player_name, applicant_to_approve .. " has been approved for the gig.")
                gigboard.send_notification(applicant_to_approve, "You have been approved for the gig: " .. gig.title)
            else
                gigboard.send_notification(player_name, "Applicant already approved or gig is not open for approvals.")
            end
            return
        end
    end
    elseif fields.complete then
        if applicant_to_approve then
            gigboard.complete_gig(gig_id, applicant_to_approve)
    end

    gigboard.save_gig_listing(gig)
end

