Hooks:PreHook(ElementMissionEnd, "on_executed", "daily_raid_give_loot_to_others", function(self, instigator)
	if self._values.enabled and self._values.state == "success" then
        if Network:is_server() and managers.challenge_cards.forced_card and managers.challenge_cards:get_active_card().status ~= managers.challenge_cards.CARD_STATUS_FAILED then
			for i = 1, managers.challenge_cards.reward, 1 do
				local greed_item = World:spawn_unit(Idstring("units/vanilla/pickups/pku_loot/pku_loot_desk_golden_inkwell/pku_loot_desk_golden_inkwell"), Vector3(0, 0, 0), Rotation(0, 0, 0))
				managers.network:session():send_to_peers("greed_item_picked_up", greed_item, tweak_data.greed.points_needed_for_gold_bar)
			end
		end
    end
end)