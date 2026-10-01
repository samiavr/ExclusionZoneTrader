-- =============================================================================
-- RadioTrader_DeliveryTimer.lua
-- [Server] 配達遅延・ゲーム内時間タイマー＆ステートマシン
-- =============================================================================
-- ゲーム内経過時間を基準に配達ステートを管理する。
-- セーブ・ロードをまたいでもタイマーが継続するよう ModData に永続保存する。
-- ステート: NONE → PENDING → APPROACHING（10分前）→ READY_FOR_DROP（手動投下待ち）→ DELIVERING → COMPLETED
-- 投下要請敆障なき未実施：48ゲーム内時間後にキャンセル（半額返金・注文没収）
-- =============================================================================

RadioTrader_DeliveryTimer = {}

-- ---------------------------------------------------------------------------
-- ログユーティリティ
-- ---------------------------------------------------------------------------
local function log(msg)
    print("[RadioTrader][Timer] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- ゲーム内「時」を取得するユーティリティ
-- GameTime は「世界の年齢（ゲーム内時間を時単位で累積）」を返す
-- ---------------------------------------------------------------------------
local function getCurrentGameHour()
    local gt = getGameTime()
    if not gt then return 0 end
    -- WorldAge は「開始からの総ゲーム時間（時）」
    return gt:getWorldAgeHours()
end

local function getUsernameSafe(player)
    if not player then return "singleplayer" end
    local uname = player.getUsername and player:getUsername()
    if not uname or uname == "" then return "singleplayer" end
    return uname
end

-- ---------------------------------------------------------------------------
-- ModData アクセスヘルパー
-- ---------------------------------------------------------------------------
local function getTimerData(player)
    local key = "RadioTrader_Timer_" .. getUsernameSafe(player)
    return ModData.getOrCreate(key)
end

-- ---------------------------------------------------------------------------
-- ステート取得
-- ---------------------------------------------------------------------------
function RadioTrader_DeliveryTimer.getState(player)
    local data = getTimerData(player)
    local state = data.state or RadioTrader_Config.STATE_NONE

    -- 【自己治癒 / リカバリーガード】
    -- DELIVERING 状態だが注文（KEY_ORDER）が存在しない場合、配達は既に完了している
    if state == RadioTrader_Config.STATE_DELIVERING then
        local gmd = ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
        if not gmd[RadioTrader_Config.KEY_ORDER] then
            log(player:getUsername() .. " auto-recovering orphan DELIVERING state -> COMPLETED")
            RadioTrader_DeliveryTimer.reset(player)
            state = RadioTrader_Config.STATE_COMPLETED
        end
    end

    return state
end

-- ---------------------------------------------------------------------------
-- タイマー開始（発注時に呼ばれる）
-- ---------------------------------------------------------------------------
function RadioTrader_DeliveryTimer.start(player)
    local data = getTimerData(player)
    local cfg  = RadioTrader_Config

    -- ランダム配達時間を決定
    local deliveryHours
    if cfg.DELIVERY_HOURS_MIN >= cfg.DELIVERY_HOURS_MAX then
        deliveryHours = cfg.DELIVERY_HOURS_MIN
    else
        deliveryHours = cfg.DELIVERY_HOURS_MIN
            + ZombRand(cfg.DELIVERY_HOURS_MAX - cfg.DELIVERY_HOURS_MIN + 1)
    end

    local now = getCurrentGameHour()
    data.state           = cfg.STATE_PENDING
    data.startHour       = now
    data.targetHour      = now + deliveryHours
    data.approachWarned  = false
    data.deliveryHours   = deliveryHours

    -- 大規模ホード発生判定 (低確率)
    local megaChance = cfg.getMegaHordeChance and cfg.getMegaHordeChance() or 0.15
    local roll = (ZombRand and (ZombRand(100) + 1)) or math.random(1, 100)
    data.isMegaHorde = (roll <= math.floor(megaChance * 100))
    if data.isMegaHorde then
        log(player:getUsername() .. " [!] MEGA HORDE scheduled for this delivery (roll: " .. roll .. " <= " .. math.floor(megaChance * 100) .. "%)")
    end

    log(player:getUsername() .. " delivery scheduled in " .. deliveryHours .. " game hours")
end

-- ---------------------------------------------------------------------------
-- タイマーリセット（配達完了後）
-- ---------------------------------------------------------------------------
function RadioTrader_DeliveryTimer.reset(player)
    local data = getTimerData(player)
    data.state          = RadioTrader_Config.STATE_COMPLETED
    data.approachWarned = nil
    data.targetHour     = nil
    data.startHour      = nil
    data.deliveryHours  = nil
    data.isMegaHorde    = nil
end

-- ---------------------------------------------------------------------------
-- 残り時間を時単位で返す（UI表示用）
-- ---------------------------------------------------------------------------
function RadioTrader_DeliveryTimer.getRemainingHours(player)
    local data = getTimerData(player)
    if not data.targetHour then return 0 end
    local now = getCurrentGameHour()
    return math.max(0, data.targetHour - now)
end

-- ---------------------------------------------------------------------------
-- アクティブなプレイヤーリストを取得 (SP/MP両対応)
-- ---------------------------------------------------------------------------
local function getActivePlayers()
    local result = {}
    if isClient() or isServer() then
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                table.insert(result, players:get(i))
            end
        end
    end
    if #result == 0 then
        local p = getSpecificPlayer(0)
        if p then table.insert(result, p) end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- メインチェック処理（EveryHours で每時呼ばれる）
-- ---------------------------------------------------------------------------
local function checkTimers()
    local players = getActivePlayers()
    if #players == 0 then return end
    local now = getCurrentGameHour()
    local cfg = RadioTrader_Config

    for _, player in ipairs(players) do
        if player then
            local data  = getTimerData(player)
            local state = data.state or cfg.STATE_NONE

            -- PENDING / APPROACHING: 到着時刻チェック
            if state == cfg.STATE_PENDING or state == cfg.STATE_APPROACHING then
                local target = data.targetHour
                if target then
                    -- 接近警告チェック（到着 APPROACH_WARNING_MINUTES 分前）
                    local approachThreshold = target - (cfg.APPROACH_WARNING_MINUTES / 60.0)
                    if not data.approachWarned and now >= approachThreshold then
                        data.approachWarned = true
                        data.state = cfg.STATE_APPROACHING
                        local approachPayload = {
                            remainingMinutes = cfg.APPROACH_WARNING_MINUTES,
                            isMegaHorde      = data.isMegaHorde or false,
                        }
                        if RadioTrader_ServerEngine and RadioTrader_ServerEngine.sendToClient then
                            RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_HELI_APPROACH, approachPayload)
                        else
                            sendServerCommand(player, "RadioTrader", cfg.CMD_HELI_APPROACH, approachPayload)
                        end
                        log(player:getUsername() .. " heli approaching warning sent (MegaHorde: " .. tostring(data.isMegaHorde) .. ")")
                    end

                    -- 到着時刻に達した→ READY_FOR_DROP へ遷移（ヘリは自動発動しない）
                    if now >= target then
                        data.state    = cfg.STATE_READY_FOR_DROP
                        data.readyHour = now  -- 有効期限の基準時刻を記録
                        -- クライアントへ「投下要請可能」連絡
                        if RadioTrader_ServerEngine and RadioTrader_ServerEngine.sendToClient then
                            RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_REQUEST_DROP, { expireHours = cfg.DROP_EXPIRE_HOURS })
                        else
                            sendServerCommand(player, "RadioTrader", cfg.CMD_REQUEST_DROP, { expireHours = cfg.DROP_EXPIRE_HOURS })
                        end
                        log(player:getUsername() .. " delivery ready, awaiting manual drop request")
                    end
                end

            -- READY_FOR_DROP: 48h 期限切れチェック
            elseif state == cfg.STATE_READY_FOR_DROP then
                local readyAt = data.readyHour
                if readyAt and (now - readyAt) >= cfg.DROP_EXPIRE_HOURS then
                    log(player:getUsername() .. " drop request expired, cancelling order")
                    RadioTrader_DeliveryTimer.expireOrder(player)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- 投下期限切れ処理（内部 / checkTimers から呼び出し）
