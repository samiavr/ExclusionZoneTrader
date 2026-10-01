-- =============================================================================
-- RadioTrader_Config.lua
-- [Shared] 全パラメータ一元管理・サンドボックス連携
-- =============================================================================
-- このファイルはクライアント・サーバー双方から require されます。
-- SandboxVars が存在する場合（ゲーム内）は動的に上書きされます。
-- =============================================================================

RadioTrader_Config = {}

-- ---------------------------------------------------------------------------
-- デフォルト値定義
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    -- 無線通信設定
    FREQUENCY          = 104.8,     -- 交易ネットワーク周波数 (MHz)
    FREQUENCY_TOLERANCE = 0.1,      -- 周波数の許容誤差 (+/- MHz)
    VALID_RADIO_TYPES  = {
        "Base.HamRadio1",
        "Base.HamRadio2",
        "Base.HamRadioMakeShift",
        "Base.WalkieTalkie1",
        "Base.WalkieTalkie2",
        "Base.WalkieTalkie3",
        "Base.WalkieTalkie4",
        "Base.WalkieTalkie5",
        "Base.WalkieTalkieMakeShift",
    },

    -- ドロップボックス / LZ 設定
    REQUIRE_OUTDOOR_LZ = true,      -- 屋外LZ必須か
    LZ_MAX_RANGE       = 500,       -- プレイヤー位置からLZ登録可能な最大距離（タイル）
    LZ_CAPACITY_SLOTS  = 20,        -- LZ コンテナの最大スロット数（容量チェック用）

    -- 配達設定 (標準: 6〜12時間)
    DELIVERY_HOURS_MIN = 6,         -- 最短配達時間（ゲーム内時間）
    DELIVERY_HOURS_MAX = 12,        -- 最長配達時間（ゲーム内時間）
    APPROACH_WARNING_MINUTES = 10,  -- 「接近警告」を出すヘリ到着前の分数

    -- 投下要請フロー設定
    DROP_REQUEST_RANGE_TILES = 50,  -- 投下要請に必要なLZからの最大距離（タイル）
    DROP_EXPIRE_HOURS        = 48,  -- READY_FOR_DROP 有効期間（ゲーム内時間）
    DROP_REFUND_RATE         = 0.5, -- キャンセル時の返金率（0.5 = 半額）

    -- ヘリ音響・ゾンビ設定
    SOUND_RADIUS_TILES         = 400,   -- 音響による既存ゾンビ誘引半径（タイル）
    HORDE_ENABLED              = true,  -- 追従ゾンビ生成の有無
    HORDE_SPAWN_RADIUS_MIN     = 45,    -- 追従ゾンビのLZからの最小スポーン半径（画面外）
    HORDE_SPAWN_RADIUS_MAX     = 85,    -- 追従ゾンビのLZからの最大スポーン半径（ロード済みチャンク内）
    PLAYER_SAFETY_RADIUS_TILES = 45,    -- プレイヤーからの絶対セーフティ除外半径（45タイル以内にはスポーンさせない）
    HORDE_SIZE                 = "Medium",  -- None / Small / Medium / Large / Insane
    MEGA_HORDE_ENABLED         = true,      -- 低確率大規模ホードの有無
    MEGA_HORDE_CHANCE          = 0.15,      -- 大規模ホード発生確率 (デフォルト: 15%)
    MEGA_HORDE_MULTIPLIER      = 2.5,       -- 大規模ホード時のゾンビ数倍率 (2.5倍)
    HORDE_REMOTE_RATIO         = 1.0,       -- 遠隔仮想ホードの割合 (デフォルト: 100% 遠隔 / 0% 近接)

    -- クレジット査定設定
    CONDITION_WEIGHT   = 0.6,       -- 耐久度の査定への影響係数
    FRESHNESS_WEIGHT   = 0.4,       -- 食品新鮮度の査定への影響係数
    MIN_SELL_CONDITION = 0.1,       -- これ未満のコンディションは買取不可

    -- 価格倍率設定 (山荘経済 / サンドボックス連携)
    BUY_PRICE_MULTIPLIER  = 2.0,    -- 購入価格倍率 (デフォルト: 2.0倍)
    SELL_PRICE_MULTIPLIER = 1.0,    -- 売却価格倍率 (デフォルト: 1.0倍)
}

-- ---------------------------------------------------------------------------
-- ホードサイズ→スポーン数のマッピング
-- ---------------------------------------------------------------------------
RadioTrader_Config.HORDE_SIZE_TABLE = {
    None   = { min = 0,   max = 0   },
    Small  = { min = 5,   max = 10  },
    Medium = { min = 15,  max = 30  },
    Large  = { min = 50,  max = 100 },
    Insane = { min = 150, max = 200 },
}

