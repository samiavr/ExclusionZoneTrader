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

-- 安全なアイテム削除ヘルパー (Javaメソッドのpcall保護・マルチプレイ同期対応)
local function safeRemoveItemFromContainer(container, item)
    if not container or not item then return false end
    local ok = pcall(function() container:DoRemoveItem(item) end)
    if ok then return true end
    ok = pcall(function() container:Remove(item) end)
    if ok then return true end
    ok = pcall(function() container:removeItemOnServer(item) end)
    if ok then return true end
    return false
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
-- 契約農園: 種プール管理
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.getSeedPool(player)
    local gmd = getPlayerGMD(player)
    if not gmd[RadioTrader_Config.KEY_SEED_POOL] then
        gmd[RadioTrader_Config.KEY_SEED_POOL] = {}
    end
    return gmd[RadioTrader_Config.KEY_SEED_POOL]
end

function RadioTrader_ServerEngine.sendSeedPoolUpdate(player)
    local pool = RadioTrader_ServerEngine.getSeedPool(player)
    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_SEED_POOL_UPDATE, {
        seedPool = pool
    })
end

function RadioTrader_ServerEngine.addSeedsToPool(player, poolKey, amount)
    if not poolKey or not amount or amount <= 0 then return end
    local pool = RadioTrader_ServerEngine.getSeedPool(player)
    pool[poolKey] = (pool[poolKey] or 0) + amount
    RadioTrader_ServerEngine.sendSeedPoolUpdate(player)
    log(("Seed pool added: %s +%d (Total: %d) for %s"):format(poolKey, amount, pool[poolKey], getUsernameSafe(player)))
end

function RadioTrader_ServerEngine.deductSeedsFromPool(player, poolKey, amount)
    if not poolKey or not amount or amount <= 0 then return false end
    local pool = RadioTrader_ServerEngine.getSeedPool(player)
    local cur = pool[poolKey] or 0
    if cur < amount then return false end
    pool[poolKey] = cur - amount
    RadioTrader_ServerEngine.sendSeedPoolUpdate(player)
    log(("Seed pool deducted: %s -%d (Remaining: %d) for %s"):format(poolKey, amount, pool[poolKey], getUsernameSafe(player)))
    return true
end

