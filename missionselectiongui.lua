--Daily Bounty icon
DB:create_entry("texture", "ui/atlas/raid_bounty", ModPath .. "assets/bounty.dds")

MissionSelectionGui.EFFECT_DESCRIPTION_MARGIN = 20

--We add daily to the list of raids by intercepting real list
--and adding daily to it
local original_raid_list_data_source = MissionSelectionGui._raid_list_data_source

function MissionSelectionGui:_raid_list_data_source()
	--Intercepting the list
	local raid_list = original_raid_list_data_source(self)

	if Global.game_settings.single_player then
		return raid_list
	end

	if not DailyRaidManager:can_do_new_daily() then
		if managers.progression:mission_progression_completed() then
			self:_layout_daily_timer()
		end
		return raid_list
	end

	local seed, daily_mission_name, daily_forced_card, reward = DailyRaidManager:generate_daily()

	local item_text = self:translate(tweak_data.operations:mission_data(daily_mission_name).name_id)

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
	self._card_panel = self._right_panel:panel(card_panel_params)

	local width = 197
	local height = 267
	local card_y = self._right_panel:h() - height
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
		text = "CARD NAME PLACEHOLDER",
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
		text = "POSITIVE EFFECT PLACEHOLDER",
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
		text = "NEGATIVE EFFECT PLACEHOLDER",
		x = desc_x,
		font = tweak_data.gui.fonts.lato,
		font_size = 16,
		color = tweak_data.gui.colors.raid_grey
	})
end)

--Creates a raid description
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
	self._daily_description = self._primary_paper_panel:text(daily_description_params)

	self._daily_description:set_visible(false)
end)

--Animating daily description
local _animate_change_primary_paper_control_original = MissionSelectionGui._animate_change_primary_paper_control
function MissionSelectionGui:_animate_change_primary_paper_control(control, mid_callback, new_active_control, ...)
	-- always start own fade out animation first (async)
	self._daily_description:stop()
	self._daily_description:animate(callback(self, self, "_animate_daily_description_fade_out"))

	-- post hook mid_callback
	local mid_callback_post_hook = function(...)
		mid_callback(...)

		-- start own fade in, only if description page of daily is selected
		if self._daily and new_active_control == self._mission_description then -- must be after/post the mid_callback
			self._daily_description:stop()
			self._daily_description:animate(callback(self, self, "_animate_daily_description_fade_in"))
		end
	end

	-- start original animation (sync)
	_animate_change_primary_paper_control_original(self, control, mid_callback_post_hook, new_active_control, ...)
end

function MissionSelectionGui:_animate_daily_description_fade_out(daily_description)
	local fade_out_duration = 0.2
	local t = nil

	if daily_description:visible() and daily_description:alpha() > 0 then
		t = (1 - daily_description:alpha()) * fade_out_duration
	else
		t = 0
	end

	while fade_out_duration > t do
		local dt = coroutine.yield()
		t = t + dt
		daily_description:set_alpha(Easing.cubic_in_out(t, 1, -1, fade_out_duration))
	end
	daily_description:set_alpha(0)
	daily_description:set_visible(false)
end

function MissionSelectionGui:_animate_daily_description_fade_in(daily_description)
	local fade_in_duration = 0.2
	local t = nil

	local _, _, _, h = self._mission_description:text_rect() -- must also be after the mid_callback
	daily_description:set_y(self._mission_description:y() + h + 16)
	daily_description:set_visible(true)

	t = daily_description:alpha() * fade_in_duration
	while fade_in_duration > t do
		local dt = coroutine.yield()
		t = t + dt
		daily_description:set_alpha(Easing.cubic_in_out(t, 0, 1, fade_in_duration))
	end
	daily_description:set_alpha(1)
end

--Fixes an issue where operation is labeled as a daily raid
Hooks:PostHook(MissionSelectionGui, "_select_operations_tab", "daily_raid_select_operations_tab", function(self)
	self._daily = nil
	if not Global.game_settings.single_player then
		self._card_panel:animate(callback(self, self, "_animate_hide_card"))
	end
end)

