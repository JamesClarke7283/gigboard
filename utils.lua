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
