-- =============================================================================
-- RadioTrader_HeliEvent.lua
-- [Server] ヘリ飛来演出・音響・ゾンビ誘引制御
-- =============================================================================
-- 仮想ヘリコプター制御 (Virtual Helicopter State Machine)
-- =============================================================================

RadioTrader_HeliEvent = {}

local virtualHelis = {}
local STATE_APPROACHING = 1
local STATE_HOVERING    = 2
local STATE_LEAVING     = 3

local HELI_SPEED = 2000     -- 1時間あたりの移動タイル数
local HOVER_DURATION = 0.33 -- 20分 (約0.33時間)
local SPAWN_DISTANCE = 1000 -- LZから1000タイル先でスポーン/デスポーン

local function log(msg)
    print("[RadioTrader][HeliEvent] " .. tostring(msg))
end

local function triggerWorldSound(x, y, z, radius, volume)
    -- 1. ゾンビを惹きつけるメタ騒音
    if addSound then
        addSound(nil, math.floor(x), math.floor(y), math.floor(z or 0), math.floor(radius), math.floor(volume))
    elseif IsoWorld and IsoWorld.instance and IsoWorld.instance.addSound then
        IsoWorld.instance:addSound(nil, math.floor(x), math.floor(y), math.floor(z or 0), math.floor(radius), math.floor(volume))
    end
end

local function fireAcousticWave(lzX, lzY, lzZ, isMegaHorde)
    local cfg = RadioTrader_Config
    local r = cfg.SOUND_RADIUS_TILES or 400
    if isMegaHorde then
        r = math.floor(r * 1.5)  -- 大規模ホード時は音響範囲1.5倍 (400->600タイル)
        log("  [!] Acoustic wave expanded to " .. r .. " tiles for MEGA HORDE")
    end
    -- 即時波
    triggerWorldSound(lzX, lzY, lzZ, r, r)

    -- 遅延吸引波（ヘリ到着時および投下後もしばらくLZへゾンビを断続的に引き寄せ続ける）
    local tickCount = 0
    local waveIntervals = { 60, 180, 360, 600, 900, 1200 } -- 約1秒, 3秒, 6秒, 10秒, 15秒, 20秒
    local waveIndex = 1

    local function onTickWave()
        tickCount = tickCount + 1
        if waveIndex <= #waveIntervals and tickCount >= waveIntervals[waveIndex] then
            -- LZ中心（わずかに揺らぎを持たせて経路再計算を促す）
            local ox = (ZombRand(11) - 5)
            local oy = (ZombRand(11) - 5)
            triggerWorldSound(lzX + ox, lzY + oy, lzZ, r, r)
            waveIndex = waveIndex + 1
        end
        if waveIndex > #waveIntervals then
            Events.OnTick.Remove(onTickWave)
        end
    end
    Events.OnTick.Add(onTickWave)
end

local function getUsernameSafe(player)
    if not player then return "singleplayer" end
    local uname = player.getUsername and player:getUsername()
    if not uname or uname == "" then return "singleplayer" end
    return uname
end

local function getCurrentGameHour()
    if GameTime and GameTime.getInstance then
        return GameTime:getInstance():getWorldAgeHours()
    elseif GameTime and GameTime.instance then
        return GameTime.instance:getWorldAgeHours()
    end
    return 0
end

local lastDebugLogTime = 0

