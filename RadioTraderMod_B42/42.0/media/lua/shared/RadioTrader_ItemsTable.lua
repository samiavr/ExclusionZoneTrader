-- =============================================================================
-- RadioTrader_ItemsTable.lua
-- [Shared] 売買可能アイテム定義テーブル
-- =============================================================================
-- カテゴリ別購入テーブルと売却査定対象テーブルを定義します。
-- price はクレジット単位。表示名はバニラAPI（getItemNameFromFullType）で自動取得されます。
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 箱詰め缶詰（ランダム配達用テーブル）
-- ---------------------------------------------------------------------------
RadioTrader_CannedBoxes = {
    "Base.CannedBolognese_Box",
    "Base.CannedCornedBeef_Box",
    "Base.CannedChili_Box",
    "Base.CannedFruitCocktail_Box",
    "Base.CannedPeaches_Box",
    "Base.CannedPineapple_Box",
    "Base.CannedMushroomSoup_Box",
    "Base.CannedSardines_Box",
    "Base.CannedTomato_Box",
    "Base.CannedPotato_Box",
    "Base.CannedCarrots_Box",
    "Base.CannedPeas_Box",
    "Base.CannedCorn_Box",
    "Base.CannedMilk_Box",
}

function RadioTrader_ItemsTable_GetRandomCannedBox()
    local count = #RadioTrader_CannedBoxes
    if count == 0 then return "Base.CannedBolognese_Box" end
    local idx = 1
    if ZombRand then
        idx = ZombRand(count) + 1
    else
        idx = math.random(1, count)
    end
    return RadioTrader_CannedBoxes[idx] or "Base.CannedBolognese_Box"
end

-- ---------------------------------------------------------------------------
-- カテゴリ別バニラクレート動的自動探索テーブル（キャッシュ管理）
-- ---------------------------------------------------------------------------
-- バニラ本体の ProceduralDistributions.list の中から、各アイテム種別の Crate を動的に自動探索・キャッシュします。
local _cachedDynamicCrateDists = {}

function RadioTrader_ItemsTable_GetDynamicCrateLists(category)
    if not ProceduralDistributions or not ProceduralDistributions.list then return {} end
    if _cachedDynamicCrateDists[category] then
        return _cachedDynamicCrateDists[category]
    end

    local list = {}
    if category == "Sports" then
        for key, _ in pairs(ProceduralDistributions.list) do
            if string.find(key, "^Crate") then
                local lkey = string.lower(key)
                if string.find(lkey, "sport") or string.find(lkey, "baseball") or string.find(lkey, "basketball")
                or string.find(lkey, "golf") or string.find(lkey, "soccer") or string.find(lkey, "football")
                or string.find(lkey, "fitness") or string.find(lkey, "tennis") or string.find(lkey, "gym") then
                    table.insert(list, key)
                end
            end
        end
    elseif category == "Welding" then
        for key, _ in pairs(ProceduralDistributions.list) do
            if string.find(key, "^Crate") then
                local lkey = string.lower(key)
                if (string.find(lkey, "metal") or string.find(lkey, "weld") or string.find(lkey, "pipe")
                or string.find(lkey, "sheetmetal") or string.find(lkey, "blacksmith") or string.find(lkey, "chains"))
                and not string.find(lkey, "locker") then
                    table.insert(list, key)
                end
            end
        end
    elseif category == "Carpentry" then
        for key, _ in pairs(ProceduralDistributions.list) do
            if string.find(key, "^Crate") then
                local lkey = string.lower(key)
                if (string.find(lkey, "tool") or string.find(lkey, "carpentry") or string.find(lkey, "lumber")
                or string.find(lkey, "concrete") or string.find(lkey, "plaster") or string.find(lkey, "paint")
                or string.find(lkey, "clay") or string.find(lkey, "masonry") or string.find(lkey, "sandbag")
                or string.find(lkey, "gravel"))
                and not string.find(lkey, "chair") and not string.find(lkey, "stool") then
                    table.insert(list, key)
                end
            end
        end
    elseif category == "Food" then
        local foodWords = {
            "food", "canned", "cereal", "chips", "candy", "chocolate", "beer", "soda", "wine",
            "coffee", "tea", "buns", "butter", "flour", "rice", "pasta", "sugar", "oil",
            "sauce", "crackers", "macaroni", "popcorn", "marinara", "marshmallows", "yeast",
            "condiments", "peanuts", "graham", "cocoa", "baking"
        }
        -- 腐敗品(Spoiled)や家畜の飼料(Animal/Feed)、設備・ゴミ類は厳格に除外
        local excludeWords = {
            "spoiled", "animal", "feed", "toilet", "table", "chair", "sink", "oven", "stove"
        }
        for key, _ in pairs(ProceduralDistributions.list) do
            if string.find(key, "^Crate") then
                local lkey = string.lower(key)
                local matched = false
                for _, fw in ipairs(foodWords) do
                    if string.find(lkey, fw, 1, true) then
                        matched = true
                        break
                    end
                end
                if matched then
                    local excluded = false
                    for _, ew in ipairs(excludeWords) do
                        if string.find(lkey, ew, 1, true) then
                            excluded = true
                            break
                        end
                    end
                    if not excluded then
                        table.insert(list, key)
                    end
                end
            end
        end
    end

    _cachedDynamicCrateDists[category] = list
    return list
end

-- ---------------------------------------------------------------------------
-- ミステリー家具抽選（バニラの家具木箱ディストリビューションから動的自動探索）
-- ---------------------------------------------------------------------------
-- バニラ本体の ProceduralDistributions.list から "Crate...Chair/Table/Stove" 等を
-- 実行時に自動収集・キャッシュし、MOD側でのリスト管理を完全不要にします。
-- 配達時は必ずミリタリー木箱（Base.Mov_MilitaryCrate）が1個届き、
-- さらにバニラ家具クレート抽選テーブルから引かれた家具現品（Mov_...）が同封されます。
local _cachedFurnitureDists = nil

