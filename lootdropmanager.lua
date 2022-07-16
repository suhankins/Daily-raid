function LootDropManager:give_loot_to_player(loot_value, use_reroll_drop_tables, forced_loot_group)
	self._loot_value = loot_value
	local need_reroll = false
	local drop = nil

	if managers.challenge_cards.forced_card and not self._cards_already_rejected then
		drop = {
			reward_type = LootDropTweakData.REWARD_GOLD_BARS,
			gold_bars_min = managers.challenge_cards.reward,
			gold_bars_max = managers.challenge_cards.reward
		}
	elseif game_state_machine._current_state._current_job_data and game_state_machine._current_state._current_job_data.consumable then
		drop = self:produce_consumable_mission_drop()
	else
		drop = self:produce_loot_drop(self._loot_value, use_reroll_drop_tables, forced_loot_group)
	end

	self._dropped_loot = drop

	Application:trace("[LootDropManager:give_loot_to_player]        loot drop 1: ", inspect(self._dropped_loot))

	if drop.reward_type == LootDropTweakData.REWARD_CARD_PACK then
		if not self._cards_already_rejected and not managers.raid_menu:is_offline_mode() then
			managers.network.account:inventory_reward(drop.pack_type, callback(self, self, "card_drop_callback"))

			self._card_drop_pack_type = drop.pack_type

			managers.network.account:inventory_load()

			return
		end

		Application:trace(" **** REROLLING CARDS **** ")
		self:give_loot_to_player(self._loot_value, false)

		return
	elseif drop.reward_type == LootDropTweakData.REWARD_XP then
		self:_give_xp_to_player(drop)
	elseif drop.reward_type == LootDropTweakData.REWARD_CUSTOMIZATION then
		local result = self:_give_character_customization_to_player(drop)
		need_reroll = not result
	elseif drop.reward_type == LootDropTweakData.REWARD_WEAPON_POINT then
		self:_give_weapon_point_to_player(drop)
	elseif drop.reward_type == LootDropTweakData.REWARD_MELEE_WEAPON then
		local result = self:_give_melee_weapon_to_player(drop)
		need_reroll = not result
	elseif drop.reward_type == LootDropTweakData.REWARD_GOLD_BARS then
		self:_give_gold_bars_to_player(drop)
	elseif drop.reward_type == LootDropTweakData.REWARD_HALLOWEEN_2017 then
		local result = self:_give_halloween_2017_weapon_to_player(drop)
		need_reroll = not result
	end

	if need_reroll then
		Application:trace(" **** REROLLING **** ")
		self:give_loot_to_player(self._loot_value, true)

		return
	end

	Application:trace("[LootDropManager:give_loot_to_player]        loot drop 2: ", inspect(self._dropped_loot))
	self:on_loot_dropped_for_player()
end