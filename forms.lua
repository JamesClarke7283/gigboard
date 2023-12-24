-- Function to show the form for posting a new gig with better layout and a submit button
function gigboard.show_post_gig_formspec(player_name)
    local categories = gigboard.get_all_categories()
    local categories_list = ""
    for category, _ in pairs(categories) do
        categories_list = categories_list == "" and category or categories_list .. "," .. category
    end
    local gig_types = "job,service"

    local formspec = {
        "formspec_version[4]",
        "size[8,10]",  -- Increased height for better spacing
        "label[0.5,0.5;Post a New Gig]",
        "field[0.5,2;7.5,1;title;Title;]",
        "textarea[0.5,3.5;7.5,2;description;Description;]",
        "field[0.5,6;7.5,1;fee;Fee (Emeralds);]",
        "dropdown[0.5,7;7.5,1;category;" .. categories_list .. ";1]",
        "dropdown[0.5,8;7.5,1;gig_type;" .. gig_types .. ";1]",
        "button[2.5,9;3,1;post_gig;Submit]",  -- Changed 'Post Gig' to 'Submit'
        "button[5.5,9;2,1;back;Back]"
    }
    minetest.show_formspec(player_name, "gigboard:post_gig", table.concat(formspec, ""))
end


-- Function to show the main Gigboard formspec with a personal profile view option
-- Adjust the main menu to include an option to add categories
-- Function to show the main Gigboard formspec
function gigboard.show_main_menu(player_name)
    local formspec = table.concat({
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;Welcome to Gigboard]",
        "button[0.3,1.5;7.4,0.8;view_gigs;View Gigs]",
        "button[0.3,2.7;7.4,0.8;post_gig;Post Gig]",
        "button[0.3,3.9;7.4,0.8;applications;View Applications]",
        "button[0.3,5.1;7.4,0.8;view_profiles;View Profiles]",
        "button[0.3,6.3;7.4,0.8;view_my_profile;View My Profile]",
        "button_exit[3,7.5;2,1;close;Close]"
    }, "")
    minetest.show_formspec(player_name, "gigboard:main", formspec)
end

