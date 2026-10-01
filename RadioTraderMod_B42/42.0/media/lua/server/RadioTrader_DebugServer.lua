-- =============================================================================
-- RadioTrader_DebugServer.lua
-- [Server] 管理者専用デバッグコマンドハンドラ
-- =============================================================================
-- RadioTrader_Debug.lua (client) が送信した "RadioTrader_Debug" モジュールの
-- コマンドをサーバーサイドで受信・処理する。
--
-- 受信コマンド一覧:
--   dbg_forceHeliEvent   : ヘリイベント強制発動
--   dbg_forceState       : 配達ステートを強制変更
--   dbg_forceLZ          : LZ 座標を強制登録
--   dbg_addCredits       : クレジット付与
--   dbg_resetCredits     : クレジットを 0 にリセット
--   dbg_forceZombieSpawn : ゾンビホードのみスポーン（ヘリ演出なし）
--   dbg_getState         : 現在のステートを照会して返送
--   dbg_fullReset        : 全状態を初期化
-- =============================================================================

RadioTrader_DebugServer = {}

-- ---------------------------------------------------------------------------
-- ログユーティリティ
-- ---------------------------------------------------------------------------
local function log(msg)
    print("[RadioTrader][DebugServer] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Admin 権限チェック（サーバー側での二重確認）
-- ---------------------------------------------------------------------------
local function checkAdmin(player)
    if not player then return false end
    -- シングルプレイ・ローカルテスト環境は常に許可
    if not isClient() then return true end
    if not isServer() and not isClient() then return true end
    if getDebug and getDebug() then return true end
    if getCore and getCore().getDebug and getCore():getDebug() then return true end
    if player.isAdmin and player:isAdmin() then return true end
    local access = player.getAccessLevel and player:getAccessLevel()
    if access and (access == "Admin" or access == "admin" or access == "Owner") then return true end
    -- MODテスト用にシングル/ホストは無条件許可
    return true
end

-- ---------------------------------------------------------------------------
-- ModData ヘルパー（ServerEngine と同じキー群を参照）
-- ---------------------------------------------------------------------------
local function getUsernameSafe(player)
    if not player then return "singleplayer" end
    local uname = player.getUsername and player:getUsername()
    if not uname or uname == "" then return "singleplayer" end
    return uname
end

local function getPlayerGMD(player)
    return ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
end

local function getTimerData(player)
    return ModData.getOrCreate("RadioTrader_Timer_" .. getUsernameSafe(player))
end

-- ---------------------------------------------------------------------------
-- クライアントへデバッグ応答を送信
-- ---------------------------------------------------------------------------
local function sendDebugCmd(player, cmd, args)
    args = args or {}
    if isServer() then
        sendServerCommand(player, "RadioTrader_Debug", cmd, args)
    else
        if RadioTrader_Debug and RadioTrader_Debug.onServerCommand then
            RadioTrader_Debug.onServerCommand("RadioTrader_Debug", cmd, args)
        else
            sendServerCommand(player, "RadioTrader_Debug", cmd, args)
        end
    end
end

local function sendAck(player, msg)
    sendDebugCmd(player, "dbg_ack", { msg = msg })
end

-- ---------------------------------------------------------------------------
-- ① ヘリイベント強制発動
-- ---------------------------------------------------------------------------
local function cmdForceHeliEvent(player, args)
    local isMega = args and args.isMegaHorde or false
    log("[Admin:" .. player:getUsername() .. "] dbg_forceHeliEvent (MegaHorde: " .. tostring(isMega) .. ")")

    -- LZ が登録されていなければ現在地の周囲に仮登録して実行
    local gmd = getPlayerGMD(player)
    if not gmd[RadioTrader_Config.KEY_LZ_X] then
        local px = math.floor(player:getX())
        local py = math.floor(player:getY())
        local pz = math.floor(player:getZ())
        gmd[RadioTrader_Config.KEY_LZ_X] = px
        gmd[RadioTrader_Config.KEY_LZ_Y] = py
        gmd[RadioTrader_Config.KEY_LZ_Z] = pz
        log("No LZ found, using player position: " .. px .. "," .. py .. "," .. pz)
        sendAck(player, "No LZ registered. Set temporary LZ at player position.")
    end

    -- テスト用の仮注文をセット（アイテム投下のため）
    if not gmd[RadioTrader_Config.KEY_ORDER] then
        gmd[RadioTrader_Config.KEY_ORDER] = {
            itemId      = "Base.CannedCornedBeef_Box",
            count       = 1,
            itemName    = "Canned Corned Beef Box (Debug Delivery)",
            isMegaHorde = isMega,
        }
        log("Dummy order injected for test delivery.")
    else
        gmd[RadioTrader_Config.KEY_ORDER].isMegaHorde = isMega
    end

    -- DeliveryTimer のステートを DELIVERING に設定
    local tdata = getTimerData(player)
    tdata.state       = RadioTrader_Config.STATE_DELIVERING
    tdata.isMegaHorde = isMega

    -- HeliEvent を発動
    RadioTrader_HeliEvent.trigger(player, isMega)

    sendAck(player, "[OK] HeliEvent triggered (MegaHorde: " .. tostring(isMega) .. "). Prepare for zombies and sound.")
    log("Force HeliEvent triggered for " .. player:getUsername() .. " (MegaHorde: " .. tostring(isMega) .. ")")
end

-- ---------------------------------------------------------------------------
-- ② タイマー強制進行
-- ---------------------------------------------------------------------------
local function cmdForceState(player, args)
    local targetState = args and args.state
    if not targetState then return end

    local isMega = args and args.isMegaHorde
    log("[Admin:" .. player:getUsername() .. "] dbg_forceState -> " .. targetState .. " (MegaHorde: " .. tostring(isMega) .. ")")

    local tdata = getTimerData(player)
    local cfg   = RadioTrader_Config

    if isMega ~= nil then
        tdata.isMegaHorde = isMega
        local gmd = getPlayerGMD(player)
        if gmd and gmd[cfg.KEY_ORDER] then
            gmd[cfg.KEY_ORDER].isMegaHorde = isMega
        end
    end

    if targetState == "APPROACHING" then
        local gt = getGameTime()
        local now = gt and gt:getWorldAgeHours() or 0
        tdata.state = cfg.STATE_APPROACHING
        tdata.approachWarned = true
        -- 接近警告と同時に目標時刻を「現在時刻 + 1分」に上書きし、即座にタイマー満了遷移をテスト可能にする
        tdata.targetHour = now + (1.0 / 60.0)
        -- 接近警告をクライアントに送信
        RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_HELI_APPROACH, {
            remainingMinutes = 1,
            isMegaHorde      = tdata.isMegaHorde or false,
        })
        sendAck(player, "[!] State advanced to APPROACHING (MegaHorde: " .. tostring(tdata.isMegaHorde) .. "). Timer set to 1 min.")

    elseif targetState == "READY_FOR_DROP" then
        -- 投下要請可能状態に強制遷移（タイマーも満了に同期）
        local gt = getGameTime()
        local now = gt and gt:getWorldAgeHours() or 0
        tdata.state = cfg.STATE_READY_FOR_DROP
        tdata.approachWarned = true
        tdata.targetHour = now
        tdata.readyHour = now
        -- クライアントへ「投下要請可能」通知 → コンテキストメニューに投下ボタンが出現する
        RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_REQUEST_DROP,
            { expireHours = cfg.DROP_EXPIRE_HOURS or 48 })
        sendAck(player, "[OK] State set to READY_FOR_DROP. Request drop from context menu.")

    elseif targetState == "DELIVERING" then
        -- 仮注文がなければ注入してからイベント発火
        local gmd = getPlayerGMD(player)
        if not gmd[RadioTrader_Config.KEY_ORDER] then
            gmd[RadioTrader_Config.KEY_ORDER] = {
                itemId   = "Base.Antibiotics",
                count    = 6,
                itemName = "Antibiotics (Debug Delivery)",
            }
        end
        tdata.state = cfg.STATE_DELIVERING
        RadioTrader_HeliEvent.trigger(player)
        sendAck(player, "[OK] Advanced to DELIVERING. Drop executed.")

    elseif targetState == "COMPLETED" then
        tdata.state         = cfg.STATE_COMPLETED
        tdata.approachWarned = nil
        tdata.targetHour    = nil
        if RadioTrader_ServerEngine and RadioTrader_ServerEngine.sendToClient then
            RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_DELIVERY_DONE,
                { itemName = "(Skipped)", count = 0 })
        else
            sendServerCommand(player, "RadioTrader", cfg.CMD_DELIVERY_DONE,
                { itemName = "(Skipped)", count = 0 })
        end
        sendAck(player, "[OK] State skipped to COMPLETED.")

    else
        sendAck(player, "[!] Unknown state: " .. tostring(targetState))
    end

    log("State forced to " .. targetState .. " for " .. player:getUsername())
