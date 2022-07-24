--Daily Bounty icon
DB:create_entry("texture", "ui/atlas/raid_bounty", ModPath .. "assets/bounty.dds")

MissionSelectionGui.EFFECT_DESCRIPTION_MARGIN = 20

--We add daily to the list of raids by intercepting real list
--and adding daily to it
local original_raid_list_data_source = MissionSelectionGui._raid_list_data_source

function MissionSelectionGui:_raid_list_data_source()
	--Intercepting the list
	local raid_list = original_raid_list_data_source(self)

	if Global.game_settings.single_player or not DailyRaidManager:can_do_new_daily() then
		return raid_list
	end

	local seed, daily_mission_name, mission_data, daily_forced_card, reward = DailyRaidManager:generate_daily()

	local item_text = self:translate(mission_data.name_id)
	local item_icon_name = mission_data.icon_menu
	local item_icon = {
		texture = "ui/atlas/raid_bounty",
		texture_rect = {
			0,
			0,
			56,
			56
		}
	}
	
	table.insert(raid_list, 1, {
		text = managers.localization:text("daily_daily_bounty") .. ": " .. item_text,
		value = daily_mission_name,
		icon = item_icon,
		color = tweak_data.gui.colors.raid_white,
		selected_color = tweak_data.gui.colors.raid_red,
		unlocked = true,
		daily = {
			challenge_card = daily_forced_card,
			reward = reward,
			seed = seed
		}
	})

	return raid_list
end

function MissionSelectionGui:_animate_hide_card()
	local duration = 0.25
	local t = self._card_animation_t * duration

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local setting_alpha = Easing.cubic_in_out(t, 1, -1, duration)

		self._card_panel:set_alpha(setting_alpha)

		self._card_animation_t = t / duration
	end

	self._card_panel:set_alpha(0)
	self._card_panel:set_visible(false)

	self._card_animation_t = 1
end

function MissionSelectionGui:_animate_show_card()
	local duration = 0.25
	local t = (1 - self._card_animation_t) * duration

	self._card_panel:set_visible(true)

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local setting_alpha = Easing.cubic_in_out(t, 0, 1, duration)

		self._card_panel:set_alpha(setting_alpha)

		self._card_animation_t = 1 - t / duration
	end

	self._card_panel:set_alpha(1)

	self._card_animation_t = 0
end

--Creates a card display
Hooks:PostHook(MissionSelectionGui, "_layout_settings", "daily_raid_layout_settings", function(self)
	--Card display crashes the game in single player
	if Global.game_settings.single_player then
		return
	end
	self._card_animation_t = 1
	local card_panel_params = {
		name = "card_panel"
	}
	self._card_panel = self._settings_panel:panel(card_panel_params)

	local width = 197
	local height = 267
	local card_y = 350
	local card_details_params = {
		name = "card_details",
		visible = true,
		x = 0,
		y = card_y,
		w = width,
		h = height,
		card_x = 0,
		card_y = 0,
		card_w = width,
		card_h = height
	}
	self._card_details = self._card_panel:create_custom_control(RaidGUIControlCardDetails, card_details_params)

	local text_info_pos = width + 25

	--Text "FORCED DAILY CARD"
	local params_card_title_right = {
		name = "card_title_label_right",
		h = 72,
		wrap = true,
		w = 255,
		align = "left",
		vertical = "left",
		text = managers.localization:text("daily_forced_challenge_card"),
		y = card_y,
		x = text_info_pos,
		color = tweak_data.gui.colors.raid_red,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = 26
	}
	self._card_title_label_right = self._card_panel:label(params_card_title_right)

	--Card name
	local params_card_name_right = {
		name = "card_name_label_right",
		h = 72,
		wrap = true,
		w = 255,
		align = "left",
		vertical = "left",
		text = "DON'T YOU DIE ON ME",
		y = card_y + 30,
		x = text_info_pos,
		color = tweak_data.gui.colors.white,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = 26
	}
	self._card_name_label_right = self._card_panel:label(params_card_name_right)

	local bonus_y = card_y + 80

	local desc_x = text_info_pos + 65

	--Positive effect display
	self._bonus_effect_label = self._card_panel:label({
		w = 190,
		name = "bonus_effect_label",
		h = 72,
		wrap = true,
		align = "left",
		vertical = "center",
		text = "Your mother is gay",
		x = desc_x,
		y = bonus_y,
		font = tweak_data.gui.fonts.lato,
		font_size = 16,
		color = tweak_data.gui.colors.raid_grey
	})
	--Y Coordiantes for the rest of the things don't actually matter in any way
	--They will be set later
	self._bonus_effect_icon = self._card_panel:image({
		name = "bonus_effect_icon",
		h = 64,
		w = 64,
		visible = true,
		x = text_info_pos,
		texture = tweak_data.gui.icons.ico_bonus.texture,
		texture_rect = tweak_data.gui.icons.ico_bonus.texture_rect
	})
	
	--Negative effect display
	self._malus_effect_icon = self._card_panel:image({
		name = "malus_effect_icon",
		h = 64,
		w = 64,
		visible = true,
		x = text_info_pos,
		texture = tweak_data.gui.icons.ico_malus.texture,
		texture_rect = tweak_data.gui.icons.ico_malus.texture_rect
	})
	self._malus_effect_label = self._card_panel:label({
		w = 190,
		name = "malus_effect_label",
		h = 72,
		wrap = true,
		align = "left",
		vertical = "center",
		text = "So are you",
		x = desc_x,
		font = tweak_data.gui.fonts.lato,
		font_size = 16,
		color = tweak_data.gui.colors.raid_grey
	})
end)

