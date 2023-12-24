-- Reading settings from settingtypes.txt
gigboard.config = {
    max_gigs_per_player = tonumber(minetest.settings:get("max_gigs_per_player")) or 10,
}
