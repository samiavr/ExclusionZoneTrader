-- =============================================================================
-- RadioTrader_ZombieSpawnQueue.lua
-- [Server] ゾンビ予約スポーンキューシステム
-- =============================================================================
RadioTrader_ZombieSpawnQueue = {}

local QUEUE_MODDATA_KEY  = "RadioTrader_SpawnQueue"
local SPAWN_EXPIRE_HOURS = 24   -- 予約の有効期間（ゲーム内時間）
local SCAN_ANGLES        = 72   -- 1回のスキャンで試行する角度分割数
local MAX_SCAN_PER_CHUNK = 50   -- チャンクロード時の最大スキャン回数（負荷対策）
local DELAY_PENALTY_MULTIPLIER = 1.5

local function log(msg) print("[RadioTrader][SpawnQueue] " .. tostring(msg)) end
local function getCurrentGameHour() return GameTime.instance and GameTime.instance:getWorldAgeHours() or 0 end
local function getQueue()
    local gmd = ModData.getOrCreate(QUEUE_MODDATA_KEY)
    if not gmd.entries then gmd.entries = {} end
    return gmd
end

local function getActivePlayers()
    local players = {}
    if IsoPlayer and IsoPlayer.getPlayers then
        local pList = IsoPlayer.getPlayers()
        if pList and pList.size then
            for i = 0, pList:size() - 1 do
                local p = pList:get(i)
                if p and not p:isDead() then
                    table.insert(players, p)
                end
            end
        end
    end
    if #players == 0 and getSpecificPlayer then
        local p0 = getSpecificPlayer(0)
        if p0 and not p0:isDead() then
            table.insert(players, p0)
        end
    end
    return players
end

local function getNaturalScore(sq, players, minPlayerDist)
    if not sq then return 0 end
    if not sq:isFree(false) then return 0 end
    if not sq:isOutside() then return 0 end

    -- プレイヤーセーフティ: どのプレイヤーからも最低 minPlayerDist タイル以上離れていること
    if players and #players > 0 then
        local sqX = sq:getX()
        local sqY = sq:getY()
        local minDistSq = (minPlayerDist or 45) * (minPlayerDist or 45)
        for _, p in ipairs(players) do
            if p then
                local px = p:getX()
                local py = p:getY()
                local distSq = (sqX - px) * (sqX - px) + (sqY - py) * (sqY - py)
                if distSq < minDistSq then
                    return 0 -- プレイヤー至近距離（視界内）のため除外
                end
            end
        end
    end

    if SafeHouse then
        if SafeHouse.getSafeHouse and SafeHouse.getSafeHouse(sq) then return 0
        elseif SafeHouse.isSafeHouse and SafeHouse.isSafeHouse(sq, nil, false) then return 0 end
    end

    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and instanceof(obj, "IsoThumpable") then return 0 end
    end
    local score = 1
    if sq:HasTree() then score = score + 10 end
    return score
end

local function spawnZombiesBatch(cell, sq, lzX, lzY, lzZ, batch)
    local x = sq:getX()
    local y = sq:getY()
    local z = sq:getZ()
    local success = false
    batch = batch or 1

    if createHordeFromTo then
        local ok = pcall(createHordeFromTo, x, y, lzX, lzY, batch)
        if ok then success = true end
    end
    if not success and addZombiesInOutfit then
        local ok, zombies = pcall(addZombiesInOutfit, x, y, z, batch, nil, nil)
        if ok and zombies and zombies:size() > 0 then
            success = true
            for zIdx = 0, zombies:size() - 1 do
                local zObj = zombies:get(zIdx)
                if zObj and zObj.pathToLocationF then
                    pcall(function() zObj:pathToLocationF(lzX, lzY, lzZ) end)
                end
            end
        end
    end
    return success and batch or 0
end

local function trySpawnFromLoadedArea(entry, maxAttempts)
    local cell = getWorld():getCell()
    if not cell then return 0 end
    local cfg    = RadioTrader_Config
    local lzX    = entry.lzX
    local lzY    = entry.lzY
    local lzZ    = entry.lzZ
    local count  = entry.count
    local appAngle = entry.approachAngle
    local spread   = entry.spreadAngle or 30  -- デフォルト +/-30度 (合計60度のシャープな進入回廊)
    maxAttempts  = maxAttempts or (count * 10)
    local spawned = 0

    local players = getActivePlayers()
    local minPlayerDist = cfg.PLAYER_SAFETY_RADIUS_TILES or 45
    local minHordeRadius = entry.minRadius or cfg.HORDE_SPAWN_RADIUS_MIN or 45
    local maxHordeRadius = entry.maxRadius or math.max(120, (cfg.HORDE_SPAWN_RADIUS_MAX or 85) + 35)

    for i = 1, maxAttempts do
        if spawned >= count then break end
        local angle
        if appAngle ~= nil then
            -- ヘリ進入方向を中心としたシャープな進入回廊から角度を選択
            local offset = ZombRand(spread * 2 + 1) - spread
            angle = (appAngle + offset) % 360
        else
            local baseAngle = (i / SCAN_ANGLES) * 360
            angle = (baseAngle + ZombRand(math.max(1, math.floor(360 / SCAN_ANGLES)))) % 360
        end
        local rad = math.rad(angle)
        
        local foundValid = false
        local sq, score, spawnX, spawnY
        
        for r = minHordeRadius, maxHordeRadius, 6 do
            spawnX = math.floor(lzX + r * math.cos(rad))
            spawnY = math.floor(lzY + r * math.sin(rad))
            sq = cell:getGridSquare(spawnX, spawnY, lzZ)
            if sq then
                score = getNaturalScore(sq, players, minPlayerDist)
                if score > 0 then
                    foundValid = true
                    break
                end
            end
        end

        if foundValid and sq then
            local batch = math.min(ZombRand(2, 6), count - spawned)
            local numSpawned = spawnZombiesBatch(cell, sq, lzX, lzY, lzZ, batch)
            spawned = spawned + numSpawned
        end
    end
    return spawned