--Creates a card display
Hooks:PostHook(MissionSelectionGui, "_layout_raid_description", "daily_raid_layout_description", function(self)
	local daily_description_params = {
		w = 432,
		name = "daily_descripton",
		h = 528,
		wrap = true,
		text = self:translate("paper_daily_explanation"),
		y = 136,
		x = 38,
		font = tweak_data.gui.fonts.lato,
		font_size = tweak_data.gui.font_sizes.paragraph,
		color = tweak_data.gui.colors.raid_dark_red,
		layer = self._primary_paper_panel:layer() + 1
	}
	self._daily_description = self._primary_paper_panel:label(daily_description_params)

	self._daily_description:set_visible(false)
end)

--Animating daily description
function MissionSelectionGui:_animate_change_primary_paper_control(control, mid_callback, new_active_control)
	local fade_out_duration = 0.2
	local t = nil

	if self._active_primary_paper_control then
		t = (1 - self._active_primary_paper_control:alpha()) * fade_out_duration
	else
		t = 0
	end

	while fade_out_duration > t do
		local dt = coroutine.yield()
		t = t + dt
		local alpha = Easing.cubic_in_out(t, 1, -1, fade_out_duration)

		self._active_primary_paper_control:set_alpha(alpha)
		self._daily_description:set_alpha(alpha)
	end

	self._active_primary_paper_control:set_alpha(0)
	self._daily_description:set_alpha(0)
	self._active_primary_paper_control:set_visible(false)
	self._daily_description:set_visible(false)

	--Mid callback is ALWAYS set_text
	if mid_callback then
		mid_callback()
	end

	local _, _, w, h = self._mission_description:text_rect()
	self._daily_description:set_y(self._mission_description:y() + h + 16)
	if self._daily then
		self._daily_description:set_visible(true)
	end

	self._active_primary_paper_control = new_active_control

	self._active_primary_paper_control:set_visible(true)
	if self.daily then
		self._daily_description:set_visible(true)
	end

	local fade_in_duration = 0.25
	t = self._active_primary_paper_control:alpha() * fade_out_duration

	while fade_in_duration > t do
		local dt = coroutine.yield()
		t = t + dt
		local alpha = Easing.cubic_in_out(t, 0, 1, fade_in_duration)

		self._active_primary_paper_control:set_alpha(alpha)
		self._daily_description:set_alpha(alpha)
	end

	self._active_primary_paper_control:set_alpha(1)
	self._daily_description:set_alpha(1)
end


