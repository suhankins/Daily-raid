--Sending a message when someone joins mid raid
--ugly way to do it, but can't come up with anything better...
function HostNetworkSession:do_dropin_spawn()
	local current_state = managers.player:current_state()

	if current_state == "freefall" or current_state == "parachuting" then
		return
	end

	for peer_id, peer in pairs(self._peers) do
		if peer.ready_for_dropin_spawn and not peer:spawn_unit_called() then
			if not managers.worldcollection:check_all_peers_synced_last_world(CoreWorldCollection.STAGE_LOAD_FINISHED) then
				Application:debug("[HostNetworkSession:do_dropin_spawn()] Waiting for all peers to load words before dropin.")

				return
			end

			Application:debug("[HostNetworkSession:do_dropin_spawn()] Trying spawn for", peer_id)

			local spawned = self:chk_spawn_member_unit(peer, peer:id())

			if spawned then
				managers.player:update_carry_to_peer(peer)

				for other_peer_id, other_peer in pairs(self._peers) do
					if other_peer_id ~= peer_id then
						other_peer:set_expecting_drop_in_pause_confirmation(peer_id, nil)
						other_peer:send_after_load("request_drop_in_pause", peer_id, "", false)
					end
				end

				if self._local_peer:is_expecting_pause_confirmation(peer:id()) then
					self._local_peer:set_expecting_drop_in_pause_confirmation(peer:id(), nil)
					self:on_drop_in_pause_request_received(peer:id(), peer:name(), false)
				end

                if managers.challenge_cards.forced_card then
                    DailyRaidManager:send_message("chat_message_drop_in", {
                        GOLD_BARS = managers.challenge_cards.daily_reward
                    })
                end
			end
		end
	end
end