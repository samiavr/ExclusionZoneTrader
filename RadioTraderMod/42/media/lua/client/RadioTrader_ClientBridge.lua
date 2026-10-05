-- =============================================================================
-- RadioTrader_ClientBridge.lua
-- [Client] サーバー通知受信・演出処理
-- =============================================================================
-- サーバー (sendServerCommand) からのメッセージを受信し、以下を担当する:
--   - ゲーム内テキスト・ログへのメッセージ表示
--   - SE 再生（無線ノイズ・着陸音）
--   - RadioTrader_UI.instance への通知転送
-- アイテム操作はここでは一切行わない（Dupe 防止）。
-- =============================================================================

RadioTrader_ClientBridge = {}

-- ---------------------------------------------------------------------------
-- 多言語翻訳ヘルパー（可変長引数・pcall安全版・文字列化保証）
-- ---------------------------------------------------------------------------
local function tr(key, defaultText, ...)
    local rawArgs = {...}
    local args = {}
    for i, v in ipairs(rawArgs) do
        table.insert(args, tostring(v))
    end
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

-- ---------------------------------------------------------------------------
-- 英語名/フォールバック名からアイテムIDを逆引き解決するヘルパー
-- ---------------------------------------------------------------------------
local function resolveItemIdFromName(name)
    if not name or name == "" or not RadioTrader_Shop then return nil end
    local cleanName = tostring(name):gsub("%s*%(%+%d+ more%)", ""):gsub("%s*%(他%s*%d+%s*品%)", ""):gsub("%s*x%d+$", "")
    for _, catList in pairs(RadioTrader_Shop) do
        for _, entry in ipairs(catList) do
            if entry.name == cleanName or entry.id == cleanName then
                return entry.id
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- アイテム表示名取得（バニラ公式ローカライズ優先 ＆ 逆引きフォールバック）
-- ---------------------------------------------------------------------------
local function getItemDisplayName(fullType, fallbackName)
    local targetId = fullType
    if (not targetId or targetId == "") and fallbackName then
        targetId = resolveItemIdFromName(fallbackName)
    end
    if targetId then
        local i18nKey = "UI_RadioTrader_Item_" .. tostring(targetId)
        local i18nName = tr(i18nKey, nil)
        if i18nName and i18nName ~= i18nKey and i18nName ~= "" then
            return i18nName
        end
        if string.find(tostring(targetId), "%.") and getItemNameFromFullType then
            local ok, vanillaName = pcall(getItemNameFromFullType, targetId)
            if ok and vanillaName and vanillaName ~= "" and vanillaName ~= targetId then
                return vanillaName
            end
        end
        if ScriptManager and ScriptManager.instance and ScriptManager.instance.getItem then
            local ok, item = pcall(function() return ScriptManager.instance:getItem(targetId) end)
            if ok and item and item.getDisplayName then
                local dn = item:getDisplayName()
                if dn and dn ~= "" then return dn end
            end
        end
        if getItem then
            local ok, itemScript = pcall(getItem, targetId)
            if ok and itemScript and itemScript.getDisplayName then
                local dn = itemScript:getDisplayName()
                if dn and dn ~= "" then return dn end
            end
        end
    end
    return fallbackName or fullType or "Goods"
end

-- ---------------------------------------------------------------------------
-- 注文アイテムの複合表示名フォーマッタ（単一・複数・数量ローカライズ対応）
-- ---------------------------------------------------------------------------
local function getOrderDisplayName(args)
    if not args then return "Goods" end
    local itemId = args.itemId
    if not itemId and args.itemName then
        itemId = resolveItemIdFromName(args.itemName)
    end
    local baseName = getItemDisplayName(itemId, args.itemName)
    local totalKinds = tonumber(args.totalKinds) or 1
    local count = tonumber(args.count) or tonumber(args.itemCount) or 1

    if totalKinds > 1 then
        local moreText = tr("UI_RadioTrader_BatchMoreItems", "(+%s more)", tostring(totalKinds - 1))
        return baseName .. " " .. moreText
    elseif count > 1 and not string.find(baseName, " x%d+") then
        return baseName .. " x" .. tostring(count)
    end
    return baseName
end

