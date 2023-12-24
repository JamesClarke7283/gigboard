-- Reading settings from settingtypes.txt
gigboard.config = {
    max_jobs_per_player = tonumber(minetest.settings:get("max_jobs_per_player")) or 5,
    max_services_per_player = tonumber(minetest.settings:get("max_services_per_player")) or 5,
}
