-- =============================================================================
-- RadioTrader_UnlockFlyer.lua
-- [Client] Scavenger Flyer creation, drop, foraging, and read unlock system
-- =============================================================================

RadioTrader_UnlockFlyer = {}

local function tr(key, defaultText, ...)
    local args = {...}
    if not key then return defaultText or "" end
    if #args > 0 then
        if getTextOrNull then
            local ok, val = pcall(getTextOrNull, key, unpack(args))
            if ok and val then return val end
        end
        if getText then
            local ok, val = pcall(getText, key, unpack(args))
            if ok and val and val ~= key then return val end
        end
        if defaultText then
            local safeDefault = string.gsub(defaultText, "%%d", "%%s")
            local ok, res = pcall(string.format, safeDefault, unpack(args))
            if ok then return res end
            return defaultText
        end
        return key
    else
        if getTextOrNull then
            local ok, val = pcall(getTextOrNull, key)
            if ok and val then return val end
        end
        if getText then
            local ok, val = pcall(getText, key)
            if ok and val and val ~= key then return val end
        end
        return defaultText or key
    end
end

local DEFAULT_FLYER_TITLE = "Scavengers Wanted!"
local DEFAULT_FLYER_BODY = [[To any survivors still breathing:
We are a civilian logistics network operating outside the Knox Exclusion Zone.
We are looking to preserve pre-exclusion documents, records, and valuables.
In return, we will trade vital survival supplies gathered across the state.
If you want to trade, tune your two-way radio to [ 104.8 MHz ].
We'll drop what you need from the skies. Stay alive.]]

local function log(msg)
    print("[RadioTrader][UnlockFlyer] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- チラシアイテムの生成 (バニラ手書き紙 Base.SheetPaper2)
-- ---------------------------------------------------------------------------
function RadioTrader_UnlockFlyer.createFlyerItem()
    local item = instanceItem("Base.SheetPaper2")
    if not item then return nil end

    local flyerTitle = tr("UI_RadioTrader_Flyer_Title", DEFAULT_FLYER_TITLE)
    local flyerBody = tr("UI_RadioTrader_Flyer_Body", DEFAULT_FLYER_BODY)

    item:setName(flyerTitle)
    if item.setCustomName then item:setCustomName(true) end

    if item.addPage then
        item:addPage(1, flyerBody)
    end
    if item.setLockedBy then
        item:setLockedBy("ExclusionZoneTrader")
    end
    if item.setCanBeWrite then
        item:setCanBeWrite(false)
    end

    local md = item:getModData()
    if md then
        md.bRadioTraderFlyer = true
    end

    return item
end

-- ---------------------------------------------------------------------------
-- アンロック済みチェック
-- ---------------------------------------------------------------------------
function RadioTrader_UnlockFlyer.isUnlocked(player)
    player = player or getSpecificPlayer(0)
    if not player then return false end
    local md = player:getModData()
    return md and (md.bRadioTraderUnlocked == true)
end

-- ---------------------------------------------------------------------------
-- アンロック実行（手帳に記録・演出）
-- ---------------------------------------------------------------------------
function RadioTrader_UnlockFlyer.unlock(player)
    player = player or getSpecificPlayer(0)
    if not player then return end

    local md = player:getModData()
    if md and md.bRadioTraderUnlocked then return end -- 既に記録済み

    md.bRadioTraderUnlocked = true

    -- 頭上通知
    local notifyUnlock = tr("UI_RadioTrader_Halo_FlyerUnlocked", "Trade frequency (104.8 MHz) recorded in journal!")
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, notifyUnlock)
    elseif HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, notifyUnlock)
    end

    log("Radio trade network unlocked for player: " .. tostring(player:getUsername()))
end

-- ---------------------------------------------------------------------------
-- 読了検知: ISReadABook.perform フック
-- ---------------------------------------------------------------------------
if ISReadABook and ISReadABook.perform then
    local original_perform = ISReadABook.perform
    function ISReadABook:perform()
        if self.item and self.item.getModData then
            local md = self.item:getModData()
            if md and md.bRadioTraderFlyer then
                RadioTrader_UnlockFlyer.unlock(self.character)
            end
        end
        original_perform(self)
    end
end

-- ---------------------------------------------------------------------------
-- 読了検知: Events.OnReadLiterature フック (念のための二重安全策)
-- ---------------------------------------------------------------------------
local function onReadLiterature(player, item, percent)
    if not item or not item.getModData then return end
    local md = item:getModData()
    if md and md.bRadioTraderFlyer then
        RadioTrader_UnlockFlyer.unlock(player)
    end
end
if Events.OnReadLiterature then
    Events.OnReadLiterature.Add(onReadLiterature)
end

-- ---------------------------------------------------------------------------
-- ゾンビ討伐ドロップ (生存5日以上で4%の確率でドロップ、討伐褒章としてアンロック後も継続)
-- ---------------------------------------------------------------------------
local function onZombieDead(zombie)
    if not zombie then return end

    -- 1. 最軽量の乱数判定で 96% を即座に除外（Early Exit: CPU負荷ゼロ）
    if ZombRand(100) >= 4 then return end

    -- 2. 設定チェック: チラシ必須化OFFの場合はドロップ不要
    local cfg = RadioTrader_Config
    if cfg and cfg.isFlyerRequired and not cfg.isFlyerRequired() then
        return
    end

    -- 3. 生存日数チェック (デフォルト: 5日以上)
    local minDays = (cfg and cfg.getFlyerMinSurvivedDays and cfg.getFlyerMinSurvivedDays()) or 5
    local gt = getGameTime and getGameTime()
    local daysSurvived = 0
    if gt then
        daysSurvived = gt:getNightsSurvived() or math.floor(gt:getWorldAgeHours() / 24)
    end
    if daysSurvived < minDays then
        return
    end

    -- 4. ゾンビのインベントリにチラシを追加（討伐褒章・換金アイテムとしても機能）
    local inv = zombie:getInventory()
    if inv then
        local flyer = RadioTrader_UnlockFlyer.createFlyerItem()
        if flyer then
            inv:AddItem(flyer)
            log("Dropped Scavenger Flyer on dead zombie (Day " .. tostring(daysSurvived) .. ").")
        end
    end
end
if Events.OnZombieDead then
    Events.OnZombieDead.Add(onZombieDead)
end

-- ---------------------------------------------------------------------------
-- 採集 (Foraging) での発見 (生存5日以上かつ未アンロック時のみ 5% の確率で追加発見)
-- ---------------------------------------------------------------------------
if ISForageAction and ISForageAction.perform then
    local original_forage_perform = ISForageAction.perform
    function ISForageAction:perform()
        original_forage_perform(self)

        -- 1. 乱数判定で 95% を即座に除外
        if ZombRand(100) >= 5 then return end

        local cfg = RadioTrader_Config
        if cfg and cfg.isFlyerRequired and not cfg.isFlyerRequired() then return end

        local player = self.character or getSpecificPlayer(0)
        if RadioTrader_UnlockFlyer.isUnlocked(player) then return end

        -- 2. 生存日数チェック
        local minDays = (cfg and cfg.getFlyerMinSurvivedDays and cfg.getFlyerMinSurvivedDays()) or 5
        local gt = getGameTime and getGameTime()
        local daysSurvived = 0
        if gt then
            daysSurvived = gt:getNightsSurvived() or math.floor(gt:getWorldAgeHours() / 24)
        end
        if daysSurvived < minDays then return end

        -- 3. チラシを自然界から発見
        local inv = player and player:getInventory()
        if inv then
            local flyer = RadioTrader_UnlockFlyer.createFlyerItem()
            if flyer then
                inv:AddItem(flyer)
                local notifyFound = tr("UI_RadioTrader_Halo_FlyerFound", "Found a handwritten flyer")
                if HaloTextHelper and HaloTextHelper.addGoodText then
                    HaloTextHelper.addGoodText(player, notifyFound)
                end
                log("Found Scavenger Flyer via Foraging (Day " .. tostring(daysSurvived) .. ").")
            end
        end
    end
end