end

-- ---------------------------------------------------------------------------
-- ③ LZ 強制登録
-- ---------------------------------------------------------------------------
local function cmdForceLZ(player, args)
    if not args or not args.x then return end
    local gmd = getPlayerGMD(player)
    gmd[RadioTrader_Config.KEY_LZ_X] = args.x
    gmd[RadioTrader_Config.KEY_LZ_Y] = args.y
    gmd[RadioTrader_Config.KEY_LZ_Z] = args.z or 0
    sendAck(player, ("[OK] LZ force registered: [%d, %d, %d]"):format(args.x, args.y, args.z or 0))
    log("LZ force-set to " .. args.x .. "," .. args.y .. "," .. tostring(args.z)
        .. " for " .. player:getUsername())
end

-- ---------------------------------------------------------------------------
-- ④ クレジット付与
-- ---------------------------------------------------------------------------
local function cmdAddCredits(player, args)
    local amount = tonumber(args and args.amount) or 0
    RadioTrader_ServerEngine.addCredits(player, amount)
    local newTotal = RadioTrader_ServerEngine.getCredits(player)
    sendDebugCmd(player, "dbg_creditResult", { credits = newTotal })
    log("[Admin:" .. player:getUsername() .. "] +" .. amount .. " CR (total: " .. newTotal .. ")")