function RadioTrader_ItemsTable_GetRandomFurniture()
    if not ProceduralDistributions or not ProceduralDistributions.list then return nil end

    if not _cachedFurnitureDists then
        _cachedFurnitureDists = {}
        for key, _ in pairs(ProceduralDistributions.list) do
            if string.find(key, "^Crate") then
                local lkey = string.lower(key)
                if string.find(lkey, "chair") or string.find(lkey, "table") or string.find(lkey, "stove")
                or string.find(lkey, "desk") or string.find(lkey, "couch") or string.find(lkey, "shelf")
                or string.find(lkey, "bench") or string.find(lkey, "bed") then
                    table.insert(_cachedFurnitureDists, key)
                end
            end
        end
    end

    if #_cachedFurnitureDists == 0 then return nil end

    local idx = 1
    if ZombRand then
        idx = ZombRand(#_cachedFurnitureDists) + 1
    else
        idx = math.random(1, #_cachedFurnitureDists)
    end

    local distName = _cachedFurnitureDists[idx]
    return RadioTrader_ItemsTable_RollProceduralItem(distName)
end

-- ---------------------------------------------------------------------------
-- クレート定義テーブル（バニラの ProceduralDistributions から動的抽選してダッフルバッグに充填）
-- ---------------------------------------------------------------------------
-- ※価格は基準価格（basePrice）。設定の BuyPriceMultiplier（デフォルト2.0倍）が掛け合わされます。
RadioTrader_CrateDefinitions = {

    RadioTrader_Crate_Food = {
        id = "RadioTrader_Crate_Food",
        name = "Food Supply Duffel Bag",
        price = 600,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 10,
        dynamicCategory = "Food",
        cannedBoxChance = 20, -- 20%の低確率で箱詰め缶詰が1個ボーナス封入
        distributionLists = {
            "GigamartCannedFood",
            "GigamartDryGoods",
            "GigamartCandy",
            "GigamartBreakfast",
            "KitchenCannedFood",
            "KitchenDryFood",
            "KitchenBaking",
            "ArmySurplusSnacks",
        },
    },

    RadioTrader_Crate_Medical = {
        id = "RadioTrader_Crate_Medical",
        name = "Medical Aid Duffel Bag",
        price = 800,
        container = "Base.Bag_DuffelBag",
        minItems = 3,
        maxItems = 9,
        distributionLists = {
            "ArmyStorageMedical",
            "MedicalClinicDrugs",
            "PharmacyDrugs",
            "HospitalSupplies",
            "AmbulanceDriverTools",
        },
    },

    RadioTrader_Crate_Weapons = {
        id = "RadioTrader_Crate_Weapons",
        name = "Arms & Ammo Duffel Bag",
        price = 1000,
        container = "Base.Bag_DuffelBag",
        minItems = 3,
        maxItems = 8,
        distributionLists = {
            "ArmyStorageAmmunition",
            "ArmySurplusAmmoBoxes",
            "GunStoreAmmunition",
            "GunStoreMagsAmmo",
            "GunStorePistols",
            "GunStoreShotguns",
            "GunStoreRifles",
            "PoliceStorageGuns",
        },
    },

    RadioTrader_Crate_Carpentry = {
        id = "RadioTrader_Crate_Carpentry",
        name = "Tools & Carpentry Duffel Bag",
        price = 700,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 9,
        dynamicCategory = "Carpentry",
        distributionLists = {
            "ToolStoreTools",
            "CarpenterTools",
            "LoggingFactoryTools",
            "ConstructionWorkerTools",
        },
    },

    RadioTrader_Crate_Welding = {
        id = "RadioTrader_Crate_Welding",
        name = "Metal & Welding Duffel Bag",
        price = 650,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 9,
        dynamicCategory = "Welding",
        distributionLists = {
            "WeldingWorkshopMetal",
            "WeldingWorkshopTools",
        },
    },

    RadioTrader_Crate_Vehicles = {
        id = "RadioTrader_Crate_Vehicles",
        name = "Vehicle Mechanics Duffel Bag",
        price = 750,
        container = "Base.Bag_DuffelBag",
        minItems = 3,
        maxItems = 8,
        distributionLists = {
            "CarSupplyBatteries",
            "CarSupplyTools",
            "CarSupplyGasCans",
            "MechanicShelfTools",
            "MechanicShelfMisc",
        },
    },

    RadioTrader_Crate_Fishing = {
        id = "RadioTrader_Crate_Fishing",
        name = "Fishing Tackle Duffel Bag",
        price = 500,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 10,
        distributionLists = {
            "FishingStoreGear",
            "FishingStoreBait",
            "FishermanTools",
        },
    },

    RadioTrader_Crate_Books = {
        id = "RadioTrader_Crate_Books",
        name = "Books & Media Duffel Bag",
        price = 450,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 10,
        distributionLists = {
            "BookstoreBooks",
            "BookstoreMagazines",
            "BookstoreComics",
            "CarpentryBooks",
            "MechanicShelfBooks",
            "GunStoreLiterature",
            "BookstoreHobbies",
            "BookstoreCrafts",
        },
    },

    RadioTrader_Crate_Sports = {
        id = "RadioTrader_Crate_Sports",
        name = "Sports Equipment Duffel Bag",
        price = 550,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 8,
        dynamicCategory = "Sports",
        distributionLists = {
            "CrateSports",
            "SchoolGymSportsGear",
            "ClosetSportsEquipment",
        },
        customItems = {
            "Base.BaseballBat",
            "Base.BaseballBat_Metal",
            "Base.Golfclub",
            "Base.TennisRacket",
            "Base.IceHockeyStick",
            "Base.BadmintonRacket",
            "Base.LaCrosseStick",
            "Base.Poolcue",
            "Base.DumbBell",
            "Base.Football",
            "Base.Basketball",
            "Base.Baseball",
            "Base.Gloves_IceHockeyGloves_Black",
            "Base.Hat_HockeyMask",
            "Base.Hat_FootballHelmet",
        },
    },

    RadioTrader_Crate_Blades = {
        id = "RadioTrader_Crate_Blades",
        name = "Blades & Axes Duffel Bag",
        price = 1300,
        container = "Base.Bag_DuffelBag",
        minItems = 3,
        maxItems = 6,
        distributionLists = {
            "FiremanTools",
            "FireStorageTools",
            "LoggingFactoryTools",
            "KnifeFactoryTools",
            "KitchenKnives",
            "ButcherTools",
        },
        customItems = {
            "Base.Axe",
            "Base.HandAxe",
            "Base.WoodAxe",
            "Base.FireAxeHead",
            "Base.HandAxeHead",
            "Base.WoodAxeHead",
            "Base.HuntingKnife",
            "Base.KitchenKnife",
            "Base.MeatCleaver",
            "Base.Machete",
            "Base.Whetstone",
        },
    },

    RadioTrader_Crate_Apparel = {
        id = "RadioTrader_Crate_Apparel",
        name = "Apparel & Armor Surprise Bag",
        price = 850,
        container = "Base.Bag_DuffelBag",
        minItems = 8,
        maxItems = 16,
        distributionLists = {
            "FireStorageOutfit",
            "PoliceStorageOutfit",
            "ArmyStorageClothing",
            "CrateClothesRandom",
            "OutdoorSupplyClothes",
        },
        customItems = {
            "Base.Vest_BulletCivilian",
            "Base.Vest_BulletPolice",
            "Base.Vest_BulletArmy",
            "Base.Jacket_Fireman",
            "Base.Trousers_Fireman",
            "Base.Hat_Fireman",
            "Base.Hat_CrashHelmet",
            "Base.Hat_RiotHelmet",
            "Base.Hat_HardHat",
            "Base.ShemaghScarf",
            "Base.ShemaghScarf_Green",
            "Base.Scarf_White",
            "Base.Scarf_StripeBlackWhite",
        },
    },

    RadioTrader_Crate_Fuel = {
        id = "RadioTrader_Crate_Fuel",
        name = "Fuels & Fire Supplies Duffel Bag",
        price = 750,
        container = "Base.Bag_DuffelBag",
        minItems = 3,
        maxItems = 6,
        distributionLists = {
            "WeldingWorkshopFuel",
            "CarSupplyGasCans",
        },
        customItems = {
            "Base.PetrolCan",
            "Base.LighterFluid",
            "Base.Lantern_Hurricane",
            "Base.PropaneTank",
            "Base.BlowTorch",
            "Base.Lighter",
            "Base.Matches",
            "Base.Charcoal",
        },
    },

    -- トレーダーのごみ袋（長期生存支援物資・放出品）
    RadioTrader_Crate_TrashBag = {
        id = "RadioTrader_Crate_TrashBag",
        name = "Trader's Mystery Trash Bag",
        price = 350,
        container = "Base.Garbagebag",
        isTrashBag = true,
    },
}

-- ---------------------------------------------------------------------------
-- バニラルートテーブルからアイテムを重み付け抽選
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_RollProceduralItem(distName)
    if not ProceduralDistributions or not ProceduralDistributions.list then return nil end
    local dist = ProceduralDistributions.list[distName]
    if not dist or not dist.items or #dist.items < 2 then return nil end

    local items = dist.items
    -- 1. 重みの合計を計算 (奇数がアイテム名、偶数がウェイト)
    local totalWeight = 0
    for i = 2, #items, 2 do
        local w = items[i]
        if type(w) == "number" and w > 0 then
            totalWeight = totalWeight + w
        end
    end
    if totalWeight <= 0 then return nil end

    -- 2. 乱数でアイテム選定
    local roll = 0
    if ZombRandFloat then
        roll = ZombRandFloat(0, totalWeight)
    else
        roll = math.random() * totalWeight
    end

    local current = 0
    for i = 2, #items, 2 do
        local w = items[i]
        if type(w) == "number" and w > 0 then
            current = current + w
            if roll <= current then
                local itemName = items[i - 1]
                if itemName and not string.find(itemName, "%.") then
                    itemName = "Base." .. itemName
                end
                return itemName
            end
        end
    end

    local fallback = items[1]
    if fallback and not string.find(fallback, "%.") then
        fallback = "Base." .. fallback
    end
    return fallback
end

-- ---------------------------------------------------------------------------
-- バニラルートテーブルからアイテム名と重みを重み付け抽選
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_RollProceduralItemWithWeight(distName)
    if not ProceduralDistributions or not ProceduralDistributions.list then return nil, 0 end
    local dist = ProceduralDistributions.list[distName]
    if not dist or not dist.items or #dist.items < 2 then return nil, 0 end

    local items = dist.items
    local totalWeight = 0
    for i = 2, #items, 2 do
        local w = items[i]
        if type(w) == "number" and w > 0 then
            totalWeight = totalWeight + w
        end
    end
    if totalWeight <= 0 then return nil, 0 end

    local roll = 0
    if ZombRandFloat then
        roll = ZombRandFloat(0, totalWeight)
    else
        roll = math.random() * totalWeight
    end

    local current = 0
    for i = 2, #items, 2 do
        local w = items[i]
        if type(w) == "number" and w > 0 then
            current = current + w
            if roll <= current then
                local itemName = items[i - 1]
                if itemName and not string.find(itemName, "%.") then
                    itemName = "Base." .. itemName
                end
                return itemName, w
            end
        end
    end

    local fallback = items[1]
    if fallback and not string.find(fallback, "%.") then
        fallback = "Base." .. fallback
    end
    return fallback, items[2] or 1.0
end

-- ---------------------------------------------------------------------------
-- 日替わりスポット品目 抽選用バニラCrate定義群
-- ---------------------------------------------------------------------------
RadioTrader_DailyCrateCategories = {
    { category = "Carpentry",  label = "Carpentry", dists = { "CrateCarpentry", "CrateLumber", "CrateTools", "CrateToolsOld" } },
    { category = "Pottery",    label = "Pottery",   dists = { "CratePottery", "CrateClayBags", "CrateClayBricks", "CrateMasonry" } },
    { category = "Blacksmith", label = "Metalwork", dists = { "CrateBlacksmithing", "CrateMetalwork", "CrateSheetMetal" } },
    { category = "Electric",   label = "Electric",  dists = { "CrateElectronics", "CrateBatteries" } },
    { category = "AnimalFarm", label = "Farming",   dists = { "CrateAnimalFeed", "CrateFarming", "CrateFertilizer" } },
    { category = "Medical",    label = "Medical",   dists = { "CrateHumanitarian", "ArmyStorageMedical", "MedicalClinicDrugs" } },
    { category = "Food",       label = "Food",      dists = { "CrateCannedFood", "CrateFlour", "CrateRice", "CratePasta" } },
    { category = "Building",   label = "Building",  dists = { "CrateConcrete", "CrateSandBags", "CrateGravelBags", "CratePaint" } },
    { category = "Tailoring",  label = "Tailoring", dists = { "SewingStoreFabric", "SewingStoreTools", "CrateFabric_Cotton", "CrateFabric_DenimBlue", "CrateLeather", "CrateTailoring" } },
}

-- アイテムのウェイト・種別から価格と販売数量を自動算出
local function calculateDailyItemPriceAndCount(itemId, weight)
    local count = 1
    local price = 250

    if not weight or weight <= 0 then weight = 1.0 end

    if weight <= 0.1 then
        -- 激レア品 (例: Axe, BenchAnvil, 貴重スキル本等) - 4倍ベース
        count = 1
        price = 3200
    elseif weight <= 1.0 then
        -- レア品 (例: 工具・特殊医薬品・中間スキル本等) - 4倍ベース
        count = 1
        price = 1680
    elseif weight <= 10.0 then
        -- アンコモン - 4倍ベース
        count = (ZombRand and (ZombRand(2) + 1)) or 1
        price = 960
    else
        -- コモン資材 (木板・粘土・釘・砂袋・セメント・布束・糸など実用資材) - 4倍ベース
        if string.find(itemId, "Plank") or string.find(itemId, "ClayBrick") then
            count = 10
            price = 880
        elseif string.find(itemId, "FabricRoll") or string.find(itemId, "Leather") then
            -- 布束・布ロール・革材
            count = 2
            price = 720
        elseif string.find(itemId, "Thread") or string.find(itemId, "Yarn") then
            -- 糸・毛糸（まとめ買い需要）
            count = 4
            price = 560
        elseif string.find(itemId, "Claybag") or string.find(itemId, "ConcretePowder")
            or string.find(itemId, "Sandbag") or string.find(itemId, "Gravelbag")
            or string.find(itemId, "SheetMetal") or string.find(itemId, "BatteryBox") then
            count = 4
            price = 800
        elseif string.find(itemId, "NailsBox") or string.find(itemId, "ScrewsBox") or string.find(itemId, "Fertilizer")
            or string.find(itemId, "AnimalFeedBag") or string.find(itemId, "Wheat") then
            count = 2
            price = 720
        else
            count = 3
            price = 640
        end
    end

    -- 特殊高額機材・装備への例外調整
    if string.find(itemId, "Generator") then
        count = 1
        price = 5000
    elseif string.find(itemId, "ALICEpack") then
        count = 1
        price = 3000
    end

    return count, price
end

-- ---------------------------------------------------------------------------
-- 日替わりスポット品目の動的選定・生成関数
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_RollDailyShop()
    local dailyItems = {}
    local cats = {}
    for _, c in ipairs(RadioTrader_DailyCrateCategories) do
        table.insert(cats, c)
    end

    -- シャッフル
    local n = #cats
    for i = n, 2, -1 do
        local j = (ZombRand and (ZombRand(i) + 1)) or math.random(1, i)
        cats[i], cats[j] = cats[j], cats[i]
    end

    local pickedCount = math.min(6, #cats)
    local seenIds = {}

    for k = 1, pickedCount do
        local cat = cats[k]
        local dists = cat.dists
        local dIdx = (ZombRand and (ZombRand(#dists) + 1)) or math.random(1, #dists)
        local distName = dists[dIdx]

        local itemId, weight = RadioTrader_ItemsTable_RollProceduralItemWithWeight(distName)
        if itemId and not seenIds[itemId] then
            seenIds[itemId] = true
            local count, price = calculateDailyItemPriceAndCount(itemId, weight)
            local entry = {
                id       = itemId,
                name     = itemId,
                price    = price,
                count    = count,
                category = "Daily",
                subCat   = cat.category
            }
            table.insert(dailyItems, entry)
        end
    end

    RadioTrader_Shop.Daily = dailyItems
    return dailyItems
end

-- ---------------------------------------------------------------------------
-- トレーダーのごみ袋充填処理 (長期生存支援物資・放出品)
-- ---------------------------------------------------------------------------
-- 1〜7のカテゴリから重複しない2つのカテゴリを重み付け抽選し、各2〜4個充填。
-- さらに確定でお菓子系テーブルから1〜2個のおやつを同梱。
-- ---------------------------------------------------------------------------
-- トレーダーのごみ袋充填処理 (長期生存支援物資・放出品)
-- ---------------------------------------------------------------------------
-- 通常時は1〜6のカテゴリから重複しない2つのカテゴリを重み付け抽選し、各2〜4個充填＋お菓子。
-- プレッパー枠（約5%の激レア超大当たり）当選時は、激レア品1種（またはサバイバルセット）とお菓子のみ封入。
function RadioTrader_ItemsTable_FillTrashBag(bagContainer)
    if not bagContainer then return 0 end
    local addedCount = 0

    local function addItems(fullType, count)
        local script = getItem(fullType)
        if script then
            for i = 1, (count or 1) do
                local itm = instanceItem(fullType)
                if itm then
                    bagContainer:AddItem(itm)
                    addedCount = addedCount + 1
                end
            end
        end
    end

    local snackItems = {
        "Base.Crisps", "Base.Popcorn", "Base.CandyPackage",
        "Base.Chocolate", "Base.GummyBears", "Base.JellyBeans"
    }
    local function spawnSnacks()
        local snackCount = (ZombRand and ZombRand(1, 3)) or math.random(1, 2)
        for i = 1, snackCount do
            local sIdx = (ZombRand and (ZombRand(#snackItems) + 1)) or math.random(1, #snackItems)
            addItems(snackItems[sIdx], 1)
        end
    end

    -- =========================================================================
    -- 1. プレッパー超大当たり判定 (5 / 115 ≒ 約4.3% の激レア確率)
    -- =========================================================================
    local totalWeight = 115
    local roll = (ZombRandFloat and ZombRandFloat(0, totalWeight)) or (math.random() * totalWeight)
    if roll < 5 then
        local subRoll = (ZombRand and ZombRand(3)) or math.random(0, 2)
        if subRoll == 0 then
            -- パターンA: 近接・破壊の最高峰 または 万能マルチツール2個セット
            local tools = {
                "Base.Katana",
                "Base.Machete",
                "Base.Sledgehammer",
                "Base.Sledgehammer2",
                "Base.PickAxe",
                "Base.Multitool",
            }
            local tIdx = (ZombRand and (ZombRand(#tools) + 1)) or math.random(1, #tools)
            local chosen = tools[tIdx]
            if chosen == "Base.Multitool" then
                addItems(chosen, 2) -- マルチツールは2個セット！
            else
                addItems(chosen, 1)
            end
        elseif subRoll == 1 then
            -- パターンB: ALICE系装備（アリスパック単体、またはALICEベルトサスペンダー＋懐中電灯＋電池箱セット）
            local isPack = ((ZombRand and ZombRand(2)) or math.random(0, 1)) == 0
            if isPack then
                local packs = { "Base.Bag_ALICEpack", "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack_DesertCamo" }
                local pIdx = (ZombRand and (ZombRand(#packs) + 1)) or math.random(1, #packs)
                addItems(packs[pIdx], 1)
            else
                local belts = { "Base.Bag_ALICE_BeltSus", "Base.Bag_ALICE_BeltSus_Camo", "Base.Bag_ALICE_BeltSus_Green" }
                local bIdx = (ZombRand and (ZombRand(#belts) + 1)) or math.random(1, #belts)
                addItems(belts[bIdx], 1)
                addItems("Base.FlashLight_AngleHead_Army", 1) -- 米軍アングルヘッド懐中電灯
                addItems("Base.BatteryBox", 1)                 -- 乾電池の箱
            end
        else
            -- パターンC: プレッパー緊急サバイバル＆医療セット（豪華一式）
            addItems("Base.WaterPurificationTablets", 1)
            addItems("Base.PillsVitamins", 1)
            addItems("Base.BeefJerky", 5) -- ビーフジャーキー5個！
            local ponchos = { "Base.PonchoGreen", "Base.PonchoYellow", "Base.PonchoTarp" }
            local pIdx = (ZombRand and (ZombRand(#ponchos) + 1)) or math.random(1, #ponchos)
            addItems(ponchos[pIdx], 1)
            -- 医療品セット
            addItems("Base.Antibiotics", 3)
            addItems("Base.Disinfectant", 1)
            addItems("Base.CottonBalls", 5)
            addItems("Base.SutureNeedleBox", 1)
            addItems("Base.Bandage", 1)
        end

        -- プレッパー当選時は、それとお菓子1〜2個のみで終了
        spawnSnacks()
        return addedCount
    end

    -- =========================================================================
    -- 2. 通常当選時：1〜6のカテゴリから重複しない2つを重み付け抽選
    -- =========================================================================
    local categories = {
        { id = "Farming",     weight = 15, dists = { "CrateFarming", "CrateGardening", "CrateFertilizer" }, items = { "Base.Fertilizer", "Base.WateredCan", "Base.HandShovel" } },
        { id = "Livestock",   weight = 10, dists = { "CrateAnimalFeed" }, items = { "Base.AnimalFeedBag", "Base.Rope" } },
        { id = "Electronics", weight = 15, dists = { "CrateElectronics", "CrateBatteries" }, items = { "Base.ElectronicsScrap", "Base.ElectricWire", "Base.Battery" } },
        { id = "Nails",       weight = 15, dists = { "ToolStoreCarpentry", "CarpenterTools", "ConstructionWorkerTools" }, items = { "Base.NailsBox", "Base.ScrewsBox", "Base.Doorknob", "Base.Hinge", "Base.BarbedWire" } },
        { id = "Hygiene",     weight = 20, dists = { "CrateLinens", "CrateToiletPaper", "CrateSalonSupplies" }, items = { "Base.Soap2", "Base.Bleach", "Base.BathTowel", "Base.ToiletPaper" } },
        { id = "Vice",        weight = 35, dists = { "CrateCigarettes", "CrateBeer", "CrateLiquor", "CrateWine", "CrateCoffee", "CrateChocolate" }, items = { "Base.CigarettePack", "Base.CigaretteCarton", "Base.Lighter", "Base.Matches", "Base.Whiskey", "Base.BeerCan" } },
    }

    local function pickCategory(excludeIdx)
        local normalWeight = 0
        for i, c in ipairs(categories) do
            if i ~= excludeIdx then
                normalWeight = normalWeight + c.weight
            end
        end
        local cRoll = (ZombRandFloat and ZombRandFloat(0, normalWeight)) or (math.random() * normalWeight)
        local cur = 0
        for i, c in ipairs(categories) do
            if i ~= excludeIdx then
                cur = cur + c.weight
                if cRoll <= cur then
                    return i, c
                end
            end
        end
        return 1, categories[1]
    end

    local idx1, cat1 = pickCategory(-1)
    local idx2, cat2 = pickCategory(idx1)

    local function spawnFromCategory(cat, count)
        for i = 1, count do
            local itemId = nil
            local rollVal = (ZombRand and ZombRand(100)) or math.random(0, 99)
            local usePool = rollVal < 50
            if usePool and #cat.items > 0 then
                local pIdx = (ZombRand and (ZombRand(#cat.items) + 1)) or math.random(1, #cat.items)
                itemId = cat.items[pIdx]
            elseif #cat.dists > 0 then
                local dIdx = (ZombRand and (ZombRand(#cat.dists) + 1)) or math.random(1, #cat.dists)
                itemId = RadioTrader_ItemsTable_RollProceduralItem(cat.dists[dIdx])
            elseif #cat.items > 0 then
                local pIdx = (ZombRand and (ZombRand(#cat.items) + 1)) or math.random(1, #cat.items)
                itemId = cat.items[pIdx]
            end

            if itemId then
                addItems(itemId, 1)
            end
        end
    end

    local count1 = (ZombRand and ZombRand(2, 5)) or math.random(2, 4)
    local count2 = (ZombRand and ZombRand(2, 5)) or math.random(2, 4)
    spawnFromCategory(cat1, count1)
    spawnFromCategory(cat2, count2)

    -- おまけのお菓子 (1〜2個確定)
    spawnSnacks()

    return addedCount
end

-- ---------------------------------------------------------------------------
-- ダッフルバッグにバニラルートアイテムを充填（全体乱数カウント 3〜10 に収まるまで抽選）
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_FillDuffelBag(bagItem, crateDef)
    if not bagItem or not crateDef then return 0 end
    local bagContainer = bagItem:getItemContainer()
    if not bagContainer then return 0 end

    -- ゴミ袋の場合は専用の複合・重み付け抽選処理を実行
    if crateDef.isTrashBag then
        return RadioTrader_ItemsTable_FillTrashBag(bagContainer)
    end

    local minItems = crateDef.minItems or 3
    local maxItems = crateDef.maxItems or 10
    local targetCount = minItems
    if ZombRand then
        targetCount = ZombRand(minItems, maxItems + 1)
    else
        targetCount = math.random(minItems, maxItems)
    end

    -- 動的カテゴリ探索と静的リストの統合
    local lists = {}
    if crateDef.dynamicCategory then
        local dynLists = RadioTrader_ItemsTable_GetDynamicCrateLists(crateDef.dynamicCategory)
        if dynLists and #dynLists > 0 then
            for _, dl in ipairs(dynLists) do
                table.insert(lists, dl)
            end
        end
    end
    if crateDef.distributionLists then
        for _, dl in ipairs(crateDef.distributionLists) do
            table.insert(lists, dl)
        end
    end

    local customPool = crateDef.customItems or {}
    if #lists == 0 and #customPool == 0 then return 0 end

    -- 食料クレート等の場合: 低確率（約20%）でカスタム箱詰め缶詰が1個ボーナス封入
    if crateDef.cannedBoxChance and crateDef.cannedBoxChance > 0 then
        local rollVal = ZombRand and ZombRand(100) or math.random(0, 99)
        if rollVal < crateDef.cannedBoxChance then
            local bonusBoxId = RadioTrader_ItemsTable_GetRandomCannedBox()
            if bonusBoxId then
                local script = getItem(bonusBoxId)
                if script then
                    local spawnedBox = instanceItem(bonusBoxId)
                    if spawnedBox then
                        bagContainer:AddItem(spawnedBox)
                    end
                end
            end
        end
    end

    local addedCount = 0
    local attempts = 0
    while addedCount < targetCount and attempts < 100 do
        attempts = attempts + 1
        local itemId = nil

        -- customItems がある場合、約50%の確率（またはリストが空の場合）で直接プールから選出
        local usePool = false
        if #customPool > 0 then
            if #lists == 0 then
                usePool = true
            else
                local rollVal = ZombRand and ZombRand(100) or math.random(0, 99)
                if rollVal < 50 then
                    usePool = true
                end
            end
        end

        if usePool then
            local cIdx = 1
            if ZombRand then
                cIdx = ZombRand(#customPool) + 1
            else
                cIdx = math.random(1, #customPool)
            end
            itemId = customPool[cIdx]
        else
            local listIdx = 1
            if ZombRand then
                listIdx = ZombRand(#lists) + 1
            else
                listIdx = math.random(1, #lists)
            end
            local distName = lists[listIdx]
            itemId = RadioTrader_ItemsTable_RollProceduralItem(distName)
        end

        if itemId then
            local script = getItem(itemId)
            if script then
                -- B42: InventoryItemFactory.CreateItem は廃止。instanceItem() を使用。
                local spawned = instanceItem(itemId)
                if spawned then
                    bagContainer:AddItem(spawned)
                    addedCount = addedCount + 1
                end
            end
        end
    end
    return addedCount
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: 実効購入価格の算出（設定の BuyPriceMultiplier を適用）
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetEffectiveBuyPrice(basePrice)
    if not basePrice then return 0 end
    local mult = 2.0
    if RadioTrader_Config and RadioTrader_Config.getBuyPriceMultiplier then
        mult = RadioTrader_Config.getBuyPriceMultiplier()
    end
    return math.max(1, math.floor(basePrice * mult + 0.5))
end

-- ---------------------------------------------------------------------------
-- 購入可能アイテムテーブル（各カテゴリのダッフルバッグおよび大型機材）
-- ---------------------------------------------------------------------------
RadioTrader_Shop = {

    -- 種類別補給バッグ（全種集約・中央リストに並べて選択）
    Bags = {
        { id = "RadioTrader_Crate_Food",        name = "Food Supply Duffel Bag",        price = 600,  count = 1 },
        { id = "RadioTrader_Crate_Medical",     name = "Medical Aid Duffel Bag",        price = 800,  count = 1 },
        { id = "RadioTrader_Crate_Weapons",     name = "Arms & Ammo Duffel Bag",        price = 1000, count = 1 },
        { id = "RadioTrader_Crate_Blades",      name = "Blades & Axes Duffel Bag",      price = 1300, count = 1 },
        { id = "RadioTrader_Crate_Sports",      name = "Sports Equipment Duffel Bag",   price = 550,  count = 1 },
        { id = "RadioTrader_Crate_Apparel",     name = "Apparel & Armor Surprise Bag",  price = 850,  count = 1 },
        { id = "RadioTrader_Crate_Carpentry",   name = "Tools & Carpentry Duffel Bag",  price = 700,  count = 1 },
        { id = "RadioTrader_Crate_Welding",     name = "Metal & Welding Duffel Bag",    price = 650,  count = 1 },
        { id = "RadioTrader_Crate_Vehicles",    name = "Vehicle Mechanics Duffel Bag",  price = 750,  count = 1 },
        { id = "RadioTrader_Crate_Fuel",        name = "Fuels & Fire Supplies Duffel Bag", price = 750, count = 1 },
        { id = "RadioTrader_Crate_Fishing",     name = "Fishing Tackle Duffel Bag",     price = 500,  count = 1 },
        { id = "RadioTrader_Crate_Books",       name = "Books & Media Duffel Bag",      price = 450,  count = 1 },
        { id = "RadioTrader_Mystery_Furniture", name = "Mystery Furniture Delivery",   price = 1800, count = 1 },
    },

    -- 食料補給 (互換用)
    Food = {
        { id = "RadioTrader_Crate_Food",      name = "Food Supply Duffel Bag",        price = 600,  count = 1  },
    },

    -- 医療支援
    Medical = {
        { id = "RadioTrader_Crate_Medical",   name = "Medical Aid Duffel Bag",        price = 800,  count = 1  },
    },

    -- 銃器弾薬
    Weapons = {
        { id = "RadioTrader_Crate_Weapons",   name = "Arms & Ammo Duffel Bag",        price = 1000, count = 1  },
    },

    -- 工具大工
    Carpentry = {
        { id = "RadioTrader_Crate_Carpentry", name = "Tools & Carpentry Duffel Bag",  price = 700,  count = 1  },
    },

    -- 金属溶接
    Welding = {
        { id = "RadioTrader_Crate_Welding",   name = "Metal & Welding Duffel Bag",    price = 650,  count = 1  },
    },

    -- 車両パーツ
    Vehicles = {
        { id = "RadioTrader_Crate_Vehicles",  name = "Vehicle Mechanics Duffel Bag",  price = 750,  count = 1  },
    },

    -- 釣り具
    Fishing = {
        { id = "RadioTrader_Crate_Fishing",   name = "Fishing Tackle Duffel Bag",     price = 500,  count = 1  },
    },

    -- 書籍・雑誌（娯楽・スキル・切り抜き・雑誌）
    Books = {
        { id = "RadioTrader_Crate_Books",     name = "Books & Media Duffel Bag",      price = 450,  count = 1  },
    },

    -- スポーツ用品
    Sports = {
        { id = "RadioTrader_Crate_Sports",    name = "Sports Equipment Duffel Bag",   price = 550,  count = 1  },
    },

    -- 刃物・斧系（割高）
    Blades = {
        { id = "RadioTrader_Crate_Blades",    name = "Blades & Axes Duffel Bag",      price = 1300, count = 1  },
    },

    -- 防具・衣料品（大量ランダム）
    Apparel = {
        { id = "RadioTrader_Crate_Apparel",   name = "Apparel & Armor Surprise Bag",  price = 850,  count = 1  },
    },

    -- 燃料・熱源
    Fuel = {
        { id = "RadioTrader_Crate_Fuel",      name = "Fuels & Fire Supplies Duffel Bag", price = 750, count = 1 },
    },

    -- ミステリー家具配送（高額・1点限定）
    Furniture = {
        { id = "RadioTrader_Mystery_Furniture", name = "Mystery Furniture Delivery",   price = 1800, count = 1 },
    },

    -- その他・放出品・大型機材（バッグに入らない重機材や設置式設備）
    Misc = {
        { id = "RadioTrader_Crate_TrashBag",      name = "Trader's Mystery Trash Bag",    price = 350,  count = 1 },
        { id = "Base.Generator",                  name = "Generator",                     price = 5000, count = 1 },
        { id = "Base.Mov_RoadBarrier",            name = "Concrete Barricade",            price = 2000, count = 1 },
        { id = "Base.Mov_LightConstruction",      name = "Flood Lights",                  price = 5000, count = 1 },
        { id = "Base.Battery",                    name = "Battery",                       price = 90,   count = 2 },
    },

    -- 日替わり特売・スポット入荷枠（バニラCrateから動的抽選・初期空テーブル）
    Daily = {},
}

-- ---------------------------------------------------------------------------
-- 売却査定対象テーブル (仕様書 5.2 準拠: 隔離地域遺物・一次資料・貴金属・農作物)
-- ---------------------------------------------------------------------------
-- 外の世界の富裕層・好事家需要があるものを買取。
-- ただし「高地の山荘」経済同様、ヘリの回収リスク・空輸輸送費・検疫マージンが
-- 査定額から差し引かれるため、現地での手取り価格は控えめになります。
-- ---------------------------------------------------------------------------
RadioTrader_Sell = {

    -- =========================================================================
    -- カテゴリ1: 一次資料・記録・記念品 (Archives & Memorabilia)
    -- =========================================================================
    -- 「失われたノックスの生々しい記録」として歴史家・メディアが高値で争奪
    -- （※現地回収手数料が引かれた実効買取額）
    { id = "Base.Journal",             name = "Journal",              basePricePerUnit = 40,  category = "Archives" },
    { id = "Base.Notebook",            name = "Notebook",             basePricePerUnit = 25,  category = "Archives" },
    { id = "Base.Diary1",              name = "Diary",                basePricePerUnit = 40,  category = "Archives" },
    { id = "Base.Diary2",              name = "Diary",                basePricePerUnit = 40,  category = "Archives" },
    { id = "Base.SheetMusic",          name = "Sheet Music",          basePricePerUnit = 20,  category = "Archives" },
    { id = "Base.LetterHandwritten",   name = "Handwritten Letter",   basePricePerUnit = 30,  category = "Archives" },
    { id = "Base.GenericMail",         name = "Postal Mail",          basePricePerUnit = 17,  category = "Archives" },
    { id = "Base.Brochure",            name = "Brochure / Flyer",     basePricePerUnit = 12,  category = "Archives" },
    { id = "Base.Note",                name = "Survivor Note",        basePricePerUnit = 17,  category = "Archives" },
    { id = "Base.Notepad",             name = "Notepad",              basePricePerUnit = 25,  category = "Archives" },
    { id = "Base.SheetPaper2",         name = "Piece of Paper",       basePricePerUnit = 7,   category = "Archives" },
    { id = "Base.Postcard",            name = "Postcard",             basePricePerUnit = 15,  category = "Archives" },

    -- =========================================================================
    -- カテゴリ2: 貴金属・ジュエリー・高級時計 (Precious & Jewelry)
    -- =========================================================================
    -- 封鎖地域から持ち出される本物の金・宝石・高級アンティーク
    -- 金・ルビー・ダイヤ指輪
    { id = "Base.Ring_Right_RingFinger_GoldDiamond",   name = "Gold Diamond Ring",   basePricePerUnit = 140, category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_GoldDiamond",    name = "Gold Diamond Ring",   basePricePerUnit = 140, category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_GoldDiamond", name = "Gold Diamond Ring",   basePricePerUnit = 140, category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_GoldDiamond",  name = "Gold Diamond Ring",   basePricePerUnit = 140, category = "Jewelry" },
    { id = "Base.Ring_Right_RingFinger_GoldRuby",      name = "Gold Ruby Ring",      basePricePerUnit = 110, category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_GoldRuby",       name = "Gold Ruby Ring",      basePricePerUnit = 110, category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_GoldRuby",    name = "Gold Ruby Ring",      basePricePerUnit = 110, category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_GoldRuby",     name = "Gold Ruby Ring",      basePricePerUnit = 110, category = "Jewelry" },

    -- 金の指輪・シグネットリング
    { id = "Base.Ring_Right_RingFinger_Gold",          name = "Gold Ring",           basePricePerUnit = 60,  category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_Gold",           name = "Gold Ring",           basePricePerUnit = 60,  category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_Gold",        name = "Gold Ring",           basePricePerUnit = 60,  category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_Gold",         name = "Gold Ring",           basePricePerUnit = 60,  category = "Jewelry" },
    { id = "Base.Ring_Right_RingFinger_Signet",        name = "Signet Ring",         basePricePerUnit = 50,  category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_Signet",         name = "Signet Ring",         basePricePerUnit = 50,  category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_Signet",      name = "Signet Ring",         basePricePerUnit = 50,  category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_Signet",       name = "Signet Ring",         basePricePerUnit = 50,  category = "Jewelry" },

    -- 銀・ダイヤ指輪
    { id = "Base.Ring_Right_RingFinger_SilverDiamond",   name = "Silver Diamond Ring", basePricePerUnit = 90,  category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_SilverDiamond",    name = "Silver Diamond Ring", basePricePerUnit = 90,  category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_SilverDiamond", name = "Silver Diamond Ring", basePricePerUnit = 90,  category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_SilverDiamond",  name = "Silver Diamond Ring", basePricePerUnit = 90,  category = "Jewelry" },
    { id = "Base.Ring_Right_RingFinger_Silver",          name = "Silver Ring",         basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.Ring_Left_RingFinger_Silver",           name = "Silver Ring",         basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.Ring_Right_MiddleFinger_Silver",        name = "Silver Ring",         basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.Ring_Left_MiddleFinger_Silver",         name = "Silver Ring",         basePricePerUnit = 30,  category = "Jewelry" },

    -- ネックレス・チョーカー
    { id = "Base.Necklace_GoldDiamond",     name = "Gold Diamond Necklace",   basePricePerUnit = 130, category = "Jewelry" },
    { id = "Base.NecklaceLong_GoldDiamond", name = "Gold Diamond Necklace",   basePricePerUnit = 130, category = "Jewelry" },
    { id = "Base.Necklace_Choker_Diamond",  name = "Diamond Choker",          basePricePerUnit = 120, category = "Jewelry" },
    { id = "Base.Necklace_GoldRuby",        name = "Gold Ruby Necklace",      basePricePerUnit = 100, category = "Jewelry" },
    { id = "Base.Necklace_Pearl",           name = "Pearl Necklace",          basePricePerUnit = 110, category = "Jewelry" },
    { id = "Base.Necklace_Gold",            name = "Gold Necklace",           basePricePerUnit = 65,  category = "Jewelry" },
    { id = "Base.NecklaceLong_Gold",        name = "Gold Necklace",           basePricePerUnit = 65,  category = "Jewelry" },
    { id = "Base.Necklace_SilverDiamond",   name = "Silver Diamond Necklace", basePricePerUnit = 80,  category = "Jewelry" },
    { id = "Base.Necklace_SilverSapphire",  name = "Silver Sapphire Necklace",basePricePerUnit = 65,  category = "Jewelry" },
    { id = "Base.Necklace_Silver",          name = "Silver Necklace",         basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.NecklaceLong_Silver",      name = "Silver Necklace",         basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.Necklace_Crucifix",        name = "Crucifix Necklace",       basePricePerUnit = 20,  category = "Jewelry" },
    { id = "Base.Necklace_SilverCrucifix",  name = "Silver Crucifix",         basePricePerUnit = 40,  category = "Jewelry" },

    -- イヤリング
    { id = "Base.Earring_LoopLrg_Gold",        name = "Gold Hoop Earrings",   basePricePerUnit = 45,  category = "Jewelry" },
    { id = "Base.Earring_LoopMed_Gold",        name = "Gold Hoop Earrings",   basePricePerUnit = 37,  category = "Jewelry" },
    { id = "Base.Earring_LoopSmall_Gold_Both", name = "Gold Stud Earrings",   basePricePerUnit = 30,  category = "Jewelry" },
    { id = "Base.Earring_LoopLrg_Silver",      name = "Silver Hoop Earrings", basePricePerUnit = 25,  category = "Jewelry" },
    { id = "Base.Earring_LoopMed_Silver",      name = "Silver Hoop Earrings", basePricePerUnit = 20,  category = "Jewelry" },

    -- 高級時計・懐中時計
    { id = "Base.Pocketwatch",                    name = "Antique Pocketwatch", basePricePerUnit = 90,  category = "Antiques" },
    { id = "Base.WristWatch_Right_Expensive",     name = "Luxury Watch",        basePricePerUnit = 90,  category = "Antiques" },
    { id = "Base.WristWatch_Right_ClassicGold",   name = "Classic Gold Watch",  basePricePerUnit = 75,  category = "Antiques" },
    { id = "Base.WristWatch_Left_ClassicGold",    name = "Classic Gold Watch",  basePricePerUnit = 75,  category = "Antiques" },
    { id = "Base.WristWatch_Right_ClassicBlack",  name = "Classic Watch",       basePricePerUnit = 30,  category = "Antiques" },
    { id = "Base.WristWatch_Left_ClassicBlack",   name = "Classic Watch",       basePricePerUnit = 30,  category = "Antiques" },
    { id = "Base.WristWatch_Right_ClassicBrown",  name = "Classic Watch",       basePricePerUnit = 30,  category = "Antiques" },
    { id = "Base.WristWatch_Left_ClassicBrown",   name = "Classic Watch",       basePricePerUnit = 30,  category = "Antiques" },
    { id = "Base.WristWatch_Right_ClassicMilitary", name = "Military Watch",    basePricePerUnit = 40,  category = "Antiques" },
    { id = "Base.WristWatch_Left_ClassicMilitary",  name = "Military Watch",    basePricePerUnit = 40,  category = "Antiques" },

    -- 分解した宝石（ルース宝石 / 重量比価値が高いため換金効率良）
    { id = "Base.Diamond",                        name = "Cut Diamond",         basePricePerUnit = 120, category = "Gems" },
    { id = "Base.Ruby",                           name = "Cut Ruby",            basePricePerUnit = 95,  category = "Gems" },
    { id = "Base.Sapphire",                       name = "Cut Sapphire",        basePricePerUnit = 75,  category = "Gems" },
    { id = "Base.Emerald",                        name = "Cut Emerald",         basePricePerUnit = 75,  category = "Gems" },

    -- 金・銀・金属インゴット（地金類 / 重量があるため輸送手数料を差し引き）
    { id = "Base.GoldBar",                        name = "Gold Ingot (Large)",  basePricePerUnit = 275, category = "Ingots" },
    { id = "Base.SmallGoldBar",                   name = "Gold Ingot (Small)",  basePricePerUnit = 110, category = "Ingots" },
    { id = "Base.SilverBar",                      name = "Silver Ingot (Large)",basePricePerUnit = 130, category = "Ingots" },
    { id = "Base.SmallSilverBar",                 name = "Silver Ingot (Small)",basePricePerUnit = 50,  category = "Ingots" },
    { id = "Base.SteelIngot",                     name = "Steel Ingot",         basePricePerUnit = 35,  category = "Ingots" },
    { id = "Base.BrassIngot",                     name = "Brass Ingot",         basePricePerUnit = 22,  category = "Ingots" },
    { id = "Base.CopperIngot",                    name = "Copper Ingot",        basePricePerUnit = 17,  category = "Ingots" },
    { id = "Base.IronIngot",                      name = "Iron Ingot",          basePricePerUnit = 12,  category = "Ingots" },

    -- =========================================================================
    -- カテゴリ3: 終末サバイバーハンドクラフト・工芸 (Handcrafts)
    -- =========================================================================
    -- 死線で手作りされた一点物としてのコレクター需要
    { id = "Base.WoodenToy",           name = "Handmade Wooden Toy",  basePricePerUnit = 30,  category = "Handcrafts" },

    -- =========================================================================
    -- カテゴリ4: 隔離地域産のオーガニック農作物 (Organic Produce)
    -- =========================================================================
    -- 外の富裕層向けの希少な生鮮産品（生鮮空輸コスト控除後の買取額）
    { id = "Base.Cabbage",             name = "Fresh Cabbage",        basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.Tomato",              name = "Fresh Tomato",         basePricePerUnit = 5,   category = "Produce" },
    { id = "Base.Potato",              name = "Fresh Potato",         basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.Corn",                name = "Fresh Corn",           basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.Carrots",             name = "Fresh Carrots",        basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.Broccoli",            name = "Fresh Broccoli",       basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.RedRadish",           name = "Fresh Radish",         basePricePerUnit = 3,   category = "Produce" },
    { id = "Base.Apple",               name = "Fresh Apple",          basePricePerUnit = 4,   category = "Produce" },
    { id = "Base.Peach",               name = "Fresh Peach",          basePricePerUnit = 5,   category = "Produce" },
    { id = "Base.Watermelon",          name = "Fresh Watermelon",     basePricePerUnit = 8,   category = "Produce" },

    -- =========================================================================
    -- カテゴリ5: 旧世界の通貨・カード類 (Currency & Financial)
    -- =========================================================================
    -- 現金は 1 CR、札束は 50 CR、クレジットカードは 1〜5 CR 程度で買取
    { id = "Base.Money",               name = "Cash (Bill/Coin)",     basePricePerUnit = 1,   category = "Currency" },
    { id = "Base.MoneyBundle",         name = "Money Bundle",         basePricePerUnit = 50,  category = "Currency" },
    { id = "Base.CreditCard",          name = "Credit Card",          basePricePerUnit = 2,   category = "Currency", isRandom = true },
    { id = "Base.CreditCard_Stolen",   name = "Stolen Credit Card",   basePricePerUnit = 2,   category = "Currency", isRandom = true },
}

-- ---------------------------------------------------------------------------
-- ユーティリティ: アイテムIDから売却定義を検索 (スマートマッチング機能付き)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetSellEntry(itemId)
    if not itemId then return nil end

    -- 1. 完全一致
    for _, entry in ipairs(RadioTrader_Sell) do
        if entry.id == itemId then return entry end
    end

    -- 2. スマートパターンマッチング (バリエーション・Mod対応フォールバック)
    -- 指輪類
    if string.find(itemId, "Ring_") then
        if string.find(itemId, "Diamond") or string.find(itemId, "Ruby") then
            return { id = itemId, name = "Gemstone Ring", basePricePerUnit = 90, category = "Jewelry" }
        elseif string.find(itemId, "Gold") or string.find(itemId, "Signet") then
            return { id = itemId, name = "Gold Ring", basePricePerUnit = 55, category = "Jewelry" }
        elseif string.find(itemId, "Silver") then
            return { id = itemId, name = "Silver Ring", basePricePerUnit = 27, category = "Jewelry" }
        end
    end

    -- ネックレス類
    if string.find(itemId, "Necklace") then
        if string.find(itemId, "Diamond") or string.find(itemId, "Pearl") then
            return { id = itemId, name = "Precious Necklace", basePricePerUnit = 110, category = "Jewelry" }
        elseif string.find(itemId, "Gold") then
            return { id = itemId, name = "Gold Necklace", basePricePerUnit = 60, category = "Jewelry" }
        elseif string.find(itemId, "Silver") then
            return { id = itemId, name = "Silver Necklace", basePricePerUnit = 30, category = "Jewelry" }
        end
    end

    -- 時計類
    if string.find(itemId, "WristWatch_") or string.find(itemId, "Pocketwatch") then
        if string.find(itemId, "Gold") or string.find(itemId, "Expensive") or string.find(itemId, "Pocketwatch") then
            return { id = itemId, name = "Luxury Watch", basePricePerUnit = 75, category = "Antiques" }
        else
            return { id = itemId, name = "Classic Watch", basePricePerUnit = 25, category = "Antiques" }
        end
    end

    -- 一次資料・手紙・メモ・チラシ類
    if string.find(itemId, "Letter") or string.find(itemId, "Mail") then
        return { id = itemId, name = "Survivor Letter", basePricePerUnit = 22, category = "Archives" }
    elseif string.find(itemId, "Brochure") or string.find(itemId, "Flyer") then
        return { id = itemId, name = "Old Flyer", basePricePerUnit = 10, category = "Archives" }
    elseif string.find(itemId, "Note") or string.find(itemId, "Postcard") then
        return { id = itemId, name = "Handwritten Note", basePricePerUnit = 12, category = "Archives" }
    end

    -- インゴット・地金類
    if string.find(itemId, "Ingot") or string.find(itemId, "Bar") then
        if string.find(itemId, "Gold") then
            return { id = itemId, name = "Gold Ingot", basePricePerUnit = 110, category = "Ingots" }
        elseif string.find(itemId, "Silver") then
            return { id = itemId, name = "Silver Ingot", basePricePerUnit = 55, category = "Ingots" }
        elseif string.find(itemId, "Steel") then
            return { id = itemId, name = "Steel Ingot", basePricePerUnit = 35, category = "Ingots" }
        elseif string.find(itemId, "Brass") or string.find(itemId, "Copper") then
            return { id = itemId, name = "Metal Ingot", basePricePerUnit = 20, category = "Ingots" }
        end
    end

    -- 単体宝石類
    if string.find(itemId, "Diamond") then
        return { id = itemId, name = "Cut Diamond", basePricePerUnit = 120, category = "Gems" }
    elseif string.find(itemId, "Ruby") then
        return { id = itemId, name = "Cut Ruby", basePricePerUnit = 95, category = "Gems" }
    elseif string.find(itemId, "Sapphire") then
        return { id = itemId, name = "Cut Sapphire", basePricePerUnit = 75, category = "Gems" }
    elseif string.find(itemId, "Emerald") then
        return { id = itemId, name = "Cut Emerald", basePricePerUnit = 75, category = "Gems" }
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: カテゴリ名からショップリストを取得
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetShopCategory(categoryName)
    return RadioTrader_Shop[categoryName] or {}
end

-- ---------------------------------------------------------------------------
-- カテゴリ表示定義（UI用 / キー名で管理し、表示はUI側で多言語化）
-- ---------------------------------------------------------------------------
-- 日替わり、種類別バッグ（全種）、特殊機材の3つに集約してすっきり整理
RadioTrader_ShopCategories = {
    { key = "Daily", label = "[Daily] Daily Deals"           },
    { key = "Bags",  label = "[Bags] Supply Bags"            },
    { key = "Misc",  label = "[Misc] Machinery & Gear"       },
}

-- ---------------------------------------------------------------------------
-- 共通: LZ座標取得ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_GetLZCoords(player)
    if not player then return nil end
    local uname = player.getUsername and player:getUsername()
    if not uname or uname == "" then uname = "singleplayer" end
    local gmdKey = "RadioTrader_" .. uname
    if not (ModData and ModData.exists and ModData.exists(gmdKey)) then return nil end
    local gmd = ModData.get(gmdKey)
    local x = gmd[RadioTrader_Config.KEY_LZ_X]
    local y = gmd[RadioTrader_Config.KEY_LZ_Y]
    local z = gmd[RadioTrader_Config.KEY_LZ_Z]
    if not x or not y or not z then return nil end
    return x, y, z
end

-- ---------------------------------------------------------------------------
-- 共通: LZコンテナオブジェクト取得
-- ---------------------------------------------------------------------------
function RadioTrader_GetLZContainer(player)
    local x, y, z = RadioTrader_GetLZCoords(player)
    if not x then return nil end
    local world = getWorld()
    if not world then return nil end
    local cell = world:getCell()
    if not cell then return nil end
    local sq = cell:getGridSquare(x, y, z)
    if not sq then return nil end

    -- 1. 通常オブジェクト
    local objs = sq:getObjects()
    if objs then
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            if obj and obj.getContainer and obj:getContainer() then
                return obj:getContainer(), obj
            end
        end
    end

    -- 2. 特殊オブジェクト
    local specObjs = sq:getSpecialObjects()
    if specObjs then
        for i = 0, specObjs:size() - 1 do
            local obj = specObjs:get(i)
            if obj and obj.getContainer and obj:getContainer() then
                return obj:getContainer(), obj
            end
        end
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- 共通: ドロップボックス査定エンジン（クライアント・サーバー両用）
-- ---------------------------------------------------------------------------
function RadioTrader_AssessContainer(player)
    local x, y, z = RadioTrader_GetLZCoords(player)
    if not x then
        return nil, 0, "LZ_NOT_SET", 0, {}
    end

    local container, obj = RadioTrader_GetLZContainer(player)
    if not container then
        return nil, 0, "LZ_CONTAINER_NOT_FOUND", 0, {}
    end

    local totalCredits = 0
    local assessedItems = {}
    local unacceptedItems = {}
    local cfg = RadioTrader_Config

    local items = container:getItems()
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local itemType = item:getFullType()
                local sellEntry = RadioTrader_ItemsTable_GetSellEntry(itemType)
                if sellEntry then
                    -- コンディション計算（耐久度）
                    local condition = 1.0
                    if item.getCondition and item.getConditionMax then
                        local maxC = item:getConditionMax()
                        if maxC and maxC > 0 then
                            condition = math.max(0.1, item:getCondition() / maxC)
                        end
                    end

                    -- 新鮮度計算（食品）
                    local freshness = 1.0
                    if item.isRotten and item:isRotten() then
                        freshness = 0.0
                    elseif item.isFresh and not item:isFresh() then
                        freshness = 0.5
                    end

                    -- 腐敗品でなければ査定計算
                    if freshness > 0 and condition >= cfg.MIN_SELL_CONDITION then
                        local basePrice = sellEntry.basePricePerUnit
                        -- クレジットカードのランダム買取 (1〜5 CR)
                        if sellEntry.isRandom or string.find(itemType, "CreditCard") then
                            local seed = (item.getID and item:getID()) or 0
                            basePrice = 1 + (math.abs(seed) % 5)
                        end

                        local condValue = condition * cfg.CONDITION_WEIGHT
                        local freshValue = freshness * cfg.FRESHNESS_WEIGHT
                        local totalWeight = cfg.CONDITION_WEIGHT + cfg.FRESHNESS_WEIGHT
                        local qualityMultiplier = (condValue + freshValue) / totalWeight
                        -- 通貨類（現金・束・カード）はコンディション減衰なし
                        if sellEntry.category == "Currency" then
                            qualityMultiplier = 1.0
                        end

                        local sellMult = RadioTrader_Config.getSellPriceMultiplier and RadioTrader_Config.getSellPriceMultiplier() or 1.0
                        local itemCredits = math.max(1, math.floor(basePrice * qualityMultiplier * sellMult + 0.5))

                        if itemCredits > 0 then
                            table.insert(assessedItems, {
                                item = item,
                                name = sellEntry.name,
                                credits = itemCredits,
                                condition = condition,
                            })
                            totalCredits = totalCredits + itemCredits
                        end
                    else
                        table.insert(unacceptedItems, item:getName() or itemType)
                    end
                else
                    table.insert(unacceptedItems, item:getName() or itemType)
                end
            end
        end
    end

    return assessedItems, totalCredits, nil, #unacceptedItems, unacceptedItems
end
