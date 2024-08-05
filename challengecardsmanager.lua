Hooks:PostHook(ChallengeCardsManager, "deactivate_active_challenge_card", "daily_raid_on_card_failed", function(self)
    if Network:is_server() and self.forced_card then
        DailyRaidManager:send_message("chat_message_card_failed")
    end
end)

--Game won't allow to activate challenge card again unless status is normal
function ChallengeCardsManager:set_active_card_status_normal()
    self._active_card.status = ChallengeCardsManager.CARD_STATUS_NORMAL
end

-- By BangL <3
-- fixes "attempt to index local 'remove_suggested_card' (a nil value)" crash
local sync_remove_suggested_card_from_peer_original = ChallengeCardsManager.sync_remove_suggested_card_from_peer
function ChallengeCardsManager:sync_remove_suggested_card_from_peer(peer_id, ...)
    if self._suggested_cards and self._suggested_cards[peer_id] then
        sync_remove_suggested_card_from_peer_original(self, peer_id, ...)
    end
end