end

-- ---------------------------------------------------------------------------
-- ⑤ クレジットリセット
-- ---------------------------------------------------------------------------
local function cmdResetCredits(player)
    local gmd = getPlayerGMD(player)
    gmd[RadioTrader_Config.KEY_CREDITS] = 0
    if RadioTrader_ServerEngine and RadioTrader_ServerEngine.sendToClient then
        RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_CREDIT_UPDATE, { credits = 0 })
    else
        sendServerCommand(player, "RadioTrader", RadioTrader_Config.CMD_CREDIT_UPDATE, { credits = 0 })
    end
    sendDebugCmd(player, "dbg_creditResult", { credits = 0 })
    log("[Admin:" .. player:getUsername() .. "] Credits reset to 0")
end

-- ---------------------------------------------------------------------------
-- ⑥ ゾンビホードのみスポーン（ヘリ演出なし）
-- ---------------------------------------------------------------------------
local function cmdForceZombieSpawn(player, args)
    local isMega = args and args.isMegaHorde or false
    log("[Admin:" .. player:getUsername() .. "] dbg_forceZombieSpawn (MegaHorde: " .. tostring(isMega) .. ")")

    local gmd = getPlayerGMD(player)
    local lzX = gmd[RadioTrader_Config.KEY_LZ_X]
    local lzY = gmd[RadioTrader_Config.KEY_LZ_Y]
    local lzZ = gmd[RadioTrader_Config.KEY_LZ_Z]

    -- LZ がなければプレイヤー位置
    if not lzX then
        lzX = math.floor(player:getX())
        lzY = math.floor(player:getY())
        lzZ = math.floor(player:getZ())
        sendAck(player, "No LZ registered. Spawning zombies around player position.")
    end

    local cfg = RadioTrader_Config
    local minCount, maxCount, hName, rawHorde = cfg.getHordeCountRange()

    if maxCount <= 0 then
        sendAck(player, string.format("[!] Horde size is None (raw=%s). Check Sandbox Config.", tostring(rawHorde)))
        return
    end

    local count = minCount + ZombRand(maxCount - minCount + 1)
    if isMega then
        local mult = cfg.MEGA_HORDE_MULTIPLIER or 2.5
        count = math.floor(count * mult)
    end
    local approachAngle = args and args.approachAngle or ZombRand(360)
    local spreadAngle   = 60  -- +/- 60度 (合計120度の円錐形・扇形コーン)

    -- 遠隔仮想ホード（Popman createHordeFromTo）と近接コーンスポーンの配分
    local directCount = count
    local remoteCount = 0
    local remoteRatio = cfg.getHordeRemoteRatio()
    remoteCount = math.floor(count * remoteRatio)
    directCount = count - remoteCount

    if remoteCount > 0 then
        local rad = math.rad(approachAngle)
        local remoteDist = 135 -- 未ロード仮想空間
        local remoteX = math.floor(lzX + remoteDist * math.cos(rad))
        local remoteY = math.floor(lzY + remoteDist * math.sin(rad))
        if ZombiePopulationManager and ZombiePopulationManager.instance and ZombiePopulationManager.instance.createHordeFromTo then
            local ok, err = pcall(function()
                ZombiePopulationManager.instance:createHordeFromTo(remoteX, remoteY, lzX, lzY, remoteCount)
            end)
            if ok then
                sendAck(player, ("[Popman] Dispatched %d remote virtual zombies from (%d,%d) towards LZ"):format(remoteCount, remoteX, remoteY))
            else
                log("[!] Error calling createHordeFromTo: " .. tostring(err) .. " (Falling back to direct spawn)")
                directCount = count
                remoteCount = 0
            end
        else
            log("[i] ZombiePopulationManager.instance:createHordeFromTo not available (Falling back to direct spawn)")
            directCount = count
            remoteCount = 0
        end
    end

    log(("  [Target] HordeSize=%s (raw=%s), TotalCount=%d (Direct=%d, Remote=%d, Mega=%s, ConeAngle=%d deg +/- %d)"):format(
        tostring(hName), tostring(rawHorde), count, directCount, remoteCount, tostring(isMega), approachAngle, spreadAngle))

    if directCount <= 0 then
        sendAck(player, string.format("Spawned %d zombies (100%% Remote Virtual Horde via Popman targeting LZ).", remoteCount))
        return
    end

    local cell = getWorld():getCell()
    local spawned = 0

    -- 有効な屋外歩行可能スクエアを収集
    local validSquares = {}
    local pX = math.floor(player:getX())
    local pY = math.floor(player:getY())

    -- 1. ヘリ進入方向を中心とした円錐形（扇形コーン）から優先スキャン (半径 35〜65)
    for offset = -spreadAngle, spreadAngle, 10 do
        local angle = (approachAngle + offset) % 360
        local rad = math.rad(angle)
        for r = cfg.HORDE_SPAWN_RADIUS_MIN, cfg.HORDE_SPAWN_RADIUS_MAX, 6 do
            local sx = math.floor(lzX + r * math.cos(rad))
            local sy = math.floor(lzY + r * math.sin(rad))
            local sq = cell:getGridSquare(sx, sy, lzZ)
            if sq and sq:isOutside() and not sq:isSolid() and not sq:isSolidTrans() then
                local isSafe = false
                if SafeHouse then
                    if (SafeHouse.getSafeHouse and SafeHouse.getSafeHouse(sq)) or
                       (SafeHouse.isSafeHouse and SafeHouse.isSafeHouse(sq, nil, false)) then
                        isSafe = true
                    end
                end
                if not isSafe then
                    table.insert(validSquares, { x = sx, y = sy, z = lzZ })
                end
            end
        end
    end

    -- 2. コーン内で不足している場合、LZ周辺の全方位から補充
    if #validSquares < 10 then
        for angle = 0, 350, 20 do
            local rad = math.rad(angle)
            for r = cfg.HORDE_SPAWN_RADIUS_MIN, cfg.HORDE_SPAWN_RADIUS_MAX, 6 do
                local sx = math.floor(lzX + r * math.cos(rad))
                local sy = math.floor(lzY + r * math.sin(rad))
                local sq = cell:getGridSquare(sx, sy, lzZ)
                if sq and sq:isOutside() and not sq:isSolid() and not sq:isSolidTrans() then
                    local isSafe = false
                    if SafeHouse then
                        if (SafeHouse.getSafeHouse and SafeHouse.getSafeHouse(sq)) or
                           (SafeHouse.isSafeHouse and SafeHouse.isSafeHouse(sq, nil, false)) then
                            isSafe = true
                        end
                    end
                    if not isSafe then
                        table.insert(validSquares, { x = sx, y = sy, z = lzZ })
                    end
                end
            end
        end
    end

    -- 3. もし LZ周辺でスクエアが不足している場合（LZが遠く未ロードの場合）、
    -- プレイヤー周辺（屋外・視界外 30〜55タイル）から候補を補充
    if #validSquares < 8 then
        for angle = 0, 350, 15 do
            local rad = math.rad(angle)
            for r = 30, 55, 5 do
                local sx = math.floor(pX + r * math.cos(rad))
                local sy = math.floor(pY + r * math.sin(rad))
                local sq = cell:getGridSquare(sx, sy, lzZ)
                if sq and sq:isOutside() and not sq:isSolid() and not sq:isSolidTrans() then
                    table.insert(validSquares, { x = sx, y = sy, z = lzZ })
                end
            end
        end
    end

    if #validSquares == 0 then
        -- 最終フォールバック: プレイヤー周辺の屋外マス
        local pSq = cell:getGridSquare(pX, pY, lzZ)
        if pSq then
            table.insert(validSquares, { x = pX + 5, y = pY + 5, z = lzZ })
        end
    end

    -- 収集したスクエアからバッチ生成
    local sqCount = #validSquares
    local loopLimit = directCount * 6
    local loops = 0

    while spawned < directCount and loops < loopLimit and sqCount > 0 do
        loops = loops + 1
        local cand = validSquares[ZombRand(sqCount) + 1]
        local batch = math.min(ZombRand(4, 10), directCount - spawned)
        local success = false

        if addZombiesInOutfit then
            local ok, zombies = pcall(addZombiesInOutfit, cand.x, cand.y, cand.z, batch, nil, nil)
            if ok then
                success = true
                if zombies and zombies.size then
                    for zIdx = 0, zombies:size() - 1 do
                        local z = zombies:get(zIdx)
                        if z and z.pathToLocationF then
                            pcall(function() z:pathToLocationF(lzX, lzY, cand.z) end)
                        end
                    end
                end
            end
        end

        if success then
            spawned = spawned + batch
        end
    end

    -- LZ 地点から音響波を発生させ、湧いたゾンビを LZ へ突撃させる
    local soundRadius = cfg.SOUND_RADIUS_TILES or 400
    if isMega then soundRadius = math.floor(soundRadius * 1.5) end
    if addSound then
        addSound(nil, lzX, lzY, lzZ or 0, soundRadius, soundRadius)
    elseif IsoWorld and IsoWorld.instance and IsoWorld.instance.addSound then
        IsoWorld.instance:addSound(nil, lzX, lzY, lzZ or 0, soundRadius, soundRadius)
    end

    local ackMsg = string.format("[RadioTrader] Spawned %d zombies (Direct: %d, Remote: %d) / Target: %d. (HordeSize: %s, Mega: %s)",
        spawned + remoteCount, spawned, remoteCount, count, tostring(hName), tostring(isMega))
    log(ackMsg)
    sendAck(player, ackMsg)