-- ---------------------------------------------------------------------------
-- ログユーティリティ
-- ---------------------------------------------------------------------------
local function log(msg)
    print("[RadioTrader][Client] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- プレイヤーの無線受信テキスト表示（チャットエレメント）
-- ---------------------------------------------------------------------------
local function showRadioText(player, msg)
    local prefix = tr("UI_RadioTrader_Radio_Prefix", "[Radio] ")
    player:addLineChatElement(prefix .. msg, 0.2, 0.9, 0.5)
end

-- ---------------------------------------------------------------------------
-- SE 再生ヘルパー（B42 対応・World/Player/UI 優先再生）
-- ---------------------------------------------------------------------------
local function playSound(soundName)
    local player = getPlayer()
    if player and player.playSound then
        local ok = pcall(function() player:playSound(soundName) end)
        if ok then return end
    end
    local sm = getSoundManager()
    if sm and sm.playUISound then
        pcall(function() sm:playUISound(soundName) end)
    end
end

-- ---------------------------------------------------------------------------
-- ヘリ滞空時サーチライト演出（IsoLightSource）
-- ---------------------------------------------------------------------------
local currentSearchlight = nil
local searchlightTimeoutMs = 0

local function removeSearchlight()
    if currentSearchlight then
        local cell = getCell()
        if cell and cell.removeLamppost then
            pcall(function() cell:removeLamppost(currentSearchlight) end)
        end
        currentSearchlight = nil
        searchlightTimeoutMs = 0
        log("Heli searchlight removed.")
    end
end
RadioTrader_ClientBridge.removeSearchlight = removeSearchlight

local function activateSearchlight(x, y, z, radius)
    removeSearchlight()
    if not x or not y then return end
    
    local r = radius or 20
    local targetZ = z or 0
    
    if IsoLightSource and getCell() then
        local ok, light = pcall(function()
            -- IsoLightSource.new(int x, int y, int z, float r, float g, float b, int radius)
            return IsoLightSource.new(math.floor(x), math.floor(y), math.floor(targetZ), 0.95, 0.98, 1.0, r)
        end)
        if ok and light then
            local cell = getCell()
            if cell and cell.addLamppost then
                local addedOk, err = pcall(function() cell:addLamppost(light) end)
                if addedOk then
                    currentSearchlight = light
                    -- フェイルセーフ：現実時間90秒（90,000ms）経過後に強制消灯
                    local curMs = (getTimestampMs and getTimestampMs() or 0)
                    searchlightTimeoutMs = curMs + 90000
                    log(("Heli searchlight activated at (%d, %d, %d), radius: %d"):format(
                        math.floor(x), math.floor(y), math.floor(targetZ), r))
                else
                    log("[!] Error calling addLamppost: " .. tostring(err))
                end
            end
        else
            log("[!] Failed to create IsoLightSource: " .. tostring(light))
        end
    end
end

-- ---------------------------------------------------------------------------
-- サーバーコマンド受信ハンドラ (SP/MP二重発火デバウンスガード付き)
-- ---------------------------------------------------------------------------
local lastCmdTimes = {}
local function isDuplicateCommand(cmd, windowMs)
    local curMs = (getTimestampMs and getTimestampMs() or 0)
    if curMs <= 0 then return false end
    local last = lastCmdTimes[cmd] or 0
    if (curMs - last) < (windowMs or 300) then
        return true
    end
    lastCmdTimes[cmd] = curMs
    return false
end

local function onServerCommand(module, command, args)
    if module ~= "RadioTrader" then return end
    if isDuplicateCommand(command, 300) then
        log("Ignoring duplicate server command: " .. tostring(command))
        return
    end

    local player = getPlayer()
    if not player then return end

    log("Received server command: " .. command)

    -- === 発注受付通知 ===
    if command == RadioTrader_Config.CMD_TRADE_ACCEPTED then
        local itemName = getOrderDisplayName(args)
        local cost     = args and args.cost or 0
        local isDrone  = args and args.isDrone
        local msg
        if isDrone then
            msg = tr("UI_RadioTrader_Radio_OrderAcceptedDrone", "[Stealth Drone Delivery] Order accepted for %s. Dispatched a quiet one. Cost: %s CR.", itemName, tostring(cost))
        else
            msg = tr("UI_RadioTrader_Radio_Accepted", "Order accepted. Dispatched transport heli for %s. Cost: %s CR. Stay alert.", itemName, tostring(cost))
        end
        if args and args.hasTraderStash then
            local stashMsg = tr("UI_RadioTrader_Radio_StashAccepted", " '...That was my personal stash, you know. Ah well, enjoy it.'")
            msg = msg .. stashMsg
        end
        showRadioText(player, msg)
        playSound("RadioStatic")
        log("Trade accepted: " .. itemName .. (isDrone and " [Stealth Drone]" or "") .. (args and args.hasTraderStash and " (Trader's Stash ordered!)" or ""))

    -- === ヘリ接近警告 ===
    elseif command == RadioTrader_Config.CMD_HELI_APPROACH then
        local mins    = args and args.remainingMinutes or 10
        local isMega  = args and args.isMegaHorde or false
        local isDrone = args and args.isDrone or false
        local msg
        if isDrone then
            msg = tr("UI_RadioTrader_Radio_ApproachDrone", "Drone reached LZ airspace. Commencing silent drop shortly.")
        elseif isMega then
            msg = tr("UI_RadioTrader_Radio_ApproachMega", "Approaching drop point. ETA %s min. ...Hold on, there's an insane swarm gathering down there! Stay sharp!", tostring(mins))
        else
            msg = tr("UI_RadioTrader_Radio_Approach", "Approaching drop point. ETA %s min. Multiple heat signatures nearby--stay sharp.", tostring(mins))
        end
        showRadioText(player, msg)
        if not isDrone then
            playSound("RadioStatic")
        end
        log("Approach warning displayed (MegaHorde: " .. tostring(isMega) .. ", Drone: " .. tostring(isDrone) .. ")")

    -- === ヘリLZ到着・ホバリング開始（サーチライト点灯） ===
    elseif command == RadioTrader_Config.CMD_HELI_HOVER_START then
        local x = args and args.x
        local y = args and args.y
        local z = args and args.z or 0
        local radius = args and args.radius or 20
        activateSearchlight(x, y, z, radius)

    -- === ヘリホバリング終了・離脱（サーチライト消灯） ===
    elseif command == RadioTrader_Config.CMD_HELI_HOVER_END then
        removeSearchlight()

    -- === 配達完了通知 ===
    elseif command == RadioTrader_Config.CMD_DELIVERY_DONE then
        local itemDisplay = getOrderDisplayName(args)
        local bonusId     = args and args.bonusItemName
        local bonusName   = bonusId and getItemDisplayName(bonusId, bonusId)
        local isMega      = args and args.isMegaHorde or false
        local isDrone     = args and args.isDrone or false

        local hasLunchbox = args and args.hasLunchboxBonus

        local msg
        if isDrone then
            msg = tr("UI_RadioTrader_Radio_DeliveredDrone", "Supplies dropped. Stay out of sight. Disengaging.")
        elseif isMega then
            if bonusName then
                msg = tr("UI_RadioTrader_Radio_DeliveredWithBonusMega",
                    "Supply drop complete (%s)! 'Threw in extra (+ %s), but you'd better run!' Swarm's on you! Departing LZ!",
                    itemDisplay, bonusName)
            else
                msg = tr("UI_RadioTrader_Radio_DeliveredMega",
                    "Supply drop complete! The whole damn town is swarming you! Grab %s and get the hell out of there! Departing LZ!",
                    itemDisplay)
            end
        else
            if bonusName then
                msg = tr("UI_RadioTrader_Radio_DeliveredWithBonus",
                    "Supply drop complete (%s). 'Threw in a little extra for ya!' (+ %s). Departing LZ.",
                    itemDisplay, bonusName)
            else
                msg = tr("UI_RadioTrader_Radio_Delivered",
                    "Supply drop complete. Check LZ for %s. Departing LZ.",
                    itemDisplay)
            end
        end

        if hasLunchbox then
            local lunchMsg = tr("UI_RadioTrader_Radio_LunchboxBonus",
                " 'Thanks for the great salvage! Crew packed you a fresh lunchbox.'")
            msg = msg .. lunchMsg
        end

        local isFallbackDrop = args and args.isFallbackDrop
        if isFallbackDrop then
            local fallbackNotice = tr("UI_RadioTrader_Radio_FallbackDropNotice",
                " [WARNING] Drop box was missing/destroyed. Supplies air-dropped directly onto the ground. Condition and freshness reduced by 10% from impact.")
            msg = msg .. fallbackNotice
        end

        showRadioText(player, msg)
        if not isDrone then
            playSound("Helicopter")
        end
        log("Delivery complete (MegaHorde: " .. tostring(isMega) .. ", Drone: " .. tostring(isDrone) .. ", Lunchbox: " .. tostring(hasLunchbox) .. ", Fallback: " .. tostring(isFallbackDrop) .. "): " .. itemDisplay .. (bonusName and (" + Bonus: " .. bonusName) or ""))

    -- === クレジット残高更新 ===
    elseif command == RadioTrader_Config.CMD_CREDIT_UPDATE then
        local credits = args and args.credits or 0
        log("Credits updated: " .. credits)

    -- === 売却成功通知 ===
    elseif command == "sellSuccess" then
        local credits    = args and args.credits or 0
        local count      = args and args.count or 0
        local unaccepted = args and tonumber(args.unacceptedCount) or 0
        local msg
        if unaccepted > 0 then
            msg = tr("UI_RadioTrader_Log_SellSuccessWithLeftover", "Sale complete: Sold %s items for %s CR. (%s unaccepted items remain)", tostring(count), tostring(credits), tostring(unaccepted))
        else
            msg = tr("UI_RadioTrader_Log_SellSuccess", "Sale complete: Sold %s items for %s CR.", tostring(count), tostring(credits))
        end
        showRadioText(player, msg)
        playSound("GainExperienceLevel")
        log(("Sell complete: %s items for %s CR (leftover=%d)"):format(tostring(count), tostring(credits), unaccepted))

    -- === 査定結果 ===
    elseif command == "assessmentResult" then
        local credits    = args and args.credits or 0
        local accepted   = args and tonumber(args.acceptedCount) or 0
        local unaccepted = args and tonumber(args.unacceptedCount) or 0
        if credits > 0 then
            local msg = tr("UI_RadioTrader_Radio_Assessed", "Drop box contents valued at %s CR. Click [Send Sell Request] to sell.", tostring(credits))
            showRadioText(player, msg)
        elseif unaccepted > 0 then
            local msg = tr("UI_RadioTrader_Log_AssessedAllUnaccepted", "Assessment: 0 CR (All %s items in drop box are unaccepted)", tostring(unaccepted))
            showRadioText(player, msg)
        end

    -- === ステートリフレッシュ（UI再開時）===
    elseif command == "stateRefresh" then
        log(("State refresh: state=%s, credits=%d"):format(
            tostring(args and args.state), tostring(args and args.credits)))

    -- === エラーメッセージ ===
    elseif command == "error" then
        local msg = args and args.message
        if args and args.errCode then
            msg = tr("UI_RadioTrader_Err_" .. args.errCode, args.message or args.errCode)
        end
        showRadioText(player, "[!] " .. (msg or "Unknown Error"))
        playSound("AccessDenied")

    -- === LZ 登録サーバー確認 ===
    elseif command == "lzConfirmed" then
        showRadioText(player, tr("UI_RadioTrader_Radio_LZConfirmed", "LZ registered confirmed. Please ensure it is in an open outdoor area."))

    -- === 投下準備完了通知 (手動投下待ち) ===
    elseif command == RadioTrader_Config.CMD_REQUEST_DROP then
        local expH = args and args.expireHours or 48
        local msg  = tr("UI_RadioTrader_Say_ReadyForDrop", "Incoming transmission: Supplies ready. Request drop near LZ.")
        showRadioText(player, msg)
        playSound("GainExperienceLevel")
        log("READY_FOR_DROP received. Expire in " .. expH .. " hrs.")

    -- === 注文期限切れ通知 ===
    elseif command == RadioTrader_Config.CMD_ORDER_EXPIRED then
        local refund = args and args.refund or 0
        local msg    = tr("UI_RadioTrader_Say_OrderExpired", "Drop expired. Order cancelled. Refunded: %d CR", refund)
        showRadioText(player, msg)
        playSound("AccessDenied")
        log("Order expired. Refund: " .. refund .. " CR")

    -- === 日替わりショップ同期 ===
    elseif command == "syncDailyShop" then
        if args and args.items and RadioTrader_Shop then
            RadioTrader_Shop.Daily = args.items
            log("Daily shop items synced from server: " .. #args.items)
        end

    -- === 追加物資の打診（リロール）成功 ===
    elseif command == "rerollSuccess" then
        if args and args.items and RadioTrader_Shop then
            RadioTrader_Shop.Daily = args.items
        end
        local cost = args and args.cost or 50
        local msg = tr("UI_RadioTrader_Log_RerollSuccess", "Asked 'Got anything else?' over the radio (-%s CR). '...Hold on, I've got these in the back.'", tostring(cost))
        showRadioText(player, msg)
        playSound("RadioStatic")
        if HaloTextHelper and HaloTextHelper.addGoodText then
            HaloTextHelper.addGoodText(player, tr("UI_RadioTrader_Halo_RerollSuccess", "+ Checking other supplies..."))
        end
        log("Inquire success: " .. (args and args.items and #args.items or 0) .. " items")
    end

    -- === ContextMenu のステート同期（SP/MP共通） ===
    if RadioTrader_ContextMenu and RadioTrader_ContextMenu.onServerCommand then
        pcall(RadioTrader_ContextMenu.onServerCommand, module, command, args)
    end

    -- === UI が開いていれば通知転送 ===
    if RadioTrader_UI.instance and RadioTrader_UI.instance:isVisible() then
        RadioTrader_UI.instance:onServerNotify(command, args or {})
    end
end

RadioTrader_ClientBridge.onServerCommand = onServerCommand
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- フェイルセーフタイマー監視（90秒経過で自動消灯）
-- ---------------------------------------------------------------------------
Events.OnTick.Add(function()
    if currentSearchlight and searchlightTimeoutMs > 0 then
        local curMs = (getTimestampMs and getTimestampMs() or 0)
        if curMs >= searchlightTimeoutMs then
            removeSearchlight()
        end
    end
end)

-- ---------------------------------------------------------------------------
-- プレイヤー死亡・リセット時のクリーンアップ
-- ---------------------------------------------------------------------------
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(deadPlayer)
        if deadPlayer and deadPlayer:isLocalPlayer() then
            removeSearchlight()
        end
    end)
end

