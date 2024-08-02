Hooks:PostHook(GreedManager, "register_greed_item", "daily_raid_register_greed_item", function(self, unit, tweak_table, world_id)
    if DailyRaidManager then
        DailyRaidManager.greed_item = unit:name()
    end
end)