-- Function to show the Applications menu formspec
function gigboard.show_applications_formspec(player_name)
    local applications = gigboard.get_player_applications(player_name) -- You'll need to implement this function
    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;Your Applications]",
        "textlist[0.3,1;7.4,7;applications_list;"
    }

    local list_items = {}
    for _, app in ipairs(applications) do
        table.insert(list_items, minetest.formspec_escape(app.gig.title .. " - " .. app.status))
    end

    formspec[#formspec + 1] = table.concat(list_items, ",")
    formspec[#formspec + 1] = ";1;false]"
    formspec[#formspec + 1] = "button[0.3,8.5;7.4,0.8;back;Back]"

    minetest.show_formspec(player_name, "gigboard:applications", table.concat(formspec))
end




-- Function to show job listings or service listings based on the type
function gigboard.show_gig_listings_formspec(player_name)
    local gigs = gigboard.get_gig_listings()
    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;Listings]",
        "textlist[0.3,1;7.4,7;gig_list;"
    }

    local list_items = {}
    for _, gig in ipairs(gigs) do
        -- Include the category in the listing
        table.insert(list_items, minetest.formspec_escape(gig.title .. " by " .. gig.author .. " - " .. gig.type .. " - " .. gig.category))
    end

    formspec[#formspec + 1] = table.concat(list_items, ",")
    formspec[#formspec + 1] = ";1;false]"
    formspec[#formspec + 1] = "button[0.3,8.5;2,1;back;Back]"

    minetest.show_formspec(player_name, "gigboard:listings", table.concat(formspec))
end





-- Function to show a player's profile with reviews and add review form
function gigboard.show_player_profile(player_name, target_player_name)
    local profile = gigboard.get_player_profile(target_player_name)
    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;", minetest.formspec_escape(target_player_name), "'s Profile]",
        "label[0.3,1;Reviews:]"
    }
    local y = 1.5
    for _, review in ipairs(profile.reviews) do
        formspec[#formspec+1] = "label[0.5,".. y .. ";" .. minetest.formspec_escape(review.reviewer) .. ": " .. review.rating .. " stars - " .. minetest.formspec_escape(review.comment) .. "]"
        y = y + 0.5
    end
    if player_name ~= target_player_name then
        formspec[#formspec+1] = "button[0.3,".. y .. ";4,1;add_review;Add Review]"
    end
    formspec[#formspec+1] = "button[3.5,".. y+0.5 ..";2,1;back;Back]"
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
        "button[3.5,3.5;2,1;cancel;Cancel]"
    }
    minetest.show_formspec(player_name, "gigboard:add_review_" .. target_player_name, table.concat(formspec, ""))
end


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


-- Function to show all profiles
function gigboard.show_profiles_formspec(player_name)
    local all_profiles = gigboard.get_all_profiles()
    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.3,0.5;All Profiles]",
    }
    local y = 1
    for _, profile in ipairs(all_profiles) do
        formspec[#formspec+1] = "button[0.3,".. y ..";7.4,0.8;profile_".. profile.name ..";" .. minetest.formspec_escape(profile.name) .. "]"
        y = y + 0.8
    end
    -- Add a back button at the bottom of the formspec
    formspec[#formspec+1] = "button[0.3,8.5;7.4,0.8;back;Back]"
    minetest.show_formspec(player_name, "gigboard:view_profiles", table.concat(formspec, ""))
end


-- Function to show the form for adding a new category
function gigboard.show_add_category_formspec(player_name)
    local formspec = {
        "formspec_version[4]",
        "size[8,5]",
        "label[0.5,0.5;Add a New Category]",
        "field[0.5,1.5;7.5,1;category_name;Category Name;]",
        "button[2.5,3;3,1;add_category;Add Category]",
        "button[5.5,3;2,1;back;Back]"
    }
    minetest.show_formspec(player_name, "gigboard:add_category", table.concat(formspec, ""))
end


-- Function to handle the new category submission
function gigboard.handle_add_category_submission(player_name, fields)
    if fields.add_category and fields.category_name and fields.category_name ~= "" then
        if gigboard.add_category(fields.category_name) then
            minetest.chat_send_player(player_name, "New category added: " .. fields.category_name)
        else
            minetest.chat_send_player(player_name, "Category already exists.")
        end
    end
end

-- Function to show gig details with Edit and Delete options for authors and admins
-- Function to show gig details with Edit and Delete options for authors and admins
function gigboard.show_gig_details(player_name, gig)
    local player_has_admin_priv = minetest.check_player_privs(player_name, {gigboard_admin=true})
    local is_author = player_name == gig.author

    local formspec = {
        "formspec_version[3]",
        "size[8,9]",
        "label[0.5,0.5;", minetest.formspec_escape("Title: " .. gig.title), "]",
        "label[0.5,1;", minetest.formspec_escape("Author: " .. gig.author), "]",
        "label[0.5,1.5;", minetest.formspec_escape("Type: " .. gig.type), "]",
        "label[0.5,2;", minetest.formspec_escape("Category: " .. gig.category), "]", -- Display the category
        "textarea[0.5,2.5;7.5,3;description;;", minetest.formspec_escape(gig.description), "]",
        "label[0.5,6;", minetest.formspec_escape("Fee: " .. gig.fee), "]"
    }

    local apply_button_label = gig.type == "job" and "Apply for Job" or "Request Service"

    -- Add 'Apply' button only if the player is not the author and the gig is open
    if not is_author and gig.status == "open" then
        table.insert(formspec, "button[0.5,7;3,1;apply;".. apply_button_label .."]")
    end

    table.insert(formspec, "button[5,7;3,1;back;Back]")

    -- Add Edit and Delete buttons for authors and admins
    if is_author or player_has_admin_priv then
        table.insert(formspec, "button[0.5,8;3,1;edit_gig;Edit]")
        table.insert(formspec, "button[3.5,8;3,1;delete_gig;Delete]")
    end

    minetest.show_formspec(player_name, "gigboard:gig_details_" .. gig.id , table.concat(formspec))
end



-- Function to show the form for editing an existing gig
function gigboard.show_edit_gig_form(player_name, gig)
    local categories = gigboard.get_all_categories()
    local categories_list = ""
    local current_category_index = 1  -- Default to the first category in the list
    local index = 1  -- Initialize index to iterate over categories

    -- Build the categories list string and find the current category index
    for category, _ in pairs(categories) do
        categories_list = categories_list == "" and category or categories_list .. "," .. category
        if category == gig.category then
            current_category_index = index  -- Set the index to the gig's current category
        end
        index = index + 1  -- Increment index
    end

    -- Make sure to construct the formspec correctly
    local formspec = {
        "formspec_version[4]",
        "size[8,10]",
        "label[0.5,0.5;Edit Gig]",
        "field[0.5,2;7.5,1;title;Title;", minetest.formspec_escape(gig.title), "]",
        "textarea[0.5,3.5;7.5,2;description;Description;", minetest.formspec_escape(gig.description), "]",
        "field[0.5,6;7.5,1;fee;Fee (Emeralds);", tostring(gig.fee), "]",
        "dropdown[0.5,7;7.5,1;category;", categories_list, ";", tostring(current_category_index), "]",  -- Ensure index is a string
        "button[2.5,9;3,1;submit_edit;Submit Changes]",
        "button[5.5,9;2,1;btn_cancel_edit;Cancel]"
    }

    -- Display the formspec to the player
    minetest.show_formspec(player_name, "gigboard:edit_gig_" .. gig.id, table.concat(formspec, ""))
end