local _on_raid_clicked_original = MissionSelectionGui._on_raid_clicked
function MissionSelectionGui:_on_raid_clicked(raid_data, ...)
	if not raid_data.daily then -- non-daily is selected now
		if self._daily then -- reset daily selection
			self._daily = nil
			self._selected_job_id = nil -- forces original func to recognize as changed, if same raid (normal/nondaily) is selected 
		end
		_on_raid_clicked_original(self, raid_data, ...)
		self:_check_difficulty_warning() -- hide warning, in case daily was selected before, and warning was shown
		if self._card_panel then
			self._card_panel:animate(callback(self, self, "_animate_hide_card")) --Hide card
		end
		-- Showing event if one is active
		if self._event_display then
			self._event_display:set_visible(true)
		end

		return
	elseif raid_data.daily == self._daily then -- same daily is selected
		return -- do nothing
	end

	--- daily newly selected ---

	--Saving daily data
	self._daily = raid_data.daily

	-- FIXME?
	-- everything below here (in this func)
	-- is mostly a clone of the original func
	-- might need update if game update adds smth
	-- current state fits: U21.6

	self._operation_tutorialization_panel:get_engine_panel():stop()
	self._operation_tutorialization_panel:get_engine_panel():animate(callback(self, self, "_animate_hide_operation_tutorialization"))

	self._selected_job_id = raid_data.value
	self._selected_new_operation_index = nil

	if Network:is_server() then
		self._start_disabled_message:set_visible(false)
		self._raid_start_button:set_visible(true)
	end

	--Disabling difficulties lower than allowed
	local difficulties = { false, false, false, false }
	for i = 1, #difficulties, 1 do
		if i >= DailyRaidManager.required_difficulty then
			difficulties[i] = true
		end
	end
	self._difficulty_stepper:set_disabled_items(difficulties)
	--If stepper is too low, setting it to lowest allowed difficulty
	local difficulty = tweak_data:difficulty_to_index(self._difficulty_stepper:get_value())
	if difficulty < DailyRaidManager.required_difficulty then
		self._difficulty_stepper:set_value_and_render("difficulty_" .. DailyRaidManager.required_difficulty, true)
	end
	self:_check_difficulty_warning()

	local raid_tweak_data = tweak_data.operations.missions[raid_data.value]

	self._primary_paper_mission_icon:set_image(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture)
	self._primary_paper_mission_icon:set_texture_rect(unpack(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture_rect))
	self._primary_paper_mission_icon:set_w(tweak_data.gui:icon_w(raid_tweak_data.icon_menu))
	self._primary_paper_mission_icon:set_h(tweak_data.gui:icon_h(raid_tweak_data.icon_menu))
	self._primary_paper_title:set_text(self:translate(raid_tweak_data.name_id, true))

	self._primary_paper_subtitle:set_visible(true)
	self._primary_paper_subtitle:set_text(self:translate("daily_daily_bounty", true))
	self._primary_paper_difficulty_indicator:set_visible(false)

	--Showing card
	self._card_panel:animate(callback(self, self, "_animate_show_card"))

	local card_data = tweak_data.challenge_cards:get_card_by_key_name(raid_data.daily.challenge_card)
	local bonus_description, malus_description = managers.challenge_cards:get_card_description(raid_data.daily.challenge_card)

	self._card_details:set_card(raid_data.daily.challenge_card)
	self._card_name_label_right:set_text(self:translate(card_data.name))
	self._bonus_effect_label:set_text(bonus_description)
	self._malus_effect_label:set_text(malus_description)

	--Effect text can be very long and we should be prepared for that
	local _, _, _, h = self._bonus_effect_label:text_rect()
	self._bonus_effect_label:set_h(h)
	self._bonus_effect_icon:set_y(self._bonus_effect_label:y() + self._bonus_effect_label:h() / 2 - self._bonus_effect_icon:h() / 2)

	_, _, _, h = self._malus_effect_label:text_rect()
	self._malus_effect_label:set_h(h)
	if (self._bonus_effect_label:h() > self._bonus_effect_icon:h()) then
		self._malus_effect_label:set_y(self._bonus_effect_label:y() + self._bonus_effect_label:h() + MissionSelectionGui.EFFECT_DESCRIPTION_MARGIN)
	else
		self._malus_effect_label:set_y(self._bonus_effect_icon:y() + self._bonus_effect_icon:h() + MissionSelectionGui.EFFECT_DESCRIPTION_MARGIN)
	end
	self._malus_effect_icon:set_y(self._malus_effect_label:y() + self._malus_effect_label:h() / 2 - self._malus_effect_icon:h() / 2)

	local stamp_texture = tweak_data.gui.icons[MissionSelectionGui.PAPER_STAMP_ICON]

	self._soe_emblem:set_image(stamp_texture.texture)
	self._soe_emblem:set_texture_rect(unpack(stamp_texture.texture_rect))
	self._info_button:set_active(true)
	self._intel_button:set_active(false)
	self._audio_button:set_active(false)
	self._info_button:enable()
	self._intel_button:enable()
	self._audio_button:show()
	self._audio_button:enable()

	self:_update_information_buttons(true, true, not raid_tweak_data.consumable)

	self:_on_info_clicked(nil, true)
	self._intel_image_grid:clear_selection()
	self:_stop_mission_briefing_audio()

	local short_audio_briefing_id = raid_tweak_data.short_audio_briefing_id

	if short_audio_briefing_id then
		managers.queued_tasks:queue("play_short_audio_briefing", self.play_short_audio_briefing, self,
			short_audio_briefing_id, 1, nil)
	end
end

