--Sending a message when someone joins mid raid
Hooks:PostHook(HostNetworkSession, "do_dropin_spawn", "daily_raid_on_drop_in", function(self)
    if Network:is_server() and managers.challenge_cards.forced_card then
        DailyRaidManager:send_message("chat_message_drop_in")
    end
end)