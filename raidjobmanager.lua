--Awarding gold on success
Hooks:PreHook(RaidJobManager, "external_end_mission", "daily_raid_reward_gold", function(self, restart_camp, is_failed)
	if self._current_job and Network:is_server() then
		if not is_failed and DailyRaidManager.forced_card then
			if managers.challenge_cards:get_active_card_status() ~= managers.challenge_cards.CARD_STATUS_FAILED then
				-- Awarding the bounty
				managers.greed:secure_bounty(DailyRaidManager.daily_reward)
				-- Notifying everyone in the lobby
				DailyRaidManager:send_message("chat_message_daily_finished", {
					GOLD_BARS = DailyRaidManager.daily_reward
				})
				-- Resetting everything and saving completion
				DailyRaidManager:job_finished(DailyRaidManager.daily_seed)
			end
		end
	end
end)

--After restart card gets removed, so we have to apply it again
Hooks:PostHook(RaidJobManager, "on_mission_started", "daily_raid_sync_card_on_start", function(self)
	if Network:is_server() and DailyRaidManager.forced_card then
		--Card got removed after restart - need to apply it again
		if not managers.challenge_cards:get_active_card() then
			--Delay by 1 second because otherwise other players don't get the message, for some reason
			DelayedCalls:Add("reapply_forced_card", 1, function()
				local card = deep_clone(tweak_data.challenge_cards:get_card_by_key_name(DailyRaidManager.forced_card))
				card.status = ChallengeCardsManager.CARD_STATUS_NORMAL
				managers.challenge_cards:set_active_card(card)
				managers.challenge_cards:activate_challenge_card()
			end)
		end
	end
end)