--Displays warning when selecting locked difficulty
Hooks:PostHook(MissionSelectionGui, "_check_difficulty_warning", "daily_raid_check_difficulty_warning", function(self)
	if not self._daily then
		return
	end

	if tweak_data:difficulty_to_index(self._difficulty_stepper:get_value()) < DailyRaidManager.required_difficulty then
		local message = managers.localization:text("daily_daily_bounty_difficulty", {
			NEEDED_DIFFICULTY = managers.localization:text("menu_difficulty_" ..
				tostring(DailyRaidManager.required_difficulty))
		})

		--Hiding card display if message appears, or else all the buttons will be on top of it
		self._card_panel:animate(callback(self, self, "_animate_hide_card"))
		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(
			callback(self, self, "_animate_slide_in_difficulty_warning_message"), message)
		self._raid_start_button:disable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_set_difficulty_warning_message"), message)

		self:_bind_locked_raid_controller_inputs()
	else
		--Showing card again, in case it was hidden
		self._card_panel:animate(callback(self, self, "_animate_show_card"))
		if self._event_display then
			self._event_display:set_visible(false)
		end

		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self,
			"_animate_slide_out_difficulty_warning_message"))
		self._raid_start_button:enable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_hide_difficulty_warning_message"))

		self:_bind_raid_controller_inputs()
	end
end)

Hooks:PostHook(MissionSelectionGui, "_start_job", "daily_raid_start_job", function(self, job_id)
	if Network:is_server() and self._daily then
		--Saving all the stuff for daily cards
		DailyRaidManager.forced_card = self._daily.challenge_card
		DailyRaidManager.daily_reward = self._daily.reward
		DailyRaidManager.daily_seed = self._daily.seed
		local card_data = tweak_data.challenge_cards:get_card_by_key_name(DailyRaidManager.forced_card)

		DailyRaidManager:send_message("chat_message_daily_started", {
			GOLD_BARS = DailyRaidManager.daily_reward,
			CARD_NAME = managers.localization:text(card_data.name),
			POSITIVE_EFFECT = managers.localization:text(card_data.positive_description.desc_id, card_data.positive_description.desc_params),
			NEGATIVE_EFFECT = managers.localization:text(card_data.negative_description.desc_id, card_data.negative_description.desc_params)
		})

		card_data.status = ChallengeCardsManager.CARD_STATUS_NORMAL
		card_data.locked_suggestion = true

		managers.challenge_cards:set_active_card(card_data)
	else
		DailyRaidManager:remove_daily()
	end
end)

function MissionSelectionGui:_layout_daily_timer()
	local progression_timer_panel_params = {
		halign = "right",
		name = "progression_timer_panel",
		h = 64,
		valign = "top"
	}
	self._progression_timer_panel = self._root_panel:panel(progression_timer_panel_params)
	local progression_timer_icon_params = {
		name = "progression_timer_icon",
		valign = "center",
		halign = "left",
		texture = "ui/atlas/raid_bounty",
		texture_rect = {
			0,
			0,
			56,
			56
		},
		color = tweak_data.gui.colors.raid_dirty_white
	}
	local progression_timer_icon = self._progression_timer_panel:bitmap(progression_timer_icon_params)

	progression_timer_icon:set_center_y(self._progression_timer_panel:h() / 2)

	local timer_title_params = {
		name = "progression_timer_title",
		vertical = "center",
		h = 32,
		halign = "left",
		x = 64,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		color = tweak_data.gui.colors.raid_dirty_white,
		text = self:translate("daily_time_until_next", false)
	}
	local timer_title = self._progression_timer_panel:text(timer_title_params)

	local timer_params = {
		name = "timer",
		vertical = "top",
		x = 64,
		h = 32,
		text = "00:00:00",
		horizontal = "left",
		halign = "left",
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		color = tweak_data.gui.colors.raid_dirty_white
	}
	self._daily_timer = self._progression_timer_panel:text(timer_params)

	self._daily_timer:set_bottom(self._progression_timer_panel:h())

	local _, _, daily_w, _ = self._daily_timer:text_rect()

	self:_update_daily_timer()

	local _, _, w, _ = timer_title:text_rect()

	timer_title:set_w(w)

	self._progression_timer_panel:set_w(timer_title:w() + 32 + daily_w)
	self._progression_timer_panel:set_right(self._root_panel:w())
end

function MissionSelectionGui:_update_daily_timer(finish)
	local text
	if not finish then
		local remaining_time = math.floor(DailyRaidManager:time_until_next())
		local hours = math.floor(remaining_time / 3600)
		remaining_time = remaining_time - hours * 3600
		local minutes = math.floor(remaining_time / 60)
		remaining_time = remaining_time - minutes * 60
		local seconds = math.floor(remaining_time)
		text = hours > 0 and string.format("%02d", hours) .. ":" or ""
		text = text .. string.format("%02d", minutes) .. ":" .. string.format("%02d", seconds)
	else
		text = self:translate("daily_time_done", false)
	end
	self._daily_timer:set_text(text)
	local _, _, w, _ = self._daily_timer:text_rect()

	self._daily_timer:set_w(w)
end

Hooks:PostHook(MissionSelectionGui, "update", "daily_raid_time_until_next_daily", function(self, t, dt)
	if managers.progression:mission_progression_completed() and self._progression_timer_panel then
		if not DailyRaidManager:can_do_new_daily() then
			self:_update_daily_timer()
		else
			self:_update_daily_timer(true)
		end
	end
end)