-- ---------------------------------------------------------------------------
-- 日替わりスポット品目（Daily Shop）管理
-- ---------------------------------------------------------------------------
local DAILY_MODDATA_KEY = "RadioTrader_DailyState"
local DAILY_DATA_VERSION = 10  -- プレミアム枠価格本格化（革大4000/粘土1800/布1500等）
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

    if not assessedItems or #assessedItems == 0 then
        log("processSell: No sellable items found (totalCredits=" .. tostring(totalCredits) .. ")")
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "NO_SELLABLE_ITEMS", message = "No sellable or deposit items in LZ container." })
        return
    end

    -- アイテムを物理削除（査定対象のみ削除、対象外アイテムはそのまま残る）
    -- ＋ 種アイテムのプール加算
    local container = getLZContainer(player)
    local removedCount = 0
    local seedsAdded = 0
    local poolAddedMap = {}

    if container then
        for _, entry in ipairs(assessedItems) do
            local targetCont = entry.container or container
            if entry.item then
                if safeRemoveItemFromContainer(targetCont, entry.item) then
                    removedCount = removedCount + 1
                end
            end
            if entry.isSeed and entry.poolKey then
                local pKey = entry.poolKey
                local count = entry.poolCount or 1
                poolAddedMap[pKey] = (poolAddedMap[pKey] or 0) + count
                seedsAdded = seedsAdded + count
            end
        end
    end

    -- プールへの加算を実行
    for pKey, count in pairs(poolAddedMap) do
        RadioTrader_ServerEngine.addSeedsToPool(player, pKey, count)
    end
    log(("processSell: Successfully removed %d / %d items from container (seeds pooled=%d, left unaccepted=%d)"):format(
        removedCount, #assessedItems, seedsAdded, unacceptedCount or 0))

    -- クレジットを付与（0 CRより大きい場合のみ）
    if totalCredits > 0 then
        RadioTrader_ServerEngine.addCredits(player, totalCredits)
    end
    log(username .. " processed " .. #assessedItems .. " items for " .. totalCredits .. " credits (+ " .. seedsAdded .. " seeds pooled)")

    -- クライアントへ売却成功通知
    RadioTrader_ServerEngine.sendToClient(player, "sellSuccess", {
        credits         = totalCredits,
        count           = #assessedItems,
        seedsAdded      = seedsAdded,
        unacceptedCount = unacceptedCount or 0,
    })
    RadioTrader_ServerEngine.sendSeedPoolUpdate(player)
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
                    subCat   = shopEntry.subCat,
                    isCrop   = shopEntry.isCrop,
                    poolKey  = shopEntry.poolKey,
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
            subCat   = shopEntry.subCat,
            isCrop   = shopEntry.isCrop,
            poolKey  = shopEntry.poolKey,
        })
    end

    if #orderItems == 0 then
        RadioTrader_ServerEngine.sendToClient(player, "error", { errCode = "INVALID_ITEM", message = "No valid items to order." })
        return
    end

    -- 作物発注における種プール事前チェック
    local currentPool = RadioTrader_ServerEngine.getSeedPool(player)
    local requiredSeeds = {}
    for _, it in ipairs(orderItems) do
        if it.isCrop and it.poolKey then
            requiredSeeds[it.poolKey] = (requiredSeeds[it.poolKey] or 0) + (it.count or 1)
        end
    end
    for pKey, needed in pairs(requiredSeeds) do
        local available = currentPool[pKey] or 0
        if available < needed then
            RadioTrader_ServerEngine.sendToClient(player, "error", {
                errCode = "NOT_ENOUGH_SEEDS",
                message = "Not enough seeds in pool for " .. tostring(pKey) .. " (Available: " .. available .. ", Required: " .. needed .. ")"
            })
            return
        end
    end

    -- ドロップボックス内の不用品査定（下取り相殺用）
    local container, obj = RadioTrader_GetLZContainer and RadioTrader_GetLZContainer(player)
    local assessedItems = {}
    local assessedCredits = 0
    if container then
        local items, totalCr, err = RadioTrader_AssessContainer(player)
        if items and #items > 0 then
            assessedItems = items
            assessedCredits = totalCr or 0
        end
    end

    -- 利用可能予算（手持ちCR + ドロップボックス下取り査定額）の確認
    local playerCredits = RadioTrader_ServerEngine.getCredits(player)
    local availableCredits = playerCredits + assessedCredits
    if availableCredits < totalCost then
        RadioTrader_ServerEngine.sendToClient(player, "error",
            { errCode = "NOT_ENOUGH_CREDITS", message = "Not enough credits." })
        return
    end

    -- ドロップボックス内の不用品を一括回収（削除）＆種下取りプール加算
    local removedTradeInCount = 0
    local tradeInSeedsAdded = 0
    local poolAddedMap = {}
    if #assessedItems > 0 and container then
        for _, entry in ipairs(assessedItems) do
            local targetCont = entry.container or container
            if entry.item then
                if safeRemoveItemFromContainer(targetCont, entry.item) then
                    removedTradeInCount = removedTradeInCount + 1
                end
            end
            if entry.isSeed and entry.poolKey then
                local pKey = entry.poolKey
                local count = entry.poolCount or 1
                poolAddedMap[pKey] = (poolAddedMap[pKey] or 0) + count
                tradeInSeedsAdded = tradeInSeedsAdded + count
            end
        end
        for pKey, count in pairs(poolAddedMap) do
            RadioTrader_ServerEngine.addSeedsToPool(player, pKey, count)
        end
        log(("processTrade: Collected %d items from LZ container (Trade-in value: %d CR, Seeds pooled: %d)"):format(
            removedTradeInCount, assessedCredits, tradeInSeedsAdded))
    end

    -- クレジット清算（相殺計算: netDiff = 査定額 - 購入代金）
    local netDiff = assessedCredits - totalCost
    if netDiff > 0 then
        -- 査定額の方が大きい場合：余剰差額を手持ちCRに加算！
        RadioTrader_ServerEngine.addCredits(player, netDiff)
    elseif netDiff < 0 then
        -- 購入代金の方が多い場合：不足分を手持ちCRから引き落とし！
        RadioTrader_ServerEngine.deductCredits(player, -netDiff)
    end

    -- 契約農園: 発注した作物の種プールを消費
    for pKey, needed in pairs(requiredSeeds) do
        RadioTrader_ServerEngine.deductSeedsFromPool(player, pKey, needed)
    end

    -- 配達タイマー起動
    RadioTrader_DeliveryTimer.start(player)

    -- 合計アイテム個数を算出
    local totalItemCount = 0
    for _, it in ipairs(orderItems) do
        totalItemCount = totalItemCount + (it.count or 1)
    end

    -- 不用品の中に家具 (Furniture) または 軍用品 (Military) が含まれていたかチェック
    local hasValuableSalvage = false
    if #assessedItems > 0 then
        for _, entry in ipairs(assessedItems) do
            if entry.category == "Furniture" or entry.category == "Military" then
                hasValuableSalvage = true
                break
            end
        end
    end

    -- 家具または軍用品が含まれていれば 40% の確率でランチボックス差し入れ当選！
    local bonusLunchbox = false
    if hasValuableSalvage then
        local roll = (ZombRand and ZombRand(100)) or math.random(0, 99)
        if roll < 40 then
            bonusLunchbox = true
            log("processTrade: Crew lunchbox bonus rolled! (Valuable salvage detected)")
        end
    end

    -- 注文内容を保存（投下要請待ち・ヘリ到着後に配達される）
    local timerData = ModData.getOrCreate("RadioTrader_Timer_" .. getUsernameSafe(player))
    local gmd = getPlayerGMD(player)
    gmd[RadioTrader_Config.KEY_ORDER] = {
        items         = orderItems,
        itemName      = summaryName,
        totalItems    = #orderItems,
        count         = totalItemCount,
        paidCredits   = totalCost,   -- 返金計算用：発注時の支払額を記録
        isMegaHorde   = timerData and timerData.isMegaHorde or false,
        bonusLunchbox = bonusLunchbox,
    }

    -- クレジット残高をクライアントに同期
    RadioTrader_ServerEngine.sendCreditUpdate(player)

    -- 注文品に「俺のおやつ (TraderStash)」が含まれているかチェック
    local hasTraderStash = false
    for _, it in ipairs(orderItems) do
        if it.subCat == "TraderStash" then
            hasTraderStash = true
            break
        end
    end

    -- クライアントへ受注通知（下取り相殺情報・俺のおやつフラグも同封）
    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_TRADE_ACCEPTED, {
        itemName       = summaryName,
        cost           = totalCost,
        tradeInCredits = assessedCredits,
        tradeInCount   = removedTradeInCount,
        newCredits     = RadioTrader_ServerEngine.getCredits(player),
        hasTraderStash = hasTraderStash,
    })

    log(player:getUsername() .. " placed order: " .. summaryName .. " (Cost: " .. totalCost .. " CR, TradeIn: " .. assessedCredits .. " CR)")
