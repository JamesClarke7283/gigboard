-- Function to calculate the average rating
function gigboard.calculate_average_rating(ratings)
    local total = 0
    for _, rating in ipairs(ratings) do
        total = total + rating
    end
    return total / #ratings
end

function gigboard.send_notification(player_name, message)
    minetest.chat_send_player(player_name, "[GIGBOARD] "..message)
end

function gigboard.clear_all_data()
    local storage_keys = gigboard.storage:get_keys()
    for _, key in ipairs(storage_keys) do
        if key:find("^gigboard_") then
            gigboard.storage:set_string(key, "")
        end
    end
    return true
end