-- ---------------------------------------------------------------------------
-- サンドボックス設定の安全な多層フォールバック取得
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getSandboxOption(key)
    -- 1. 最優先: ゲーム中の動的変更を即座に拾うため Java getSandboxOptions() API を最初にチェック
    if getSandboxOptions then
        local ok, val = pcall(function()
            local so = getSandboxOptions()
            if so and so.getOptionByName then
                local opt = so:getOptionByName("RadioTrader." .. key) or so:getOptionByName(key)
                if opt and opt.getValue then
                    local v = opt:getValue()
                    if v ~= nil then return v end
                end
            end
            return nil
        end)
        if ok and val ~= nil then
            -- Lua 側の SandboxVars キャッシュも最新値に追従同期
            if SandboxVars and SandboxVars.RadioTrader then
                SandboxVars.RadioTrader[key] = val
            end
            return val
        end
    end

    -- 2. フォールバック: Lua グローバルテーブル SandboxVars
    if SandboxVars and SandboxVars.RadioTrader and SandboxVars.RadioTrader[key] ~= nil then
        return SandboxVars.RadioTrader[key]
    end
    if SandboxVars and SandboxVars[key] ~= nil then
        return SandboxVars[key]
    end
    if SandboxVars and SandboxVars["RadioTrader." .. key] ~= nil then
        return SandboxVars["RadioTrader." .. key]
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- 設定初期化（ゲーム起動後やワールドロード時に呼び出す）
-- ---------------------------------------------------------------------------
function RadioTrader_Config.init()
    local getOpt = RadioTrader_Config.getSandboxOption

    RadioTrader_Config.FREQUENCY         = getOpt("TradeFrequency") or DEFAULTS.FREQUENCY
    RadioTrader_Config.FREQUENCY_TOLERANCE = DEFAULTS.FREQUENCY_TOLERANCE
    RadioTrader_Config.VALID_RADIO_TYPES = DEFAULTS.VALID_RADIO_TYPES

    local reqOutdoor = getOpt("RequireOutdoorLZ")
    RadioTrader_Config.REQUIRE_OUTDOOR_LZ = (reqOutdoor ~= nil) and reqOutdoor or DEFAULTS.REQUIRE_OUTDOOR_LZ
    RadioTrader_Config.LZ_MAX_RANGE       = getOpt("LZMaxRange") or DEFAULTS.LZ_MAX_RANGE
    RadioTrader_Config.LZ_CAPACITY_SLOTS  = DEFAULTS.LZ_CAPACITY_SLOTS

    RadioTrader_Config.DELIVERY_HOURS_MIN        = DEFAULTS.DELIVERY_HOURS_MIN
    RadioTrader_Config.DELIVERY_HOURS_MAX        = DEFAULTS.DELIVERY_HOURS_MAX
    RadioTrader_Config.APPROACH_WARNING_MINUTES  = DEFAULTS.APPROACH_WARNING_MINUTES

    RadioTrader_Config.DROP_REQUEST_RANGE_TILES  = DEFAULTS.DROP_REQUEST_RANGE_TILES
    RadioTrader_Config.DROP_EXPIRE_HOURS         = DEFAULTS.DROP_EXPIRE_HOURS
    RadioTrader_Config.DROP_REFUND_RATE          = DEFAULTS.DROP_REFUND_RATE

    -- 配達時間プリセット変換
    local delTime = getOpt("DeliveryTimeHours")
    if delTime ~= nil then
        local presetMap = {
            [1] = { min = 1,  max = 2 },
            [2] = { min = 3,  max = 6 },
            [3] = { min = 6,  max = 12 },
            [4] = { min = 12, max = 24 },
            [5] = { min = 24, max = 72 },
            [0] = { min = 1,  max = 2 },
        }
        local range = presetMap[delTime] or { min = 6, max = 12 }
        RadioTrader_Config.DELIVERY_HOURS_MIN = range.min
        RadioTrader_Config.DELIVERY_HOURS_MAX = range.max
    end

    RadioTrader_Config.SOUND_RADIUS_TILES     = getOpt("HeliZombieAttractRadius") or DEFAULTS.SOUND_RADIUS_TILES
    local hordeEn = getOpt("HeliHordeEnabled")
    RadioTrader_Config.HORDE_ENABLED          = (hordeEn ~= nil) and hordeEn or DEFAULTS.HORDE_ENABLED
    RadioTrader_Config.HORDE_SPAWN_RADIUS_MIN     = DEFAULTS.HORDE_SPAWN_RADIUS_MIN
    RadioTrader_Config.HORDE_SPAWN_RADIUS_MAX     = DEFAULTS.HORDE_SPAWN_RADIUS_MAX
    RadioTrader_Config.PLAYER_SAFETY_RADIUS_TILES = DEFAULTS.PLAYER_SAFETY_RADIUS_TILES

    -- ホード規模
    local minCount, maxCount, hName, rawHorde = RadioTrader_Config.getHordeCountRange()
    RadioTrader_Config.HORDE_SIZE = hName

    RadioTrader_Config.CONDITION_WEIGHT   = DEFAULTS.CONDITION_WEIGHT
    RadioTrader_Config.FRESHNESS_WEIGHT   = DEFAULTS.FRESHNESS_WEIGHT
    RadioTrader_Config.MIN_SELL_CONDITION = DEFAULTS.MIN_SELL_CONDITION

    -- 価格倍率
    RadioTrader_Config.BUY_PRICE_MULTIPLIER  = getOpt("BuyPriceMultiplier")  or DEFAULTS.BUY_PRICE_MULTIPLIER
    RadioTrader_Config.SELL_PRICE_MULTIPLIER = getOpt("SellPriceMultiplier") or DEFAULTS.SELL_PRICE_MULTIPLIER

    -- 大規模ホード
    RadioTrader_Config.MEGA_HORDE_ENABLED    = DEFAULTS.MEGA_HORDE_ENABLED
    RadioTrader_Config.MEGA_HORDE_MULTIPLIER = DEFAULTS.MEGA_HORDE_MULTIPLIER

    print(("[RadioTrader][Config] Initialized: HORDE_SIZE=%s (%d-%d, raw=%s), BuyMult=%.1f, SellMult=%.1f, MegaChance=%.0f%%, RemoteRatio=%.0f%%"):format(
        tostring(RadioTrader_Config.HORDE_SIZE), minCount, maxCount, tostring(rawHorde),
        RadioTrader_Config.getBuyPriceMultiplier(),
        RadioTrader_Config.getSellPriceMultiplier(),
        RadioTrader_Config.getMegaHordeChance() * 100,
        RadioTrader_Config.getHordeRemoteRatio() * 100))