end

-- ---------------------------------------------------------------------------
-- 配達アイテム生成（HeliEvent から呼ばれる）
-- B42: InventoryItemFactory.CreateItem は廃止。instanceItem() を使用する。
-- ---------------------------------------------------------------------------
-- アイテムへの落下衝撃ダメージ（耐久度および食品鮮度を1割削る）
local function applyImpactDamage(item)
    if not item then return end

    -- 1. 耐久度 (Condition) の1割削れ (90%に減少、最低1)
    if item.getCondition and item.setCondition then
        local curCond = item:getCondition()
        if curCond and curCond > 1 then
            local newCond = math.max(1, math.floor(curCond * 0.9))
            item:setCondition(newCond)
        end
    end

    -- 2. 食品・農作物の鮮度 (Age) の1割削れ
    -- 腐敗開始時間(offAge/offAgeMax)の10%分、Ageを加算して劣化させる
    if item.getAge and item.setAge then
        local offAge = 0
        if item.getOffAgeMax and item:getOffAgeMax() and item:getOffAgeMax() > 0 then
            offAge = item:getOffAgeMax()
        elseif item.getOffAge and item:getOffAge() and item:getOffAge() > 0 then
            offAge = item:getOffAge()
        end

        local curAge = item:getAge() or 0
        if offAge > 0 then
            item:setAge(curAge + (offAge * 0.1))
        elseif curAge > 0 then
            item:setAge(curAge * 1.1)
        else
            item:setAge(1.0)
        end
    end
end

