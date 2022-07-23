--Forcing card suggestion
Hooks:PostHook(ReadyUpGui, "_layout_buttons", "daily_raid_ready_up_init", function(self)
	if Network:is_server() and managers.challenge_cards.forced_card then
		local card_data = tweak_data.challenge_cards:get_card_by_key_name(managers.challenge_cards.forced_card)
		DailyRaidManager:send_message("chat_message_forced_challenge_card_applied", {
			CARD_NAME = managers.localization:text(card_data.name)
		})
		managers.challenge_cards:suggest_challenge_card(managers.challenge_cards.forced_card, 0)
	end
end)

--Removing suggest card button
Hooks:PostHook(ReadyUpGui, "_set_card_selection_controls", "daily_raid_set_card_selection_controls", function(self)
	if Network:is_server() and managers.challenge_cards.forced_card then
		self._suggest_card_button:hide()
		self._suggest_card_button:disable()
	end
end)

--Not the cleanest way to do this(C)
--Forces the game to skip "choose suggested card" screen
function ReadyUpGui:update(t, dt)
	self:_show_characters()
	self:_show_player_challenge_card_info()
	self:_update_challenge_card_selected_icon()
	self:_update_status()
	self:_update_controls_contining_mission()
	self:_update_peers()

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

		if Network:is_server() then
			managers.network:session():set_state("in_game")
		elseif not self._synced_document_spawn_chance_to_host then
			managers.consumable_missions:sync_document_spawn_chance()

			self._synced_document_spawn_chance_to_host = true
		end

		if self._continuing_mission then
			managers.global_state:fire_event(GlobalStateManager.EVENT_START_RAID)
		elseif self._is_single_player then
			managers.challenge_cards:select_challenge_card(self._current_peer_index)
			managers.global_state:fire_event(GlobalStateManager.EVENT_START_RAID)
		else
			local challenge_cards = managers.challenge_cards:get_suggested_cards()
			local immidiate_start = true

			for _, card in pairs(challenge_cards) do
				if card.key_name ~= ChallengeCardsManager.CARD_PASS_KEY_NAME then
					immidiate_start = false

					break
				end
			end

			--Skipping "choose suggested card" screen
			if managers.challenge_cards.forced_card then
				managers.challenge_cards:select_challenge_card(managers.network:session():local_peer():id())
				immidiate_start = true
			end

			if immidiate_start then
				managers.global_state:fire_event(GlobalStateManager.EVENT_START_RAID)
			else
				ChallengeCardsGui.PHASE = 2

				managers.raid_menu:open_menu("challenge_cards_menu")
			end
		end
	end
end