end

-- ---------------------------------------------------------------------------
-- ゲッター: 遠隔仮想ホード割合 (0.0〜1.0)
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getHordeRemoteRatio()
    local raw = RadioTrader_Config.getSandboxOption("HeliHordeRemoteRatio")
    if raw ~= nil then
        local map = { [1] = 0.0, [2] = 0.25, [3] = 0.50, [4] = 0.75, [5] = 1.0, [0] = 1.0 }
        local num = tonumber(raw)
        if num and map[num] ~= nil then
            return map[num], num
        end
    end
    return DEFAULTS.HORDE_REMOTE_RATIO or 1.0, 5
end

-- ---------------------------------------------------------------------------
-- ゲッター: 大規模ホード発生確率 (0.0〜1.0)
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getMegaHordeChance()
    local raw = RadioTrader_Config.getSandboxOption("MegaHordeChance")
    if raw ~= nil then
        local map = { [1] = 0.0, [2] = 0.05, [3] = 0.15, [4] = 0.25, [5] = 1.0, [0] = 0.0 }
        local num = tonumber(raw)
        if num and map[num] ~= nil then
            return map[num]
        end
    end
    return DEFAULTS.MEGA_HORDE_CHANCE or 0.15
end

-- ---------------------------------------------------------------------------
-- ゲッター: 購入価格倍率
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getBuyPriceMultiplier()
    local raw = RadioTrader_Config.getSandboxOption("BuyPriceMultiplier")
    if raw ~= nil then
        local m = tonumber(raw)
        if m and m > 0 then return m end
    end
    return RadioTrader_Config.BUY_PRICE_MULTIPLIER or 2.0
end