end

function RadioTrader_ZombieSpawnQueue.processQueue(maxAttemptsOverride)
    local gmd = getQueue()
    if not gmd.entries or #gmd.entries == 0 then return end
    local now       = getCurrentGameHour()
    local remaining = {}
    local totalLeft = 0

    for _, entry in ipairs(gmd.entries) do
        if now >= entry.expireHour then
            log(("Entry expired: %d zombies discarded for LZ (%d,%d,%d)"):format(entry.count, entry.lzX, entry.lzY, entry.lzZ))
        else
            local attempts = maxAttemptsOverride or (entry.count * SCAN_ANGLES)
            local spawned  = trySpawnFromLoadedArea(entry, attempts)
            local leftover = entry.count - spawned
            if spawned > 0 then
                log(("Spawned %d / %d for LZ (%d,%d,%d) (ConeAngle: %s)"):format(
                    spawned, entry.count, entry.lzX, entry.lzY, entry.lzZ, tostring(entry.approachAngle)))
            end
            if leftover > 0 then
                entry.count = leftover
                table.insert(remaining, entry)
                totalLeft = totalLeft + leftover
            end
        end
    end
    gmd.entries = remaining
    if totalLeft > 0 then log(totalLeft .. " zombie(s) still queued.") end
end

function RadioTrader_ZombieSpawnQueue.enqueue(lzX, lzY, lzZ, count, approachAngle, spreadAngle, minRadius, maxRadius)
    if count <= 0 then return end
    spreadAngle = spreadAngle or 30
    local immediateEntry = {
        lzX = lzX, lzY = lzY, lzZ = lzZ,
        count = count,
        approachAngle = approachAngle,
        spreadAngle = spreadAngle,
        minRadius = minRadius,
        maxRadius = maxRadius,
    }
    local attempts = count * 15
    local spawned = trySpawnFromLoadedArea(immediateEntry, attempts)
    local leftover = count - spawned
    if leftover <= 0 then
        log(("All %d zombies spawned immediately for LZ (%d,%d,%d) (Cone: %s +/- %d deg, R: %s-%s). No queue needed."):format(
            count, lzX, lzY, lzZ, tostring(approachAngle), spreadAngle, tostring(minRadius), tostring(maxRadius)))
        return
    end

    local penalizedCount = math.ceil(leftover * DELAY_PENALTY_MULTIPLIER)
    log(("Immediate spawn missed %d zombies. Applying penalty (x%.1f) -> %d queued (Cone: %s +/- %d deg)"):format(
        leftover, DELAY_PENALTY_MULTIPLIER, penalizedCount, tostring(approachAngle), spreadAngle))
    
    local now = getCurrentGameHour()
    local gmd = getQueue()

    for _, entry in ipairs(gmd.entries) do
        if entry.lzX == lzX and entry.lzY == lzY and entry.lzZ == lzZ then
            entry.count = entry.count + penalizedCount
            entry.expireHour = now + SPAWN_EXPIRE_HOURS
            entry.approachAngle = approachAngle or entry.approachAngle
            entry.spreadAngle = spreadAngle or entry.spreadAngle
            entry.minRadius = minRadius or entry.minRadius
            entry.maxRadius = maxRadius or entry.maxRadius
            return
        end
    end

    table.insert(gmd.entries, {
        lzX = lzX, lzY = lzY, lzZ = lzZ,
        count = penalizedCount,
        expireHour = now + SPAWN_EXPIRE_HOURS,
        approachAngle = approachAngle,
        spreadAngle = spreadAngle,
        minRadius = minRadius,
        maxRadius = maxRadius,
    })
end

local function onChunkLoaded(chunk)
    local gmd = getQueue()
    if not gmd.entries or #gmd.entries == 0 then return end
    RadioTrader_ZombieSpawnQueue.processQueue(MAX_SCAN_PER_CHUNK)
end

if Events.LoadChunk then Events.LoadChunk.Add(onChunkLoaded) end
if Events.EveryTenMinutes then
    Events.EveryTenMinutes.Add(function()
        local gmd = getQueue()
        if not gmd.entries or #gmd.entries == 0 then return end
        RadioTrader_ZombieSpawnQueue.processQueue()
    end)
end
if Events.EveryHours then
    Events.EveryHours.Add(function() RadioTrader_ZombieSpawnQueue.processQueue() end)
end

function RadioTrader_ZombieSpawnQueue.debugDump()
    local gmd = getQueue()
    local now = getCurrentGameHour()
    if not gmd.entries or #gmd.entries == 0 then log("Queue is empty."); return end
    for i, entry in ipairs(gmd.entries) do
        local remaining = math.max(0, entry.expireHour - now)
        log(("  [%d] LZ(%d,%d,%d) count=%d expire_in=%.1fh"):format(i, entry.lzX, entry.lzY, entry.lzZ, entry.count, remaining))
    end
end