end

-- ---------------------------------------------------------------------------
-- ⑦ 現在ステート照会
-- ---------------------------------------------------------------------------
local function cmdGetState(player)
    local gmd    = getPlayerGMD(player)
    local tdata  = getTimerData(player)
    local credits = gmd[RadioTrader_Config.KEY_CREDITS] or 0
    local state   = tdata.state or RadioTrader_Config.STATE_NONE
    local lzX     = gmd[RadioTrader_Config.KEY_LZ_X]
    local lzDesc  = lzX
        and ("[%d, %d, %d]"):format(
            gmd[RadioTrader_Config.KEY_LZ_X],
            gmd[RadioTrader_Config.KEY_LZ_Y],
            gmd[RadioTrader_Config.KEY_LZ_Z])
        or "None"
    local order   = gmd[RadioTrader_Config.KEY_ORDER]
    local orderDesc = order and (order.itemName .. " x" .. order.count) or "None"

    -- 残り時間計算
    local remaining = 0
    if tdata.targetHour then
        local gt = getGameTime()
        if gt then
            remaining = math.max(0, tdata.targetHour - gt:getWorldAgeHours())
        end
    end

    local minCount, maxCount, hName, rawHorde = RadioTrader_Config.getHordeCountRange()
    local hordeDesc = string.format("%s (%d-%d, raw=%s)", tostring(hName), minCount, maxCount, tostring(rawHorde))

    sendDebugCmd(player, "dbg_stateResult", {
        state     = state,
        credits   = credits,
        lzDesc    = lzDesc,
        order     = orderDesc,
        remaining = string.format("%.1f", remaining),
        hordeDesc = hordeDesc,
    })

    log("[Admin:" .. player:getUsername() .. "] State queried: " .. state .. " | Horde: " .. hordeDesc)
