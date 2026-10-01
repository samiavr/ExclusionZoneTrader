-- =============================================================================
-- RadioTrader_ServerEngine.lua
-- [Server] 査定・取引判定・アイテム操作コア
-- =============================================================================
-- すべての物理的なアイテム操作はこのモジュールが行う。
-- クライアントは sendClientCommand 経由でのリクエストのみ送信し、
-- 実際のアイテム生成・削除はここで完結する（Dupe 防止の要）。
-- =============================================================================

RadioTrader_ServerEngine = {}

-- ---------------------------------------------------------------------------
-- 内部定数
-- ---------------------------------------------------------------------------
local MODULE_NAME = "RadioTrader_ServerEngine"

-- ---------------------------------------------------------------------------
-- ログユーティリティ
-- ---------------------------------------------------------------------------
local function log(msg)
    print("[RadioTrader][Server] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- ModData ヘルパー
-- ---------------------------------------------------------------------------
local function getUsernameSafe(player)
    if not player then return "singleplayer" end
    local uname = player.getUsername and player:getUsername()
    if not uname or uname == "" then return "singleplayer" end
    return uname
end

-- プレイヤーの GlobalModData を取得（マルチプレイ対応）
local function getPlayerGMD(player)
    return ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
end

-- LZ 座標を取得 (x, y, z)
local function getLZCoords(player)
    local gmd = getPlayerGMD(player)
    local x = gmd[RadioTrader_Config.KEY_LZ_X]
    local y = gmd[RadioTrader_Config.KEY_LZ_Y]
    local z = gmd[RadioTrader_Config.KEY_LZ_Z]
    if not x or not y or not z then return nil end
    return x, y, z
end

-- LZ のワールドオブジェクト（IsoObject / コンテナ）を取得（shared/RadioTrader_GetLZContainer へ委託）
local function getLZContainer(player)
    return RadioTrader_GetLZContainer(player)
end

-- ---------------------------------------------------------------------------
-- クレジット管理
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.getCredits(player)
    local gmd = getPlayerGMD(player)
    return gmd[RadioTrader_Config.KEY_CREDITS] or 0
end

function RadioTrader_ServerEngine.setCredits(player, amount)
    local gmd = getPlayerGMD(player)
    gmd[RadioTrader_Config.KEY_CREDITS] = math.max(0, amount)
    -- クライアントに残高更新を通知
    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_CREDIT_UPDATE, {
        credits = gmd[RadioTrader_Config.KEY_CREDITS]
    })
end

function RadioTrader_ServerEngine.addCredits(player, amount)
    RadioTrader_ServerEngine.setCredits(player,
        RadioTrader_ServerEngine.getCredits(player) + amount)
end

function RadioTrader_ServerEngine.deductCredits(player, amount)
    local current = RadioTrader_ServerEngine.getCredits(player)
    if current < amount then return false end
    RadioTrader_ServerEngine.setCredits(player, current - amount)
    return true
end

-- ---------------------------------------------------------------------------
-- 日替わりスポット品目（Daily Shop）管理
-- ---------------------------------------------------------------------------
local DAILY_MODDATA_KEY = "RadioTrader_DailyState"
local DAILY_DATA_VERSION = 3  -- 発電機5000CR・特殊品追加対応版
local REROLL_COST = 50

