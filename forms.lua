-- Function to show the form for posting a new gig
function gigboard.show_post_gig_formspec(player_name)
    local categories = table.concat(gigboard.get_unique_categories(), ",")
    local gig_types = "Job,Service" -- Added gig types

    local formspec = {
        "formspec_version[4]",
        "size[8,9]",
        "label[0.5,0.5;Post a New Gig]",
        "field[0.5,1.5;7.5,1;title;Title;]",
        "textarea[0.5,2.5;7.5,3;description;Description;]",
        "field[0.5,6;7.5,1;fee;Fee (Emeralds);]",
        "dropdown[0.5,7;7.5,1;category;"..categories..";1]",
        "dropdown[0.5,8;7.5,1;gig_type;"..gig_types..";1]", -- Dropdown for gig types
        "button[2.5,9;3,1;post_gig;Post Gig]",
        "button_exit[5.5,9;2,1;cancel;Cancel]"
    }
    minetest.show_formspec(player_name, "gigboard:post_gig", table.concat(formspec, ""))
end


-- Function to show the main Gigboard formspec with a personal profile view option
function gigboard.show_main_formspec(player_name)
    local formspec = table.concat({
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;Welcome to Gigboard]",
        "button[0.3,1.5;7.4,0.8;view_gigs;View Gigs]",
        "button[0.3,2.7;7.4,0.8;post_gig;Post Gig]",
        "button[0.3,3.9;7.4,0.8;view_profiles;View Profiles]",
        "button[0.3,5.1;7.4,0.8;view_my_profile;View My Profile]",
        "button_exit[3,8;2,1;close;Close]"
    }, "")
    minetest.show_formspec(player_name, "gigboard:main", formspec)
end



-- Function to show job listings or service listings based on the type
function gigboard.show_gig_listings_formspec(player_name, gig_type)
    local gigs = gigboard.get_gig_listings(gig_type)
    local formspec = "formspec_version[3]size[8,9]label[0.3,0.5;"..gig_type.." Listings]"

    local y = 1
    for _, gig in ipairs(gigs) do
        formspec = formspec .. "button[0.3,".. y ..";7.4,0.8;gig_".. gig.id ..";" .. minetest.formspec_escape(gig.title) .. "]"
        y = y + 1
    end

    minetest.show_formspec(player_name, "gigboard:"..gig_type.."_listings", formspec)
end



