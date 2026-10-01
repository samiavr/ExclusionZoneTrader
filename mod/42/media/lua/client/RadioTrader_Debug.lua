-- =============================================================================
-- RadioTrader_Debug.lua
-- [Client] 管理者専用インゲームデバッグメニュー
-- =============================================================================
-- isAdmin() または isDebug() が true のプレイヤーにのみ表示される
-- 右クリックサブメニュー「[無線] [RadioTrader Debug]」を追加する。
--
-- デバッグ機能一覧:
--   ① ヘリイベント強制発動
--   ② タイマー強制進行 (→APPROACHING / →DELIVERING)
--   ③ LZ 強制登録（屋外判定スキップ）
--   ④ クレジット付与 (+100 / +500 / +1000 / +9999)
--   ⑤ クレジットリセット (→0)
--   ⑥ ゾンビスポーンのみテスト（ヘリ演出なし）
--   ⑦ 現在のステート照会（画面に表示）
--   ⑧ 全状態リセット
-- =============================================================================

RadioTrader_Debug = {}

-- ---------------------------------------------------------------------------
-- デバッグ有効判定（Admin または Debug モード）
-- ---------------------------------------------------------------------------
local function isDebugEnabled(player)
    if not player then return false end
    if getDebug and getDebug() then return true end
    if getCore and getCore().getDebug and getCore():getDebug() then return true end
    if not isServer() and not isClient() then return true end
    if player.isAdmin and player:isAdmin() then return true end
    local access = player.getAccessLevel and player:getAccessLevel()
    if access == "Admin" or access == "admin" then return true end
    return false
end

-- ---------------------------------------------------------------------------
-- デバッグログ（チャットに表示）
-- ---------------------------------------------------------------------------
local function dbgLog(player, msg, r, g, b)
    r = r or 0.4; g = g or 1.0; b = b or 0.6
    -- ゲーム内チャット（デバッグチャンネル）に出力
    if player.addLineChatElement then
        player:addLineChatElement("[RT-DEBUG] " .. msg, r, g, b)
    end
    print("[RadioTrader][DEBUG] " .. msg)
end

-- ---------------------------------------------------------------------------
-- サーバーへデバッグコマンドを送信するヘルパー
-- ---------------------------------------------------------------------------
local function sendDebug(player, cmd, args)
    sendClientCommand(player, "RadioTrader_Debug", cmd, args or {})
end

-- ---------------------------------------------------------------------------
-- ステート表示（クライアントサイドで UI も更新する）
-- ---------------------------------------------------------------------------
local function showCurrentState(player)
    sendDebug(player, "dbg_getState", {})
end