local function updateVirtualHelis()
    if #virtualHelis == 0 then return end
    
    local now = getCurrentGameHour()
    
    -- デバッグ用: 10分おき（ゲーム内時間）に生存報告ログを出す
    if (now - lastDebugLogTime) > (10/60) then
        lastDebugLogTime = now
        log("updateVirtualHelis is ticking. Active helis: " .. tostring(#virtualHelis))
        for i, h in ipairs(virtualHelis) do
            log(("  Heli[%d]: state=%d, dist_to_target=%.1f, age=%.3fh"):format(
                i, h.state, math.sqrt((h.targetX - h.x)^2 + (h.targetY - h.y)^2), now - h.lastUpdate))
        end
    end
    
    for i = #virtualHelis, 1, -1 do
        local heli = virtualHelis[i]
        local dtHours = now - heli.lastUpdate
        heli.lastUpdate = now

        -- 保護: マイナス時間経過や異常なジャンプを防ぐ
        if dtHours < 0 then dtHours = 0 end
        if dtHours > 1.0 then dtHours = 1.0 end

        -- オーディオエミッターの初期化（3D距離減衰用）
        if not heli.emitter and getWorld():getFreeEmitter() then
            heli.emitter = getWorld():getFreeEmitter()
            heli.emitter:setPos(heli.x, heli.y, heli.z or 0)
        end
        -- オーディオエミッターの座標更新と再生
        if heli.emitter then
            heli.emitter:setPos(heli.x, heli.y, heli.z or 0)
            if not heli.emitter:isPlaying("Helicopter") then
                heli.emitter:playSound("Helicopter")
            end
        end

        if heli.state == STATE_APPROACHING then
            local dx = heli.targetX - heli.x
            local dy = heli.targetY - heli.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                local move = HELI_SPEED * dtHours
                if move >= dist then
                    -- 到着
                    heli.x = heli.targetX
                    heli.y = heli.targetY
                    heli.state = STATE_HOVERING
                    heli.hoverStartTime = now
                    log(("VirtualHeli arrived at LZ (%d,%d). State -> HOVERING"):format(heli.x, heli.y))
                    
                    -- サーチライト点灯通知 (LZ直上を照射, 半径20)
                    if RadioTrader_ServerEngine and RadioTrader_ServerEngine.broadcastToClients then
                        RadioTrader_ServerEngine.broadcastToClients(RadioTrader_Config.CMD_HELI_HOVER_START, {
                            x = heli.targetX,
                            y = heli.targetY,
                            z = heli.z or 0,
                            radius = 20
                        })
                    end
                    
                    -- 音響
                    fireAcousticWave(heli.x, heli.y, heli.z, heli.isMegaHorde)
                    
                    -- 残りのゾンビがいればここで最終湧き (仮想ホードに失敗した残存分のみ)
                    local leftFallback = heli.fallbackDirect - heli.spawnedDirect
                    if leftFallback > 0 and RadioTrader_ZombieSpawnQueue and RadioTrader_ZombieSpawnQueue.enqueue then
                        log(("Heli arrived: Flushing %d fallback direct zombies to queue"):format(leftFallback))
                        RadioTrader_ZombieSpawnQueue.enqueue(heli.targetX, heli.targetY, heli.z, leftFallback, heli.approachAngle, 30, 45, 85)
                        heli.spawnedDirect = heli.fallbackDirect
                    end
                    
                    -- 配達
                    if heli.player then
                        local ok, err = pcall(function()
                            RadioTrader_ServerEngine.deliverItems(heli.player)
                        end)
                        if not ok then
                            log("[!] Error during deliverItems: " .. tostring(err))
                        end
                        RadioTrader_DeliveryTimer.reset(heli.player)
                    end
                else
                    heli.x = heli.x + (dx / dist) * move
                    heli.y = heli.y + (dy / dist) * move
                    
                    local newDist = math.sqrt((heli.targetX - heli.x)^2 + (heli.targetY - heli.y)^2)
                    
                    -- ヘリがLZ周辺（ロード済みチャンク周辺）に近づいたら、飛行ルート上で段階的に仮想ホードを発進させる
                    while heli.nextSpawnDist > 0 and newDist <= heli.nextSpawnDist do
                        -- 1. 最優先: 遠隔チャンク（ヘリ現在地）への仮想ホード (Popman) 配置
                        if heli.totalHorde > 0 and heli.dispatchedVirtual < heli.totalHorde then
                            local left = heli.totalHorde - heli.dispatchedVirtual
                            local batch = math.floor(heli.totalHorde / 4)
                            if heli.nextSpawnDist <= 50 or batch > left then
                                batch = left
                            end
                            
                            if batch > 0 then
                                local hX = math.floor(heli.x)
                                local hY = math.floor(heli.y)
                                local popmanSuccess = false
                                if ZombiePopulationManager and ZombiePopulationManager.instance and ZombiePopulationManager.instance.createHordeFromTo then
                                    local ok, err = pcall(function()
                                        ZombiePopulationManager.instance:createHordeFromTo(hX, hY, heli.targetX, heli.targetY, batch)
                                    end)
                                    if ok then
                                        popmanSuccess = true
                                        heli.dispatchedVirtual = heli.dispatchedVirtual + batch
                                        log(("  [Popman] Successfully dispatched virtual horde from Heli position (%d,%d) towards LZ (%d,%d): %d zombies [remaining: %d]"):format(
                                            hX, hY, heli.targetX, heli.targetY, batch, heli.totalHorde - heli.dispatchedVirtual))
                                    else
                                        log("[!] Error in Popman createHordeFromTo: " .. tostring(err))
                                    end
                                end
                                
                                -- 仮想ホードとして配置できなかった場合のみ実体フォールバックへ回す
                                if not popmanSuccess then
                                    heli.dispatchedVirtual = heli.dispatchedVirtual + batch
                                    heli.fallbackDirect = heli.fallbackDirect + batch
                                    log(("  [!] Popman unavailable/failed. Routed %d zombies to fallback direct queue"):format(batch))
                                end
                            end
                        end

                        -- 2. フォールバック: 仮想配置に失敗した分のみ実体スポーン（安全距離45タイル＋進入回廊連動）
                        if heli.fallbackDirect > heli.spawnedDirect and RadioTrader_ZombieSpawnQueue and RadioTrader_ZombieSpawnQueue.enqueue then
                            local directBatch = heli.fallbackDirect - heli.spawnedDirect
                            local minR = (heli.nextSpawnDist >= 150) and 85 or 50
                            local maxR = (heli.nextSpawnDist >= 150) and 120 or 85
                            log(("Heli at dist %.1f: Spawning fallback direct batch of %d zombies (Angle: %s deg +/- 30, R: %d-%d)"):format(
                                newDist, directBatch, tostring(heli.approachAngle), minR, maxR))
                            RadioTrader_ZombieSpawnQueue.enqueue(heli.targetX, heli.targetY, heli.z, directBatch, heli.approachAngle, 30, minR, maxR)
                            heli.spawnedDirect = heli.fallbackDirect
                        end

                        heli.nextSpawnDist = heli.nextSpawnDist - 50
                    end
                end
            end
            
            if (now - heli.lastSoundTime) > 0.05 then
                heli.lastSoundTime = now
                triggerWorldSound(heli.x, heli.y, heli.z, 200, 200)
            end

        elseif heli.state == STATE_HOVERING then
            if (now - heli.lastSoundTime) > 0.05 then
                heli.lastSoundTime = now
                triggerWorldSound(heli.x, heli.y, heli.z, 400, 400)
            end
            
            if (now - heli.hoverStartTime) >= HOVER_DURATION then
                heli.state = STATE_LEAVING
                local angle = ZombRand(360)
                local rad = math.rad(angle)
                heli.leaveTargetX = heli.x + SPAWN_DISTANCE * math.cos(rad)
                heli.leaveTargetY = heli.y + SPAWN_DISTANCE * math.sin(rad)
                log("VirtualHeli finished hover. State -> LEAVING")
                
                -- サーチライト消灯通知
                if RadioTrader_ServerEngine and RadioTrader_ServerEngine.broadcastToClients then
                    RadioTrader_ServerEngine.broadcastToClients(RadioTrader_Config.CMD_HELI_HOVER_END, {})
                end
            end

        elseif heli.state == STATE_LEAVING then
            local dx = heli.leaveTargetX - heli.x
            local dy = heli.leaveTargetY - heli.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                local move = HELI_SPEED * dtHours
                if move >= dist then
                    log("VirtualHeli despawned.")
                    if heli.emitter then
                        heli.emitter:stopAll()
                    end
                    if RadioTrader_ServerEngine and RadioTrader_ServerEngine.broadcastToClients then
                        RadioTrader_ServerEngine.broadcastToClients(RadioTrader_Config.CMD_HELI_HOVER_END, {})
                    end
                    table.remove(virtualHelis, i)
                else
                    heli.x = heli.x + (dx / dist) * move
                    heli.y = heli.y + (dy / dist) * move
                end
            end
            
            -- 離脱時はメタ音響誘引をカット（ゾンビがLZからヘリを追いかけて離脱するのを防止）
            -- 3D音響エミッター（効果音）のみで飛び去る
        end
    end
end
Events.OnTick.Add(updateVirtualHelis)

function RadioTrader_HeliEvent.trigger(player, isMegaHorde)
    local gmd = ModData.getOrCreate("RadioTrader_" .. getUsernameSafe(player))
    local lzX = gmd[RadioTrader_Config.KEY_LZ_X]
    local lzY = gmd[RadioTrader_Config.KEY_LZ_Y]
    local lzZ = gmd[RadioTrader_Config.KEY_LZ_Z]

    if not lzX or not lzY or not lzZ then
        log("No LZ registered for " .. player:getUsername() .. ", aborting HeliEvent.")
        RadioTrader_DeliveryTimer.reset(player)
        return
    end

    log(("HeliEvent triggered for %s (MegaHorde: %s). Spawning Virtual Heli targeting LZ (%d,%d,%d)"):format(
        player:getUsername(), tostring(isMegaHorde), lzX, lzY, lzZ))

    local angle = ZombRand(360)
    local rad = math.rad(angle)
    local startX = lzX + SPAWN_DISTANCE * math.cos(rad)
    local startY = lzY + SPAWN_DISTANCE * math.sin(rad)
    
    local count = 0
    local cfg = RadioTrader_Config
    if cfg.HORDE_ENABLED then
        local minCount, maxCount = cfg.getHordeCountRange()
        if maxCount > 0 then
            count = minCount + ZombRand(maxCount - minCount + 1)
            if isMegaHorde then
                local mult = cfg.MEGA_HORDE_MULTIPLIER or 2.5
                count = math.floor(count * mult)
                log(("  [!] MEGA HORDE ACTIVE: Spawning %d zombies (x%.1f)"):format(count, mult))
            end
        end
    end
    
    log(("  Heli horde planned: %d total (primary: virtual Popman horde at flight coordinates, fallback: direct spawn)"):format(count))
    
    local now = getCurrentGameHour()
    table.insert(virtualHelis, {
        player = player,
        state = STATE_APPROACHING,
        x = startX,
        y = startY,
        z = lzZ,
        targetX = lzX,
        targetY = lzY,
        lastUpdate = now,
        lastSoundTime = now,
        totalHorde = count,
        dispatchedVirtual = 0,
        fallbackDirect = 0,
        spawnedDirect = 0,
        nextSpawnDist = 200,
        approachAngle = angle,
        isMegaHorde = isMegaHorde or false,
    })
end