-- Function to show a player's profile with reviews and add review form
function gigboard.show_player_profile(player_name, target_player_name)
    local profile = gigboard.get_player_profile(target_player_name)
    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;".. minetest.formspec_escape(target_player_name) .."'s Profile]",
        "label[0.3,1;Reviews:]"
    }
    local y = 1.5
    for _, review in ipairs(profile.reviews) do
        formspec[#formspec+1] = "label[0.5,".. y .. ";" .. minetest.formspec_escape(review.reviewer) .. ": " .. review.rating .. " stars - " .. minetest.formspec_escape(review.comment) .. "]"
        y = y + 0.5
    end
    formspec[#formspec+1] = "button[0.3,".. y .. ";4,1;add_review;Add Review]"
    minetest.show_formspec(player_name, "gigboard:player_profile_" .. target_player_name, table.concat(formspec, ""))
end

-- Callback function for receiving fields in formspecs
function gigboard.on_receive_fields(player_name, form_name, fields)
    if form_name:find("gigboard:player_profile_") and fields.add_review then
        local target_player_name = form_name:sub(25)
        gigboard.show_add_review_form(player_name, target_player_name)
    end
end

-- Function to show the form for adding a review
function gigboard.show_add_review_form(player_name, target_player_name)
    -- Formspec for adding a review
    local formspec = {
        "formspec_version[4]",
        "size[6,4]",
        "label[0.5,0.5;Add Review]",
        "field[0.5,1.5;5.5,1;rating;Rating (1-5);]",
        "textarea[0.5,2.5;5.5,1;comment;Comment;]",
        "button[0.5,3.5;2,1;submit_review;Submit]",
        "button_exit[3.5,3.5;2,1;cancel;Cancel]"
    }
    minetest.show_formspec(player_name, "gigboard:add_review_" .. target_player_name, table.concat(formspec, ""))
end

minetest.register_on_player_receive_fields(gigboard.on_receive_fields)


-- Function to show job application form
function gigboard.show_job_application_form(player_name, job_id)
    local formspec = {
        "formspec_version[4]",
        "size[6,4]",
        "label[0.5,0.5;Apply for Job]",
        "button[0.5,3;2,1;apply_job;Apply]",
        "button_exit[3.5,3;2,1;cancel;Cancel]"
    }
    minetest.show_formspec(player_name, "gigboard:apply_job_" .. job_id, table.concat(formspec, ""))
end

-- Function to show form for approving a job applicant
function gigboard.show_approve_applicant_form(player_name, job_id)
    local job = gigboard.get_job_listing(job_id)
    if job and job.status == "open" then
        local formspec = {
            "formspec_version[4]",
            "size[6,4]",
            "label[0.5,0.5;Approve Applicant for Job: " .. minetest.formspec_escape(job.title) .. "]"
        }

        local y = 1.5
        for _, applicant in ipairs(job.applicants or {}) do
            formspec[#formspec + 1] = "button[0.5,".. y .. ";5,1;approve_" .. applicant .. ";" .. minetest.formspec_escape(applicant) .. "]"
            y = y + 1
        end

        minetest.show_formspec(player_name, "gigboard:approve_applicant_" .. job_id, table.concat(formspec, ""))
    end
end

-- Function to handle form submissions for job approval
function gigboard.handle_approve_applicant_form(player_name, form_name, fields)
    for key, _ in pairs(fields) do
        if key:find("approve_") then
            local applicant_name = key:match("approve_(%w+)")
            local job_id = form_name:match("gigboard:approve_applicant_(%d+)")
            gigboard.approve_applicant(tonumber(job_id), applicant_name)
            gigboard.send_notification(player_name, "Applicant " .. applicant_name .. " approved.")
            break
        end
    end
end

minetest.register_on_player_receive_fields(function(player, form_name, fields)
    gigboard.handle_approve_applicant_form(player:get_player_name(), form_name, fields)
end)



-- Placeholder function to get player profile
function gigboard.get_player_profile(player_name)
    -- Retrieve player profile data
    -- Placeholder code
    return {}
end

-- Function to show job cancellation form
function gigboard.show_cancel_job_form(player_name, job_id)
    local formspec = {
        "formspec_version[4]",
        "size[6,4]",
        "label[0.5,0.5;Cancel Job]",
        "button[0.5,3;2,1;cancel_job;Cancel Job]",
        "button_exit[3.5,3;2,1;exit;Exit]"
    }
    minetest.show_formspec(player_name, "gigboard:cancel_job_" .. job_id, table.concat(formspec, ""))
end

-- Function to show applicants for a job
function gigboard.show_applicants_form(player_name, job_id)
    local applicants = gigboard.get_applicant_details(job_id)
    local formspec = {"formspec_version[4]", "size[8,9]", "label[0.3,0.5;Applicants for Job ID: " .. job_id .. "]"}

    local y = 1
    for _, applicant in ipairs(applicants) do
        formspec[#formspec + 1] = "button[0.3,".. y ..";7,1;view_" .. applicant.name .. ";" .. minetest.formspec_escape(applicant.name) .. "]"
        y = y + 1
    end

    minetest.show_formspec(player_name, "gigboard:show_applicants_" .. job_id, table.concat(formspec, ""))
end

-- Function to show form for updating job status
function gigboard.show_update_job_status_form(player_name, job_id)
    local formspec = {
        "formspec_version[4]",
        "size[6,4]",
        "label[0.5,0.5;Update Job Status]",
        "dropdown[0.5,1.5;5,1;status;open,completed,cancelled;".. job.status .."]",
        "button[0.5,3;2,1;update_status;Update]",
        "button_exit[3.5,3;2,1;exit;Exit]"
    }
    minetest.show_formspec(player_name, "gigboard:update_status_" .. job_id, table.concat(formspec, ""))
end