--This isn't the cleanest way to do it, but so be it
function MissionSelectionGui:_on_raid_clicked(raid_data)
	--If we clicked the same thing, no reason to change anything
	if raid_data.daily ~= self._daily or self._selected_job_id ~= raid_data.value then
		self:_stop_mission_briefing_audio()
	else
		return
	end

	--Saving daily data
	self._daily = raid_data.daily

	local difficulty_available = managers.progression:get_mission_progression(tweak_data.operations.missions[raid_data.value].job_type, raid_data.value)

	if difficulty_available and difficulty_available < tweak_data:difficulty_to_index(self._difficulty_stepper:get_value()) then
		self._difficulty_stepper:set_value_and_render(tweak_data:index_to_difficulty(difficulty_available), true)
		self:_check_difficulty_warning()
	end

	self._operation_tutorialization_panel:get_engine_panel():stop()
	self._operation_tutorialization_panel:get_engine_panel():animate(callback(self, self, "_animate_hide_operation_tutorialization"))

	self._selected_job_id = raid_data.value
	self._selected_new_operation_index = nil

	local job_tweak_data = tweak_data.operations.missions[self._selected_job_id]

	--This line is very long, but it boils down to
	--"If mission is not unlock but needs to be unlocked to be played, display locked screen"
	if not managers.progression:mission_unlocked(job_tweak_data.job_type, self._selected_job_id) and not job_tweak_data.consumable and not job_tweak_data.debug and not raid_data.daily then
		if Network:is_server() then
			self._start_disabled_message:set_text(self:translate("raid_locked_progression", true))
			self._start_disabled_message:set_visible(true)
			self._raid_start_button:set_visible(false)
		end

		self:_on_locked_raid_clicked()
	else
		if Network:is_server() then
			self._start_disabled_message:set_visible(false)
			self._raid_start_button:set_visible(true)
		end

		local difficulty_available, difficulty_completed = 0, 0
		if not raid_data.daily then
			difficulty_available, difficulty_completed = managers.progression:get_mission_progression(OperationsTweakData.JOB_TYPE_RAID, self._selected_job_id)

			self:set_difficulty_stepper_data(difficulty_available, difficulty_completed)
		else
			--Dailies have forced difficulty
			self._difficulty_stepper:set_disabled_items({false, false, true, false})
			self._difficulty_stepper:set_value_and_render("difficulty_3", true)
			self:_check_difficulty_warning()
		end

		local raid_tweak_data = tweak_data.operations.missions[raid_data.value]

		self._primary_paper_mission_icon:set_image(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture)
		self._primary_paper_mission_icon:set_texture_rect(unpack(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture_rect))
		self._primary_paper_mission_icon:set_w(tweak_data.gui:icon_w(raid_tweak_data.icon_menu))
		self._primary_paper_mission_icon:set_h(tweak_data.gui:icon_h(raid_tweak_data.icon_menu))
		self._primary_paper_title:set_text(self:translate(raid_tweak_data.name_id, true))

		if job_tweak_data.consumable then
			self._primary_paper_subtitle:set_visible(true)
			self._primary_paper_subtitle:set_text(self:translate("menu_mission_selected_mission_type_consumable", true))
			self._primary_paper_difficulty_indicator:set_visible(false)
		elseif raid_data.daily then
			self._primary_paper_subtitle:set_visible(true)
			self._primary_paper_subtitle:set_text(self:translate("daily_daily_bounty", true))
			self._primary_paper_difficulty_indicator:set_visible(false)
		elseif difficulty_available and difficulty_completed then
			self._primary_paper_subtitle:set_visible(false)
			self._primary_paper_difficulty_indicator:set_visible(true)
			self._primary_paper_difficulty_indicator:set_progress(difficulty_available, difficulty_completed)
		end

		if raid_data.daily then
			--Showing card
			self._card_panel:animate(callback(self, self, "_animate_show_card"))

			local card_data = tweak_data.challenge_cards:get_card_by_key_name(raid_data.daily.challenge_card)
			local bonus_description, malus_description = managers.challenge_cards:get_card_description(raid_data.daily.challenge_card)

			self._card_details:set_card(raid_data.daily.challenge_card)
			self._card_name_label_right:set_text(self:translate(card_data.name))
			self._bonus_effect_label:set_text(bonus_description)
			self._malus_effect_label:set_text(malus_description)

			--Effect text can be very long and we should be prepared for that
			local _, _, w, h = self._bonus_effect_label:text_rect()
			self._bonus_effect_label:set_h(h)
			self._bonus_effect_icon:set_y(self._bonus_effect_label:y() + self._bonus_effect_label:h() / 2 - self._bonus_effect_icon:h() / 2)

			_, _, w, h = self._malus_effect_label:text_rect()
			self._malus_effect_label:set_h(h)
			self._malus_effect_label:set_y(self._bonus_effect_label:y() + self._bonus_effect_label:h() + MissionSelectionGui.EFFECT_DESCRIPTION_MARGIN)
			self._malus_effect_icon:set_y(self._malus_effect_label:y() + self._malus_effect_label:h() / 2 - self._malus_effect_icon:h() / 2)
		else
			--In single player we don't even create card display
			if not Global.game_settings.single_player then
				--Hide card
				self._card_panel:animate(callback(self, self, "_animate_hide_card"))
			end
		end

		local stamp_texture = tweak_data.gui.icons[MissionSelectionGui.PAPER_STAMP_ICON]

		if raid_tweak_data.consumable then
			stamp_texture = tweak_data.gui.icons[MissionSelectionGui.PAPER_STAMP_ICON_CONSUMABLE]
		end

		self._soe_emblem:set_image(stamp_texture.texture)
		self._soe_emblem:set_texture_rect(unpack(stamp_texture.texture_rect))
		self._info_button:set_active(true)
		self._intel_button:set_active(false)
		self._audio_button:set_active(false)
		self._info_button:enable()
		self._intel_button:enable()

		if raid_tweak_data.consumable then
			self._audio_button:hide()
		else
			self._audio_button:show()
			self._audio_button:enable()
		end

		self:_on_info_clicked(nil, true)
		self._intel_image_grid:clear_selection()
		self:_stop_mission_briefing_audio()

		local short_audio_briefing_id = raid_tweak_data.short_audio_briefing_id

		if short_audio_briefing_id then
			managers.queued_tasks:queue("play_short_audio_briefing", self.play_short_audio_briefing, self, short_audio_briefing_id, 1, nil)
		end
	end
