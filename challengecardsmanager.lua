Hooks:PostHook(ChallengeCardsManager, "deactivate_active_challenge_card", "daily_raid_on_card_failed", function(self)
    if Network:is_server() and self.forced_card then
        DailyRaidManager:send_message("chat_message_card_failed")
    end
end)

--Game won't allow to activate challenge card again unless status is normal
function ChallengeCardsManager:set_active_card_status_normal()
    self._active_card.status = ChallengeCardsManager.CARD_STATUS_NORMAL
end