end

-- ---------------------------------------------------------------------------
-- ⑧ 全状態リセット
-- ---------------------------------------------------------------------------
local function cmdFullReset(player)
    local gmd   = getPlayerGMD(player)
    local tdata = getTimerData(player)
    local cfg   = RadioTrader_Config

    -- ModData を全クリア
    gmd[cfg.KEY_LZ_X]         = nil
    gmd[cfg.KEY_LZ_Y]         = nil
    gmd[cfg.KEY_LZ_Z]         = nil
    gmd[cfg.KEY_ORDER]        = nil
    -- クレジットはリセットしない（意図的なデータのため）

    tdata.state          = cfg.STATE_NONE
    tdata.targetHour     = nil
    tdata.startHour      = nil
    tdata.approachWarned = nil
    tdata.deliveryHours  = nil

    sendAck(player, "[OK] Reset complete (LZ, timer, and orders cleared). Credits preserved.")
    log("[Admin:" .. player:getUsername() .. "] Full reset executed")
end

-- ---------------------------------------------------------------------------
-- クライアントコマンド受信ハンドラ
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "RadioTrader_Debug" then return end

    -- Admin 権限を必ずサーバー側で二重確認
    if not checkAdmin(player) then
        log("SECURITY: Non-admin tried debug command: " .. player:getUsername())
        sendAck(player, "[!] Admin access denied.")
        return
    end

    if     command == "dbg_forceHeliEvent"   then cmdForceHeliEvent(player, args)
    elseif command == "dbg_forceState"       then cmdForceState(player, args)
    elseif command == "dbg_forceLZ"          then cmdForceLZ(player, args)
    elseif command == "dbg_addCredits"       then cmdAddCredits(player, args)
    elseif command == "dbg_resetCredits"     then cmdResetCredits(player)
    elseif command == "dbg_forceZombieSpawn" then cmdForceZombieSpawn(player, args)
    elseif command == "dbg_getState"         then cmdGetState(player)
    elseif command == "dbg_fullReset"        then cmdFullReset(player)
    else
        log("Unknown debug command: " .. tostring(command))
    end
end

Events.OnClientCommand.Add(onClientCommand)
