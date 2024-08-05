--Removing suggest card button
Hooks:PostHook(ReadyUpGui, "_set_card_selection_controls", "daily_raid_set_card_selection_controls", function(self)
	if Network:is_server() and DailyRaidManager.forced_card then
		self._suggest_card_button:hide()
		self._suggest_card_button:disable()
	end
end)

Hooks:PostHook(ReadyUpGui, "_update_peers", "daily_raid_update_peers", function(self)

	--We have to suggest challenge card here or else the game crashes when
	--you try to start a new daily after returning to camp from previous one
	if Network:is_server() and DailyRaidManager.forced_card then
		local local_peer = managers.network:session():local_peer()
		local local_peer_control = self._player_control_list[local_peer]
		local challenge_cards = managers.challenge_cards:get_suggested_cards()
		if challenge_cards and not challenge_cards[local_peer_control:params().peer_index] then
			managers.challenge_cards:suggest_challenge_card(DailyRaidManager.forced_card)
			local card_data = tweak_data.challenge_cards:get_card_by_key_name(DailyRaidManager.forced_card)
			DailyRaidManager:send_message("chat_message_forced_challenge_card_applied", {
				CARD_NAME = managers.localization:text(card_data.name)
			})
		end

		--Force the game to skip "choose suggested card" screen
		if managers.challenge_cards:did_everyone_locked_sugested_card() then
			if not self._stinger_played then
				if managers.challenge_cards:get_suggested_cards() and managers.challenge_cards:get_suggested_cards()[1] and managers.challenge_cards:get_suggested_cards()[1].selected_sound then
					managers.menu_component:post_event(managers.challenge_cards:get_suggested_cards()[1].selected_sound)
				else
					managers.menu_component:post_event("ready_up_stinger")
				end

				self._stinger_played = true
			end

			for _, unit in pairs(self._spawned_character_units) do
				if not unit:anim_data().ready_transition_anim_finished then
					return
				end
			end

			managers.network:session():set_state("in_game")

			if not self._continuing_mission and not self._is_single_player then
				managers.challenge_cards:select_challenge_card(managers.network:session():local_peer():id())
				managers.global_state:fire_event(GlobalStateManager.EVENT_START_RAID)
			end
		end
	end
end)