-- ---------------------------------------------------------------------------
-- 右クリックメニュー追加
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- 翻訳ヘルパー (PZ i18n 連携 / 未ロード時は ASCII 英語フォールバック)
-- ---------------------------------------------------------------------------
local function tr(key, defaultText)
    if getTextOrNull then
        local res = getTextOrNull(key)
        if res then return res end
    end
    if getText then
        local res = getText(key)
        if res and res ~= key then return res end
    end
    return defaultText or key
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- 管理者 / デバッグモードでなければ何もしない
    if not isDebugEnabled(player) then return end

    -- ===== サブメニュー構築 =====
    local parentLabel = tr("ContextMenu_RadioTrader_Debug", "[DEBUG] [RadioTrader Debug]")
    local parentOpt   = context:addOption(parentLabel, player, nil)
    local sub         = context:getNew(context)
    context:addSubMenu(parentOpt, sub)

    -- ① ヘリイベント強制発動
    sub:addOption(tr("ContextMenu_RadioTrader_ForceHeli", "[Heli] Force Heli Event (Normal)"), player, function(pl)
        dbgLog(pl, "Force trigger heli event (Normal)...")
        sendDebug(pl, "dbg_forceHeliEvent", { isMegaHorde = false })
    end)
    sub:addOption(tr("ContextMenu_RadioTrader_ForceHeliMega", "[Heli] Force Heli Event (MEGA HORDE 2.5x)"), player, function(pl)
        dbgLog(pl, "[!] Force trigger heli event with MEGA HORDE (2.5x)!")
        sendDebug(pl, "dbg_forceHeliEvent", { isMegaHorde = true })
    end)

    -- ② タイマー強制進行
    local timerOpt = sub:addOption(tr("ContextMenu_RadioTrader_ForceTimer", "[Timer] Force Advance >"), player, nil)
    local timerSub = context:getNew(context)
    sub:addSubMenu(timerOpt, timerSub)

    timerSub:addOption(tr("ContextMenu_RadioTrader_TimerApproaching", "-> APPROACHING (Normal)"), player, function(pl)
        dbgLog(pl, "Advancing state to APPROACHING (Normal)...")
        sendDebug(pl, "dbg_forceState", { state = "APPROACHING", isMegaHorde = false })
    end)
    timerSub:addOption(tr("ContextMenu_RadioTrader_TimerApproachingMega", "-> APPROACHING (MEGA HORDE)"), player, function(pl)
        dbgLog(pl, "[!] Advancing state to APPROACHING with MEGA HORDE warning!")
        sendDebug(pl, "dbg_forceState", { state = "APPROACHING", isMegaHorde = true })
    end)
    timerSub:addOption(tr("ContextMenu_RadioTrader_TimerReadyForDrop", "-> READY_FOR_DROP"), player, function(pl)
        dbgLog(pl, "Advancing state to READY_FOR_DROP (Drop Request unlocked)...")
        sendDebug(pl, "dbg_forceState", { state = "READY_FOR_DROP" })
    end)
    timerSub:addOption(tr("ContextMenu_RadioTrader_TimerDelivering", "-> DELIVERING"), player, function(pl)
        dbgLog(pl, "Advancing state to DELIVERING (Instant Drop)...")
        sendDebug(pl, "dbg_forceState", { state = "DELIVERING" })
    end)
    timerSub:addOption(tr("ContextMenu_RadioTrader_TimerCompleted", "-> COMPLETED"), player, function(pl)
        dbgLog(pl, "Skipping state to COMPLETED...")
        sendDebug(pl, "dbg_forceState", { state = "COMPLETED" })
    end)

    -- ③ LZ 強制登録（右クリック対象コンテナに）
    local hasContainer = false
    for _, obj in ipairs(worldObjects) do
        if obj.getContainer and obj:getContainer() then
            hasContainer = true
            sub:addOption(tr("ContextMenu_RadioTrader_ForceLZ", "[LZ] Force Register LZ on this Container"), player, function(pl)
                local sq = obj:getSquare()
                if not sq then
                    dbgLog(pl, "ERROR: Square not found", 1, 0.3, 0.3)
                    return
                end
                local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
                -- ローカル ModData に即時書き込み
                local md = pl:getModData()
                md[RadioTrader_Config.KEY_LZ_X] = cx
                md[RadioTrader_Config.KEY_LZ_Y] = cy
                md[RadioTrader_Config.KEY_LZ_Z] = cz
                -- サーバーにも通知
                sendDebug(pl, "dbg_forceLZ", { x = cx, y = cy, z = cz })
                dbgLog(pl, ("Force LZ Registered: [%d, %d, %d]"):format(cx, cy, cz))
            end)
            break
        end
    end
    if not hasContainer then
        sub:addOption(tr("ContextMenu_RadioTrader_ForceLZ_NoCont", "[LZ] (Right-click a container)"), nil, nil)
    end

    -- ④ クレジット付与
    local credOpt = sub:addOption(tr("ContextMenu_RadioTrader_AddCredits", "[Credits] Add Credits >"), player, nil)
    local credSub = context:getNew(context)
    sub:addSubMenu(credOpt, credSub)

    local amounts = { 100, 500, 1000, 9999 }
    for _, amt in ipairs(amounts) do
        credSub:addOption("+" .. amt .. " CR", player, function(pl)
            sendDebug(pl, "dbg_addCredits", { amount = amt })
            dbgLog(pl, "+" .. amt .. " CR added")
        end)
    end

    -- ⑤ クレジットリセット
    sub:addOption(tr("ContextMenu_RadioTrader_ResetCredits", "[Credits] Reset Credits to 0"), player, function(pl)
        sendDebug(pl, "dbg_resetCredits", {})
        dbgLog(pl, "Credits reset to 0", 1, 0.7, 0.2)
    end)

    -- ⑥ ゾンビスポーンのみテスト
    sub:addOption(tr("ContextMenu_RadioTrader_ForceHorde", "[Zombie] Spawn Horde Only (Normal)"), player, function(pl)
        dbgLog(pl, "Spawning zombie horde test (Normal)...")
        sendDebug(pl, "dbg_forceZombieSpawn", { isMegaHorde = false })
    end)
    sub:addOption(tr("ContextMenu_RadioTrader_ForceHordeMega", "[Zombie] Spawn Horde Only (MEGA HORDE 2.5x)"), player, function(pl)
        dbgLog(pl, "[!] Spawning zombie horde test with MEGA HORDE (2.5x)!")
        sendDebug(pl, "dbg_forceZombieSpawn", { isMegaHorde = true })
    end)

    -- ⑦ 現在のステート照会
    sub:addOption(tr("ContextMenu_RadioTrader_ShowState", "[State] Print Current State"), player, function(pl)
        showCurrentState(pl)
    end)

    -- 区切り線
    sub:addOption("---------------------", nil, nil)

    -- ⑧ 全状態リセット（LZ解除含む）
    sub:addOption(tr("ContextMenu_RadioTrader_FullReset", "[!] Full Reset (LZ, Timer, Orders)"), player, function(pl)
        -- ローカル ModData もクリア
        local md = pl:getModData()
        md[RadioTrader_Config.KEY_LZ_X] = nil
        md[RadioTrader_Config.KEY_LZ_Y] = nil
        md[RadioTrader_Config.KEY_LZ_Z] = nil
        sendDebug(pl, "dbg_fullReset", {})
        dbgLog(pl, "All RadioTrader states have been reset.", 1, 0.5, 0.1)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ---------------------------------------------------------------------------
-- サーバーからのデバッグ応答を受信して画面表示
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "RadioTrader_Debug" then return end

    local player = getPlayer()
    if not player then return end

    if command == "dbg_stateResult" then
        local lines = {
            "===== RadioTrader Debug State =====",
            "State:     " .. (args.state     or "?"),
            "Credits:   " .. (args.credits   or "?") .. " CR",
            "LZ:        " .. (args.lzDesc    or "None"),
            "Order:     " .. (args.order     or "None"),
            "TimerRem:  " .. (args.remaining or "?") .. " h",
            "HordeCfg:  " .. (args.hordeDesc or "?"),
            "===================================",
        }
        for _, line in ipairs(lines) do
            dbgLog(player, line, 0.4, 0.9, 1.0)
        end

        -- UI が開いていれば通知
        if RadioTrader_UI.instance and RadioTrader_UI.instance:isVisible() then
            RadioTrader_UI.instance:onServerNotify("stateRefresh", {
                state   = args.state,
                credits = tonumber(args.credits) or 0,
            })
        end

    elseif command == "dbg_creditResult" then
        dbgLog(player, "Credits updated: " .. (args.credits or "?") .. " CR", 0.4, 1.0, 0.6)
        if RadioTrader_UI.instance and RadioTrader_UI.instance:isVisible() then
            RadioTrader_UI.instance:onServerNotify("creditUpdate", { credits = args.credits })
        end

    elseif command == "dbg_ack" then
        dbgLog(player, args.msg or "Command executed", 0.4, 0.9, 1.0)
    end
end

RadioTrader_Debug.onServerCommand = onServerCommand
Events.OnServerCommand.Add(onServerCommand)