-- ---------------------------------------------------------------------------
-- ゲッター: 売却価格倍率
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getSellPriceMultiplier()
    local raw = RadioTrader_Config.getSandboxOption("SellPriceMultiplier")
    if raw ~= nil then
        local m = tonumber(raw)
        if m and m > 0 then return m end
    end
    return RadioTrader_Config.SELL_PRICE_MULTIPLIER or 1.0
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: 無線機が有効な周波数に合っているか判定
-- ---------------------------------------------------------------------------
function RadioTrader_Config.isValidFrequency(freq)
    if not freq then return false end
    local freqMhz = tonumber(freq)
    if not freqMhz then return false end
    -- PZバニラの周波数は kHz 単位 (例: 104800 = 104.8MHz) の場合があるため自動正規化
    if freqMhz > 1000 then
        freqMhz = freqMhz / 1000.0
    end
    local diff = math.abs(freqMhz - RadioTrader_Config.FREQUENCY)
    return diff <= RadioTrader_Config.FREQUENCY_TOLERANCE
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: アイテムタイプが有効な無線機か判定
-- ---------------------------------------------------------------------------
function RadioTrader_Config.isValidRadioType(itemType)
    if not itemType then return false end
    local s = tostring(itemType)
    for _, t in ipairs(RadioTrader_Config.VALID_RADIO_TYPES) do
        if t == s or string.find(s, t) or string.find(string.lower(s), string.lower(t)) then
            return true
        end
    end
    -- "hamradio" が含まれていれば許可
    if string.find(string.lower(s), "hamradio") then
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: ホードサイズ名からスポーン数範囲を取得
-- 戻り値: min, max, resolvedName, rawValue
-- ---------------------------------------------------------------------------
function RadioTrader_Config.getHordeCountRange()
    local raw = RadioTrader_Config.getSandboxOption("HeliHordeSize")
    local hName = "Medium"
    if raw ~= nil then
        if type(raw) == "string" and RadioTrader_Config.HORDE_SIZE_TABLE[raw] then
            hName = raw
        else
            local num = tonumber(raw)
            if num then
                local hordeMap1 = { [1]="None", [2]="Small", [3]="Medium", [4]="Large", [5]="Insane" }
                local hordeMap0 = { [0]="None", [1]="Small", [2]="Medium", [3]="Large", [4]="Insane" }
                hName = hordeMap1[num] or hordeMap0[num] or "Medium"
            end
        end
    elseif RadioTrader_Config.HORDE_SIZE then
        hName = RadioTrader_Config.HORDE_SIZE
    end
    local entry = RadioTrader_Config.HORDE_SIZE_TABLE[hName] or RadioTrader_Config.HORDE_SIZE_TABLE["Medium"]
    return (entry and entry.min or 0), (entry and entry.max or 0), hName, raw
end

-- ---------------------------------------------------------------------------
-- ModData キー定数
-- ---------------------------------------------------------------------------
RadioTrader_Config.KEY_LZ_X         = "RadioTrader_LZ_X"
RadioTrader_Config.KEY_LZ_Y         = "RadioTrader_LZ_Y"
RadioTrader_Config.KEY_LZ_Z         = "RadioTrader_LZ_Z"
RadioTrader_Config.KEY_CREDITS      = "RadioTrader_Credits"
RadioTrader_Config.KEY_DELIVERY     = "RadioTrader_DeliveryState"
RadioTrader_Config.KEY_DELIVER_TIME = "RadioTrader_DeliveryTargetHour"
RadioTrader_Config.KEY_ORDER        = "RadioTrader_PendingOrder"

-- イベントコマンド名
RadioTrader_Config.CMD_REQUEST_TRADE   = "requestTrade"
RadioTrader_Config.CMD_REQUEST_SELL    = "requestSell"
RadioTrader_Config.CMD_REQUEST_DROP    = "requestDrop"   -- 手動投下要請
RadioTrader_Config.CMD_TRADE_ACCEPTED  = "tradeAccepted"
RadioTrader_Config.CMD_HELI_APPROACH   = "heliApproaching"
RadioTrader_Config.CMD_HELI_HOVER_START = "heliHoverStart" -- ヘリLZ到着・ホバリング開始（サーチライト点灯）
RadioTrader_Config.CMD_HELI_HOVER_END   = "heliHoverEnd"   -- ヘリホバリング終了・離脱（サーチライト消灯）
RadioTrader_Config.CMD_DELIVERY_DONE   = "deliveryComplete"
RadioTrader_Config.CMD_CREDIT_UPDATE   = "creditUpdate"
RadioTrader_Config.CMD_ORDER_EXPIRED   = "orderExpired"  -- 要請期限切れ通知



-- 配達ステート定数
RadioTrader_Config.STATE_NONE          = "NONE"
RadioTrader_Config.STATE_PENDING       = "PENDING"
RadioTrader_Config.STATE_APPROACHING   = "APPROACHING"
RadioTrader_Config.STATE_READY_FOR_DROP = "READY_FOR_DROP" -- 到着済み・投下要請待ち
RadioTrader_Config.STATE_DELIVERING    = "DELIVERING"
RadioTrader_Config.STATE_COMPLETED     = "COMPLETED"

-- ---------------------------------------------------------------------------
-- 初期化をゲーム起動時およびワールド読み込み時に自動実行
-- ---------------------------------------------------------------------------
Events.OnGameBoot.Add(function()
    RadioTrader_Config.init()
end)
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(function()
        RadioTrader_Config.init()
    end)
end
if Events.OnGameStart then
    Events.OnGameStart.Add(function()
        RadioTrader_Config.init()
    end)
end
if Events.OnServerStarted then
    Events.OnServerStarted.Add(function()
        RadioTrader_Config.init()
    end)
end