-- コンテナ内の全アイテムに落下衝撃ダメージを再帰適用
local function applyImpactDamageToContainerItems(container)
    if not container then return end
    local items = container:getItems()
    if items then
        for j = 0, items:size() - 1 do
            local it = items:get(j)
            if it then
                applyImpactDamage(it)
                if it.getItemContainer and it:getItemContainer() then
                    applyImpactDamageToContainerItems(it:getItemContainer())
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- 配達アイテム生成（HeliEvent から呼ばれる）
-- B42: InventoryItemFactory.CreateItem は廃止。instanceItem() を使用する。
-- ボックス破壊時はLZ地面への直接ワールドドロップ（フォールバック）を行い、耐久・鮮度を1割削る。
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.deliverItems(player)
    local gmd   = getPlayerGMD(player)
    local order = gmd[RadioTrader_Config.KEY_ORDER]
    if not order then
        log("No pending order for " .. player:getUsername() .. " - resetting delivery timer.")
        RadioTrader_DeliveryTimer.reset(player)
        return
    end

    local inv = getLZContainer(player)
    local isFallbackDrop = false
    local dropSquare = nil

    if not inv then
        local lx, ly, lz = getLZCoords(player)
        if lx and ly and lz and getCell() then
            dropSquare = getCell():getGridSquare(lx, ly, lz)
        end
        if not dropSquare and player and player.getCurrentSquare then
            dropSquare = player:getCurrentSquare()
        end
        if not dropSquare then
            log("LZ square not found for delivery: " .. player:getUsername())
            return
        end
        isFallbackDrop = true
        log("LZ container missing! Switching to FALLBACK GROUND DROP at (" .. tostring(lx) .. "," .. tostring(ly) .. "," .. tostring(lz) .. ")")
    else
        log("LZ container found: " .. tostring(inv))
    end

    -- 配達アイテム配備ヘルパー（コンテナ格納または地面ドロップ＋衝撃1割損耗）
    local function placeItem(item)
        if not item then return end
        if isFallbackDrop then
            applyImpactDamage(item)
            if item.getItemContainer and item:getItemContainer() then
                applyImpactDamageToContainerItems(item:getItemContainer())
            end
            if dropSquare then
                dropSquare:AddWorldInventoryItem(item, 0.5, 0.5, 0)
            end
            log(("  [!] Direct ground dropped item with 10%% wear: %s"):format(
                tostring(item.getFullType and item:getFullType() or item)))
        else
            if inv then
                inv:AddItem(item)
                sendAddItemToContainer(inv, item)
            end
        end
    end

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
                    placeItem(duffelBag)
                    log(("  + Spawned Duffel Bag (%s) packed with %d items (fallback=%s)"):format(
                        targetId, packedCount or 0, tostring(isFallbackDrop)))
                else
                    log(("  [!] Failed to create duffel bag container: %s"):format(tostring(containerType)))
                end
            end
        elseif targetId == "RadioTrader_Mystery_Furniture" then
            -- 家具ミステリー発注時：バニラ家具クレート抽選テーブルから引かれた家具現品（Mov_...）を届ける
            for i = 1, count do
                local rolledFurnId = RadioTrader_ItemsTable_GetRandomFurniture and RadioTrader_ItemsTable_GetRandomFurniture()
                if not rolledFurnId then
                    -- フォールバック（家具が引けなかった場合のみ木箱）
                    rolledFurnId = "Base.Mov_MilitaryCrate"
                end

                local furnItem = instanceItem(rolledFurnId)
                if furnItem then
                    placeItem(furnItem)
                    log(("  + Spawned Mystery Furniture: %s (fallback=%s)"):format(
                        rolledFurnId, tostring(isFallbackDrop)))
                else
                    log(("  [!] Failed to instance furniture item: %s"):format(tostring(rolledFurnId)))
                end
            end
        elseif orderItem.isCrop or (RadioTrader_CropYieldDefaults and RadioTrader_CropYieldDefaults[targetId]) then
            -- 契約農園・農作物交換発注時：農作物用の箱(大) (Base.ProduceBox_Large) に詰めて配達 ＆ 農業経験値（Farming XP）付与
            local farmingLevel = 0
            if player and player.getPerkLevel and Perks and Perks.Farming then
                farmingLevel = player:getPerkLevel(Perks.Farming) or 0
            end

            -- 1. 発注された作物の数（口数）だけ、そのレベルで収穫した時の個数の30〜75%を計算して合算
            local totalProduceCount = 0
            for i = 1, count do
                local singleHarvest = 1
                if RadioTrader_CalculateCropYield then
                    singleHarvest = RadioTrader_CalculateCropYield(targetId, farmingLevel)
                end
                totalProduceCount = totalProduceCount + math.max(1, singleHarvest)
            end

            -- 2. 発注された作物の数だけ、そのレベルで作物を収穫した場合の経験値を取得
            -- バニラ基準: 1回の収穫あたり 6 XP
            local xpPerHarvest = 6
            local totalXP = xpPerHarvest * count
            if player and player.getXp and Perks and Perks.Farming then
                local xpObj = player:getXp()
                if xpObj and xpObj.AddXP then
                    xpObj:AddXP(Perks.Farming, totalXP, false, true, true)
                    log(("  + Awarded %d Farming XP to %s for %d crop deliveries"):format(
                        totalXP, player:getUsername(), count))
                end
            end

            -- 3. 農作物用の箱(大) (Base.ProduceBox_Large) を生成して作物を格納
            local boxItem = instanceItem("Base.ProduceBox_Large")
            if not boxItem then
                -- フォールバック
                boxItem = instanceItem("Base.WoodenCrate") or instanceItem("Base.Bag_DuffelBag")
            end

            if boxItem then
                local boxContainer = boxItem.getItemContainer and boxItem:getItemContainer()
                local packedCount = 0
                for pIdx = 1, totalProduceCount do
                    local produceItem = instanceItem(targetId)
                    if produceItem then
                        if boxContainer then
                            boxContainer:AddItem(produceItem)
                        else
                            placeItem(produceItem)
                        end
                        packedCount = packedCount + 1
                    end
                end

                placeItem(boxItem)
                log(("  + Spawned ProduceBox_Large containing %d x %s (Farming Lv.%d, %d orders, fallback=%s)"):format(
                    packedCount, targetId, farmingLevel, count, tostring(isFallbackDrop)))
            else
                -- フォールバック（箱が生成できなかった場合は直接投入）
                for pIdx = 1, totalProduceCount do
                    local produceItem = instanceItem(targetId)
                    if produceItem then
                        placeItem(produceItem)
                    end
                end
                log(("  [!] Direct spawned %d x %s (fallback=%s)"):format(
                    totalProduceCount, targetId, tostring(isFallbackDrop)))
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
                    placeItem(item)
                    log(("  + Spawned delivery item: %s (fallback=%s)"):format(
                        curTargetId, tostring(isFallbackDrop)))
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
                    placeItem(bonusItem)
                    log(("  + Bonus gift from merchant spawned: %s (fallback=%s)"):format(
                        bonusId, tostring(isFallbackDrop)))
                end
            end
        end
    end

    -- 家具・軍用品下取り提供時のお礼差し入れ（現場クルー特製ランチボックス）
    local hasLunchboxBonus = (order and order.bonusLunchbox) or false
    if hasLunchboxBonus then
        local boxType = ((ZombRand and ZombRand(2) == 0) or math.random(0, 1) == 0) and "Base.Lunchbox" or "Base.Lunchbox2"
        local lunchbox = instanceItem(boxType)
        if lunchbox then
            local container = lunchbox:getItemContainer()
            local packedCount = 0
            if container and RadioTrader_ItemsTable_FillLunchbox then
                packedCount = RadioTrader_ItemsTable_FillLunchbox(container)
            end
            placeItem(lunchbox)
            log(("  + Crew Lunchbox Bonus (%s packed with %d fresh treats) spawned (fallback=%s)"):format(
                boxType, packedCount, tostring(isFallbackDrop)))
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
        itemName         = orderItemName,
        count            = orderCount,
        bonusItemName    = bonusId,
        hasLunchboxBonus = hasLunchboxBonus,
        isMegaHorde      = isMega,
        isFallbackDrop   = isFallbackDrop,
    })

    log("Delivered " .. tostring(orderItemName) .. " (count: " .. tostring(orderCount) .. ")"
        .. (bonusId and (" (+Bonus: " .. tostring(bonusId) .. ")") or "")
        .. " to " .. tostring(player:getUsername())
        .. " (FallbackGroundDrop: " .. tostring(isFallbackDrop) .. ")")
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
-- クレジット残高更新ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_ServerEngine.sendCreditUpdate(player)
    if not player then return end
    local credits = RadioTrader_ServerEngine.getCredits(player)
    RadioTrader_ServerEngine.sendToClient(player, RadioTrader_Config.CMD_CREDIT_UPDATE, {
        credits = credits,
    })
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
        -- 配達ステート・残高・種プールを送信（UI再開時のリフレッシュ）
        local state    = RadioTrader_DeliveryTimer.getState(player)
        local credits  = RadioTrader_ServerEngine.getCredits(player)
        local seedPool = RadioTrader_ServerEngine.getSeedPool(player)
        RadioTrader_ServerEngine.sendToClient(player, "stateRefresh", {
            state    = state,
            credits  = credits,
            seedPool = seedPool,
        })

    elseif command == "requestSeedPool" then
        -- 種プール明示同期リクエスト
        RadioTrader_ServerEngine.sendSeedPoolUpdate(player)

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
