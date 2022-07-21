function RaidMenuCallbackHandler:restart_mission(item)
	if not managers.vote:available() or managers.vote:is_restarting() then
		return
	end

	local dialog_data = {
		title = managers.localization:text("dialog_mp_restart_mission_title"),
	}
    if managers.vote:option_vote_restart() then
        dialog_data["text"] = managers.localization:text("dialog_mp_restart_level_message")
    elseif managers.challenge_cards.forced_card then
        dialog_data["text"] = managers.localization:text("dialog_mp_restart_mission_no_card_host_message")
    else
        dialog_data["text"] = managers.localization:text("dialog_mp_restart_mission_host_message")
    end
	local yes_button = {
		text = managers.localization:text("dialog_yes"),
		callback_func = function ()
			if managers.vote:option_vote_restart() then
				managers.vote:restart_mission()
			else
				managers.vote:restart_mission_auto()
			end

			managers.raid_menu:on_escape()
		end
	}
	local no_button = {
		text = managers.localization:text("dialog_no"),
		class = RaidGUIControlButtonShortSecondary,
		cancel_button = true
	}
	dialog_data.button_list = {
		yes_button,
		no_button
	}

	managers.system_menu:show(dialog_data)
end