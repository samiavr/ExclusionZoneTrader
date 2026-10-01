-- =============================================================================
-- RadioTrader_ContextMenu.lua
-- [Client] 右クリックメニュー登録・起動エントリポイント
-- =============================================================================
-- 右クリック時にコンテナまたは無線機を対象として以下のメニューを追加する:
--   コンテナ対象:
--     [交易LZ/ドロップボックスに指定]
--     [交易LZ/ドロップボックスを解除]
--   無線機対象:
--     [無線取引ネットワークに接続]
-- =============================================================================

RadioTrader_ContextMenu = {}

-- ---------------------------------------------------------------------------
-- ログユーティリティ
-- ---------------------------------------------------------------------------
local function log(msg)
    print("[RadioTrader][ContextMenu] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- 多言語化ヘルパー（可変長引数・pcall安全版・文字列化保証）
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
-- 安全な HaloText 表示ヘルパー (PZ B41/B42 互換)
-- ---------------------------------------------------------------------------
local function showGoodText(player, text)
    if not player or not text then return end
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, text)
    elseif HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, text)
    end
end

local function showBadText(player, text)
    if not player or not text then return end
    if HaloTextHelper and HaloTextHelper.addBadText then
        HaloTextHelper.addBadText(player, text)
    elseif HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, text)
    end
end

-- 配達ステートをローカルにキャッシュ（サーバーから受取った値を保持）
local cachedDeliveryState = nil

-- ---------------------------------------------------------------------------
-- プレイヤーの LocalModData ヘルパー（クライアント側はローカルMDを使用）
-- ---------------------------------------------------------------------------
local function getLocalMD(player)
    return player:getModData()
end

-- ---------------------------------------------------------------------------
-- コンテナのスクエアが屋外かどうかを判定
-- ---------------------------------------------------------------------------
local function isOutdoor(isoObject)
    local sq = isoObject:getSquare()
    if not sq then return false end
    return sq:isOutside()
end

-- ---------------------------------------------------------------------------
-- LZ 登録処理
-- ---------------------------------------------------------------------------
local function registerLZ(player, isoObject)
    local sq = isoObject:getSquare()
    if not sq then
        player:Say(tr("UI_RadioTrader_Say_NoSquare", "Unable to get coordinates."))
        return
    end

    -- 屋外判定
    if RadioTrader_Config.REQUIRE_OUTDOOR_LZ and not sq:isOutside() then
        player:Say(tr("UI_RadioTrader_Say_OutdoorOnly", "Only outdoor containers can be designated as an LZ."))
        showBadText(player, tr("UI_RadioTrader_Halo_OutdoorOnly", "Outdoors only"))
        return
    end

    -- プレイヤーとコンテナの距離チェック
    local px, py = player:getX(), player:getY()
    local cx, cy = sq:getX(), sq:getY()
    local dist   = math.sqrt((px - cx)^2 + (py - cy)^2)
    if dist > RadioTrader_Config.LZ_MAX_RANGE then
        player:Say(tr("UI_RadioTrader_Say_LZTooFar", "LZ is too far (%d tiles).", math.floor(dist)))
        return
    end

    -- LocalModData に保存（サーバーとの同期はコマンド送信時に実施）
    local md = getLocalMD(player)
    md[RadioTrader_Config.KEY_LZ_X] = cx
    md[RadioTrader_Config.KEY_LZ_Y] = cy
    md[RadioTrader_Config.KEY_LZ_Z] = sq:getZ()

    -- サーバー側 ModData にも記録
    sendClientCommand(player, "RadioTrader", "setLZ", {
        x = cx, y = cy, z = sq:getZ()
    })

    -- フィードバック
    player:Say(tr("UI_RadioTrader_Say_LZRegistered", "LZ registered. Clear the perimeter for heli drop."))
    showGoodText(player, tr("UI_RadioTrader_Halo_LZRegistered", "LZ Registered!"))
    log(("LZ registered: [%d, %d, %d]"):format(cx, cy, sq:getZ()))
end

-- ---------------------------------------------------------------------------
-- LZ 解除処理
-- ---------------------------------------------------------------------------
local function deregisterLZ(player)
    local md = getLocalMD(player)
    md[RadioTrader_Config.KEY_LZ_X] = nil
    md[RadioTrader_Config.KEY_LZ_Y] = nil
    md[RadioTrader_Config.KEY_LZ_Z] = nil

    sendClientCommand(player, "RadioTrader", "clearLZ", {})

    player:Say(tr("UI_RadioTrader_Say_LZCleared", "Trade LZ registration cleared."))
    showBadText(player, tr("UI_RadioTrader_Halo_LZCleared", "LZ Cleared"))
    log("LZ deregistered for " .. player:getUsername())
end

-- ---------------------------------------------------------------------------
-- LZ 登録済みかチェック
-- ---------------------------------------------------------------------------
local function hasLZ(player)
    local md = getLocalMD(player)
    return md[RadioTrader_Config.KEY_LZ_X] ~= nil
