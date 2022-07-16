Hooks:PreHook(RaidJobManager, "external_end_mission", "daily_raid_give_loot_to_others", function(self, restart_camp, is_failed)
	if self._current_job and not is_failed then
		if Network:is_server() and managers.challenge_cards.forced_card and managers.challenge_cards:get_active_card_status() ~= managers.challenge_cards.CARD_STATUS_FAILED then
			local greed_item = World:spawn_unit(Idstring("units/vanilla/pickups/pku_loot/pku_loot_desk_golden_inkwell/pku_loot_desk_golden_inkwell"), Vector3(0, 0, 0), Rotation(0, 0, 0))
			local value = tweak_data.greed.points_needed_for_gold_bar * managers.challenge_cards.daily_reward
			managers.greed:pickup_greed_item(value, greed_item)
			managers.network:session():send_to_peers("greed_item_picked_up", greed_item, value)
		end
    end
end)