end

--Again, not the cleanest way to do this stuff
--Displays warning when selecting locked difficulty
function MissionSelectionGui:_check_difficulty_warning()
	if self._selected_job_id and tweak_data.operations.missions[self._selected_job_id].consumable then
		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_out_difficulty_warning_message"))
		self._raid_start_button:enable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_hide_difficulty_warning_message"))

		return
	elseif not self._selected_job_id or (not managers.progression:mission_unlocked(tweak_data.operations.missions[self._selected_job_id].job_type, self._selected_job_id) and not self._daily) then
		return
	end

	local difficulty_available, difficulty_completed = 99, 0
	local difficulty = tweak_data:difficulty_to_index(self._difficulty_stepper:get_value())

	--Dailies don't need to known what difficulties are available
	if not self._daily then
		difficulty_available, difficulty_completed = managers.progression:get_mission_progression(tweak_data.operations.missions[self._selected_job_id].job_type, self._selected_job_id)
	end

	if (difficulty_available < difficulty) or (self._daily and difficulty ~= 3) then
		local message = ""
		if difficulty_available < difficulty then
			message = managers.localization:text("raid_difficulty_warning", {
				TARGET_DIFFICULTY = managers.localization:text("menu_difficulty_" .. tostring(difficulty)),
				NEEDED_DIFFICULTY = managers.localization:text("menu_difficulty_" .. tostring(difficulty - 1))
			})
		else
			message = managers.localization:text("daily_daily_bounty_difficulty")
		end

		--Hiding card display if message appears, or else all the buttons will be on top of it
		self._card_panel:animate(callback(self, self, "_animate_hide_card"))

		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_in_difficulty_warning_message"), message)
		self._raid_start_button:disable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_set_difficulty_warning_message"), message)

		if self._current_mission_type == "raids" then
			self:_bind_locked_raid_controller_inputs()
		elseif self._current_mission_type == "operations" and self._current_display == MissionSelectionGui.DISPLAY_SECOND then
			self:_bind_locked_operation_list_controller_inputs()
		elseif self._current_mission_type == "operations" and self._current_display == MissionSelectionGui.DISPLAY_FIRST then
			self:_bind_operation_list_controller_inputs()
		end
	else
		--Showing card again, in case it was hidden
		if (self._daily) then
			self._card_panel:animate(callback(self, self, "_animate_show_card"))
		end
		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_out_difficulty_warning_message"))
		self._raid_start_button:enable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_hide_difficulty_warning_message"))

		if self._current_mission_type == "raids" then
			self:_bind_raid_controller_inputs()
		elseif self._current_mission_type == "operations" then
			self:_bind_operation_list_controller_inputs()
		end
	end
end

Hooks:PostHook(MissionSelectionGui, "_start_job", "daily_raid_start_job", function(self, job_id)
	if Network:is_server() and self._daily then
		--Saving all the stuff for daily cards
		managers.challenge_cards.forced_card = self._daily.challenge_card
		managers.challenge_cards.daily_reward = self._daily.reward
		managers.challenge_cards.daily_seed = self._daily.seed

		DailyRaidManager:send_message("chat_message_daily_started", {
			GOLD_BARS = managers.challenge_cards.daily_reward
		})
	else
		managers.challenge_cards.forced_card = nil
		managers.challenge_cards.daily_reward = nil
		managers.challenge_cards.daily_seed = nil
	end
end)