function RadioTrader_ServerEngine.getOrUpdateDailyShop(forceReroll)
    local dailyState = ModData.getOrCreate(DAILY_MODDATA_KEY)
    local curHour = (getGameTime and getGameTime():getWorldAgeHours()) or 0
    local curDay = math.floor(curHour / 24)

    local needRoll = forceReroll
        or (dailyState.version ~= DAILY_DATA_VERSION)
        or (dailyState.lastRolledDay == nil)
        or (dailyState.lastRolledDay ~= curDay)
        or (dailyState.items == nil)
        or (#dailyState.items == 0)

    if needRoll then
        if RadioTrader_ItemsTable_RollDailyShop then
            local newItems = RadioTrader_ItemsTable_RollDailyShop()
            dailyState.version = DAILY_DATA_VERSION
            dailyState.lastRolledDay = curDay
            dailyState.items = newItems
            log(("Daily shop generated: %d items (Day %d, v%d)"):format(#newItems, curDay, DAILY_DATA_VERSION))
        end
    else
        if dailyState.items and RadioTrader_Shop then
            RadioTrader_Shop.Daily = dailyState.items
        end
    end

    return dailyState.items or {}
end

-- ---------------------------------------------------------------------------
-- アイテム査定エンジン（shared/RadioTrader_AssessContainer へ委託）
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.assessContainer(player)
    local assessedItems, totalCredits, err, unacceptedCount, unacceptedItems =
        RadioTrader_AssessContainer(player)
    local username = getUsernameSafe(player)
    if err then
        log(("assessContainer: %s for %s"):format(tostring(err), username))
        return nil, 0, err, 0, {}
    end
    log(("assessContainer: Summary for %s -> %d items sellable, %d unaccepted, Total: %d CR"):format(
        username, #assessedItems, unacceptedCount or 0, totalCredits))
    return assessedItems, totalCredits, nil, unacceptedCount, unacceptedItems
end

-- ---------------------------------------------------------------------------
-- 売却処理 (requestSell)
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.processSell(player)
    local username = getUsernameSafe(player)
    log("processSell requested by " .. username)

    local state = RadioTrader_DeliveryTimer.getState(player)
    -- DELIVERING（ヘリが飛来し投下中）の瞬間のみコンテナ操作競合を防ぐため一時待機を要求
    if state == RadioTrader_Config.STATE_DELIVERING then
        log("processSell rejected: airdrop in progress (" .. tostring(state) .. ")")
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "DELIVERY_IN_PROGRESS", message = "Airdrop in progress. Please wait for delivery to finish." })
        return
    end

    local assessedItems, totalCredits, err, unacceptedCount = RadioTrader_ServerEngine.assessContainer(player)
    if err then
        log("processSell assess error: " .. tostring(err))
        RadioTrader_ServerEngine.sendToClient(player, "error", { errCode = err, message = err })
        return
    end

    if totalCredits <= 0 or #assessedItems == 0 then
        log("processSell: No sellable items found (totalCredits=" .. tostring(totalCredits) .. ")")
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "NO_SELLABLE_ITEMS", message = "No sellable items in LZ container." })
        return
    end

    -- アイテムを物理削除（査定対象のみ削除、対象外アイテムはそのまま残る）
    local container = getLZContainer(player)
    local removedCount = 0
    if container then
        for _, entry in ipairs(assessedItems) do
            if container.DoRemoveItem then
                container:DoRemoveItem(entry.item)
                removedCount = removedCount + 1
            elseif container.Remove then
                container:Remove(entry.item)
                removedCount = removedCount + 1
            end
        end
    end
    log(("processSell: Successfully removed %d / %d items from container (left unaccepted=%d)"):format(
        removedCount, #assessedItems, unacceptedCount or 0))

    -- クレジットを付与
    RadioTrader_ServerEngine.addCredits(player, totalCredits)
    log(username .. " sold " .. #assessedItems .. " items for " .. totalCredits .. " credits")

    -- クライアントへ売却成功通知
    RadioTrader_ServerEngine.sendToClient(player, "sellSuccess", {
        credits         = totalCredits,
        count           = #assessedItems,
        unacceptedCount = unacceptedCount or 0,
    })
end

-- ---------------------------------------------------------------------------
-- 購入処理 (requestTrade)
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.processTrade(player, args)
    -- 二重発注ガード
    local state = RadioTrader_DeliveryTimer.getState(player)
    if state ~= RadioTrader_Config.STATE_NONE
    and state ~= RadioTrader_Config.STATE_COMPLETED then
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "DELIVERY_IN_PROGRESS", message = "Delivery already in progress." })
        return
    end

    local rawItems = args and args.items
    local orderItems = {}
    local totalCost = 0
    local summaryName = ""

    if rawItems and type(rawItems) == "table" and #rawItems > 0 then
        -- 複数アイテム発注 (カート発注)
        for _, raw in ipairs(rawItems) do
            local itId = raw.itemId
            local itQty = math.max(1, tonumber(raw.quantity) or 1)
            local shopEntry = nil
            for _, catList in pairs(RadioTrader_Shop) do
                for _, entry in ipairs(catList) do
                    if entry.id == itId then shopEntry = entry; break end
                end
                if shopEntry then break end
            end

            if shopEntry then
                local unitPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(shopEntry.price) or shopEntry.price
                local subCost = unitPrice * itQty
                totalCost = totalCost + subCost
                table.insert(orderItems, {
                    itemId   = itId,
                    itemName = shopEntry.name,
                    count    = (shopEntry.count or 1) * itQty,
                    subCost  = subCost,
                })
                if summaryName == "" then
                    summaryName = shopEntry.name .. (itQty > 1 and (" x" .. itQty) or "")
                end
            end
        end
        if #orderItems > 1 then
            summaryName = summaryName .. " (+" .. (#orderItems - 1) .. " more)"
        end
    else
        -- 単一アイテム発注 (従来互換)
        local itemId    = args and args.itemId
        local quantity  = args and tonumber(args.quantity) or 1
        if not itemId then
            RadioTrader_ServerEngine.sendToClient(player, "error", { errCode = "INVALID_ITEM", message = "Invalid item ID." })
            return
        end

        local shopEntry = nil
        for _, catList in pairs(RadioTrader_Shop) do
            for _, entry in ipairs(catList) do
                if entry.id == itemId then shopEntry = entry; break end
            end
            if shopEntry then break end
        end

        if not shopEntry then
            RadioTrader_ServerEngine.sendToClient(player, "error",
                { errCode = "CANNOT_PURCHASE", message = "Item cannot be purchased." })
            return
        end

        local unitPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(shopEntry.price) or shopEntry.price
        totalCost = unitPrice * quantity
        summaryName = shopEntry.name
        table.insert(orderItems, {
            itemId   = itemId,
            itemName = shopEntry.name,
            count    = (shopEntry.count or 1) * quantity,
            subCost  = totalCost,
        })
    end

    if #orderItems == 0 then
        RadioTrader_ServerEngine.sendToClient(player, "error", { errCode = "INVALID_ITEM", message = "No valid items to order." })
        return
    end

    -- クレジット確認・引き落とし
    if not RadioTrader_ServerEngine.deductCredits(player, totalCost) then
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "NOT_ENOUGH_CREDITS", message = "Not enough credits." })
        return
    end

    -- 配達タイマー起動
    RadioTrader_DeliveryTimer.start(player)

    -- 合計アイテム個数を算出
    local totalItemCount = 0
    for _, it in ipairs(orderItems) do
        totalItemCount = totalItemCount + (it.count or 1)
    end

    -- 注文内容を保存（投下要請待ち・ヘリ到着後に配達される）
    local timerData = ModData.getOrCreate("RadioTrader_Timer_" .. getUsernameSafe(player))
    local gmd = getPlayerGMD(player)
    gmd[RadioTrader_Config.KEY_ORDER] = {
        items       = orderItems,
        itemName    = summaryName,
        totalItems  = #orderItems,
        count       = totalItemCount,
        paidCredits = totalCost,   -- 返金計算用：発注時の支払額を記録
        isMegaHorde = timerData and timerData.isMegaHorde or false,
    }

    -- クライアントへ受注通知
    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_TRADE_ACCEPTED, {
        itemName = summaryName,
        cost     = totalCost,
    })

    log(player:getUsername() .. " placed order: " .. summaryName .. " for " .. totalCost .. " credits")