-- 半額返金し、注文を没収。
-- ---------------------------------------------------------------------------
function RadioTrader_DeliveryTimer.expireOrder(player)
    local cfg = RadioTrader_Config

    -- 返金額を計算（注文時に支払った金額の半額）
    local gmd = ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
    local order = gmd[cfg.KEY_ORDER]
    local refund = 0
    if order and order.paidCredits then
        refund = math.floor(order.paidCredits * cfg.DROP_REFUND_RATE)
    end

    -- 返金処理
    if refund > 0 then
        local current = RadioTrader_ServerEngine.getCredits(player)
        RadioTrader_ServerEngine.setCredits(player, current + refund)
    end

    -- 注文没収
    gmd[cfg.KEY_ORDER] = nil

    -- ステートリセット
    local data = getTimerData(player)
    data.state      = cfg.STATE_NONE
    data.readyHour  = nil
    data.targetHour = nil
    data.startHour  = nil
    data.deliveryHours = nil
    data.approachWarned = nil

    -- クライアントへ期限切れ通知
    if RadioTrader_ServerEngine and RadioTrader_ServerEngine.sendToClient then
        RadioTrader_ServerEngine.sendToClient(player, cfg.CMD_ORDER_EXPIRED, { refund = refund })
    else
        sendServerCommand(player, "RadioTrader", cfg.CMD_ORDER_EXPIRED, { refund = refund })
    end
    log(player:getUsername() .. " order expired. Refund: " .. refund .. " CR")
end

-- ---------------------------------------------------------------------------
-- セーブ・ロード後の復元（ゲームタイムが変わっても継続）
-- ---------------------------------------------------------------------------
local function onGameTimeLoaded()
    log("Game time loaded. Resuming active delivery timers...")
    local players = getActivePlayers()
    if #players == 0 then return end

    for _, player in ipairs(players) do
        if player then
            local data = getTimerData(player)
            -- DELIVERING のまま再起動した場合のみ再発火（READY_FOR_DROP はフロー保留中なのでそのまま）
            if data.state == RadioTrader_Config.STATE_DELIVERING then
                local gmd = ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
                if gmd and gmd[RadioTrader_Config.KEY_ORDER] then
                    log(player:getUsername() .. " resuming interrupted delivery")
                    RadioTrader_HeliEvent.trigger(player)
                else
                    log(player:getUsername() .. " delivery order already completed. Resetting timer.")
                    RadioTrader_DeliveryTimer.reset(player)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- イベント登録（ゲーム時間毎分チェックして即座にステート遷移・通知を発火）
-- ---------------------------------------------------------------------------
Events.EveryOneMinute.Add(checkTimers)
Events.OnGameTimeLoaded.Add(onGameTimeLoaded)
