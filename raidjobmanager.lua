--I'm not sure if delaying end of the mission by a couple of seconds
--is even necessary...
local original = RaidJobManager.external_end_mission

function RaidJobManager:external_end_mission(restart_camp, is_failed)
	if self._current_job and not is_failed then
		if Network:is_server() and managers.challenge_cards.forced_card and managers.challenge_cards:get_active_card_status() ~= managers.challenge_cards.CARD_STATUS_FAILED then
			for i = 1,managers.challenge_cards.daily_reward,1 do
				local greed_item = World:spawn_unit(Idstring("units/vanilla/pickups/pku_loot/pku_loot_desk_golden_inkwell/pku_loot_desk_golden_inkwell"), Vector3(0, 0, 0), Rotation(0, 0, 0))
				local value = managers.greed:loot_needed_for_gold_bar()
				managers.greed:pickup_greed_item(value, greed_item)
				managers.network:session():send_to_peers("greed_item_picked_up", greed_item, value)
			end

			Global.RaidJobManager = self
			Global.restart_camp = restart_camp

			DailyRaidManager:job_finished(managers.challenge_cards.daily_seed)

			DelayedCalls:Add("delay_mission_end", 3, self._delayed_end)
			return
		end
    end

	return original(self, restart_camp, is_failed)
end

function RaidJobManager:_delayed_end()
	original(Global.RaidJobManager, Global.restart_camp, false)
end

--Not very clean way to do this
--Making it so restart doesn't remove daily card
function RaidJobManager:on_mission_restart()
	managers.greed:on_level_exited(false)
	managers.consumable_missions:on_level_exited(false)
	managers.statistics:reset_session()
	managers.lootdrop:reset_loot_value_counters()
	self:on_mission_ended()
	self:on_mission_started()
	if not managers.challenge_cards.forced_card then
		managers.challenge_cards:remove_active_challenge_card()
	end
end

--After restart card gets removed from peers, so we have to apply it again
Hooks:PostHook(RaidJobManager, "on_mission_started", "daily_raid_sync_card_on_start", function(self)
	if Network:is_server() and managers.challenge_cards.forced_card then
		managers.network:session():send_to_peers_synched("sync_active_challenge_card", managers.challenge_cards.forced_card, true, "active")
		managers.network:session():send_to_peers_synched("sync_activate_challenge_card")
	end
end)