--Sending a message when someone joins mid raid
--gets called by HostNetworkSession:do_dropin_spawn, when peer spawned in
Hooks:PostHook(PlayerManager, "update_carry_to_peer", "daily_raid_dropin_message", function(self, peer)
	if managers.challenge_cards.forced_card then
		DelayedCalls:Add("daily_raid_chat_message_drop_in", 1, function()
			DailyRaidManager:send_message("chat_message_drop_in", {
				GOLD_BARS = managers.challenge_cards.daily_reward
			})
		end)
	end
end)