end

-- ---------------------------------------------------------------------------
-- 配達アイテム生成（HeliEvent から呼ばれる）
-- B42: InventoryItemFactory.CreateItem は廃止。instanceItem() を使用する。
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.deliverItems(player)
    local gmd   = getPlayerGMD(player)
    local order = gmd[RadioTrader_Config.KEY_ORDER]
    if not order then
        log("No pending order for " .. player:getUsername() .. " - resetting delivery timer.")
        RadioTrader_DeliveryTimer.reset(player)
        return
    end

    -- getLZContainer は obj:getContainer() を返すため、戻り値は既に ItemContainer
    -- getInventory() を呼ぶと nil になる（ItemContainer は自身がインベントリ）
    local inv = getLZContainer(player)
    if not inv then
        log("LZ container not found for delivery: " .. player:getUsername())
        return
    end
    log("LZ container found: " .. tostring(inv))

    local itemList = order.items
    if not itemList then
        -- 従来データとの互換
        itemList = {
            { itemId = order.itemId, count = order.count or 1, itemName = order.itemName }
        }
    end

    -- アイテム生成（サーバーサイド）
    for _, orderItem in ipairs(itemList) do
        local targetId = orderItem.itemId
        local count = orderItem.count or 1
        local crateDef = RadioTrader_CrateDefinitions and RadioTrader_CrateDefinitions[targetId]

        if crateDef then
            -- クレート発注：ダッフルバッグを生成し内容物を充填
            for i = 1, count do
                local containerType = crateDef.container or "Base.Bag_DuffelBag"
                local duffelBag = instanceItem(containerType)
                if duffelBag then
                    local packedCount = 0
                    if RadioTrader_ItemsTable_FillDuffelBag then
                        packedCount = RadioTrader_ItemsTable_FillDuffelBag(duffelBag, crateDef)
                    end
                    inv:AddItem(duffelBag)
                    sendAddItemToContainer(inv, duffelBag)
                    log(("  + Spawned Duffel Bag (%s) packed with %d items into LZ container"):format(
                        targetId, packedCount or 0))
                else
                    log(("  [!] Failed to create duffel bag container: %s"):format(tostring(containerType)))
                end
            end
        elseif targetId == "RadioTrader_Mystery_Furniture" then
            -- 家具ミステリー発注時：ミリタリー木箱（Base.Mov_MilitaryCrate）を必ず投入！
            -- さらにバニラ家具クレート抽選テーブルから引かれた家具現品（Mov_...）があれば同封
            for i = 1, count do
                local woodCrate = instanceItem("Base.Mov_MilitaryCrate")
                if woodCrate then
                    inv:AddItem(woodCrate)
                    sendAddItemToContainer(inv, woodCrate)
                    log("  + Spawned Wooden Military Crate for Mystery Furniture")
                end

                local rolledFurnId = RadioTrader_ItemsTable_GetRandomFurniture and RadioTrader_ItemsTable_GetRandomFurniture()
                if rolledFurnId then
                    local furnItem = instanceItem(rolledFurnId)
                    if furnItem then
                        inv:AddItem(furnItem)
                        sendAddItemToContainer(inv, furnItem)
                        log(("  + Spawned Furniture Prize: %s into LZ container"):format(rolledFurnId))
                    end
                else
                    log("  [i] Furniture rolled empty - player gets military crate only")
                end
            end
        else
            for i = 1, count do
                local curTargetId = targetId
                -- 缶詰箱の発注時は、ランダムな保存食品箱から抽選して送付
                if curTargetId == "Base.CannedBolognese_Box" or string.find(curTargetId, "Canned.*_Box") then
                    if RadioTrader_ItemsTable_GetRandomCannedBox then
                        curTargetId = RadioTrader_ItemsTable_GetRandomCannedBox()
                    end
                end

                -- B42: instanceItem() でアイテム生成
                local item = instanceItem(curTargetId)
                if item then
                    inv:AddItem(item)
                    sendAddItemToContainer(inv, item)
                    log(("  + Spawned delivery item: %s into LZ container"):format(curTargetId))
                else
                    log(("  [!] instanceItem returned nil for: %s"):format(tostring(curTargetId)))
                end
            end
        end
    end

    -- 日替わり品が含まれている場合、ランダムテーブルから「おまけアイテム (+1個)」を同封！
    local bonusId = nil
    local hasDailyItem = false
    for _, it in ipairs(itemList) do
        local isCrate = RadioTrader_CrateDefinitions and RadioTrader_CrateDefinitions[it.itemId]
        local isFurn = (it.itemId == "RadioTrader_Mystery_Furniture")
        if not isCrate and not isFurn then
            hasDailyItem = true
            break
        end
    end

    if hasDailyItem and RadioTrader_DailyCrateCategories and RadioTrader_ItemsTable_RollProceduralItem then
        local catIdx = (ZombRand and (ZombRand(#RadioTrader_DailyCrateCategories) + 1)) or math.random(1, #RadioTrader_DailyCrateCategories)
        local cat = RadioTrader_DailyCrateCategories[catIdx]
        if cat and cat.dists and #cat.dists > 0 then
            local distIdx = (ZombRand and (ZombRand(#cat.dists) + 1)) or math.random(1, #cat.dists)
            local distName = cat.dists[distIdx]
            bonusId = RadioTrader_ItemsTable_RollProceduralItem(distName)
            if bonusId then
                local bonusItem = instanceItem(bonusId)
                if bonusItem then
                    inv:AddItem(bonusItem)
                    sendAddItemToContainer(inv, bonusItem)
                    log(("  + Bonus gift from merchant spawned: %s"):format(bonusId))
                end
            end
        end
    end

    -- 注文データをクリア
    gmd[RadioTrader_Config.KEY_ORDER] = nil

    -- 配達完了通知
    local isMega = (order and order.isMegaHorde)
    if isMega == nil then
        local timerData = ModData.getOrCreate("RadioTrader_Timer_" .. getUsernameSafe(player))
        isMega = timerData and timerData.isMegaHorde or false
    end

    local orderItemName = (order and order.itemName) or "Goods"
    local orderCount    = order and order.count
    if not orderCount and order and order.items then
        orderCount = 0
        for _, it in ipairs(order.items) do
            orderCount = orderCount + (it.count or 1)
        end
    end
    orderCount = orderCount or 1

    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_DELIVERY_DONE, {
        itemName      = orderItemName,
        count         = orderCount,
        bonusItemName = bonusId,
        isMegaHorde   = isMega,
    })

    log("Delivered " .. tostring(orderItemName) .. " (count: " .. tostring(orderCount) .. ")"
        .. (bonusId and (" (+Bonus: " .. tostring(bonusId) .. ")") or "")
        .. " to " .. tostring(player:getUsername()))
end

-- ---------------------------------------------------------------------------
-- クライアントへのコマンド送信ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.sendToClient(player, cmd, args)
    args = args or {}
    if isServer() then
        sendServerCommand(player, "RadioTrader", cmd, args)
    else
        -- シングルプレイヤー環境（isClient()==false のため OnServerCommand が発火しない）
        if RadioTrader_ClientBridge and RadioTrader_ClientBridge.onServerCommand then
            RadioTrader_ClientBridge.onServerCommand("RadioTrader", cmd, args)
        else
            sendServerCommand(player, "RadioTrader", cmd, args)
        end
    end
end

-- ---------------------------------------------------------------------------
-- 全クライアントへのコマンド一斉ブロードキャストヘルパー（天候・演出・サーチライト等）
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.broadcastToClients(cmd, args)
    args = args or {}
    if isServer() then
        sendServerCommand("RadioTrader", cmd, args)
    else
        if RadioTrader_ClientBridge and RadioTrader_ClientBridge.onServerCommand then
            RadioTrader_ClientBridge.onServerCommand("RadioTrader", cmd, args)
        else
            sendServerCommand("RadioTrader", cmd, args)
        end
    end
end

-- ---------------------------------------------------------------------------
-- ATM クレジット換金処理 (サーバーサイド)
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.processATMDeposit(player, isCard)
    local inv = player:getInventory()
    if not inv then return end

    local typeToSearch = isCard and "CreditCard" or "Money"
    local item = inv:getFirstTypeRecurse(typeToSearch)

    if not item then
        RadioTrader_ServerEngine.sendToClient(player, "error", { errCode = "INVALID_ITEM", message = "Target item not found." })
        return
    end

    local creditsToAdd = 0

    if isCard then
        -- クレジットカード：500〜3000のランダムクレジット
        creditsToAdd = 500 + ZombRand(2501)
        inv:Remove(item)
        log(player:getUsername() .. " hacked ATM with CreditCard. Added " .. creditsToAdd .. " credits.")
    else
        local count = 1
        creditsToAdd = 20
        inv:Remove(item)
        log(player:getUsername() .. " deposited Money at ATM. Added " .. creditsToAdd .. " credits.")
    end

    RadioTrader_ServerEngine.addCredits(player, creditsToAdd)
    player:Say("+ " .. tostring(creditsToAdd) .. " CR")
end

-- ---------------------------------------------------------------------------
-- クライアントコマンド受信ハンドラ
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "RadioTrader" then return end
    log(("onClientCommand: [%s] from %s"):format(tostring(command), getUsernameSafe(player)))

    if command == "setLZ" then
        if not args or not args.x or not args.y then return end
        local gmd = getPlayerGMD(player)
        gmd[RadioTrader_Config.KEY_LZ_X] = math.floor(args.x)
        gmd[RadioTrader_Config.KEY_LZ_Y] = math.floor(args.y)
        gmd[RadioTrader_Config.KEY_LZ_Z] = math.floor(args.z or 0)
        log(("LZ set for %s: [%d, %d, %d]"):format(getUsernameSafe(player), args.x, args.y, args.z or 0))
        RadioTrader_ServerEngine.sendToClient(player, "lzConfirmed", {
            x = args.x, y = args.y, z = args.z or 0
        })

    elseif command == "clearLZ" then
        local gmd = getPlayerGMD(player)
        gmd[RadioTrader_Config.KEY_LZ_X] = nil
        gmd[RadioTrader_Config.KEY_LZ_Y] = nil
        gmd[RadioTrader_Config.KEY_LZ_Z] = nil
        log("LZ cleared for " .. getUsernameSafe(player))
        RadioTrader_ServerEngine.sendToClient(player, "lzCleared", {})

    elseif command == RadioTrader_Config.CMD_ATM_CARD then
        RadioTrader_ServerEngine.processATMDeposit(player, true)

    elseif command == RadioTrader_Config.CMD_ATM_CASH then
        RadioTrader_ServerEngine.processATMDeposit(player, false)

    elseif command == RadioTrader_Config.CMD_REQUEST_SELL then
        RadioTrader_ServerEngine.processSell(player)

    elseif command == RadioTrader_Config.CMD_REQUEST_TRADE then
        RadioTrader_ServerEngine.processTrade(player, args)

    elseif command == "requestAssessment" then
        -- 査定額の表示のみ（アイテム削除なし）
        local assessedItems, totalCredits, err, unacceptedCount = RadioTrader_ServerEngine.assessContainer(player)
        if err then
            log("requestAssessment error: " .. tostring(err))
            RadioTrader_ServerEngine.sendToClient(player, "error", { message = err })
        else
            local acceptedCount = assessedItems and #assessedItems or 0
            log(("requestAssessment result for %s: %d CR (accepted=%d, unaccepted=%d)"):format(
                getUsernameSafe(player), totalCredits, acceptedCount, unacceptedCount or 0))
            RadioTrader_ServerEngine.sendToClient(player, "assessmentResult", {
                credits         = totalCredits,
                acceptedCount   = acceptedCount,
                unacceptedCount = unacceptedCount or 0,
            })
        end

    elseif command == "requestState" then
        -- 配達ステート・残高を送信（UI再開時のリフレッシュ）
        local state   = RadioTrader_DeliveryTimer.getState(player)
        local credits = RadioTrader_ServerEngine.getCredits(player)
        RadioTrader_ServerEngine.sendToClient(player, "stateRefresh", {
            state   = state,
            credits = credits,
        })

    elseif command == RadioTrader_Config.CMD_REQUEST_DROP then
        -- 手動投下要請（READY_FOR_DROP 時のみ有効）
        local cfg   = RadioTrader_Config
        local state = RadioTrader_DeliveryTimer.getState(player)
        if state ~= cfg.STATE_READY_FOR_DROP then
            RadioTrader_ServerEngine.sendToClient(player, "error",
                { errCode = "NOT_READY_FOR_DROP", message = "Not ready for drop." })
            return
        end

        -- LZ 近接チェック（プレイヤーが LZ から 50 タイル以内か）
        local lzX, lzY, lzZ = getLZCoords(player)
        if not lzX then
            RadioTrader_ServerEngine.sendToClient(player, "error",
                { errCode = "LZ_NOT_SET", message = "LZ not registered." })
            return
        end
        local px = player:getX()
        local py = player:getY()
        local dist = math.sqrt((px - lzX)^2 + (py - lzY)^2)
        if dist > cfg.DROP_REQUEST_RANGE_TILES then
            RadioTrader_ServerEngine.sendToClient(player, "error",
                { errCode = "LZ_TOO_FAR", message = "Too far from LZ." })
            return
        end

        -- 要請受理: DELIVERING へ遷移しヘリイベント発動
        local data = ModData.getOrCreate("RadioTrader_Timer_" .. getUsernameSafe(player))
        data.state = cfg.STATE_DELIVERING
        RadioTrader_HeliEvent.trigger(player, data.isMegaHorde or false)
        log(getUsernameSafe(player) .. " manually requested drop (MegaHorde: " .. tostring(data.isMegaHorde) .. ") at dist=" .. math.floor(dist))

    elseif command == "requestDailyShop" then
        -- 日替わりショップ同期リクエスト
        local dailyItems = RadioTrader_ServerEngine.getOrUpdateDailyShop(false)
        RadioTrader_ServerEngine.sendToClient(player, "syncDailyShop", {
            items = dailyItems
        })

    elseif command == "rerollDaily" then
        -- 周波数再探索（リロール）処理 (50 CR 消費)
        local curCredits = RadioTrader_ServerEngine.getCredits(player)
        if curCredits < REROLL_COST then
            RadioTrader_ServerEngine.sendToClient(player, "error", {
                errCode = "NOT_ENOUGH_CREDITS_REROLL",
                message = "Not enough credits to rescan frequencies."
            })
            return
        end

        -- クレジット引き落とし & 強制再抽選
        RadioTrader_ServerEngine.deductCredits(player, REROLL_COST)
        local newDaily = RadioTrader_ServerEngine.getOrUpdateDailyShop(true)
        log(("%s paid %d CR to reroll daily frequencies -> %d new items"):format(
            getUsernameSafe(player), REROLL_COST, #newDaily))

        RadioTrader_ServerEngine.sendToClient(player, "rerollSuccess", {
            items = newDaily,
            cost  = REROLL_COST,
            remainingCredits = RadioTrader_ServerEngine.getCredits(player)
        })
    end
end

Events.OnClientCommand.Add(onClientCommand)
