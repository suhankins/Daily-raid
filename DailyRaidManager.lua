if not DailyRaidManager then
    DailyRaidManager = {}

    -- Allowlist of raids.
    -- It's an allowlist in case people start modding in custom maps
    DailyRaidManager.RAID_ALLOWLIST = {
        "flakturm",      -- Odin's Fall
        "gold_rush",     -- Gold Rush
        "train_yard",    -- Amber Train
        "radio_defense", -- Wiretap
        "ger_bridge",    -- Trainwreck
        "settlement",    -- Strongpoint
        "bunker_test",   -- Bunker Busters
        "tnd",           -- Tiger Trap
        "hunters",       -- Hunters
        "convoy",        -- Last Orders
        "spies_test",    -- Extraction
        "silo",          -- Countdown
        "kelly"          -- Kelly
    }

    -- MUG team keeps adding new unfinished cards,
    -- so it's better to have an allowlist instead of blocklist
    DailyRaidManager.CARD_ALLOWLIST = {
        "ra_on_the_scrounge",
        "ra_no_backups",
        "ra_this_is_gonna_hurt",
        "ra_not_in_the_face",
        "ra_loaded_for_bear",
        "ra_total_carnage",
        "ra_switch_hitter",
        "ra_gunslingers",
        "ra_fresh_troops",
        "ra_dont_you_die_on_me",
        "ra_no_second_chances",
        "ra_a_perfect_score",
        "ra_helmet_shortage",
        "ra_hemorrhaging",
        "ra_crab_people",
        "op_limited_supplies",
        "op_take_the_cannoli",
        "op_everyones_a_tough_guy",
        "op_nichtsplosions",
        "op_war_weary",
        "op_special_for_a_reason",
        "op_dont_blink",
        "op_bad_coffee",
        "op_playing_for_keeps",
        "op_silent_shout",
        "op_blow_me",
        "op_you_only_live_once",
        "op_short_controlled_bursts",
        "op_elite_opponents",
        "op_and_headaches_for_all",
        "ra_slasher_movie",
        "ra_pumpkin_pie",
        "ra_season_of_resurrection",
        "ra_dooms_day",
        "mag_roulette"
    }

    -- Used for saving last finished daily
    DailyRaidManager.currentMod = CurrentMod

    -- Required difficulty
    -- 1. Easy
    -- 2. Normal
    -- 3. Hard
    -- 4. Very Hard
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

    -- Currently selected forced card
    ---@type string | nil
    DailyRaidManager.forced_card = nil
    -- Reward for current daily bounty
    ---@type number | nil
    DailyRaidManager.daily_reward = nil
    -- Current daily bounty seed
    ---@type number | nil
    DailyRaidManager.daily_seed = nil

    --Seed for random raid and card is current date at UTC+0
    --converted to number. i.e. 22072022 (dd,mm,yyyy)
    --Random numbers at the end are needed because otherwise random numbers don't feel random enough
    function DailyRaidManager:seed_today()
        return math.floor(tonumber(os.date('!%d%m%Y', os.time())) * 20170926 / 201407)
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
    ---@param seed number
    function DailyRaidManager:job_finished(seed)
        self.currentMod.Options:SetValue("last_finished", seed)
        self.currentMod.Options:Save()
        self:remove_daily()
    end

    --Remove everything related to current daily
    function DailyRaidManager:remove_daily()
        DailyRaidManager.forced_card = nil
        DailyRaidManager.daily_reward = nil
        DailyRaidManager.daily_seed = nil
    end

    -- Calculates amount of gold that should be granted for given thing
    ---@param data string
    function DailyRaidManager:calculate_gold(data)
        local reward = self.rewards[data]
        if not reward then
            reward = self.rewards["default"]
        end

        return reward
    end

    ---@return integer, string, string, number
    function DailyRaidManager:generate_daily()
        --Seeding the RNG
        local seed = self:seed_today()
        math.randomseed(seed)

        -- Generating random mission
        local daily_mission_name = self.RAID_ALLOWLIST[math.random(#self.RAID_ALLOWLIST)]

        -- Generating random card
        local daily_forced_card = self.CARD_ALLOWLIST[math.random(#self.CARD_ALLOWLIST)]
        local card_data = tweak_data.challenge_cards:get_card_by_key_name(daily_forced_card)

        --Generating gold
        local reward = self:calculate_gold(daily_mission_name) + self:calculate_gold(card_data.rarity)
        return seed, daily_mission_name, daily_forced_card, reward
    end

    ---@param message_id string
    ---@param[opt] params {[string]: any}
    function DailyRaidManager:send_message(message_id, params)
        --Adding a prefix to the message
        local message = "[" ..
        managers.localization:text("daily_daily_bounty") .. "] " .. managers.localization:text(message_id, params)
        managers.chat:send_message(1, managers.network.account:username() or "SYSTEM", message)
    end
end
