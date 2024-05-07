local text_original = LocalizationManager.text
function LocalizationManager:text(string_id_in, macros, ...)
	if managers.challenge_cards and managers.challenge_cards.forced_card and string_id_in == "dialog_mp_restart_mission_host_message" then
		string_id_in = "dialog_mp_restart_mission_no_card_host_message"
	end
	return text_original(self, string_id_in, macros, ...)
end