end

-- ---------------------------------------------------------------------------
-- 配達ステート取得（ModData 直接確認 または cachedDeliveryState）
-- ---------------------------------------------------------------------------
local function getDeliveryState(player)
    player = player or getSpecificPlayer(0)
    if player then
        local uname = player.getUsername and player:getUsername()
        if not uname or uname == "" then uname = "singleplayer" end
        local timerKey = "RadioTrader_Timer_" .. uname
        if ModData and ModData.exists and ModData.exists(timerKey) then
            local tdata = ModData.get(timerKey)
            if tdata and tdata.state then
                cachedDeliveryState = tdata.state
                return tdata.state
            end
        end
    end
    return cachedDeliveryState or RadioTrader_Config.STATE_NONE
end

-- ---------------------------------------------------------------------------
-- 無線機の有効性チェック（ワールド設置 / インベントリ共通）
-- ---------------------------------------------------------------------------
local function checkRadioDevice(player, radioObj)
    local reasons = {}
    if not radioObj then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_NoData", "Radio device not found"))
        return false, reasons
    end

    local devData = radioObj.getDeviceData and radioObj:getDeviceData()
    if not devData then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_NoData", "Device data unavailable"))
        return false, reasons
    end

    -- テレビ除外
    local isTv = false
    if devData.getIsTelevision then
        isTv = devData:getIsTelevision()
    end
    if isTv then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_NotRadio", "Television cannot communicate"))
        return false, reasons
    end

    -- 双方向通信機チェック（受信専用機を除外）
    local isTwoWay = true
    if devData.getIsTwoWay then
        isTwoWay = devData:getIsTwoWay()
    end
    if not isTwoWay then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_NotTwoWay", "Receiver only (Cannot transmit)"))
        return false, reasons
    end

    -- 型名チェック（型名が取得できる場合のみフィルタ）
    local itemType = nil
    if radioObj.getFullType then
        itemType = radioObj:getFullType()
    elseif radioObj.getItemType then
        itemType = tostring(radioObj:getItemType())
    elseif radioObj.getProperties and radioObj:getProperties():get("CustomItem") then
        itemType = radioObj:getProperties():get("CustomItem")
    end

    if itemType and not RadioTrader_Config.isValidRadioType(itemType) then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_InvalidType", "Incompatible radio model"))
        return false, reasons
    end

    -- 電源チェック（PZ B42: getIsTurnedOn）
    local isPowered = false
    if devData.getIsTurnedOn then
        isPowered = devData:getIsTurnedOn()
    elseif devData.getIsSwitchedOn then
        isPowered = devData:getIsSwitchedOn()
    end
    if not isPowered then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_PowerOff", "Power is OFF"))
    end

    -- 周波数チェック (104.8 MHz / 104800 kHz)
    local freq = devData:getChannel()
    if not RadioTrader_Config.isValidFrequency(freq) then
        local dispFreq = (freq and freq > 1000) and (freq / 1000.0) or (freq or 0)
        local freqReason = tr("ContextMenu_RadioTrader_Reason_FreqMismatch", "Frequency mismatch")
            .. (": %.1f MHz (Required: %.1f MHz)"):format(dispFreq, RadioTrader_Config.FREQUENCY)
        table.insert(reasons, freqReason)
    end

    -- LZ 登録チェック
    if not hasLZ(player) then
        table.insert(reasons, tr("ContextMenu_RadioTrader_Reason_NoLZ", "No LZ registered"))
    end

    local ok = (#reasons == 0)
    return ok, reasons
end

-- ---------------------------------------------------------------------------
-- 右クリックメニューへの追加
-- ---------------------------------------------------------------------------
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end  -- ツールチップテストモードでは追加しない

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- ターゲットオブジェクトを分類
    local containers = {}
    local radios     = {}

    for _, obj in ipairs(worldObjects) do
        -- コンテナ判定
        if obj.getContainer and obj:getContainer() then
            table.insert(containers, obj)
        end

        -- 無線機判定（ワールド設置: IsoWaveSignal または getDeviceData 持ちでテレビでないもの）
        local devData = obj.getDeviceData and obj:getDeviceData()
        local isRadio = false
        if instanceof(obj, "IsoWaveSignal") or instanceof(obj, "Radio") then
            isRadio = true
        elseif devData and devData.getIsTelevision and not devData:getIsTelevision() then
            isRadio = true
        end

        if isRadio and devData then
            table.insert(radios, obj)
        end
    end

    -- --- コンテナメニュー ---
    for _, container in ipairs(containers) do
        local cfg = RadioTrader_Config
        local deliveryState = getDeliveryState(player)

        if hasLZ(player) then
            -- READY_FOR_DROP 時は「投下要請」ボタンを優先表示
            if deliveryState == cfg.STATE_READY_FOR_DROP then
                local reqDropLabel = tr("ContextMenu_RadioTrader_RequestDrop", "[Drop] Request Airdrop (Call Heli)")
                context:addOption(reqDropLabel, player, function(pl)
                    sendClientCommand(pl, "RadioTrader", cfg.CMD_REQUEST_DROP, {})
                    pl:Say("Requesting supply drop...")
                end)
            end
            -- LZ 解除メニュー（常に表示）
            local clearLabel = tr("ContextMenu_RadioTrader_ClearLZ", "[LZ] Clear LZ Registration")
            context:addOption(clearLabel, player, function(pl)
                deregisterLZ(pl)
            end)
        else
            -- LZ 登録メニュー
            local isOut = isOutdoor(container)
            local label = isOut
                and tr("ContextMenu_RadioTrader_SetLZ", "[LZ] Designate Drop Box / LZ")
                or  tr("ContextMenu_RadioTrader_SetLZ_Indoor", "[LZ] Designate Drop Box / LZ (Outdoors Only)")
            context:addOption(label, player, function(pl)
                registerLZ(pl, container)
            end)
        end
        break  -- 最初のコンテナにのみ追加
    end

    -- --- 無線機メニュー（ワールド設置優先、次いでインベントリ）---
    local function addRadioMenuFromDevice(radioObj)
        local ok, reasons = checkRadioDevice(player, radioObj)
        if ok then
            local connLabel = tr("ContextMenu_RadioTrader_Connect", "[Radio] Connect to Trade Network")
            context:addOption(connLabel, player, function(pl)
                -- 取引 UI を起動
                RadioTrader_UI.open(pl)
            end)
        else
            -- 条件不満足時はサブメニューで理由を表示
            local disLabel = tr("ContextMenu_RadioTrader_Connect_Disabled", "[Radio] Trade Network (Unavailable)")
            local submenu  = context:addOption(disLabel, player, nil)
            local sub      = context:getNew(context)
            context:addSubMenu(submenu, sub)
            for _, reason in ipairs(reasons) do
                sub:addOption("[-] " .. reason, nil, nil)
            end
        end
    end

    -- 無線機メニューの追加（ワールド設置優先、次いでインベントリ）
    local radioFound = false
    for _, radioObj in ipairs(radios) do
        addRadioMenuFromDevice(radioObj)
        radioFound = true
        break
    end

    if not radioFound then
        local inv = player:getInventory()
        if inv then
            for _, validType in ipairs(RadioTrader_Config.VALID_RADIO_TYPES) do
                local item = inv:getFirstTypeRecurse(validType)
                if item and item.getDeviceData and item:getDeviceData() then
                    addRadioMenuFromDevice(item)
                    radioFound = true
                    break
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ---------------------------------------------------------------------------
-- サーバーコマンド受信（クライアント側）
-- CMD_REQUEST_DROP : READY_FOR_DROP 遷移通知
-- CMD_ORDER_EXPIRED: 期限切れ・返金通知
-- stateRefresh     : ステートキャッシュ更新
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "RadioTrader" then return end
    local player = getSpecificPlayer(0)  -- シングル/マルチ共通：自分宛定

    if command == RadioTrader_Config.CMD_REQUEST_DROP then
        -- READY_FOR_DROP へ遷移通知
        cachedDeliveryState = RadioTrader_Config.STATE_READY_FOR_DROP
        local expH = args and args.expireHours or 48
        if player then
            player:Say(tr("UI_RadioTrader_Say_ReadyForDrop", "Incoming transmission: Supplies ready. Request drop near LZ."))
        end
        showGoodText(player or getSpecificPlayer(0),
            tr("UI_RadioTrader_Halo_ReadyForDrop", "Drop Ready! Expires in: %d hrs", expH))
        log("READY_FOR_DROP received. Expire in " .. expH .. " hrs.")

    elseif command == RadioTrader_Config.CMD_ORDER_EXPIRED then
        -- 期限切れ通知
        cachedDeliveryState = RadioTrader_Config.STATE_NONE
        local refund = args and args.refund or 0
        if player then
            player:Say(tr("UI_RadioTrader_Say_OrderExpired", "Drop expired. Order cancelled. Refunded: %d CR", refund))
        end
        showBadText(player or getSpecificPlayer(0),
            tr("UI_RadioTrader_Halo_OrderExpired", "Order Expired | Refund: %d CR", refund))
        log("Order expired. Refund: " .. refund .. " CR")

    elseif command == "stateRefresh" then
        cachedDeliveryState = args and args.state or RadioTrader_Config.STATE_NONE
    end
end

RadioTrader_ContextMenu.onServerCommand = onServerCommand
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- setLZ / clearLZ の受信処理（Server 側のハンドラに追記）
-- setLZ / clearLZ は RadioTrader_ServerEngine の OnClientCommand で受信。
-- （ここでは送信のみ行い、サーバー側 ModData 更新はサーバーで処理）
-- ---------------------------------------------------------------------------
