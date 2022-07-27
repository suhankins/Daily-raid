if not DailyRaidManager then
    DailyRaidManager = {}

    --Used for saving last finished daily
    DailyRaidManager.currentMod = CurrentMod

    --Greed item we should spawn when rewarding players
    DailyRaidManager.greed_item = nil

    --Just for convinience, so i can change it later if i wanna
    DailyRaidManager.required_difficulty = 3

    --Gold rewards for each raid and card rarity
    DailyRaidManager.rewards = {
        ["flakturm"] = 20,
        ["gold_rush"] = 20,
        ["train_yard"] = 20,
        ["radio_defense"] = 20,
        ["ger_bridge"] = 20,
        ["settlement"] = 20,
        ["bunker_test"] = 15,
        ["tnd"] = 10,
        ["hunters"] = 10,
        ["convoy"] = 15,
        ["spies_test"] = 15,
        ["silo"] = 20,
        ["kelly"] = 20,
        [LootDropTweakData.RARITY_COMMON] = 10,
        [LootDropTweakData.RARITY_UNCOMMON] = 15,
        [LootDropTweakData.RARITY_RARE] = 20,
        ["default"] = 15
    }

    --Seed for random raid and card is current date at UTC+0
    --converted to number. i.e. 20220722
    function DailyRaidManager:seed_today()
        return tonumber(os.date('!%Y%m%d', os.time()))
    end

    --time until next daily raid, in seconds
    function DailyRaidManager:time_until_next()
        --Huge thanks to dorentuz!
        local utc = os.date("!*t")
        local result = (-utc.hour * 3600 - utc.min * 60 - utc.sec) % 86400
        return result
    end

    --Checks if current date is not the same as the one saved
    function DailyRaidManager:can_do_new_daily()
        return self.currentMod.Options:GetValue("last_finished") ~= self:seed_today()
    end

    --Saves finished seed to the save file
    function DailyRaidManager:job_finished(seed)
        self.currentMod.Options:SetValue("last_finished", seed)
		self.currentMod.Options:Save()
        self:remove_daily()
    end

    --Remove everything related to dailies
    function DailyRaidManager:remove_daily()
        managers.challenge_cards.forced_card = nil
		managers.challenge_cards.daily_reward = nil
		managers.challenge_cards.daily_seed = nil
    end

    function DailyRaidManager:generate_gold(data)
        local reward = self.rewards[data]
        if not reward then
            reward = self.rewards["default"]
        end

        return reward
    end

    function DailyRaidManager:generate_daily()
        --Seeding the RNG
	    local seed = self:seed_today()
	    math.randomseed(seed)

	    --Generating random mission
	    local index = tweak_data.operations:get_raids_index()
	    local daily_mission_name
	    local mission_data
	    --Consumable dailies crash the game
	    repeat
	    	daily_mission_name = index[math.random(#index)]
	    	mission_data = tweak_data.operations:mission_data(daily_mission_name)
	    until not mission_data.consumable

	    --Generating random card
	    local cards_index = tweak_data.challenge_cards.cards_index
	    local daily_forced_card
	    local card_data
	    --Boost cards (i.e. more hp) don't really fit with the whole idea of daily raid
	    repeat
	    	daily_forced_card = cards_index[math.random(#cards_index)]
	    	card_data = tweak_data.challenge_cards:get_card_by_key_name(daily_forced_card)
	    until card_data.card_category == tweak_data.challenge_cards.CARD_CATEGORY_CHALLENGE_CARD

        --Generating gold
        local reward = self:generate_gold(daily_mission_name) + self:generate_gold(card_data.rarity)
        return seed, daily_mission_name, daily_forced_card, reward
    end

    function DailyRaidManager:send_message(message_id, params)
        --Adding a prefix to the message
        local message = "[" .. managers.localization:text("daily_daily_bounty") .. "] " .. managers.localization:text(message_id, params)
        managers.chat:send_message(1, managers.network.account:username() or "SYSTEM", message)
    end
end