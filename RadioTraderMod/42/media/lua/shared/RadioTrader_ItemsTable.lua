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
-- 生鮮野菜・果物・機能性ハーブ（ランダム配達・アソート用テーブル）
-- ---------------------------------------------------------------------------
RadioTrader_FreshVeggies = {
    "Base.Cabbage",
    "Base.Tomato",
    "Base.Potato",
    "Base.Corn",
    "Base.Carrots",
    "Base.Broccoli",
    "Base.RedRadish",
    "Base.Onion",
    "Base.Lettuce",
    "Base.BellPepper",
    "Base.Eggplant",
    "Base.Leek",
    "Base.Zucchini",
    "Base.SweetPotato",
    "Base.Pumpkin",
    "Base.Avocado",
}

RadioTrader_FreshFruits = {
    "Base.Apple",
    "Base.Peach",
    "Base.Watermelon",
    "Base.Strewberrie",
    "Base.Banana",
    "Base.Orange",
    "Base.Lemon",
    "Base.Lime",
    "Base.Grapes",
    "Base.Pineapple",
    "Base.Cherry",
}

RadioTrader_FreshHerbs = {
    "Base.WildGarlic",
    "Base.WildOnion",
    "Base.Lemongrass",
    "Base.Ginseng",
    "Base.BlackSage",
    "Base.CommonMallow",
    "Base.Plantain",
}

-- ---------------------------------------------------------------------------
-- 冷凍精肉・鮮魚アソート用テーブル（クーラーボックス充填用・完全凍結配送）
-- ---------------------------------------------------------------------------
RadioTrader_ButcherMeats = {
    "Base.Steak",
    "Base.Chicken",
    "Base.PorkChop",
    "Base.MuttonChop",
    "Base.Venison",
    "Base.Rabbitmeat",
    "Base.FishFillet",
    "Base.Salmon",
    "Base.Bacon",
    "Base.MeatPatty",
}

-- ---------------------------------------------------------------------------
-- 焼きたてベーカリースイーツ（不用品回収依頼時の30%差し入れ用テーブル）
-- ---------------------------------------------------------------------------
RadioTrader_BakerySweets = {
    -- ドーナツ
    "Base.DoughnutChocolate",
    "Base.DoughnutFrosted",
    "Base.DoughnutJelly",
    "Base.DoughnutPlain",
    -- ケーキ
    "Base.CakeBlackForest",
    "Base.CakeCarrot",
    "Base.CakeCheeseCake",
    "Base.CakeChocolate",
    "Base.CakeRedVelvet",
    "Base.CakeSlice",
    "Base.CakeStrawberryShortcake",
    -- パイ
    "Base.PieApple",
    "Base.PieBlueberry",
    "Base.PieKeyLime",
    "Base.PieLemonMeringue",
    "Base.PiePumpkin",
}

-- ---------------------------------------------------------------------------
-- 現場クルーからの差し入れランチボックス用食品リスト
-- ---------------------------------------------------------------------------
-- メイン料理枠：崩壊後は腐って手に入らなくなり、作成にも高いスキルと素材が必要なごちそう
RadioTrader_LunchMains = {
    "Base.SushiFish",            -- 握り寿司 (魚)
    "Base.SushiEgg",             -- 握り寿司 (玉子)
    "Base.Pizza",                -- 焼きたてピザスライス
    "Base.Burger",               -- ハンバーガー
    "Base.Sandwich",             -- サンドイッチ
    "Base.BaguetteSandwich",     -- バゲットサンド
    "Base.Burrito",              -- ブリトー
    "Base.Taco",                 -- タコス
    "Base.Hotdog",               -- ホットドッグ
    "Base.Corndog",              -- アメリカンドッグ
    "Base.MeatDumpling",         -- 肉まん・点心
    "Base.ShrimpDumpling",       -- 海老蒸し餃子・点心
}

-- 冷蔵・冷凍おやつ枠：電気が落ちた後は溶けて腐り、二度と手に入らなくなる冷凍・冷蔵スイーツ
RadioTrader_LunchColdDesserts = {
    "Base.Icecream",             -- カップアイスクリーム
    "Base.ConeIcecreamToppings", -- トッピング付きアイスクリームコーン
    "Base.IcecreamSandwich",     -- アイスクリームサンド
    "Base.Creamocle",            -- クリームアイスバー
    "Base.FudgeePop",            -- 濃厚チョコアイスバー
    "Base.Popsicle",             -- フルーツアイスキャンディー
    "Base.FruitSalad",           -- フレッシュフルーツサラダ
}

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
-- 配達時はバニラ家具クレート抽選テーブルから引かれた家具現品（Mov_...）が直接届きます。
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

    RadioTrader_Crate_Produce = {
        id = "RadioTrader_Crate_Produce",
        name = "Fresh Produce & Herbs Bag",
        price = 850,
        container = "Base.Bag_DuffelBag",
        isProduceBag = true,
        minItems = 5,
        maxItems = 8,
    },

    RadioTrader_Crate_Butcher = {
        id = "RadioTrader_Crate_Butcher",
        name = "Frozen Meat & Seafood Cooler",
        price = 950,
        container = "Base.Cooler_Meat",
        isButcherBag = true,
        minItems = 2,
        maxItems = 3,
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
        isWeaponsBag = true,
        distributionLists = {
            "ArmyStorageGuns",
            "ArmyStorageAmmunition",
            "ArmySurplusAmmoBoxes",
            "GunStoreAmmunition",
            "GunStoreMagsAmmo",
            "GunStorePistols",
            "GunStoreShotguns",
            "GunStoreRifles",
            "PoliceStorageGuns",
        },
        customItems = {
            "Base.Pistol",
            "Base.Pistol2",
            "Base.Pistol3",
            "Base.Revolver",
            "Base.Revolver_Long",
            "Base.Revolver_Short",
            "Base.Shotgun",
            "Base.ShotgunSawnoff",
            "Base.DoubleBarrelShotgun",
            "Base.DoubleBarrelShotgunSawnoff",
            "Base.AssaultRifle",
            "Base.AssaultRifle2",
            "Base.HuntingRifle",
            "Base.L94_Rifle",
            "Base.L92_Carbine",
            "Base.Bullets9mmBox",
            "Base.Bullets45Box",
            "Base.Bullets44Box",
            "Base.Bullets38Box",
            "Base.Bullets357Box",
            "Base.3030Box",
            "Base.ShotgunShellsBox",
            "Base.308Box",
            "Base.556Box",
            "Base.9mmClip",
            "Base.45Clip",
            "Base.44Clip",
            "Base.308Clip",
            "Base.M14Clip",
            "Base.556Clip",
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
            "CrateMechanics",
            "MechanicShelfWheels",
            "MechanicShelfBrakes",
            "CarSupplyBatteries",
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

    RadioTrader_Crate_Recipes = {
        id = "RadioTrader_Crate_Recipes",
        name = "DIY & Media Recipes Duffel Bag",
        price = 700,
        container = "Base.Bag_DuffelBag",
        minItems = 4,
        maxItems = 8,
        isMediaRecipeBag = true,
        customItems = {
            -- 電子工学・発電機・無線
            "Base.ElectronicsMag1",
            "Base.ElectronicsMag2",
            "Base.ElectronicsMag3",
            "Base.ElectronicsMag4", -- 発電機の使い方 (How to Use Generators)
            "Base.ElectronicsMag5",
            "Base.EngineerMagazine1",
            "Base.EngineerMagazine2",
            "Base.EngineerMagazine3",
            "Base.RadioMag1",
            "Base.RadioMag2",
            "Base.RadioMag3",
            -- 車両整備マニュアル
            "Base.MechanicMag1",
            "Base.MechanicMag2",
            "Base.MechanicMag3",
            -- 金属加工
            "Base.MetalworkMag1",
            "Base.MetalworkMag2",
            "Base.MetalworkMag3",
            "Base.MetalworkMag4",
            -- 狩猟・罠猟・釣り
            "Base.HuntingMag1",
            "Base.HuntingMag2",
            "Base.HuntingMag3",
            "Base.HuntingMag4",
            "Base.FishingMag1",
            "Base.FishingMag2",
            -- 医療・薬草
            "Base.HerbalistMag",
            -- 料理・食品加工
            "Base.CookingMag1",
            "Base.CookingMag2",
            "Base.CookingMag3",
            "Base.CookingMag4",
            "Base.CookingMag5",
            "Base.CookingMag6",
            -- 農業
            "Base.FarmingMag1",
            "Base.FarmingMag2",
            "Base.FarmingMag3",
            "Base.FarmingMag4",
            "Base.FarmingMag5",
            "Base.FarmingMag6",
            "Base.FarmingMag7",
            "Base.FarmingMag8",
            "Base.FarmingMag9",
            -- 鍛冶・鍛造 (Build 42 新工芸)
            "Base.SmithingMag1",
            "Base.SmithingMag2",
            "Base.SmithingMag3",
            "Base.SmithingMag4",
            "Base.SmithingMag5",
            "Base.SmithingMag6",
            "Base.SmithingMag7",
            "Base.SmithingMag8",
            "Base.SmithingMag9",
            "Base.SmithingMag10",
            "Base.SmithingMag11",
            -- 防具製作 (Build 42 新工芸)
            "Base.ArmorMag1",
            "Base.ArmorMag2",
            "Base.ArmorMag3",
            "Base.ArmorMag4",
            "Base.ArmorMag5",
            "Base.ArmorMag6",
            "Base.ArmorMag7",
            "Base.ArmorSchematic",
            -- 武器改造・原始工具
            "Base.WeaponMag1",
            "Base.WeaponMag2",
            "Base.WeaponMag3",
            "Base.WeaponMag4",
            "Base.WeaponMag5",
            "Base.WeaponMag6",
            "Base.WeaponMag7",
            "Base.PrimitiveToolMag1",
            "Base.PrimitiveToolMag2",
            "Base.PrimitiveToolMag3",
            -- 裁縫・編み物
            "Base.TailoringMag1",
            "Base.TailoringMag2",
            "Base.TailoringMag3",
            "Base.TailoringMag4",
            "Base.TailoringMag5",
            "Base.TailoringMag6",
            "Base.TailoringMag7",
            "Base.TailoringMag8",
            "Base.TailoringMag9",
            "Base.TailoringMag10",
            "Base.KnittingMag1",
            "Base.KnittingMag2",
            -- ガラス工芸・麻・合鍵
            "Base.GlassmakingMag1",
            "Base.GlassmakingMag2",
            "Base.GlassmakingMag3",
            "Base.HempMag1",
            "Base.KeyMag1",
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

    -- 不用品回収依頼（ヘリ基本出撃料100CR・30%の確率で焼きたてスイーツ差し入れ）
    RadioTrader_Crate_Pickup = {
        id = "RadioTrader_Crate_Pickup",
        name = "Cargo Pickup Request",
        price = 100,
        container = "Base.Bag_PaperBag",
        isPickupRequest = true,
        sweetChance = 30,
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
    local roll = (ZombRand and (ZombRand(math.floor(totalWeight * 100)) / 100.0)) or (math.random() * totalWeight)

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

    local roll = (ZombRand and (ZombRand(math.floor(totalWeight * 100)) / 100.0)) or (math.random() * totalWeight)

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
-- ---------------------------------------------------------------------------
-- 超プレミアム固定枠（現場資材・袋詰・BOX資材・種袋）
-- ---------------------------------------------------------------------------
RadioTrader_DailyPremiumPool = {
    -- 布束・鞣し革（大・中・小）
    { id = "Base.FabricRoll_Cotton",        baseUnit = 1500, minCount = 1, maxCount = 2 },
    { id = "Base.FabricRoll_DenimBlue",     baseUnit = 1500, minCount = 1, maxCount = 2 },
    { id = "Base.Leather_Crude_Large_Tan",  baseUnit = 4000, minCount = 1, maxCount = 1 },
    { id = "Base.Leather_Crude_Medium_Tan", baseUnit = 2500,  minCount = 1, maxCount = 2 },
    { id = "Base.Leather_Crude_Small_Tan",  baseUnit = 1000,  minCount = 1, maxCount = 3 },
    -- 釘BOX・ネジBOX
    { id = "Base.NailsBox",                 baseUnit = 950, minCount = 1, maxCount = 2 },
    { id = "Base.ScrewsBox",                baseUnit = 900, minCount = 1, maxCount = 2 },
    -- 毛糸・糸
    { id = "Base.Thread",                   baseUnit = 550,  minCount = 1, maxCount = 3 },
    { id = "Base.Yarn",                     baseUnit = 550,  minCount = 1, maxCount = 3 },
    -- 袋詰め建材
    { id = "Base.ConcretePowder",           baseUnit = 600, minCount = 1, maxCount = 2 },
    { id = "Base.Sandbag",                  baseUnit = 900, minCount = 1, maxCount = 2 },
    { id = "Base.Gravelbag",                baseUnit = 100, minCount = 1, maxCount = 2 },
    { id = "Base.Claybag",                  baseUnit = 1800, minCount = 1, maxCount = 2 },
    -- 乾電池BOX
    { id = "Base.BatteryBox",               baseUnit = 600, minCount = 1, maxCount = 1 },
    -- 動物飼料
    { id = "Base.AnimalFeedBag",            baseUnit = 450, minCount = 1, maxCount = 2 },
}

-- ---------------------------------------------------------------------------
-- 日替わりスポット品目 抽選用バニラCrate定義群（+超プレミアム固定枠）
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
    { category = "Premium",    label = "Premium",   isPremium = true },
}

-- 10の桁で切り上げヘルパー
local function ceilTo10(val)
    return math.ceil(val / 10.0) * 10
end

-- アイテムのウェイト・種別から価格と販売数量を算出
-- ユーザー算定式: ( (基準単価 + 乱数(1〜10)*10) * 個数 * 乱数(1.00〜2.00) )
-- ※購入・表示時に MOD設定係数（BuyPriceMultiplier）が掛けられます
local function calculateDailyItemPriceAndCount(itemId, weight, isTraderStash, forcedCount, forcedBaseUnit)
    local count = forcedCount or 1
    local baseUnit = forcedBaseUnit

    if not baseUnit then
        if isTraderStash then
            -- トレーダーの私物隠しおやつ・冷凍食品（超高額プレミア価格）
            if string.find(itemId, "PizzaWhole") then
                count = 1
                baseUnit = ceilTo10(1600 * 1.25)
            elseif string.find(itemId, "Frozen_") or string.find(itemId, "TVDinner") then
                count = (ZombRand and (ZombRand(2) + 1)) or math.random(1, 2)
                baseUnit = ceilTo10(600 * 1.25)
            elseif string.find(itemId, "Icecream") or string.find(itemId, "Creamocle")
                or string.find(itemId, "FudgeePop") or string.find(itemId, "Popsicle") then
                count = 1
                baseUnit = ceilTo10(950 * 1.25)
            else
                count = 1
                baseUnit = ceilTo10(850 * 1.25)
            end
        else
            -- 【バニラ品目】価格ベースは出現ウェイト（希少度）に完全一本化！
            if not weight or weight <= 0 then weight = 1.0 end

            if weight <= 0.1 then
                -- 激レア品 (例: Axe, BenchAnvil, 貴重スキル本等)
                count = 1
                baseUnit = ceilTo10(3200 * 1.25)
            elseif weight <= 1.0 then
                -- レア品 (例: 工具・特殊医薬品・中間スキル本等)
                count = 1
                baseUnit = ceilTo10(1680 * 1.25)
            elseif weight <= 10.0 then
                -- アンコモン (例: スクリュードライバー・中間資材)
                count = 1
                baseUnit = ceilTo10(960 * 1.25)
            else
                -- コモン資材 (1〜2個小口)
                count = (ZombRand and (ZombRand(2) + 1)) or math.random(1, 2)
                baseUnit = ceilTo10(200 * 1.25)
            end

            -- 特殊高額機材・装備への例外最低保証
            if string.find(itemId, "Generator") then
                count = 1
                baseUnit = ceilTo10(5000 * 1.25)
            elseif string.find(itemId, "ALICEpack") then
                count = 1
                baseUnit = ceilTo10(3000 * 1.25)
            end
        end
    end

    -- 価格計算式: (基準値 + 乱数(1〜10)*10) * 個数 * 乱数(1.00〜2.00)
    local randOffset = ((ZombRand and (ZombRand(10) + 1)) or math.random(1, 10)) * 10
    local fluctuation = 1.0 + (((ZombRand and ZombRand(101)) or math.random(0, 100)) / 100.0)
    local rawPrice = (baseUnit + randOffset) * count * fluctuation
    local price = math.max(10, math.floor(rawPrice + 0.5))

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
        local itemId, weight = nil, 1.0
        local forcedCount, forcedBaseUnit = nil, nil

        if cat.isPremium and RadioTrader_DailyPremiumPool and #RadioTrader_DailyPremiumPool > 0 then
            -- 超プレミアム固定枠から選定
            local pIdx = (ZombRand and (ZombRand(#RadioTrader_DailyPremiumPool) + 1)) or math.random(1, #RadioTrader_DailyPremiumPool)
            local pItem = RadioTrader_DailyPremiumPool[pIdx]
            itemId = pItem.id
            local minC = pItem.minCount or 1
            local maxC = pItem.maxCount or 1
            forcedCount = (minC == maxC) and minC or ((ZombRand and ZombRand(minC, maxC + 1)) or math.random(minC, maxC))
            forcedBaseUnit = ceilTo10(pItem.baseUnit * 1.25)
        else
            -- バニラCrateテーブルから選定
            local dists = cat.dists
            local dIdx = (ZombRand and (ZombRand(#dists) + 1)) or math.random(1, #dists)
            local distName = dists[dIdx]
            itemId, weight = RadioTrader_ItemsTable_RollProceduralItemWithWeight(distName)
        end

        if itemId and not seenIds[itemId] then
            seenIds[itemId] = true
            local count, price = calculateDailyItemPriceAndCount(itemId, weight, false, forcedCount, forcedBaseUnit)
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

    -- 超低確率（約3%）でトレーダーの私物「俺のおやつ(備蓄)」枠が1品追加！
    local stashRoll = (ZombRand and ZombRand(100)) or math.random(0, 99)
    if stashRoll < 3 then
        local stashDists = { "FreezerIceCream", "FreezerFrozenFood" }
        local sIdx = (ZombRand and (ZombRand(#stashDists) + 1)) or math.random(1, #stashDists)
        local stashDistName = stashDists[sIdx]
        local stashItemId, stashWeight = RadioTrader_ItemsTable_RollProceduralItemWithWeight(stashDistName)
        if stashItemId and not seenIds[stashItemId] then
            seenIds[stashItemId] = true
            local sCount, sPrice = calculateDailyItemPriceAndCount(stashItemId, stashWeight, true)
            local stashEntry = {
                id       = stashItemId,
                name     = stashItemId,
                price    = sPrice,
                count    = sCount,
                category = "Daily",
                subCat   = "TraderStash"
            }
            table.insert(dailyItems, stashEntry)
        end
    end

    RadioTrader_Shop.Daily = dailyItems
    return dailyItems
end

-- ---------------------------------------------------------------------------
-- サブコンテナアイテム（弾薬箱・各種ケース・救急箱等）の自動充填処理
-- ---------------------------------------------------------------------------
-- ダッフルバッグ等の内部にコンテナ型アイテム（Base.Bag_AmmoBox 等）がスポーンした際、
-- バニラ Distributions または専用プールから中身を充填して空箱化を防止する。
function RadioTrader_ItemsTable_FillContainerItem(item)
    if not item then return 0 end
    local innerContainer = nil
    if item.getItemContainer then
        innerContainer = item:getItemContainer()
    end
    if not innerContainer then return 0 end

    -- すでにアイテムが入っている場合は二重充填を防止
    local currentItems = innerContainer:getItems()
    if currentItems and currentItems:size() > 0 then return 0 end

    local itemType = (item.getType and item:getType()) or ""
    local shortType = itemType
    if string.find(shortType, "%.") then
        shortType = string.gsub(shortType, "^.*%.", "")
    end

    local addedCount = 0

    local function addSubItem(subId)
        if not subId then return false end
        if not string.find(subId, "%.") then
            subId = "Base." .. subId
        end
        local script = getItem(subId)
        if script then
            local spawned = instanceItem(subId)
            if spawned then
                innerContainer:AddItem(spawned)
                addedCount = addedCount + 1
                return true
            end
        end
        return false
    end

    -- 1. バニラ Distributions テーブルの参照（最優先）
    local dist = nil
    if Distributions then
        dist = Distributions[shortType] or Distributions[itemType]
    end

    if dist and dist.items and #dist.items >= 2 then
        local rolls = dist.rolls or 3
        local dItems = dist.items
        local totalW = 0
        for i = 2, #dItems, 2 do
            local w = dItems[i]
            if type(w) == "number" and w > 0 then
                totalW = totalW + w
            end
        end

        if totalW > 0 then
            for r = 1, rolls do
                local rollVal = (ZombRand and (ZombRand(math.floor(totalW * 100)) / 100.0)) or (math.random() * totalW)
                local curW = 0
                for i = 2, #dItems, 2 do
                    local w = dItems[i]
                    if type(w) == "number" and w > 0 then
                        curW = curW + w
                        if rollVal <= curW then
                            local chosenId = dItems[i - 1]
                            if chosenId then
                                addSubItem(chosenId)
                            end
                            break
                        end
                    end
                end
            end
            if addedCount > 0 then
                return addedCount
            end
        end
    end

    -- 2. 専用フォールバック（Distributions が未定義または引けなかった場合）
    -- 弾薬缶・弾薬ケース系（Bag_AmmoBox, Bag_ProtectiveCaseBulkyAmmo 等）
    if string.find(shortType, "AmmoBox") or string.find(shortType, "BulkyAmmo") then
        local ammoPool = {
            "Base.556Box",
            "Base.308Box",
            "Base.Bullets9mmBox",
            "Base.ShotgunShellsBox",
            "Base.Bullets45Box",
            "Base.Bullets44Box",
            "Base.Bullets38Box",
            "Base.3030Box",
        }

        -- 口径特化判定
        if string.find(shortType, "308") then
            ammoPool = { "Base.308Box" }
        elseif string.find(shortType, "9mm") then
            ammoPool = { "Base.Bullets9mmBox" }
        elseif string.find(shortType, "Shotgun") then
            ammoPool = { "Base.ShotgunShellsBox" }
        elseif string.find(shortType, "45") then
            ammoPool = { "Base.Bullets45Box" }
        elseif string.find(shortType, "44") then
            ammoPool = { "Base.Bullets44Box" }
        elseif string.find(shortType, "38") then
            ammoPool = { "Base.Bullets38Box" }
        elseif string.find(shortType, "Hunting") then
            ammoPool = { "Base.3030Box", "Base.308Box", "Base.556Box", "Base.ShotgunShellsBox" }
        elseif shortType == "Bag_AmmoBox" or string.find(shortType, "556") then
            ammoPool = { "Base.556Box" }
        end

        local rollCount = (ZombRand and ZombRand(2, 5)) or math.random(2, 4) -- 2〜4箱
        for i = 1, rollCount do
            local idx = (ZombRand and (ZombRand(#ammoPool) + 1)) or math.random(1, #ammoPool)
            addSubItem(ammoPool[idx])
        end
        return addedCount
    end

    -- 救急箱系（FirstAidKit 等）
    if string.find(shortType, "FirstAid") or string.find(shortType, "Medical") then
        local medPool = {
            "Base.Bandage",
            "Base.Disinfectant",
            "Base.AlcoholWipes",
            "Base.PillsPainkiller",
            "Base.PillsAntibiotics",
            "Base.SutureNeedle",
            "Base.Tweezers",
        }
        local rollCount = (ZombRand and ZombRand(2, 5)) or math.random(2, 4)
        for i = 1, rollCount do
            local idx = (ZombRand and (ZombRand(#medPool) + 1)) or math.random(1, #medPool)
            addSubItem(medPool[idx])
        end
        return addedCount
    end

    -- 工具箱系（Toolbox, Tools）
    if string.find(shortType, "Toolbox") or string.find(shortType, "Tools") then
        local toolPool = {
            "Base.Hammer",
            "Base.Screwdriver",
            "Base.Wrench",
            "Base.NailsBox",
            "Base.ScrewsBox",
        }
        local rollCount = (ZombRand and ZombRand(2, 4)) or math.random(2, 3)
        for i = 1, rollCount do
            local idx = (ZombRand and (ZombRand(#toolPool) + 1)) or math.random(1, #toolPool)
            addSubItem(toolPool[idx])
        end
        return addedCount
    end

    -- ガンケース系（PistolCase, RevolverCase, ShotgunCase, RifleCase, GunCase 等）
    if string.find(shortType, "PistolCase") then
        local sets = {
            { gun = "Base.Pistol",  ammo = "Base.Bullets9mmBox", mag = "Base.9mmClip" },
            { gun = "Base.Pistol2", ammo = "Base.Bullets45Box",  mag = "Base.45Clip" },
            { gun = "Base.Pistol3", ammo = "Base.Bullets44Box",  mag = "Base.44Clip" },
        }
        local s = sets[(ZombRand and (ZombRand(#sets) + 1)) or math.random(1, #sets)]
        addSubItem(s.gun)
        addSubItem(s.ammo)
        addSubItem(s.mag)
        return addedCount
    elseif string.find(shortType, "RevolverCase") then
        local sets = {
            { gun = "Base.Revolver",       ammo = "Base.Bullets38Box" },
            { gun = "Base.Revolver_Short", ammo = "Base.Bullets38Box" },
            { gun = "Base.Revolver_Long",  ammo = "Base.Bullets44Box" },
        }
        local s = sets[(ZombRand and (ZombRand(#sets) + 1)) or math.random(1, #sets)]
        addSubItem(s.gun)
        addSubItem(s.ammo)
        return addedCount
    elseif string.find(shortType, "ShotgunCase") then
        local guns = { "Base.Shotgun", "Base.DoubleBarrelShotgun", "Base.ShotgunSawnoff", "Base.DoubleBarrelShotgunSawnoff" }
        local g = guns[(ZombRand and (ZombRand(#guns) + 1)) or math.random(1, #guns)]
        addSubItem(g)
        addSubItem("Base.ShotgunShellsBox")
        return addedCount
    elseif string.find(shortType, "RifleCase") or string.find(shortType, "GunCase") then
        local sets = {
            { gun = "Base.AssaultRifle",  ammo = "Base.556Box",       mag = "Base.556Clip" },
            { gun = "Base.AssaultRifle2", ammo = "Base.308Box",       mag = "Base.M14Clip" },
            { gun = "Base.HuntingRifle",  ammo = "Base.308Box",       mag = "Base.308Clip" },
            { gun = "Base.L94_Rifle",     ammo = "Base.3030Box",      mag = nil },
            { gun = "Base.L92_Carbine",   ammo = "Base.Bullets357Box", mag = nil },
        }
        local s = sets[(ZombRand and (ZombRand(#sets) + 1)) or math.random(1, #sets)]
        addSubItem(s.gun)
        addSubItem(s.ammo)
        if s.mag then
            addSubItem(s.mag)
        end
        return addedCount
    end

    return addedCount
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
                    RadioTrader_ItemsTable_FillContainerItem(itm)
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
    local roll = (ZombRand and ZombRand(totalWeight)) or math.random(0, totalWeight - 1)
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
        {
            id = "Farming",
            weight = 15,
            dists = { "CrateFarming", "CrateGardening", "CrateFertilizer" },
            items = {
                "Base.Fertilizer", "Base.WateredCan", "Base.HandShovel",
                "Base.CarrotBagSeed", "Base.PotatoBagSeed", "Base.TomatoBagSeed", "Base.CabbageBagSeed",
            }
        },
        {
            id = "Livestock",
            weight = 10,
            dists = { "CrateAnimalFeed" },
            items = {
                "Base.AnimalFeedBag", "Base.Rope", "Base.BucketEmpty", "Base.Shears",
            }
        },
        {
            id = "Electronics",
            weight = 15,
            dists = { "CrateElectronics", "CrateBatteries" },
            items = {
                "Base.ElectronicsScrap", "Base.ElectricWire", "Base.Battery",
                "Base.Amplifier", "Base.Aluminum",
            }
        },
        {
            id = "Nails",
            weight = 15,
            dists = { "ToolStoreCarpentry", "CarpenterTools", "ConstructionWorkerTools" },
            items = {
                "Base.NailsBox", "Base.ScrewsBox", "Base.Doorknob", "Base.Hinge", "Base.BarbedWire",
                "Base.Woodglue", "Base.DuctTape",
            }
        },
        {
            id = "Hygiene",
            weight = 20,
            dists = { "CrateLinens", "CrateToiletPaper", "CrateSalonSupplies" },
            items = {
                "Base.Soap2", "Base.Bleach", "Base.BathTowel", "Base.ToiletPaper",
                "Base.Toothbrush", "Base.Toothpaste", "Base.Tissue",
            }
        },
        {
            id = "Vice",
            weight = 35,
            dists = { "CrateCigarettes", "CrateBeer", "CrateLiquor", "CrateWine", "CrateCoffee", "CrateChocolate" },
            items = {
                "Base.CigarettePack", "Base.CigaretteCarton", "Base.Lighter", "Base.Matches",
                "Base.Whiskey", "Base.BeerCan", "Base.Wine", "Base.Coffee2",
            }
        },
    }

    local function pickCategory(excludeIdx)
        local normalWeight = 0
        for i, c in ipairs(categories) do
            if i ~= excludeIdx then
                normalWeight = normalWeight + c.weight
            end
        end
        if normalWeight <= 0 then return 1, categories[1] end

        local cRoll = (ZombRand and ZombRand(normalWeight)) or math.random(0, normalWeight - 1)
        local cur = 0
        for i, c in ipairs(categories) do
            if i ~= excludeIdx then
                cur = cur + c.weight
                if cRoll < cur then
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
            end

            -- バニラルートテーブルから引けなかった場合は直指定プールにフォールバック
            if not itemId and #cat.items > 0 then
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
-- 生鮮野菜・果物・機能性ハーブ（薬草）の産直アソート充填処理
-- ---------------------------------------------------------------------------
-- 野菜3〜4個、果物1〜2個、ハーブ1〜2個をバランスよく封入（計5〜8個）
function RadioTrader_ItemsTable_FillProduceBag(bagContainer)
    if not bagContainer then return 0 end
    local addedCount = 0

    local function addItem(fullType)
        local script = getItem(fullType)
        if script then
            local itm = instanceItem(fullType)
            if itm then
                bagContainer:AddItem(itm)
                addedCount = addedCount + 1
            end
        end
    end

    -- 1. 生鮮野菜枠 (3〜4個)
    local veggieCount = (ZombRand and ZombRand(3, 5)) or math.random(3, 4)
    if RadioTrader_FreshVeggies and #RadioTrader_FreshVeggies > 0 then
        for i = 1, veggieCount do
            local idx = (ZombRand and (ZombRand(#RadioTrader_FreshVeggies) + 1)) or math.random(1, #RadioTrader_FreshVeggies)
            addItem(RadioTrader_FreshVeggies[idx])
        end
    end

    -- 2. 新鮮なフルーツ枠 (1〜2個)
    local fruitCount = (ZombRand and ZombRand(1, 3)) or math.random(1, 2)
    if RadioTrader_FreshFruits and #RadioTrader_FreshFruits > 0 then
        for i = 1, fruitCount do
            local idx = (ZombRand and (ZombRand(#RadioTrader_FreshFruits) + 1)) or math.random(1, #RadioTrader_FreshFruits)
            addItem(RadioTrader_FreshFruits[idx])
        end
    end

    -- 3. 機能性ハーブ・薬草枠 (1〜2個)
    local herbCount = (ZombRand and ZombRand(1, 3)) or math.random(1, 2)
    if RadioTrader_FreshHerbs and #RadioTrader_FreshHerbs > 0 then
        for i = 1, herbCount do
            local idx = (ZombRand and (ZombRand(#RadioTrader_FreshHerbs) + 1)) or math.random(1, #RadioTrader_FreshHerbs)
            addItem(RadioTrader_FreshHerbs[idx])
        end
    end

    return addedCount
end

-- ---------------------------------------------------------------------------
-- 冷凍精肉・鮮魚アソート充填処理（クーラーボックス充填用）
-- ---------------------------------------------------------------------------
-- 牛肉、豚肉、鶏肉、羊肉、鹿肉、兎肉、魚の切り身等の生肉を2〜3個封入し、全品 freeze() で完全凍結
function RadioTrader_ItemsTable_FillButcherBag(bagContainer, crateDef)
    if not bagContainer then return 0 end
    local addedCount = 0

    local minItems = (crateDef and crateDef.minItems) or 2
    local maxItems = (crateDef and crateDef.maxItems) or 3
    local targetCount = (ZombRand and ZombRand(minItems, maxItems + 1)) or math.random(minItems, maxItems)
    if RadioTrader_ButcherMeats and #RadioTrader_ButcherMeats > 0 then
        for i = 1, targetCount do
            local idx = (ZombRand and (ZombRand(#RadioTrader_ButcherMeats) + 1)) or math.random(1, #RadioTrader_ButcherMeats)
            local fullType = RadioTrader_ButcherMeats[idx]
            local script = getItem(fullType)
            if script then
                local itm = instanceItem(fullType)
                if itm then
                    -- 完全凍結処理（輸送中の腐敗防止）
                    if itm.freeze then
                        itm:freeze()
                    elseif itm.setFreezingTime then
                        itm:setFreezingTime(100.0)
                    end
                    bagContainer:AddItem(itm)
                    addedCount = addedCount + 1
                end
            end
        end
    end

    return addedCount
end

-- ---------------------------------------------------------------------------
-- 現場クルーからの差し入れランチボックス充填処理
-- ---------------------------------------------------------------------------
-- メイン料理枠（寿司・ピザ・バーガー・サンド等）から1〜2個、
-- 冷蔵・冷凍おやつ枠（アイス・アイスサンド・フルーツサラダ等）から確定1個を充填。
function RadioTrader_ItemsTable_FillLunchbox(lunchboxContainer)
    if not lunchboxContainer then return 0 end
    local addedCount = 0

    local function addItem(fullType)
        local script = getItem(fullType)
        if script then
            local itm = instanceItem(fullType)
            if itm then
                lunchboxContainer:AddItem(itm)
                addedCount = addedCount + 1
            end
        end
    end

    -- 1. メイン料理枠 (1〜2個)
    local mainCount = (ZombRand and ZombRand(1, 3)) or math.random(1, 2)
    if RadioTrader_LunchMains and #RadioTrader_LunchMains > 0 then
        for i = 1, mainCount do
            local idx = (ZombRand and (ZombRand(#RadioTrader_LunchMains) + 1)) or math.random(1, #RadioTrader_LunchMains)
            addItem(RadioTrader_LunchMains[idx])
        end
    end

    -- 2. 冷凍・冷蔵おやつ枠 (1個)
    if RadioTrader_LunchColdDesserts and #RadioTrader_LunchColdDesserts > 0 then
        local idx = (ZombRand and (ZombRand(#RadioTrader_LunchColdDesserts) + 1)) or math.random(1, #RadioTrader_LunchColdDesserts)
        addItem(RadioTrader_LunchColdDesserts[idx])
    end

    return addedCount
end

-- ---------------------------------------------------------------------------
-- 銃器スペックマッピングテーブル (銃本体 -> 対応マガジン, 対応バラ弾)
-- ---------------------------------------------------------------------------
RadioTrader_WeaponSpecs = {
    -- 拳銃 (Handguns)
    ["Base.Pistol"]                     = { mag = "Base.9mmClip",  ammo = "Base.Bullets9mm" },
    ["Base.Pistol2"]                    = { mag = "Base.45Clip",   ammo = "Base.Bullets45" },
    ["Base.Pistol3"]                    = { mag = "Base.44Clip",   ammo = "Base.Bullets44" },
    ["Base.Revolver"]                   = { mag = nil,             ammo = "Base.Bullets38" },
    ["Base.Revolver_Short"]             = { mag = nil,             ammo = "Base.Bullets38" },
    ["Base.Revolver_Long"]              = { mag = nil,             ammo = "Base.Bullets44" },

    -- ショットガン (Shotguns)
    ["Base.Shotgun"]                    = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.DoubleBarrelShotgun"]        = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.ShotgunSawnoff"]             = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.DoubleBarrelShotgunSawnoff"] = { mag = nil,             ammo = "Base.ShotgunShells" },

    -- ライフル・アサルトライフル (Rifles & Carbines)
    ["Base.AssaultRifle"]               = { mag = "Base.556Clip",  ammo = "Base.556Bullets" },
    ["Base.AssaultRifle2"]              = { mag = "Base.M14Clip",  ammo = "Base.308Bullets" },
    ["Base.HuntingRifle"]               = { mag = "Base.308Clip",  ammo = "Base.308Bullets" },
    ["Base.VarmintRifle"]               = { mag = "Base.223Clip",  ammo = "Base.223Bullets" },
    ["Base.L94_Rifle"]                  = { mag = nil,             ammo = "Base.3030Bullets" },
    ["Base.L92_Carbine"]                = { mag = nil,             ammo = "Base.Bullets357" },
}

-- ---------------------------------------------------------------------------
-- 銃器判定ヘルパー (アイテムまたはIDから対応マガジン・弾薬スペックを取得)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetWeaponSpec(item, itemId)
    if not itemId and item and item.getFullType then
        itemId = item:getFullType()
    end
    if itemId and RadioTrader_WeaponSpecs[itemId] then
        return RadioTrader_WeaponSpecs[itemId], itemId
    end

    -- 未知・MOD銃器の動的判定
    if item and instanceof(item, "HandWeapon") and item.isRanged and item:isRanged() then
        local magType = nil
        local ammoType = nil

        -- マガジン判定
        if item.getMagazineType then
            local rawMag = item:getMagazineType()
            if rawMag then
                if type(rawMag) == "string" then magType = rawMag
                elseif rawMag.getItemKey then magType = rawMag:getItemKey()
                else
                    local s = tostring(rawMag)
                    if s and s ~= "" and s ~= "null" and s ~= "nil" and not string.find(s, "^userdata:") then
                        magType = s
                    end
                end
            end
        end

        -- 弾丸判定
        if item.getAmmoType then
            local rawAmmo = item:getAmmoType()
            if rawAmmo then
                if type(rawAmmo) == "string" then ammoType = rawAmmo
                elseif rawAmmo.getItemKey then ammoType = rawAmmo:getItemKey()
                else
                    local s = tostring(rawAmmo)
                    if s and s ~= "" and s ~= "null" and s ~= "nil" and not string.find(s, "^userdata:") then
                        ammoType = s
                    end
                end
            end
        end

        if not ammoType then
            ammoType = "Base.Bullets9mm"
        end

        return { mag = magType, ammo = ammoType }, itemId
    end

    return nil, itemId
end

-- ---------------------------------------------------------------------------
-- 弾薬箱まとめ買いボーナステーブル (同一弾薬箱2箱以上購入時のおまけマガジン/バラ弾)
-- ---------------------------------------------------------------------------
RadioTrader_AmmoBoxBonus = {
    -- 着脱式マガジン対応口径 (マガジン1個ボーナス)
    ["Base.Bullets9mmBox"]   = { mag = "Base.9mmClip" },
    ["Base.Bullets45Box"]    = { mag = "Base.45Clip" },
    ["Base.Bullets44Box"]    = { mag = "Base.44Clip" },
    ["Base.556Box"]          = { mag = "Base.556Clip" },
    ["Base.308Box"]          = { mag = "Base.308Clip", altMag = "Base.M14Clip" },
    ["Base.223Box"]          = { mag = "Base.223Clip" },

    -- 内蔵弾倉・リボルバー・散弾口径 (バラ弾ボーナス)
    ["Base.ShotgunShellsBox"]= { looseAmmo = "Base.ShotgunShells", ammoCount = 6 },
    ["Base.Bullets38Box"]    = { looseAmmo = "Base.Bullets38",     ammoCount = 10 },
    ["Base.Bullets357Box"]   = { looseAmmo = "Base.Bullets357",    ammoCount = 10 },
    ["Base.3030Box"]         = { looseAmmo = "Base.3030Bullets",   ammoCount = 10 },
}

-- ---------------------------------------------------------------------------
-- 弾薬箱ボーナス判定ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetAmmoBoxBonus(boxItemId)
    if not boxItemId then return nil end
    local bonus = RadioTrader_AmmoBoxBonus[boxItemId]
    if not bonus then
        local stripped = string.gsub(boxItemId, "^Base%.", "")
        bonus = RadioTrader_AmmoBoxBonus["Base." .. stripped] or RadioTrader_AmmoBoxBonus[stripped]
    end
    return bonus
end

-- ---------------------------------------------------------------------------
-- 銃器ダッフルバッグ充填処理 (Arms & Ammo Duffel Bag)
-- ---------------------------------------------------------------------------
-- 規定数（3〜8枠）に達するまでアイテムを充填。
-- 銃本体は最大1挺まで（2挺目が抽選された場合は再抽選して弾薬等の物資に置換）。
-- 銃本体が当選した際は「対応マガジン(1個)＋対応バラ弾(5〜20個)」をセット同梱。
function RadioTrader_ItemsTable_FillWeaponsBag(bagContainer, crateDef)
    if not bagContainer or not crateDef then return 0 end

    local minItems = crateDef.minItems or 3
    local maxItems = crateDef.maxItems or 8
    local targetCount = minItems
    if ZombRand then
        targetCount = ZombRand(minItems, maxItems + 1)
    else
        targetCount = math.random(minItems, maxItems)
    end

    local lists = crateDef.distributionLists or {}
    local customPool = crateDef.customItems or {}
    if #lists == 0 and #customPool == 0 then return 0 end

    local mainItemsCount = 0
    local totalAddedCount = 0
    local attempts = 0
    local hasGun = false

    while mainItemsCount < targetCount and attempts < 150 do
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
            local cIdx = (ZombRand and (ZombRand(#customPool) + 1)) or math.random(1, #customPool)
            itemId = customPool[cIdx]
        else
            local listIdx = (ZombRand and (ZombRand(#lists) + 1)) or math.random(1, #lists)
            local distName = lists[listIdx]
            itemId = RadioTrader_ItemsTable_RollProceduralItem(distName)
        end

        if itemId then
            -- 既に銃を引いている場合、2挺目の銃器IDならインスタンス生成前に早期スキップ
            local isKnownGun = (RadioTrader_WeaponSpecs[itemId] ~= nil)
            if hasGun and isKnownGun then
                -- 2挺目の銃器のため再抽選スキップ
            else
                local script = getItem(itemId)
                if script then
                    local spawned = instanceItem(itemId)
                    if spawned then
                        -- 銃器本体かどうかの判定 (HandWeapon かつ isRanged)
                        local spec = RadioTrader_ItemsTable_GetWeaponSpec(spawned, itemId)
                        if hasGun and spec then
                            -- 2挺目の銃器だった場合はバッグに追加せず再抽選スキップ
                        else
                            RadioTrader_ItemsTable_FillContainerItem(spawned)
                            bagContainer:AddItem(spawned)
                            mainItemsCount = mainItemsCount + 1
                            totalAddedCount = totalAddedCount + 1

                            -- 初めて銃器を引いた場合のワンセット同梱処理
                            if spec and not hasGun then
                                hasGun = true

                                -- 1. 対応マガジンがあれば1個生成して同梱
                                if spec.mag then
                                    local magScript = getItem(spec.mag)
                                    if magScript then
                                        local magItem = instanceItem(spec.mag)
                                        if magItem then
                                            bagContainer:AddItem(magItem)
                                            totalAddedCount = totalAddedCount + 1
                                        end
                                    end
                                end

                                -- 2. 対応バラ弾を 5〜20個 生成して同梱
                                if spec.ammo then
                                    local ammoScript = getItem(spec.ammo)
                                    if ammoScript then
                                        local ammoCount = (ZombRand and ZombRand(5, 21)) or math.random(5, 20)
                                        for a = 1, ammoCount do
                                            local ammoItem = instanceItem(spec.ammo)
                                            if ammoItem then
                                                bagContainer:AddItem(ammoItem)
                                                totalAddedCount = totalAddedCount + 1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return totalAddedCount
end

-- ---------------------------------------------------------------------------
-- 技能スキルビデオテープ定義 (Woodcraft, Cook Show, Survival, Carzone等)
-- ---------------------------------------------------------------------------
RadioTrader_SkillVHSList = {
    "9953e7f7-396c-4400-82d7-0fc24fbfe0b7", -- VHS: Tired in Toronto
    "31a726b7-0ee6-408b-8599-95c80aa8a6c5", -- VHS: Dead Wrong
    "9ec23879-13eb-4b6a-ab44-e9038952104f", -- VHS: Mother's Boy
    "4255a86b-d9f7-45e3-bf9f-060c8a35858d", -- VHS: Z-Squad S2.02
    "4f3f30d6-df77-4e85-b1cb-4ca7e67addd9", -- VHS: Z-Squad S2.03
    "9fcadfea-5b3b-4c72-ac30-d03839a3e86d", -- VHS: Survival Instinct
    "21411665-0ce7-4200-83a1-43ae2e6cbbb3", -- VHS: The Dog Goblin
    "0bac9338-28c4-4a72-94fe-9d47cf956f7b", -- VHS: Global Warrior
    "e6fd44a9-1774-4204-ab45-9b316301aa2b", -- VHS: The Cook Show E1
    "a754fdaf-5bac-40cd-9a69-da90e8a0cac7", -- VHS: The Cook Show E2
    "7933a371-a8a6-4c31-8886-7a97d89f2c7e", -- VHS: The Cook Show E3
    "4cc3b806-4630-4dfc-a935-efa700fbd7fb", -- VHS: The Cook Show E4
    "2695eb00-ee79-4b39-833a-1023a28ce397", -- VHS: The Cook Show E5
    "01b3d832-602c-4566-b8d6-c2b74a4a0b00", -- VHS: The Cook Show E6
    "2c2a052d-097c-4507-85f4-7fda90f3e3d1", -- VHS: The Cook Show E7
    "dedd4e83-6e3b-4f4f-9c9b-72a5ed08969d", -- VHS: Woodcraft E1
    "c2d01da8-8e04-4889-8676-bb633e98df2d", -- VHS: Woodcraft E2
    "3e9c5cf0-bf40-40eb-bcd7-4fd6c5ae58ca", -- VHS: Woodcraft E3
    "0627a89a-a32b-4e80-9926-815aa9d22b2b", -- VHS: Woodcraft E4
    "2bf49f71-0d46-43aa-bbfd-f311e5bda9b2", -- VHS: Woodcraft E5
    "968591cd-d4aa-4ef1-9632-7771a1f5b9ab", -- VHS: Woodcraft E6
    "01dedfea-62eb-4ae6-a4bc-5e629b7ba54b", -- VHS: Woodcraft E7
    "ccfd97d7-6b57-432c-bca7-f9a271f8012f", -- VHS: Exposure Survival E1
    "6f1be5b5-d871-4ebf-bc44-2657f7c89bb5", -- VHS: Exposure Survival E2
    "7402fb83-b5b3-4b08-99f9-82bc67f4572b", -- VHS: Exposure Survival E3
    "a628a723-ac78-4bcb-927a-f84ad8c6c286", -- VHS: Exposure Survival E4
    "1123df57-5e9b-4d61-88f1-7561949132e3", -- VHS: Exposure Survival E5
    "75928dcd-c613-4a1e-afb5-20c4c671b835", -- VHS: Exposure Survival E6
    "2dcd687b-ac76-4b33-b0b7-79ddfba2feb4", -- VHS: Exposure Survival E7
    "f74df7fc-20ae-4600-b2d2-f504d9355440", -- VHS: Exposure Survival E8
    "98406d57-3f55-4f36-afc4-b78554acc0aa", -- VHS: Simon's Fitness Club E5
    "07b0cd73-7563-4699-9fb4-99316a0fc0bd", -- VHS: Carzone E1
    "7b192b30-ea36-4395-a5e4-ac2d825d3b91", -- VHS: Carzone E2
    "313fa630-d448-44ab-b1f0-7cff1d1db830", -- VHS: Carzone E3
    "a8c4eccf-53d9-42ad-8091-b9e562621c8f", -- Home VHS: English Cup (4.12.91)
    "1559a55a-bfc9-4cfc-967b-e26b860894c6", -- Home VHS: OSCC '92
    "8904b5c7-86f6-4b49-a163-cf37d4421895", -- Home VHS: stock cars
    "00a8b565-a566-44f3-b6d2-7a1ae2eafb0c", -- Home VHS: Granny Nani
    "af941537-39ac-42fb-8c7a-ed346ded282e", -- Home VHS: Tailoring 101
    "1c6745f6-70b8-49e8-9087-b1bbb9263985", -- Home VHS: nof vid
    "fe4ede3c-a153-4e46-aebe-9681d14fe196", -- Home VHS: no 9
    "ffe28381-b743-4300-8c5a-89b4c4983d05", -- Home VHS: Muldraugh AV Club
    "c23539e8-c5eb-4f58-850f-18522250c470", -- Home VHS: TV repair
    "14fca23a-86ca-44b3-8342-264791175421", -- Home VHS: RMFA
}

RadioTrader_SkillVHSMap = {}
for _, vid in ipairs(RadioTrader_SkillVHSList) do
    RadioTrader_SkillVHSMap[vid] = true
end

-- 一般・娯楽メディアプール (25% 枠)
RadioTrader_CasualMediaPool = {
    "Base.ComicBook",
    "Base.Magazine",
    "Base.Book",
    "Base.Newspaper",
    "Base.MagazineCrossword",
    "Base.MagazineWordsearch",
    "Base.HottieZ",
    "Base.Disc_Retail", -- 音楽CD
    "Base.VHS_Retail",  -- 一般映画VHS
    "Base.VHS_Home",    -- 一般ホームVHS
}

-- ---------------------------------------------------------------------------
-- ビデオテープへのメディアデータ設定ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_SetVHSMedia(vhsItem, mediaId)
    if not vhsItem or not mediaId then return end
    if getZomboidRadio then
        local radio = getZomboidRadio()
        if radio and radio.getRecordedMedia then
            local rm = radio:getRecordedMedia()
            if rm and rm.getMediaDataFromId then
                local mData = rm:getMediaDataFromId(mediaId)
                if mData and vhsItem.setRecordedMediaData then
                    vhsItem:setRecordedMediaData(mData)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- 記録メディア（VHSビデオテープ・音楽CD）の動的査定ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessRecordedMedia(item, itemType)
    if not item then return nil end
    local typeStr = itemType or (item.getFullType and item:getFullType()) or ""

    -- 1. ビデオテープ (VHS)
    if typeStr == "Base.VHS_Retail" or typeStr == "Base.VHS_Home" or string.find(typeStr, "VHS") or string.find(typeStr, "VideoTape") then
        local isSkillTape = false
        local mediaTitle = nil

        -- メディアデータの検査
        if item.getRecordedMediaData then
            local mData = item:getRecordedMediaData()
            if mData then
                local mId = mData.getId and mData:getId()
                if mId and RadioTrader_SkillVHSMap and RadioTrader_SkillVHSMap[mId] then
                    isSkillTape = true
                end
                mediaTitle = mData.getTranslatedItemDisplayName and mData:getTranslatedItemDisplayName()
            end
        end

        -- 名前によるフォールバック判定 (Woodcraft, Cook, Survival, Carzone 等)
        if not isSkillTape and item.getName then
            local nm = item:getName() or ""
            local lowerNm = string.lower(nm)
            if string.find(lowerNm, "woodcraft") or string.find(lowerNm, "cook")
                or string.find(lowerNm, "survival") or string.find(lowerNm, "carzone")
                or string.find(lowerNm, "tailor") or string.find(lowerNm, "repair")
                or string.find(lowerNm, "mechanic") or string.find(lowerNm, "metal") then
                isSkillTape = true
            end
            if not mediaTitle then mediaTitle = nm end
        end

        if isSkillTape then
            return {
                id               = typeStr,
                name             = mediaTitle or "Skill VHS Tape",
                basePricePerUnit = 15, -- スキルビデオは高額買取 (15 CR)
                category         = "Archives",
            }
        else
            return {
                id               = typeStr,
                name             = mediaTitle or "VHS Tape",
                basePricePerUnit = 6,  -- 一般ビデオ (6 CR)
                category         = "Archives",
            }
        end
    end

    -- 2. 音楽CD・ディスク (Disc / CD) ※CDプレイヤー等の機器は除外
    if (typeStr == "Base.Disc_Retail" or string.find(typeStr, "Disc") or string.find(typeStr, "CD")) and not string.find(typeStr, "Player") then
        local cdTitle = item.getName and item:getName()
        return {
            id               = typeStr,
            name             = cdTitle or "CD Disc",
            basePricePerUnit = 4,  -- 音楽CD (4 CR)
            category         = "Archives",
        }
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- DIY技術・メディアまぜこぜダッフルバッグ充填処理 (DIY & Media Recipes Bag)
-- ---------------------------------------------------------------------------
-- 有用枠（75%: レシピ本 50% / スキルVHS 50%）と一般枠（25%: 雑誌・書籍・映画VHS・音楽CD）のハイブリッド充填
function RadioTrader_ItemsTable_FillMediaRecipeBag(bagContainer, crateDef)
    if not bagContainer or not crateDef then return 0 end

    local minItems = crateDef.minItems or 4
    local maxItems = crateDef.maxItems or 8
    local targetCount = minItems
    if ZombRand then
        targetCount = ZombRand(minItems, maxItems + 1)
    else
        targetCount = math.random(minItems, maxItems)
    end

    local recipePool = crateDef.customItems or {}
    local addedCount = 0
    local attempts = 0

    while addedCount < targetCount and attempts < 100 do
        attempts = attempts + 1
        local rollVal = (ZombRand and ZombRand(100)) or math.random(0, 99)

        if rollVal < 75 then
            -- 75% 有用・技能枠 (レシピ本 50% / スキルVHS 50%)
            local subRoll = (ZombRand and ZombRand(100)) or math.random(0, 99)
            if subRoll < 50 and #recipePool > 0 then
                -- レシピ本 (全86種)
                local idx = (ZombRand and (ZombRand(#recipePool) + 1)) or math.random(1, #recipePool)
                local recipeId = recipePool[idx]
                local script = getItem(recipeId)
                if script then
                    local spawned = instanceItem(recipeId)
                    if spawned then
                        bagContainer:AddItem(spawned)
                        addedCount = addedCount + 1
                    end
                end
            else
                -- スキルビデオテープ (VHS)
                local tapeType = (ZombRand and ZombRand(100) < 50 or math.random(0, 99) < 50) and "Base.VHS_Retail" or "Base.VHS_Home"
                local script = getItem(tapeType)
                if script then
                    local tapeItem = instanceItem(tapeType)
                    if tapeItem then
                        if RadioTrader_SkillVHSList and #RadioTrader_SkillVHSList > 0 then
                            local vIdx = (ZombRand and (ZombRand(#RadioTrader_SkillVHSList) + 1)) or math.random(1, #RadioTrader_SkillVHSList)
                            local chosenMediaId = RadioTrader_SkillVHSList[vIdx]
                            RadioTrader_ItemsTable_SetVHSMedia(tapeItem, chosenMediaId)
                        end
                        bagContainer:AddItem(tapeItem)
                        addedCount = addedCount + 1
                    end
                end
            end
        else
            -- 25% 一般・娯楽・文化枠 (雑誌・書籍・映画VHS・CD)
            if RadioTrader_CasualMediaPool and #RadioTrader_CasualMediaPool > 0 then
                local idx = (ZombRand and (ZombRand(#RadioTrader_CasualMediaPool) + 1)) or math.random(1, #RadioTrader_CasualMediaPool)
                local itemId = RadioTrader_CasualMediaPool[idx]
                local script = getItem(itemId)
                if script then
                    local spawned = instanceItem(itemId)
                    if spawned then
                        bagContainer:AddItem(spawned)
                        addedCount = addedCount + 1
                    end
                end
            end
        end
    end

    return addedCount
end

-- ---------------------------------------------------------------------------
-- ダッフルバッグにバニラルートアイテムを充填（全体乱数カウント 3〜10 に収まるまで抽選）
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_FillDuffelBag(bagItem, crateDef)
    if not bagItem or not crateDef then return 0 end
    local bagContainer = bagItem:getItemContainer()
    if not bagContainer then return 0 end

    -- 銃器・弾薬・マガジンワンセットダッフルバッグの場合は専用充填処理を実行
    if crateDef.isWeaponsBag then
        return RadioTrader_ItemsTable_FillWeaponsBag(bagContainer, crateDef)
    end

    -- DIY技術・メディアまぜこぜダッフルバッグの場合は専用充填処理を実行
    if crateDef.isMediaRecipeBag then
        return RadioTrader_ItemsTable_FillMediaRecipeBag(bagContainer, crateDef)
    end

    -- ゴミ袋の場合は専用の複合・重み付け抽選処理を実行
    if crateDef.isTrashBag then
        return RadioTrader_ItemsTable_FillTrashBag(bagContainer)
    end

    -- 生鮮野菜・果物・ハーブアソートバッグの場合は専用充填処理を実行
    if crateDef.isProduceBag then
        return RadioTrader_ItemsTable_FillProduceBag(bagContainer)
    end

    -- 冷凍精肉・鮮魚クーラーボックスの場合は専用充填処理を実行
    if crateDef.isButcherBag then
        return RadioTrader_ItemsTable_FillButcherBag(bagContainer, crateDef)
    end

    -- 不用品回収依頼の場合は差し入れスイーツ判定 (30%確率)
    if crateDef.isPickupRequest then
        local roll = (ZombRand and ZombRand(100)) or math.random(0, 99)
        if roll < (crateDef.sweetChance or 30) and RadioTrader_BakerySweets and #RadioTrader_BakerySweets > 0 then
            local idx = (ZombRand and (ZombRand(#RadioTrader_BakerySweets) + 1)) or math.random(1, #RadioTrader_BakerySweets)
            local sweetId = RadioTrader_BakerySweets[idx]
            local itm = instanceItem(sweetId)
            if itm then
                bagContainer:AddItem(itm)
                return 1
            end
        end
        return 0
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
                    RadioTrader_ItemsTable_FillContainerItem(spawned)
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
        { id = "RadioTrader_Crate_Pickup",      name = "Cargo Pickup Request",          price = 100,  count = 1 },
        { id = "RadioTrader_Crate_Food",        name = "Food Supply Duffel Bag",        price = 600,  count = 1 },
        { id = "RadioTrader_Crate_Produce",     name = "Fresh Produce & Herbs Bag",     price = 850,  count = 1 },
        { id = "RadioTrader_Crate_Butcher",     name = "Frozen Meat & Seafood Cooler",  price = 950,  count = 1 },
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
        { id = "RadioTrader_Crate_Recipes",     name = "DIY & Crafting Recipes Duffel Bag", price = 700, count = 1 },
        { id = "RadioTrader_Mystery_Furniture", name = "Mystery Furniture Delivery",   price = 1800, count = 1 },
    },

    -- 食料補給 (互換用)
    Food = {
        { id = "RadioTrader_Crate_Food",      name = "Food Supply Duffel Bag",        price = 600,  count = 1  },
        { id = "RadioTrader_Crate_Produce",   name = "Fresh Produce & Herbs Bag",     price = 850,  count = 1  },
        { id = "RadioTrader_Crate_Butcher",   name = "Frozen Meat & Seafood Cooler",  price = 950,  count = 1  },
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
        { id = "RadioTrader_Crate_Recipes",   name = "DIY & Crafting Recipes Duffel Bag", price = 700, count = 1 },
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
        { id = "RadioTrader_Crate_Pickup",        name = "Cargo Pickup Request",          price = 100,  count = 1 },
        { id = "RadioTrader_Crate_TrashBag",      name = "Trader's Mystery Trash Bag",    price = 350,  count = 1 },
        { id = "Base.Generator",                  name = "Generator",                     price = 5000, count = 1 },
        { id = "Base.Mov_RoadBarrier",            name = "Concrete Barricade",            price = 2000, count = 1 },
        { id = "Base.Mov_LightConstruction",      name = "Flood Lights",                  price = 5000, count = 1 },
        { id = "Base.Battery",                    name = "Battery",                       price = 90,   count = 2 },
    },

    -- 弾薬庫・口径別弾薬箱指名注文枠 (1日1回更新の日替わり在庫プール 0〜5箱 / 基準 500〜800 CR)
    Ammo = {
        { id = "Base.Bullets38Box",     name = ".38 Special Ammo Box", price = 500, count = 1, isAmmo = true, poolKey = "Base.Bullets38Box" },
        { id = "Base.Bullets9mmBox",    name = "9mm Ammo Box",         price = 550, count = 1, isAmmo = true, poolKey = "Base.Bullets9mmBox" },
        { id = "Base.Bullets357Box",    name = ".357 Magnum Ammo Box", price = 600, count = 1, isAmmo = true, poolKey = "Base.Bullets357Box" },
        { id = "Base.Bullets45Box",     name = ".45 Auto Ammo Box",    price = 600, count = 1, isAmmo = true, poolKey = "Base.Bullets45Box" },
        { id = "Base.Bullets44Box",     name = ".44 Magnum Ammo Box",  price = 650, count = 1, isAmmo = true, poolKey = "Base.Bullets44Box" },
        { id = "Base.3030Box",          name = ".30-30 Ammo Box",      price = 700, count = 1, isAmmo = true, poolKey = "Base.3030Box" },
        { id = "Base.ShotgunShellsBox", name = "Shotgun Shells Box",   price = 750, count = 1, isAmmo = true, poolKey = "Base.ShotgunShellsBox" },
        { id = "Base.308Box",           name = ".308 Ammo Box",        price = 750, count = 1, isAmmo = true, poolKey = "Base.308Box" },
        { id = "Base.556Box",           name = "5.56mm Ammo Box",      price = 800, count = 1, isAmmo = true, poolKey = "Base.556Box" },
    },

    -- 契約農園・農作物交換枠 (種プールを消費して収穫委託品を受注 / 5 CR固定)
    -- Build 42 栽培可能作物 全55種
    Crops = {
        { id = "Base.BarleySheaf", name = "Barley Sheaf", price = 5, count = 1, isCrop = true, poolKey = "Base.BarleySheaf", seedType = "Barley" },
        { id = "Base.Basil", name = "Basil", price = 5, count = 1, isCrop = true, poolKey = "Base.Basil", seedType = "Basil" },
        { id = "Base.BellPepper", name = "Bell Pepper", price = 5, count = 1, isCrop = true, poolKey = "Base.BellPepper", seedType = "BellPepper" },
        { id = "Base.BlackSage", name = "Black Sage", price = 5, count = 1, isCrop = true, poolKey = "Base.BlackSage", seedType = "BlackSage" },
        { id = "Base.Broccoli", name = "Broccoli", price = 5, count = 1, isCrop = true, poolKey = "Base.Broccoli", seedType = "Broccoli" },
        { id = "Base.Cabbage", name = "Cabbage", price = 5, count = 1, isCrop = true, poolKey = "Base.Cabbage", seedType = "Cabbages" },
        { id = "Base.Carrots", name = "Carrots", price = 5, count = 1, isCrop = true, poolKey = "Base.Carrots", seedType = "Carrots" },
        { id = "Base.Cauliflower", name = "Cauliflower", price = 5, count = 1, isCrop = true, poolKey = "Base.Cauliflower", seedType = "Cauliflower" },
        { id = "Base.Chamomile", name = "Chamomile", price = 5, count = 1, isCrop = true, poolKey = "Base.Chamomile", seedType = "Chamomile" },
        { id = "Base.Chives", name = "Chives", price = 5, count = 1, isCrop = true, poolKey = "Base.Chives", seedType = "Chives" },
        { id = "Base.Cilantro", name = "Cilantro", price = 5, count = 1, isCrop = true, poolKey = "Base.Cilantro", seedType = "Cilantro" },
        { id = "Base.Comfrey", name = "Comfrey", price = 5, count = 1, isCrop = true, poolKey = "Base.Comfrey", seedType = "Comfrey" },
        { id = "Base.CommonMallow", name = "Common Mallow", price = 5, count = 1, isCrop = true, poolKey = "Base.CommonMallow", seedType = "CommonMallow" },
        { id = "Base.Corn", name = "Corn", price = 5, count = 1, isCrop = true, poolKey = "Base.Corn", seedType = "Corn" },
        { id = "Base.Cucumber", name = "Cucumber", price = 5, count = 1, isCrop = true, poolKey = "Base.Cucumber", seedType = "Cucumber" },
        { id = "Base.Flax", name = "Flax", price = 5, count = 1, isCrop = true, poolKey = "Base.Flax", seedType = "Flax" },
        { id = "Base.Garlic", name = "Garlic", price = 5, count = 1, isCrop = true, poolKey = "Base.Garlic", seedType = "Garlic" },
        { id = "Base.Greenpeas", name = "Green Peas", price = 5, count = 1, isCrop = true, poolKey = "Base.Greenpeas", seedType = "Greenpeas" },
        { id = "Base.PepperHabanero", name = "Habanero", price = 5, count = 1, isCrop = true, poolKey = "Base.PepperHabanero", seedType = "Habanero" },
        { id = "Base.HempBundle", name = "Hemp", price = 5, count = 1, isCrop = true, poolKey = "Base.HempBundle", seedType = "Hemp" },
        { id = "Base.Hops", name = "Hops", price = 5, count = 1, isCrop = true, poolKey = "Base.Hops", seedType = "Hops" },
        { id = "Base.PepperJalapeno", name = "Jalapeno", price = 5, count = 1, isCrop = true, poolKey = "Base.PepperJalapeno", seedType = "Jalapeno" },
        { id = "Base.Kale", name = "Kale", price = 5, count = 1, isCrop = true, poolKey = "Base.Kale", seedType = "Kale" },
        { id = "Base.Lavender", name = "Lavender", price = 5, count = 1, isCrop = true, poolKey = "Base.Lavender", seedType = "Lavender" },
        { id = "Base.Leek", name = "Leek", price = 5, count = 1, isCrop = true, poolKey = "Base.Leek", seedType = "Leek" },
        { id = "Base.LemonGrass", name = "Lemongrass", price = 5, count = 1, isCrop = true, poolKey = "Base.LemonGrass", seedType = "LemonGrass" },
        { id = "Base.Lettuce", name = "Lettuce", price = 5, count = 1, isCrop = true, poolKey = "Base.Lettuce", seedType = "Lettuce" },
        { id = "Base.Marigold", name = "Marigold", price = 5, count = 1, isCrop = true, poolKey = "Base.Marigold", seedType = "Marigold" },
        { id = "Base.MintHerb", name = "Mint", price = 5, count = 1, isCrop = true, poolKey = "Base.MintHerb", seedType = "Mint" },
        { id = "Base.Onion", name = "Onion", price = 5, count = 1, isCrop = true, poolKey = "Base.Onion", seedType = "Onion" },
        { id = "Base.Oregano", name = "Oregano", price = 5, count = 1, isCrop = true, poolKey = "Base.Oregano", seedType = "Oregano" },
        { id = "Base.Parsley", name = "Parsley", price = 5, count = 1, isCrop = true, poolKey = "Base.Parsley", seedType = "Parsley" },
        { id = "Base.Plantain", name = "Plantain", price = 5, count = 1, isCrop = true, poolKey = "Base.Plantain", seedType = "BroadleafPlantain" },
        { id = "Base.Poppies", name = "Poppies", price = 5, count = 1, isCrop = true, poolKey = "Base.Poppies", seedType = "Poppies" },
        { id = "Base.Potato", name = "Potato", price = 5, count = 1, isCrop = true, poolKey = "Base.Potato", seedType = "Potatoes" },
        { id = "Base.Pumpkin", name = "Pumpkin", price = 5, count = 1, isCrop = true, poolKey = "Base.Pumpkin", seedType = "Pumpkin" },
        { id = "Base.RedRadish", name = "Radish", price = 5, count = 1, isCrop = true, poolKey = "Base.RedRadish", seedType = "Radishes" },
        { id = "Base.Rosemary", name = "Rosemary", price = 5, count = 1, isCrop = true, poolKey = "Base.Rosemary", seedType = "Rosemary" },
        { id = "Base.Roses", name = "Roses", price = 5, count = 1, isCrop = true, poolKey = "Base.Roses", seedType = "Roses" },
        { id = "Base.RyeSheaf", name = "Rye Sheaf", price = 5, count = 1, isCrop = true, poolKey = "Base.RyeSheaf", seedType = "Rye" },
        { id = "Base.Sage", name = "Sage", price = 5, count = 1, isCrop = true, poolKey = "Base.Sage", seedType = "Sage" },
        { id = "Base.Soybeans", name = "Soybeans", price = 5, count = 1, isCrop = true, poolKey = "Base.Soybeans", seedType = "Soybeans" },
        { id = "Base.Spinach", name = "Spinach", price = 5, count = 1, isCrop = true, poolKey = "Base.Spinach", seedType = "Spinach" },
        { id = "Base.Strewberrie", name = "Strawberries", price = 5, count = 1, isCrop = true, poolKey = "Base.Strewberrie", seedType = "Strawberryplant" },
        { id = "Base.SugarBeet", name = "Sugar Beet", price = 5, count = 1, isCrop = true, poolKey = "Base.SugarBeet", seedType = "SugarBeets" },
        { id = "Base.SunflowerHead", name = "Sunflower Head", price = 5, count = 1, isCrop = true, poolKey = "Base.SunflowerHead", seedType = "Sunflower" },
        { id = "Base.SweetPotato", name = "Sweet Potato", price = 5, count = 1, isCrop = true, poolKey = "Base.SweetPotato", seedType = "SweetPotato" },
        { id = "Base.Thyme", name = "Thyme", price = 5, count = 1, isCrop = true, poolKey = "Base.Thyme", seedType = "Thyme" },
        { id = "Base.Tobacco", name = "Tobacco", price = 5, count = 1, isCrop = true, poolKey = "Base.Tobacco", seedType = "Tobacco" },
        { id = "Base.Tomato", name = "Tomato", price = 5, count = 1, isCrop = true, poolKey = "Base.Tomato", seedType = "Tomato" },
        { id = "Base.Turnip", name = "Turnip", price = 5, count = 1, isCrop = true, poolKey = "Base.Turnip", seedType = "Turnip" },
        { id = "Base.Watermelon", name = "Watermelon", price = 5, count = 1, isCrop = true, poolKey = "Base.Watermelon", seedType = "Watermelon" },
        { id = "Base.WheatSheaf", name = "Wheat Sheaf", price = 5, count = 1, isCrop = true, poolKey = "Base.WheatSheaf", seedType = "Wheat" },
        { id = "Base.WildGarlic2", name = "Wild Garlic", price = 5, count = 1, isCrop = true, poolKey = "Base.WildGarlic2", seedType = "WildGarlic" },
        { id = "Base.Zucchini", name = "Zucchini", price = 5, count = 1, isCrop = true, poolKey = "Base.Zucchini", seedType = "Zucchini" },
    },

    -- 日替わり特売・スポット入荷枠（バニラCrateから動的抽選・初期空テーブル）
    Daily = {},
}

-- ---------------------------------------------------------------------------
-- 契約農園: 種・種袋アイテムマッピング
-- ---------------------------------------------------------------------------
-- バラ種は1個分、パッケージされた種袋は5個分としてプールにカウント
RadioTrader_SeedMapping = {
    ["Base.BarleySeed"] = { cropId = "Base.BarleySheaf", poolKey = "Base.BarleySheaf", count = 1, name = "Barley Sheaf Seeds" },
    ["Base.BarleyBagSeed"] = { cropId = "Base.BarleySheaf", poolKey = "Base.BarleySheaf", count = 5, name = "Barley Sheaf Seed Packet" },
    ["Base.BasilSeed"] = { cropId = "Base.Basil", poolKey = "Base.Basil", count = 1, name = "Basil Seeds" },
    ["Base.BasilBagSeed"] = { cropId = "Base.Basil", poolKey = "Base.Basil", count = 5, name = "Basil Seed Packet" },
    ["Base.BellPepperSeed"] = { cropId = "Base.BellPepper", poolKey = "Base.BellPepper", count = 1, name = "Bell Pepper Seeds" },
    ["Base.BellPepperBagSeed"] = { cropId = "Base.BellPepper", poolKey = "Base.BellPepper", count = 5, name = "Bell Pepper Seed Packet" },
    ["Base.BlackSageSeed"] = { cropId = "Base.BlackSage", poolKey = "Base.BlackSage", count = 1, name = "Black Sage Seeds" },
    ["Base.BlackSageBagSeed"] = { cropId = "Base.BlackSage", poolKey = "Base.BlackSage", count = 5, name = "Black Sage Seed Packet" },
    ["Base.BroccoliSeed"] = { cropId = "Base.Broccoli", poolKey = "Base.Broccoli", count = 1, name = "Broccoli Seeds" },
    ["Base.BroccoliBagSeed2"] = { cropId = "Base.Broccoli", poolKey = "Base.Broccoli", count = 5, name = "Broccoli Seed Packet" },
    ["Base.CabbageSeed"] = { cropId = "Base.Cabbage", poolKey = "Base.Cabbage", count = 1, name = "Cabbage Seeds" },
    ["Base.CabbageBagSeed2"] = { cropId = "Base.Cabbage", poolKey = "Base.Cabbage", count = 5, name = "Cabbage Seed Packet" },
    ["Base.CarrotSeed"] = { cropId = "Base.Carrots", poolKey = "Base.Carrots", count = 1, name = "Carrots Seeds" },
    ["Base.CarrotBagSeed2"] = { cropId = "Base.Carrots", poolKey = "Base.Carrots", count = 5, name = "Carrots Seed Packet" },
    ["Base.CauliflowerSeed"] = { cropId = "Base.Cauliflower", poolKey = "Base.Cauliflower", count = 1, name = "Cauliflower Seeds" },
    ["Base.CauliflowerBagSeed"] = { cropId = "Base.Cauliflower", poolKey = "Base.Cauliflower", count = 5, name = "Cauliflower Seed Packet" },
    ["Base.ChamomileSeed"] = { cropId = "Base.Chamomile", poolKey = "Base.Chamomile", count = 1, name = "Chamomile Seeds" },
    ["Base.ChamomileBagSeed"] = { cropId = "Base.Chamomile", poolKey = "Base.Chamomile", count = 5, name = "Chamomile Seed Packet" },
    ["Base.ChivesSeed"] = { cropId = "Base.Chives", poolKey = "Base.Chives", count = 1, name = "Chives Seeds" },
    ["Base.ChivesBagSeed"] = { cropId = "Base.Chives", poolKey = "Base.Chives", count = 5, name = "Chives Seed Packet" },
    ["Base.CilantroSeed"] = { cropId = "Base.Cilantro", poolKey = "Base.Cilantro", count = 1, name = "Cilantro Seeds" },
    ["Base.CilantroBagSeed"] = { cropId = "Base.Cilantro", poolKey = "Base.Cilantro", count = 5, name = "Cilantro Seed Packet" },
    ["Base.ComfreySeed"] = { cropId = "Base.Comfrey", poolKey = "Base.Comfrey", count = 1, name = "Comfrey Seeds" },
    ["Base.ComfreyBagSeed"] = { cropId = "Base.Comfrey", poolKey = "Base.Comfrey", count = 5, name = "Comfrey Seed Packet" },
    ["Base.CommonMallowSeed"] = { cropId = "Base.CommonMallow", poolKey = "Base.CommonMallow", count = 1, name = "Common Mallow Seeds" },
    ["Base.CommonMallowBagSeed"] = { cropId = "Base.CommonMallow", poolKey = "Base.CommonMallow", count = 5, name = "Common Mallow Seed Packet" },
    ["Base.CornSeed"] = { cropId = "Base.Corn", poolKey = "Base.Corn", count = 1, name = "Corn Seeds" },
    ["Base.CornBagSeed"] = { cropId = "Base.Corn", poolKey = "Base.Corn", count = 5, name = "Corn Seed Packet" },
    ["Base.CucumberSeed"] = { cropId = "Base.Cucumber", poolKey = "Base.Cucumber", count = 1, name = "Cucumber Seeds" },
    ["Base.CucumberBagSeed"] = { cropId = "Base.Cucumber", poolKey = "Base.Cucumber", count = 5, name = "Cucumber Seed Packet" },
    ["Base.FlaxSeed"] = { cropId = "Base.Flax", poolKey = "Base.Flax", count = 1, name = "Flax Seeds" },
    ["Base.FlaxBagSeed"] = { cropId = "Base.Flax", poolKey = "Base.Flax", count = 5, name = "Flax Seed Packet" },
    ["Base.GarlicSeed"] = { cropId = "Base.Garlic", poolKey = "Base.Garlic", count = 1, name = "Garlic Seeds" },
    ["Base.GarlicBagSeed"] = { cropId = "Base.Garlic", poolKey = "Base.Garlic", count = 5, name = "Garlic Seed Packet" },
    ["Base.GreenpeasSeed"] = { cropId = "Base.Greenpeas", poolKey = "Base.Greenpeas", count = 1, name = "Green Peas Seeds" },
    ["Base.GreenpeasBagSeed"] = { cropId = "Base.Greenpeas", poolKey = "Base.Greenpeas", count = 5, name = "Green Peas Seed Packet" },
    ["Base.HabaneroSeed"] = { cropId = "Base.PepperHabanero", poolKey = "Base.PepperHabanero", count = 1, name = "Habanero Seeds" },
    ["Base.HabaneroBagSeed"] = { cropId = "Base.PepperHabanero", poolKey = "Base.PepperHabanero", count = 5, name = "Habanero Seed Packet" },
    ["Base.HempSeed"] = { cropId = "Base.HempBundle", poolKey = "Base.HempBundle", count = 1, name = "Hemp Seeds" },
    ["Base.HempBagSeed"] = { cropId = "Base.HempBundle", poolKey = "Base.HempBundle", count = 5, name = "Hemp Seed Packet" },
    ["Base.HopsSeed"] = { cropId = "Base.Hops", poolKey = "Base.Hops", count = 1, name = "Hops Seeds" },
    ["Base.HopsBagSeed"] = { cropId = "Base.Hops", poolKey = "Base.Hops", count = 5, name = "Hops Seed Packet" },
    ["Base.JalapenoSeed"] = { cropId = "Base.PepperJalapeno", poolKey = "Base.PepperJalapeno", count = 1, name = "Jalapeno Seeds" },
    ["Base.JalapenoBagSeed"] = { cropId = "Base.PepperJalapeno", poolKey = "Base.PepperJalapeno", count = 5, name = "Jalapeno Seed Packet" },
    ["Base.KaleSeed"] = { cropId = "Base.Kale", poolKey = "Base.Kale", count = 1, name = "Kale Seeds" },
    ["Base.KaleBagSeed"] = { cropId = "Base.Kale", poolKey = "Base.Kale", count = 5, name = "Kale Seed Packet" },
    ["Base.LavenderSeed"] = { cropId = "Base.Lavender", poolKey = "Base.Lavender", count = 1, name = "Lavender Seeds" },
    ["Base.LavenderBagSeed"] = { cropId = "Base.Lavender", poolKey = "Base.Lavender", count = 5, name = "Lavender Seed Packet" },
    ["Base.LeekSeed"] = { cropId = "Base.Leek", poolKey = "Base.Leek", count = 1, name = "Leek Seeds" },
    ["Base.LeekBagSeed"] = { cropId = "Base.Leek", poolKey = "Base.Leek", count = 5, name = "Leek Seed Packet" },
    ["Base.LemonGrassSeed"] = { cropId = "Base.LemonGrass", poolKey = "Base.LemonGrass", count = 1, name = "Lemongrass Seeds" },
    ["Base.LemonGrassBagSeed"] = { cropId = "Base.LemonGrass", poolKey = "Base.LemonGrass", count = 5, name = "Lemongrass Seed Packet" },
    ["Base.LettuceSeed"] = { cropId = "Base.Lettuce", poolKey = "Base.Lettuce", count = 1, name = "Lettuce Seeds" },
    ["Base.LettuceBagSeed"] = { cropId = "Base.Lettuce", poolKey = "Base.Lettuce", count = 5, name = "Lettuce Seed Packet" },
    ["Base.MarigoldSeed"] = { cropId = "Base.Marigold", poolKey = "Base.Marigold", count = 1, name = "Marigold Seeds" },
    ["Base.MarigoldBagSeed"] = { cropId = "Base.Marigold", poolKey = "Base.Marigold", count = 5, name = "Marigold Seed Packet" },
    ["Base.MintSeed"] = { cropId = "Base.MintHerb", poolKey = "Base.MintHerb", count = 1, name = "Mint Seeds" },
    ["Base.MintBagSeed"] = { cropId = "Base.MintHerb", poolKey = "Base.MintHerb", count = 5, name = "Mint Seed Packet" },
    ["Base.OnionSeed"] = { cropId = "Base.Onion", poolKey = "Base.Onion", count = 1, name = "Onion Seeds" },
    ["Base.OnionBagSeed"] = { cropId = "Base.Onion", poolKey = "Base.Onion", count = 5, name = "Onion Seed Packet" },
    ["Base.OreganoSeed"] = { cropId = "Base.Oregano", poolKey = "Base.Oregano", count = 1, name = "Oregano Seeds" },
    ["Base.OreganoBagSeed"] = { cropId = "Base.Oregano", poolKey = "Base.Oregano", count = 5, name = "Oregano Seed Packet" },
    ["Base.ParsleySeed"] = { cropId = "Base.Parsley", poolKey = "Base.Parsley", count = 1, name = "Parsley Seeds" },
    ["Base.ParsleyBagSeed"] = { cropId = "Base.Parsley", poolKey = "Base.Parsley", count = 5, name = "Parsley Seed Packet" },
    ["Base.BroadleafPlantainSeed"] = { cropId = "Base.Plantain", poolKey = "Base.Plantain", count = 1, name = "Plantain Seeds" },
    ["Base.BroadleafPlantainBagSeed"] = { cropId = "Base.Plantain", poolKey = "Base.Plantain", count = 5, name = "Plantain Seed Packet" },
    ["Base.PoppySeed"] = { cropId = "Base.Poppies", poolKey = "Base.Poppies", count = 1, name = "Poppies Seeds" },
    ["Base.PoppyBagSeed"] = { cropId = "Base.Poppies", poolKey = "Base.Poppies", count = 5, name = "Poppies Seed Packet" },
    ["Base.PotatoSeed"] = { cropId = "Base.Potato", poolKey = "Base.Potato", count = 1, name = "Potato Seeds" },
    ["Base.PotatoBagSeed2"] = { cropId = "Base.Potato", poolKey = "Base.Potato", count = 5, name = "Potato Seed Packet" },
    ["Base.PumpkinSeed"] = { cropId = "Base.Pumpkin", poolKey = "Base.Pumpkin", count = 1, name = "Pumpkin Seeds" },
    ["Base.PumpkinBagSeed"] = { cropId = "Base.Pumpkin", poolKey = "Base.Pumpkin", count = 5, name = "Pumpkin Seed Packet" },
    ["Base.RedRadishSeed"] = { cropId = "Base.RedRadish", poolKey = "Base.RedRadish", count = 1, name = "Radish Seeds" },
    ["Base.RedRadishBagSeed2"] = { cropId = "Base.RedRadish", poolKey = "Base.RedRadish", count = 5, name = "Radish Seed Packet" },
    ["Base.RosemarySeed"] = { cropId = "Base.Rosemary", poolKey = "Base.Rosemary", count = 1, name = "Rosemary Seeds" },
    ["Base.RosemaryBagSeed"] = { cropId = "Base.Rosemary", poolKey = "Base.Rosemary", count = 5, name = "Rosemary Seed Packet" },
    ["Base.RoseSeed"] = { cropId = "Base.Roses", poolKey = "Base.Roses", count = 1, name = "Roses Seeds" },
    ["Base.RoseBagSeed"] = { cropId = "Base.Roses", poolKey = "Base.Roses", count = 5, name = "Roses Seed Packet" },
    ["Base.RyeSeed"] = { cropId = "Base.RyeSheaf", poolKey = "Base.RyeSheaf", count = 1, name = "Rye Sheaf Seeds" },
    ["Base.RyeBagSeed"] = { cropId = "Base.RyeSheaf", poolKey = "Base.RyeSheaf", count = 5, name = "Rye Sheaf Seed Packet" },
    ["Base.SageSeed"] = { cropId = "Base.Sage", poolKey = "Base.Sage", count = 1, name = "Sage Seeds" },
    ["Base.SageBagSeed"] = { cropId = "Base.Sage", poolKey = "Base.Sage", count = 5, name = "Sage Seed Packet" },
    ["Base.SoybeansSeed"] = { cropId = "Base.Soybeans", poolKey = "Base.Soybeans", count = 1, name = "Soybeans Seeds" },
    ["Base.SoybeansBagSeed"] = { cropId = "Base.Soybeans", poolKey = "Base.Soybeans", count = 5, name = "Soybeans Seed Packet" },
    ["Base.SpinachSeed"] = { cropId = "Base.Spinach", poolKey = "Base.Spinach", count = 1, name = "Spinach Seeds" },
    ["Base.SpinachBagSeed"] = { cropId = "Base.Spinach", poolKey = "Base.Spinach", count = 5, name = "Spinach Seed Packet" },
    ["Base.StrewberrieSeed"] = { cropId = "Base.Strewberrie", poolKey = "Base.Strewberrie", count = 1, name = "Strawberries Seeds" },
    ["Base.StrewberrieBagSeed2"] = { cropId = "Base.Strewberrie", poolKey = "Base.Strewberrie", count = 5, name = "Strawberries Seed Packet" },
    ["Base.SugarBeetSeed"] = { cropId = "Base.SugarBeet", poolKey = "Base.SugarBeet", count = 1, name = "Sugar Beet Seeds" },
    ["Base.SugarBeetBagSeed"] = { cropId = "Base.SugarBeet", poolKey = "Base.SugarBeet", count = 5, name = "Sugar Beet Seed Packet" },
    ["Base.SunflowerSeeds"] = { cropId = "Base.SunflowerHead", poolKey = "Base.SunflowerHead", count = 1, name = "Sunflower Head Seeds" },
    ["Base.SunflowerBagSeed"] = { cropId = "Base.SunflowerHead", poolKey = "Base.SunflowerHead", count = 5, name = "Sunflower Head Seed Packet" },
    ["Base.SweetPotatoSeed"] = { cropId = "Base.SweetPotato", poolKey = "Base.SweetPotato", count = 1, name = "Sweet Potato Seeds" },
    ["Base.SweetPotatoBagSeed"] = { cropId = "Base.SweetPotato", poolKey = "Base.SweetPotato", count = 5, name = "Sweet Potato Seed Packet" },
    ["Base.ThymeSeed"] = { cropId = "Base.Thyme", poolKey = "Base.Thyme", count = 1, name = "Thyme Seeds" },
    ["Base.ThymeBagSeed"] = { cropId = "Base.Thyme", poolKey = "Base.Thyme", count = 5, name = "Thyme Seed Packet" },
    ["Base.TobaccoSeed"] = { cropId = "Base.Tobacco", poolKey = "Base.Tobacco", count = 1, name = "Tobacco Seeds" },
    ["Base.TobaccoBagSeed"] = { cropId = "Base.Tobacco", poolKey = "Base.Tobacco", count = 5, name = "Tobacco Seed Packet" },
    ["Base.TomatoSeed"] = { cropId = "Base.Tomato", poolKey = "Base.Tomato", count = 1, name = "Tomato Seeds" },
    ["Base.TomatoBagSeed2"] = { cropId = "Base.Tomato", poolKey = "Base.Tomato", count = 5, name = "Tomato Seed Packet" },
    ["Base.TurnipSeed"] = { cropId = "Base.Turnip", poolKey = "Base.Turnip", count = 1, name = "Turnip Seeds" },
    ["Base.TurnipBagSeed"] = { cropId = "Base.Turnip", poolKey = "Base.Turnip", count = 5, name = "Turnip Seed Packet" },
    ["Base.WatermelonSeed"] = { cropId = "Base.Watermelon", poolKey = "Base.Watermelon", count = 1, name = "Watermelon Seeds" },
    ["Base.WatermelonBagSeed"] = { cropId = "Base.Watermelon", poolKey = "Base.Watermelon", count = 5, name = "Watermelon Seed Packet" },
    ["Base.WheatSeed"] = { cropId = "Base.WheatSheaf", poolKey = "Base.WheatSheaf", count = 1, name = "Wheat Sheaf Seeds" },
    ["Base.WheatBagSeed"] = { cropId = "Base.WheatSheaf", poolKey = "Base.WheatSheaf", count = 5, name = "Wheat Sheaf Seed Packet" },
    ["Base.WildGarlicSeed"] = { cropId = "Base.WildGarlic2", poolKey = "Base.WildGarlic2", count = 1, name = "Wild Garlic Seeds" },
    ["Base.WildGarlicBagSeed"] = { cropId = "Base.WildGarlic2", poolKey = "Base.WildGarlic2", count = 5, name = "Wild Garlic Seed Packet" },
    ["Base.ZucchiniSeed"] = { cropId = "Base.Zucchini", poolKey = "Base.Zucchini", count = 1, name = "Zucchini Seeds" },
    ["Base.ZucchiniBagSeed"] = { cropId = "Base.Zucchini", poolKey = "Base.Zucchini", count = 5, name = "Zucchini Seed Packet" },
    -- 互換性エイリアス (旧種袋ID)
    ["Base.BroccoliBagSeed"] = { cropId = "Base.Broccoli", poolKey = "Base.Broccoli", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.CabbageBagSeed"] = { cropId = "Base.Cabbage", poolKey = "Base.Cabbage", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.CarrotBagSeed"] = { cropId = "Base.Carrots", poolKey = "Base.Carrots", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.PotatoBagSeed"] = { cropId = "Base.Potato", poolKey = "Base.Potato", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.RedRadishBagSeed"] = { cropId = "Base.RedRadish", poolKey = "Base.RedRadish", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.TomatoBagSeed"] = { cropId = "Base.Tomato", poolKey = "Base.Tomato", count = 5, name = "Seed Packet (Legacy)" },
    ["Base.StrewberrieBagSeed"] = { cropId = "Base.Strewberrie", poolKey = "Base.Strewberrie", count = 5, name = "Seed Packet (Legacy)" },
}

-- ---------------------------------------------------------------------------
-- 契約農園: 収穫量計算ヘルパー
-- ---------------------------------------------------------------------------
-- 作物IDとプレイヤーの耕作Lvから、1回分の収穫量（30%〜75%乱数）を計算
RadioTrader_CropYieldDefaults = {
    ["Base.BarleySheaf"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Barley" },
    ["Base.Basil"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Basil" },
    ["Base.BellPepper"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "BellPepper" },
    ["Base.BlackSage"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "BlackSage" },
    ["Base.Broccoli"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Broccoli" },
    ["Base.Cabbage"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Cabbages" },
    ["Base.Carrots"] = { minVeg = 3, maxVeg = 6, minVegAutorized = 10, maxVegAutorized = 15, seedType = "Carrots" },
    ["Base.Cauliflower"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Cauliflower" },
    ["Base.Chamomile"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Chamomile" },
    ["Base.Chives"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Chives" },
    ["Base.Cilantro"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Cilantro" },
    ["Base.Comfrey"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Comfrey" },
    ["Base.CommonMallow"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "CommonMallow" },
    ["Base.Corn"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Corn" },
    ["Base.Cucumber"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Cucumber" },
    ["Base.Flax"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Flax" },
    ["Base.Garlic"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Garlic" },
    ["Base.Greenpeas"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Greenpeas" },
    ["Base.PepperHabanero"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Habanero" },
    ["Base.HempBundle"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Hemp" },
    ["Base.Hops"] = { minVeg = 3, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 9, seedType = "Hops" },
    ["Base.PepperJalapeno"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Jalapeno" },
    ["Base.Kale"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Kale" },
    ["Base.Lavender"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Lavender" },
    ["Base.Leek"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Leek" },
    ["Base.LemonGrass"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "LemonGrass" },
    ["Base.Lettuce"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Lettuce" },
    ["Base.Marigold"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Marigold" },
    ["Base.MintHerb"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Mint" },
    ["Base.Onion"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Onion" },
    ["Base.Oregano"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Oregano" },
    ["Base.Parsley"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Parsley" },
    ["Base.Plantain"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "BroadleafPlantain" },
    ["Base.Poppies"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Poppies" },
    ["Base.Potato"] = { minVeg = 3, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 9, seedType = "Potatoes" },
    ["Base.Pumpkin"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Pumpkin" },
    ["Base.RedRadish"] = { minVeg = 4, maxVeg = 9, minVegAutorized = 11, maxVegAutorized = 15, seedType = "Radishes" },
    ["Base.Rosemary"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Rosemary" },
    ["Base.Roses"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Roses" },
    ["Base.RyeSheaf"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Rye" },
    ["Base.Sage"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Sage" },
    ["Base.Soybeans"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Soybeans" },
    ["Base.Spinach"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Spinach" },
    ["Base.Strewberrie"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 8, maxVegAutorized = 14, seedType = "Strawberryplant" },
    ["Base.SugarBeet"] = { minVeg = 4, maxVeg = 9, minVegAutorized = 11, maxVegAutorized = 15, seedType = "SugarBeets" },
    ["Base.SunflowerHead"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Sunflower" },
    ["Base.SweetPotato"] = { minVeg = 3, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 9, seedType = "SweetPotato" },
    ["Base.Thyme"] = { minVeg = 4, maxVeg = 6, minVegAutorized = 9, maxVegAutorized = 11, seedType = "Thyme" },
    ["Base.Tobacco"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Tobacco" },
    ["Base.Tomato"] = { minVeg = 4, maxVeg = 5, minVegAutorized = 6, maxVegAutorized = 10, seedType = "Tomato" },
    ["Base.Turnip"] = { minVeg = 3, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 9, seedType = "Turnip" },
    ["Base.Watermelon"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "Watermelon" },
    ["Base.WheatSheaf"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Wheat" },
    ["Base.WildGarlic2"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 5, maxVegAutorized = 8, seedType = "WildGarlic" },
    ["Base.Zucchini"] = { minVeg = 2, maxVeg = 4, minVegAutorized = 6, maxVegAutorized = 8, seedType = "Zucchini" },
}

function RadioTrader_CalculateCropYield(cropId, farmingLevel)
    farmingLevel = math.min(10, math.max(0, farmingLevel or 0))
    local def = RadioTrader_CropYieldDefaults[cropId] or { minVeg = 3, maxVeg = 6, minVegAutorized = 6, maxVegAutorized = 10 }

    local minVeg = def.minVeg
    local maxVeg = def.maxVeg
    local minVegAut = def.minVegAutorized
    local maxVegAut = def.maxVegAutorized

    -- バニラの farming_vegetableconf が存在する場合は実機定義を優先参照
    if farming_vegetableconf and farming_vegetableconf.props and def.seedType then
        local prop = farming_vegetableconf.props[def.seedType]
        if prop then
            minVeg = prop.minVeg or minVeg
            maxVeg = prop.maxVeg or maxVeg
            minVegAut = prop.minVegAutorized or minVegAut
            maxVegAut = prop.maxVegAutorized or maxVegAut
        end
    end

    local minVal = minVeg + (farmingLevel / 10) * (minVegAut - minVeg)
    local maxVal = maxVeg + (farmingLevel / 10) * (maxVegAut - maxVeg)
    if maxVal < minVal then maxVal = minVal end

    local fullYield = minVal
    if ZombRand then
        fullYield = ZombRand(math.floor(minVal), math.ceil(maxVal) + 1)
    else
        fullYield = math.random(math.floor(minVal), math.ceil(maxVal))
    end

    -- 30% 〜 75% の乱数を適用
    local ratio = 0.5
    if ZombRand then
        ratio = ZombRand(30, 76) / 100
    else
        ratio = math.random(30, 75) / 100
    end

    local finalYield = math.max(1, math.floor(fullYield * ratio + 0.5))
    return finalYield
end

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
    -- 新聞・雑誌・一般書籍（一次資料・文化記録）
    { id = "Base.Newspaper",           name = "Newspaper",            basePricePerUnit = 3,   category = "Archives" },
    { id = "Base.Magazine",            name = "Magazine",             basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.TVMagazine",          name = "TV Guide Magazine",    basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.MagazineCrossword",   name = "Crossword Magazine",   basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.MagazineWordsearch",  name = "Wordsearch Magazine",  basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.Catalog",             name = "Mail Order Catalog",   basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.ComicBook",           name = "Comic Book",           basePricePerUnit = 12,  category = "Archives" },
    { id = "Base.HottieZ",             name = "Adult Magazine",       basePricePerUnit = 15,  category = "Archives" },
    { id = "Base.Book",                name = "Book",                 basePricePerUnit = 10,  category = "Archives" },
    -- 公文書・重要書類・金融証書（控えめ査定）
    { id = "Base.OfficialDocument",    name = "Official Document",    basePricePerUnit = 25,  category = "Archives" },
    { id = "Base.StockCertificate",    name = "Stock Certificate",    basePricePerUnit = 20,  category = "Archives" },
    { id = "Base.Paperwork",           name = "Paperwork / File",     basePricePerUnit = 12,  category = "Archives" },
    { id = "Base.Receipt",             name = "Receipt",              basePricePerUnit = 4,   category = "Archives" },
    -- 記録メディア（VHSビデオテープ・音楽CD）※スキルビデオは動的査定で15 CR
    { id = "Base.VHS_Retail",          name = "VHS Tape (Retail)",    basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.VHS_Home",            name = "VHS Tape (Home)",      basePricePerUnit = 6,   category = "Archives" },
    { id = "Base.Disc_Retail",         name = "CD Disc (Music)",      basePricePerUnit = 4,   category = "Archives" },

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
    -- カテゴリ4: 魚の切り身・生肉 (Fish Fillet & Raw Meat)
    -- =========================================================================
    -- 0.5kg単位ブロック買取（0.5kgあたり20 CR）、端数合計1 CR
    { id = "Base.FishFillet",          name = "Fish Fillet",          basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Steak",               name = "Beef Steak",           basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.MeatPatty",           name = "Meat Patty",           basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Rabbitmeat",          name = "Rabbit Meat",          basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Smallanimalmeat",     name = "Small Animal Meat",    basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Smallbirdmeat",       name = "Small Bird Meat",      basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Chicken",             name = "Raw Chicken",          basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.PorkChop",            name = "Pork Chop",            basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.MuttonChop",          name = "Mutton Chop",          basePricePerUnit = 20,  category = "MeatFish" },
    { id = "Base.Venison",             name = "Venison",              basePricePerUnit = 20,  category = "MeatFish" },

    -- =========================================================================
    -- カテゴリ5: 朝採れ卵 (Farm Fresh Eggs)
    -- =========================================================================
    -- 1個3 CR、6個パックごとに +10 CRボーナス
    { id = "Base.Egg",                 name = "Fresh Egg",            basePricePerUnit = 3,   category = "Egg" },
    { id = "Base.WildEggs",            name = "Wild Bird Eggs",       basePricePerUnit = 3,   category = "Egg" },

    -- =========================================================================
    -- カテゴリ6: 隔離地域産のオーガニック農作物 (Organic Produce)
    -- =========================================================================
    -- 1個2 CR、10個ロットごとに +15 CRボーナス（10個で35 CR）
    { id = "Base.Cabbage",             name = "Fresh Cabbage",        basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Tomato",              name = "Fresh Tomato",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Potato",              name = "Fresh Potato",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Corn",                name = "Fresh Corn",           basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Carrots",             name = "Fresh Carrots",        basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Broccoli",            name = "Fresh Broccoli",       basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.RedRadish",           name = "Fresh Radish",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Apple",               name = "Fresh Apple",          basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Peach",               name = "Fresh Peach",          basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Watermelon",          name = "Fresh Watermelon",     basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Strewberrie",          name = "Fresh Strawberry",     basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Onion",               name = "Fresh Onion",          basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Lettuce",             name = "Fresh Lettuce",        basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.BellPepper",          name = "Fresh Bell Pepper",    basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Eggplant",            name = "Fresh Eggplant",       basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Leek",                name = "Fresh Leek",           basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Zucchini",            name = "Fresh Zucchini",       basePricePerUnit = 2,   category = "Produce" },
    -- 追加: B42野菜・根菜
    { id = "Base.SweetPotato",         name = "Sweet Potato",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Pumpkin",             name = "Fresh Pumpkin",        basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Avocado",             name = "Fresh Avocado",        basePricePerUnit = 2,   category = "Produce" },
    -- 追加: フルーツ
    { id = "Base.Banana",              name = "Fresh Banana",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Orange",              name = "Fresh Orange",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Lemon",               name = "Fresh Lemon",          basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Lime",                name = "Fresh Lime",           basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Grapes",              name = "Fresh Grapes",         basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Pineapple",           name = "Fresh Pineapple",      basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Cherry",              name = "Fresh Cherry",         basePricePerUnit = 2,   category = "Produce" },
    -- 追加: 機能性ハーブ・薬草（野草）
    { id = "Base.WildGarlic",          name = "Wild Garlic",          basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.WildOnion",           name = "Wild Onion",           basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Lemongrass",          name = "Lemongrass",           basePricePerUnit = 3,   category = "Produce" },
    { id = "Base.Ginseng",             name = "Ginseng",              basePricePerUnit = 3,   category = "Produce" },
    { id = "Base.BlackSage",           name = "Black Sage",           basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.CommonMallow",        name = "Common Mallow",        basePricePerUnit = 2,   category = "Produce" },
    { id = "Base.Plantain",            name = "Plantain",             basePricePerUnit = 2,   category = "Produce" },

    -- =========================================================================
    -- カテゴリ7: 旧世界の通貨・カード類 (Currency & Financial)
    -- =========================================================================
    -- 現金は 1 CR、札束は 50 CR、クレジットカードは 1〜5 CR 程度で買取
    { id = "Base.Money",               name = "Cash (Bill/Coin)",     basePricePerUnit = 1,   category = "Currency" },
    { id = "Base.MoneyBundle",         name = "Money Bundle",         basePricePerUnit = 50,  category = "Currency" },
    { id = "Base.CreditCard",          name = "Credit Card",          basePricePerUnit = 2,   category = "Currency", isRandom = true },
    { id = "Base.CreditCard_Stolen",   name = "Stolen Credit Card",   basePricePerUnit = 2,   category = "Currency", isRandom = true },

    -- =========================================================================
    -- カテゴリ8: 電線・電子機器の解体廃材・回路部品 (Electronics & Scrap)
    -- =========================================================================
    -- 通信設備修理や工業用リサイクル資源としての需要
    { id = "Base.ElectricWire",        name = "Electric Wire",        basePricePerUnit = 4,   category = "Electronics" },
    { id = "Base.ElectronicsScrap",    name = "Electronics Scrap",    basePricePerUnit = 5,   category = "Electronics" },
    { id = "Base.ScrapMetal",          name = "Scrap Metal",          basePricePerUnit = 2,   category = "Electronics" },
    { id = "Base.Amplifier",           name = "Signal Amplifier",     basePricePerUnit = 20,  category = "Electronics" },
    { id = "Base.RadioReceiver",       name = "Radio Receiver Unit",  basePricePerUnit = 20,  category = "Electronics" },
    { id = "Base.RadioTransmitter",    name = "Radio Transmitter Unit", basePricePerUnit = 25, category = "Electronics" },
    { id = "Base.Receiver",            name = "Receiver Board",       basePricePerUnit = 15,  category = "Electronics" },
    { id = "Base.MotionSensor",        name = "Motion Sensor",        basePricePerUnit = 25,  category = "Electronics" },
    { id = "Base.CDPlayer",            name = "CD Player",            basePricePerUnit = 12,  category = "Electronics" },

    -- =========================================================================
    -- カテゴリ8-B: 繊維・布・裁縫資材 (Textiles & Cordage)
    -- =========================================================================
    -- 野戦病院の包帯原料、軍用テント・防護服の縫製資材としての需要（※糸・より糸は残量連動）
    { id = "Base.Thread",              name = "Thread",               basePricePerUnit = 4,   category = "Industrial" },
    { id = "Base.Twine",               name = "Twine",                basePricePerUnit = 3,   category = "Industrial" },
    { id = "Base.Sheet",               name = "Sheet",                basePricePerUnit = 5,   category = "Industrial" },
    { id = "Base.Rope",                name = "Rope",                 basePricePerUnit = 8,   category = "Industrial" },
    { id = "Base.Tarp",                name = "Tarp",                 basePricePerUnit = 15,  category = "Industrial" },

    -- =========================================================================
    -- カテゴリ9: 銃器・弾薬箱・マガジン・パーツ (Firearms & Tactical Equipment)
    -- =========================================================================
    -- 武器コンテナ（1000 CR）転売による無限ループを完全防止する安全設計
    -- ※バラ弾は買取対象外
    -- ハンドガン・リボルバー (25 CR)
    { id = "Base.Pistol",                     name = "Pistol (9mm)",         basePricePerUnit = 25,  category = "Firearm" },
    { id = "Base.Pistol2",                    name = "Pistol (.45)",         basePricePerUnit = 25,  category = "Firearm" },
    { id = "Base.Pistol3",                    name = "Magnum Pistol (.44)",  basePricePerUnit = 25,  category = "Firearm" },
    { id = "Base.Revolver",                   name = "Revolver (.38)",       basePricePerUnit = 25,  category = "Firearm" },
    { id = "Base.Revolver_Long",              name = "Magnum Revolver (.44)",basePricePerUnit = 25,  category = "Firearm" },
    { id = "Base.Revolver_Short",             name = "Snubnose Revolver",    basePricePerUnit = 25,  category = "Firearm" },
    -- ショットガン・ライフル (45 CR)
    { id = "Base.Shotgun",                    name = "Shotgun",              basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.ShotgunSawnoff",             name = "Sawnoff Shotgun",      basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.DoubleBarrelShotgun",        name = "Double Barrel Shotgun",basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.DoubleBarrelShotgunSawnoff", name = "Sawnoff Double Barrel",basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.AssaultRifle",               name = "M16 Assault Rifle",    basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.AssaultRifle2",              name = "M14 Rifle",            basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.HuntingRifle",               name = "Hunting Rifle",        basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.L94_Rifle",                  name = "L94 Lever-Action Rifle",basePricePerUnit = 45,  category = "Firearm" },
    { id = "Base.L92_Carbine",                name = "L92 Lever-Action Carbine",basePricePerUnit = 45,category = "Firearm" },
    { id = "Base.VarmintRifle",               name = "Varmint Rifle",        basePricePerUnit = 45,  category = "Firearm" },
    -- 未開封・弾薬箱 (18 CR)
    { id = "Base.Bullets9mmBox",              name = "9mm Ammo Box",         basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.Bullets45Box",               name = ".45 Auto Ammo Box",    basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.Bullets44Box",               name = ".44 Magnum Ammo Box",  basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.Bullets38Box",               name = ".38 Special Ammo Box", basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.Bullets357Box",              name = ".357 Magnum Ammo Box", basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.3030Box",                    name = ".30-30 Ammo Box",      basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.ShotgunShellsBox",           name = "Shotgun Shells Box",   basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.308Box",                     name = ".308 Ammo Box",        basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.556Box",                     name = "5.56mm Ammo Box",      basePricePerUnit = 18,  category = "AmmoBox" },
    { id = "Base.223Box",                     name = ".223 Ammo Box",        basePricePerUnit = 18,  category = "AmmoBox" },
    -- 弾倉・マガジン (8 CR)
    { id = "Base.9mmClip",                    name = "9mm Magazine",         basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.45Clip",                     name = ".45 Magazine",         basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.44Clip",                     name = ".44 Magazine",         basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.223Clip",                    name = ".223 Magazine",        basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.308Clip",                    name = ".308 Magazine",        basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.M14Clip",                    name = "M14 Magazine",         basePricePerUnit = 8,   category = "Magazine" },
    { id = "Base.556Clip",                    name = "5.56mm Magazine",      basePricePerUnit = 8,   category = "Magazine" },
    -- 銃器アタッチメント・パーツ (12 CR)
    { id = "Base.ChokeTubeFull",              name = "Choke Tube (Full)",    basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.ChokeTubeImproved",          name = "Choke Tube (Improved)",basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.FiberglassStock",            name = "Fiberglass Stock",     basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.RecoilPad",                  name = "Recoil Pad",           basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.RedDot",                     name = "Red Dot Sight",        basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.x2Scope",                    name = "x2 Scope",             basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.x4Scope",                    name = "x4 Scope",             basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.x8Scope",                    name = "x8 Scope",             basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.Laser",                      name = "Laser Sight",          basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.Sling",                      name = "Gun Sling",            basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.AmmoStrap",                  name = "Ammo Strap",           basePricePerUnit = 12,  category = "GunPart" },
    { id = "Base.GunLight",                   name = "Weapon Flashlight",    basePricePerUnit = 12,  category = "GunPart" },
}

-- ---------------------------------------------------------------------------
-- ユーティリティ: 持ち運べる家具・設備 (Moveable) の動的ランク・重量判定
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessFurniture(item, fallbackId)
    local id = fallbackId or (item and item.getFullType and item:getFullType()) or ""
    local name = (item and item.getName and item:getName()) or "Furniture"
    local sprite = ""
    if item and item.getSpriteName then
        sprite = item:getSpriteName() or ""
    end
    if sprite == "" and item and item.getWorldSprite then
        sprite = item:getWorldSprite() or ""
    end

    local weight = 5.0
    if item and item.getActualWeight then
        weight = item:getActualWeight() or 5.0
    end

    -- 照合用文字列（ID、スプライト名、表示名をすべて小文字化して包括検索）
    local searchStr = string.lower(id .. " " .. sprite .. " " .. name)

    local tier = "C"
    local displayName = name
    local basePrice = 15

    -- =========================================================================
    -- 手作り家具・クラフト建築品 (Handcrafted / Carpentry & Metalworking)
    -- スキルレベル（スプライト番号・耐久値）に応じて DIY-1 / DIY-2 / Mastercraft を判定
    -- =========================================================================
    local isCarpentry = string.find(searchStr, "carpentry_")
    local isMetalwork = string.find(searchStr, "metalworking_")

    if isCarpentry or isMetalwork then
        -- スキル段階 (1: 初心者 Lv0-3, 2: 中級 Lv4-6, 3: 熟練 Lv7-10)
        local skillTier = 1
        local cType = "Crate"

        -- スプライトのインデックス番号を抽出 (例: carpentry_01_16 -> sheet=1, idx=16)
        local sheetStr, idxStr = string.match(sprite, "carpentry_(%d+)_(%d+)")
        local idx = tonumber(idxStr)
        local sheet = tonumber(sheetStr)

        if isCarpentry and idx then
            -- 木箱 (Sheet 1: 16=Lv1, 17=Lv2, 18=Lv3)
            if idx >= 16 and idx <= 18 then
                cType = "Wooden Crate"
                skillTier = (idx - 16) + 1
            -- テーブル (Sheet 1: 24,25=Lv1, 26,27=Lv2, 28,29=Lv3)
            elseif idx >= 24 and idx <= 29 then
                cType = "Wooden Table"
                skillTier = math.floor((idx - 24) / 2) + 1
            -- 椅子 (Sheet 1: 32=Lv1, 33=Lv2, 34=Lv3)
            elseif idx >= 32 and idx <= 34 then
                cType = "Wooden Chair"
                skillTier = (idx - 32) + 1
            -- 棚・本棚 (Sheet 1: 40=Lv1, 41=Lv2, 42=Lv3)
            elseif idx >= 40 and idx <= 42 then
                cType = "Wooden Shelves"
                skillTier = (idx - 40) + 1
            -- ベッド (Sheet 2: 12=Lv1, 13=Lv2, 14=Lv3)
            elseif sheet == 2 and idx >= 12 and idx <= 14 then
                cType = "Wooden Bed"
                skillTier = (idx - 12) + 1
            -- 雨水樽 (Sheet 2: 52=小型 Lv4, 54=大型 Lv7)
            elseif sheet == 2 and (idx == 52 or idx == 54 or idx == 53 or idx == 55) then
                cType = "Rain Collector Barrel"
                skillTier = (idx >= 54) and 3 or 2
            else
                -- その他大工品: スプライトの並びまたは耐久度から推測
                skillTier = (idx % 3) + 1
                cType = (name and name ~= "" and name ~= "Furniture") and name or "Handcrafted Furniture"
            end
        elseif isMetalwork then
            -- 金属加工品は金属板や溶接棒が必要なため基本的にTier 2以上
            cType = "Metal Container/Shelves"
            skillTier = 2
            if item and item.getConditionMax and item:getConditionMax() >= 10 then
                skillTier = 3
            end
        end

        -- 耐久値（ConditionMax）による最終補正: 高スキル建築でHPが跳ね上がっている場合の安全網
        if item and item.getConditionMax then
            local maxC = item:getConditionMax()
            if maxC and maxC >= 10 and skillTier < 3 then
                skillTier = 3
            elseif maxC and maxC >= 6 and skillTier < 2 then
                skillTier = 2
            end
        end

        -- スキル段階別の価格・名称決定
        local tierLabel = "DIY-1"
        local prefix = "Crude "
        local base = 3

        if skillTier == 1 then
            tierLabel = "DIY-1"
            prefix = "Crude Handcrafted "
            if cType == "Wooden Crate" then base = 3
            elseif cType == "Wooden Chair" then base = 2
            elseif cType == "Wooden Table" then base = 4
            elseif cType == "Wooden Shelves" then base = 3
            elseif cType == "Wooden Bed" then base = 6
            else base = 3 end

        elseif skillTier == 2 then
            tierLabel = "DIY-2"
            prefix = "Standard Handcrafted "
            if cType == "Wooden Crate" then base = 6
            elseif cType == "Wooden Chair" then base = 5
            elseif cType == "Wooden Table" then base = 8
            elseif cType == "Wooden Shelves" then base = 7
            elseif cType == "Wooden Bed" then base = 12
            elseif cType == "Rain Collector Barrel" then base = 10
            elseif isMetalwork then base = 15
            else base = 6 end

        else -- skillTier == 3 (熟練・名工)
            tierLabel = "Mastercraft"
            prefix = "Fine Handcrafted "
            if cType == "Wooden Crate" then base = 12
            elseif cType == "Wooden Chair" then base = 10
            elseif cType == "Wooden Table" then base = 16
            elseif cType == "Wooden Shelves" then base = 14
            elseif cType == "Wooden Bed" then base = 22
            elseif cType == "Rain Collector Barrel" then base = 20
            elseif isMetalwork then base = 25
            else base = 14 end
        end

        displayName = prefix .. cType
        tier = tierLabel
        basePrice = base

    -- Sランク: 超希少・設備・伝説のアンティーク (120〜150 CR)
    elseif string.find(searchStr, "antiquestove") or string.find(searchStr, "woodstove") then
        tier = "S"
        displayName = "Antique Wood Stove"
        basePrice = 150
    elseif string.find(searchStr, "gunsafe") or (string.find(searchStr, "safe") and not string.find(searchStr, "safety")) then
        tier = "S"
        displayName = "Heavy Security Safe"
        basePrice = 130
    elseif string.find(searchStr, "arcade") or string.find(searchStr, "jukebox") or string.find(searchStr, "piano") then
        tier = "S"
        displayName = "Vintage Entertainment (Arcade/Piano/Jukebox)"
        basePrice = 120

    -- Aランク: 高機能大型家電・医療・工業設備 (50〜75 CR)
    elseif string.find(searchStr, "refrigeration") or string.find(searchStr, "fridge") or string.find(searchStr, "freezer") or string.find(searchStr, "icebox") then
        tier = "A"
        displayName = "Major Appliance (Refrigerator/Freezer)"
        basePrice = 65
    elseif string.find(searchStr, "appliances_cooking") or string.find(searchStr, "oven") or string.find(searchStr, "stove") then
        tier = "A"
        displayName = "Major Appliance (Cooking Range/Oven)"
        basePrice = 55
    elseif string.find(searchStr, "appliances_laundry") or string.find(searchStr, "washingmachine") or string.find(searchStr, "dryer") then
        tier = "A"
        displayName = "Major Appliance (Washer/Dryer)"
        basePrice = 50
    elseif string.find(searchStr, "medical") or string.find(searchStr, "hospital") or string.find(searchStr, "dentist") or string.find(searchStr, "operating") then
        tier = "A"
        displayName = "Specialized Medical Equipment"
        basePrice = 75
    elseif string.find(searchStr, "lightconstruction") or string.find(searchStr, "floodlight") or string.find(searchStr, "generator") then
        tier = "A"
        displayName = "Heavy Industrial Floodlight/Work Station"
        basePrice = 50

    -- Bランク: 高級内装・上質快適家具・大型AV機器 (30〜45 CR)
    elseif string.find(searchStr, "bedding") and (weight >= 12 or string.find(searchStr, "double") or string.find(searchStr, "king")) then
        tier = "B"
        displayName = "Luxury Bedding (Double/King)"
        basePrice = 40
    elseif string.find(searchStr, "seating_indoor") and (weight >= 10 or string.find(searchStr, "leather") or string.find(searchStr, "couch") or string.find(searchStr, "sofa") or string.find(searchStr, "executive")) then
        tier = "B"
        displayName = "Executive Leather Sofa/Armchair"
        basePrice = 38
    elseif string.find(searchStr, "television") or string.find(searchStr, "stereo") or string.find(searchStr, "hifi") or string.find(searchStr, "tv") then
        tier = "B"
        displayName = "High-End Audio/Visual Entertainment"
        basePrice = 35
    elseif string.find(searchStr, "pooltable") or string.find(searchStr, "billiard") or string.find(searchStr, "recreation") then
        tier = "B"
        displayName = "Recreational Table/Games"
        basePrice = 45
    elseif string.find(searchStr, "storage") and (weight >= 15 or string.find(searchStr, "dresser") or string.find(searchStr, "armoire") or string.find(searchStr, "wardrobe")) then
        tier = "B"
        displayName = "Antique/Hardwood Storage Furniture"
        basePrice = 32

    -- Dランク: 簡易・粗大ゴミ・プラスチック・資材 (4〜8 CR)
    elseif string.find(searchStr, "plastic") then
        tier = "D"
        displayName = "Cheap Plastic Furniture"
        basePrice = 6
    elseif string.find(searchStr, "cardboard") or string.find(searchStr, "trash") or string.find(searchStr, "garbage") or string.find(searchStr, "waste") then
        tier = "D"
        displayName = "Discarded Container/Trash Can"
        basePrice = 4
    elseif string.find(searchStr, "cone") or string.find(searchStr, "traffic") then
        tier = "D"
        displayName = "Traffic/Road Utility Cone"
        basePrice = 4

    -- Cランク: 一般的な実用家具 (15〜25 CR)
    elseif string.find(searchStr, "roadbarrier") or string.find(searchStr, "militarycrate") then
        tier = "C"
        displayName = "Reinforced Barrier/Military Crate"
        basePrice = 25
    elseif string.find(searchStr, "tables") or string.find(searchStr, "table") or string.find(searchStr, "desk") then
        tier = "C"
        displayName = "Standard Wooden Table/Desk"
        basePrice = 20
    elseif string.find(searchStr, "shelving") or string.find(searchStr, "bookcase") or string.find(searchStr, "shelves") then
        tier = "C"
        displayName = "Standard Shelving/Bookcase"
        basePrice = 18
    elseif string.find(searchStr, "seating") or string.find(searchStr, "chair") or string.find(searchStr, "stool") then
        tier = "C"
        displayName = "Standard Chair/Stool"
        basePrice = 14
    elseif string.find(searchStr, "sink") or string.find(searchStr, "bath") or string.find(searchStr, "toilet") then
        tier = "C"
        displayName = "Plumbing Fixture (Sink/Tub/Toilet)"
        basePrice = 22
    else
        -- デフォルト一般家具
        tier = "C"
        displayName = (name and name ~= "" and name ~= "Furniture") and name or "Salvaged Furniture"
        basePrice = 12
    end

    -- 重量ボーナス（重い家具ほど運搬リスクへの正当な報酬: +0.8 CR / kg）
    local weightBonus = math.floor(math.max(0, weight) * 0.8)
    local totalBasePrice = basePrice + weightBonus

    return {
        id               = id,
        name             = displayName,
        basePricePerUnit = totalBasePrice,
        category         = "Furniture",
        tier             = tier,
        weightBonus      = weightBonus,
        rawBasePrice     = basePrice,
        actualWeight     = weight,
    }
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: アイテムIDから売却定義を検索 (スマートマッチング機能付き)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_GetSellEntry(itemId)
    if not itemId then return nil end

    -- 0. 契約農園の種・種袋マッピングを最優先チェック (Base.有無・大文字小文字に対応)
    if RadioTrader_SeedMapping then
        local match = RadioTrader_SeedMapping[itemId]
        if not match and not string.find(itemId, "%.") then
            match = RadioTrader_SeedMapping["Base." .. itemId]
        end
        if not match and string.find(itemId, "^Base%.") then
            local stripped = string.gsub(itemId, "^Base%.", "")
            match = RadioTrader_SeedMapping[stripped]
        end
        if match then
            return {
                id               = itemId,
                name             = match.name or "Seeds",
                basePricePerUnit = 0,
                category         = "Seed",
                poolKey          = match.poolKey,
                poolCount        = match.count or 1,
            }
        end
    end

    -- 1. 完全一致
    for _, entry in ipairs(RadioTrader_Sell) do
        if entry.id == itemId then return entry end
    end

    -- 2. 種・種袋のスマートフォールバック（命名規則から作物を自動特定）
    if string.find(itemId, "BagSeed") or string.find(itemId, "Seed") then
        local cleanId = string.gsub(itemId, "^Base%.", "")
        local isPacket = string.find(cleanId, "Bag") or string.find(cleanId, "Pack")
        if RadioTrader_Shop and RadioTrader_Shop.Crops then
            for _, crop in ipairs(RadioTrader_Shop.Crops) do
                local cropPure = string.gsub(crop.id, "^Base%.", "")
                local seedPure = crop.seedType or cropPure
                if string.find(cleanId, cropPure) or string.find(cleanId, seedPure) then
                    return {
                        id               = itemId,
                        name             = crop.name .. (isPacket and " Seed Packet" or " Seeds"),
                        basePricePerUnit = 0,
                        category         = "Seed",
                        poolKey          = crop.id,
                        poolCount        = isPacket and 5 or 1,
                    }
                end
            end
        end
    end

    -- 2. スマートパターンマッチング (バリエーション・Mod対応フォールバック)
    -- 貴金属・ジュエリー共通素材ヘルパー
    local isGem = string.find(itemId, "Diamond") or string.find(itemId, "Ruby") or string.find(itemId, "Sapphire")
               or string.find(itemId, "Emerald") or string.find(itemId, "Amethyst") or string.find(itemId, "Amber")
               or string.find(itemId, "Pearl")
    local isGold = string.find(itemId, "Gold") or string.find(itemId, "Signet")
    local isSilver = string.find(itemId, "Silver")

    -- 指輪類 (Rings)
    if string.find(itemId, "Ring_") or string.find(itemId, "Finger_") then
        if isGem and isGold then
            return { id = itemId, name = "Gold Gemstone Ring", basePricePerUnit = 110, category = "Jewelry" }
        elseif isGem then
            return { id = itemId, name = "Gemstone Ring", basePricePerUnit = 70, category = "Jewelry" }
        elseif isGold then
            return { id = itemId, name = "Gold Ring", basePricePerUnit = 55, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Ring", basePricePerUnit = 27, category = "Jewelry" }
        else
            return { id = itemId, name = "Ring", basePricePerUnit = 15, category = "Jewelry" }
        end
    end

    -- ネックレス・ペンダント類 (Necklace & Locket & DogTag)
    if string.find(itemId, "Necklace") or string.find(itemId, "Locket") or string.find(itemId, "DogTag") then
        if isGem and isGold then
            return { id = itemId, name = "Gold Gemstone Necklace", basePricePerUnit = 120, category = "Jewelry" }
        elseif isGem then
            return { id = itemId, name = "Precious Necklace", basePricePerUnit = 80, category = "Jewelry" }
        elseif isGold then
            return { id = itemId, name = "Gold Necklace", basePricePerUnit = 60, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Necklace", basePricePerUnit = 30, category = "Jewelry" }
        elseif string.find(itemId, "Locket") then
            return { id = itemId, name = "Vintage Locket", basePricePerUnit = 35, category = "Jewelry" }
        elseif string.find(itemId, "DogTag") then
            return { id = itemId, name = "Military Dog Tag", basePricePerUnit = 25, category = "Jewelry" }
        else
            return { id = itemId, name = "Symbol Necklace", basePricePerUnit = 20, category = "Jewelry" }
        end
    end

    -- ブレスレット・バングル類 (Bracelet & Bangle)
    if string.find(itemId, "Bracelet") or string.find(itemId, "Bangle") then
        if isGem then
            return { id = itemId, name = "Gemstone Bracelet", basePricePerUnit = 65, category = "Jewelry" }
        elseif isGold then
            return { id = itemId, name = "Gold Bracelet", basePricePerUnit = 50, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Bangle", basePricePerUnit = 25, category = "Jewelry" }
        else
            return { id = itemId, name = "Bracelet", basePricePerUnit = 15, category = "Jewelry" }
        end
    end

    -- イヤリング・ピアス類 (Earrings & Dangle)
    if string.find(itemId, "Earring") then
        if isGem then
            return { id = itemId, name = "Gemstone Earrings", basePricePerUnit = 55, category = "Jewelry" }
        elseif isGold then
            return { id = itemId, name = "Gold Earrings", basePricePerUnit = 40, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Earrings", basePricePerUnit = 22, category = "Jewelry" }
        else
            return { id = itemId, name = "Earrings", basePricePerUnit = 15, category = "Jewelry" }
        end
    end

    -- へそピアス・ボディジュエリー (Belly Button & Body Jewelry)
    if string.find(itemId, "BellyButton") or string.find(itemId, "Belly") then
        if isGem then
            return { id = itemId, name = "Gemstone Belly Piercing", basePricePerUnit = 45, category = "Jewelry" }
        elseif isGold then
            return { id = itemId, name = "Gold Belly Ring", basePricePerUnit = 35, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Belly Ring", basePricePerUnit = 20, category = "Jewelry" }
        else
            return { id = itemId, name = "Belly Piercing", basePricePerUnit = 12, category = "Jewelry" }
        end
    end

    -- 鼻ピアス (Nose Stud & Nose Ring)
    if string.find(itemId, "NoseRing") or string.find(itemId, "NoseStud") then
        if isGold then
            return { id = itemId, name = "Gold Nose Piercing", basePricePerUnit = 30, category = "Jewelry" }
        elseif isSilver then
            return { id = itemId, name = "Silver Nose Piercing", basePricePerUnit = 18, category = "Jewelry" }
        else
            return { id = itemId, name = "Nose Piercing", basePricePerUnit = 10, category = "Jewelry" }
        end
    end

    -- 時計類 (Watches)
    if string.find(itemId, "WristWatch_") or string.find(itemId, "Pocketwatch") then
        if string.find(itemId, "Gold") or string.find(itemId, "Expensive") or string.find(itemId, "Pocketwatch") then
            return { id = itemId, name = "Luxury Watch", basePricePerUnit = 75, category = "Antiques" }
        else
            return { id = itemId, name = "Classic Watch", basePricePerUnit = 25, category = "Antiques" }
        end
    end

    -- 一次資料・手紙・メモ・チラシ・写真・記念カード類 (Archives & Memorabilia)
    if string.find(itemId, "Letter") or string.find(itemId, "Mail") then
        return { id = itemId, name = "Survivor Letter", basePricePerUnit = 22, category = "Archives" }
    elseif string.find(itemId, "Brochure") or string.find(itemId, "Flyer") or string.find(itemId, "Flier") then
        return { id = itemId, name = "Historic Flyer", basePricePerUnit = 12, category = "Archives" }
    elseif string.find(itemId, "Photograph") or string.find(itemId, "Photo") then
        return { id = itemId, name = "Old Photograph", basePricePerUnit = 18, category = "Archives" }
    elseif string.find(itemId, "Card") and not string.find(itemId, "CreditCard") then
        return { id = itemId, name = "Vintage Greeting Card", basePricePerUnit = 14, category = "Archives" }
    elseif string.find(itemId, "Doodle") or string.find(itemId, "Drawing") then
        return { id = itemId, name = "Hand-drawn Sketch", basePricePerUnit = 15, category = "Archives" }
    elseif string.find(itemId, "OfficialDocument") or (string.find(itemId, "Document") and not string.find(itemId, "Paperwork")) then
        return { id = itemId, name = "Official Document", basePricePerUnit = 25, category = "Archives" }
    elseif string.find(itemId, "StockCertificate") or string.find(itemId, "Certificate") or string.find(itemId, "Deed") then
        return { id = itemId, name = "Certificate / Deed", basePricePerUnit = 20, category = "Archives" }
    elseif string.find(itemId, "Paperwork") or string.find(itemId, "File") and not string.find(itemId, "SmallFileSet") then
        return { id = itemId, name = "Paperwork / File", basePricePerUnit = 12, category = "Archives" }
    elseif string.find(itemId, "Receipt") or string.find(itemId, "Invoice") then
        return { id = itemId, name = "Receipt / Invoice", basePricePerUnit = 4, category = "Archives" }
    elseif string.find(itemId, "Note") or string.find(itemId, "Postcard") or string.find(itemId, "SheetPaper") then
        return { id = itemId, name = "Handwritten Note", basePricePerUnit = 12, category = "Archives" }
    elseif string.find(itemId, "Magazine") or string.find(itemId, "Catalog") or string.find(itemId, "RPG") then
        return { id = itemId, name = "Magazine / Hobby Publication", basePricePerUnit = 6, category = "Archives" }
    elseif string.find(itemId, "ComicBook") or string.find(itemId, "HottieZ") then
        return { id = itemId, name = "Comic / Special Issue", basePricePerUnit = 12, category = "Archives" }
    elseif (
        -- 文庫本・小説・ペーパーバック（Base.Book, Base.Book_Fiction, Base.Paperback_* 等）
        (
            string.find(itemId, "Paperback") or
            string.find(itemId, "Novel") or
            string.find(itemId, "^Base%.Book") or
            string.find(itemId, "^Book") or
            string.find(itemId, "Literature")
        )
        and not string.find(itemId, "Recipe")
        and not string.find(itemId, "Skill")
        and not string.find(itemId, "Manual")
        and not string.find(itemId, "Guide")
        and not string.find(itemId, "Carpentry")
        and not string.find(itemId, "Cooking")
        and not string.find(itemId, "Farming")
        and not string.find(itemId, "FirstAid")
        and not string.find(itemId, "Electricity")
        and not string.find(itemId, "MetalWelding")
        and not string.find(itemId, "Mechanic")
        and not string.find(itemId, "Tailoring")
        and not string.find(itemId, "Fishing")
        and not string.find(itemId, "Trapping")
        and not string.find(itemId, "Foraging")
        and not string.find(itemId, "Blacksmith")
        and not string.find(itemId, "%d") -- スキル本特有の巻数数字(1〜5)を除外
    ) then
        return { id = itemId, name = "Literature Book", basePricePerUnit = 10, category = "Archives" }
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

    -- 魚の切り身・各種生肉
    if string.find(itemId, "FishFillet") then
        return { id = itemId, name = "Fish Fillet", basePricePerUnit = 20, category = "MeatFish" }
    elseif string.find(itemId, "Steak") or string.find(itemId, "Meat") or string.find(itemId, "Chop")
        or string.find(itemId, "Chicken") or string.find(itemId, "Venison") then
        return { id = itemId, name = "Raw Meat", basePricePerUnit = 20, category = "MeatFish" }
    end

    -- 卵
    if string.find(itemId, "Egg") then
        return { id = itemId, name = "Fresh Egg", basePricePerUnit = 3, category = "Egg" }
    end

    -- 未開封の缶詰・保存食（Canned & Tinned Food）
    -- ※開封済み（Open）や空き缶（Empty）は査定除外
    local isCanned = (string.find(itemId, "Canned") or string.find(itemId, "Tinned") or string.find(itemId, "TunaTin")
        or string.find(itemId, "Dogfood") or string.find(itemId, "MysteryCan") or string.find(itemId, "DentedCan")
        or string.find(itemId, "WaterRationCan"))
        and not string.find(itemId, "Open") and not string.find(itemId, "_Open")
        and not string.find(itemId, "Empty")
    if isCanned then
        local basePrice = 6
        if string.find(itemId, "Box") or string.find(itemId, "_Box") then
            basePrice = 45 -- 箱詰め缶詰ケース（まとめ売り）は45 CR
        elseif string.find(itemId, "Dogfood") or string.find(itemId, "Dented") then
            basePrice = 4  -- ドッグフード・凹み缶は4 CR
        elseif string.find(itemId, "Bolognese") or string.find(itemId, "Chili") or string.find(itemId, "CornedBeef")
            or string.find(itemId, "Sardines") or string.find(itemId, "Tuna") or string.find(itemId, "Roe") then
            basePrice = 8  -- 肉・魚・主食系缶詰は8 CR
        end
        return { id = itemId, name = "Canned Food", basePricePerUnit = basePrice, category = "CannedFood" }
    end

    -- 電線・電子廃材・回路部品 (Electronics & Scrap)
    if string.find(itemId, "ElectricWire") or (string.find(itemId, "Wire") and not string.find(itemId, "Barbed")) then
        return { id = itemId, name = "Electric Wire", basePricePerUnit = 4, category = "Electronics" }
    elseif string.find(itemId, "ElectronicsScrap") then
        return { id = itemId, name = "Electronics Scrap", basePricePerUnit = 5, category = "Electronics" }
    elseif string.find(itemId, "ScrapMetal") then
        return { id = itemId, name = "Scrap Metal", basePricePerUnit = 2, category = "Electronics" }
    elseif string.find(itemId, "Amplifier") or string.find(itemId, "Transmitter") or string.find(itemId, "Receiver") or string.find(itemId, "MotionSensor") then
        return { id = itemId, name = "Electronic Component", basePricePerUnit = 20, category = "Electronics" }
    end

    -- 工具類 (Tools: 中古スクラップ・リサイクル資材)
    if string.find(itemId, "Jack") or string.find(itemId, "LugWrench") or string.find(itemId, "TirePump")
        or string.find(itemId, "BlowTorch") or string.find(itemId, "HandDrill") or string.find(itemId, "Multitool") then
        return { id = itemId, name = "Heavy Tool", basePricePerUnit = 20, category = "Tools" }
    elseif string.find(itemId, "Hammer") or string.find(itemId, "Wrench") or string.find(itemId, "Screwdriver")
        or string.find(itemId, "Saw") or string.find(itemId, "Pliers") or string.find(itemId, "Crowbar")
        or string.find(itemId, "PipeWrench") or string.find(itemId, "Snips") or string.find(itemId, "Chisel") then
        return { id = itemId, name = "Hand Tool", basePricePerUnit = 8, category = "Tools" }
    end

    -- 車両パーツ (Vehicle Parts: タイヤ・足回り・電装部品)
    if string.find(itemId, "Tire") then
        return { id = itemId, name = "Vehicle Tire", basePricePerUnit = 15, category = "Vehicles" }
    elseif string.find(itemId, "Brake") then
        return { id = itemId, name = "Vehicle Brake", basePricePerUnit = 10, category = "Vehicles" }
    elseif string.find(itemId, "Suspension") then
        return { id = itemId, name = "Vehicle Suspension", basePricePerUnit = 12, category = "Vehicles" }
    elseif string.find(itemId, "Muffler") then
        return { id = itemId, name = "Vehicle Muffler", basePricePerUnit = 10, category = "Vehicles" }
    elseif string.find(itemId, "CarBattery") then
        return { id = itemId, name = "Car Battery", basePricePerUnit = 25, category = "Vehicles" }
    elseif string.find(itemId, "EngineParts") then
        return { id = itemId, name = "Engine Parts", basePricePerUnit = 2, category = "Vehicles" }
    end

    -- 持ち運べる家具・設備 (Moveable Furniture: レア度・設備・重量動的査定)
    if string.find(itemId, "Mov_") or string.find(itemId, "^Moveables") then
        return RadioTrader_ItemsTable_AssessFurniture(nil, itemId)
    end

    -- 軍用品・サバイバル装備 (Military Surplus: レア装備・軍服・無線機)
    if string.find(itemId, "ALICE") or string.find(itemId, "Bag_Military") then
        return { id = itemId, name = "Military Backpack", basePricePerUnit = 35, category = "Military" }
    elseif string.find(itemId, "HamRadio2") or string.find(itemId, "WalkieTalkie5") then
        return { id = itemId, name = "Military Radio Equipment", basePricePerUnit = 30, category = "Military" }
    elseif string.find(itemId, "Vest_Bullet") or string.find(itemId, "Hat_Army") or string.find(itemId, "Hat_CrashHelmet")
        or string.find(itemId, "Hat_BeretArmy") or string.find(itemId, "Holster") or string.find(itemId, "AmmoStrap") then
        return { id = itemId, name = "Military Tactical Gear", basePricePerUnit = 20, category = "Military" }
    elseif string.find(itemId, "Camo") or string.find(itemId, "Army") or string.find(itemId, "Military") then
        return { id = itemId, name = "Military Apparel", basePricePerUnit = 12, category = "Military" }
    end

    -- -----------------------------------------------------------------------
    -- 銃器・弾薬箱・弾倉・銃器パーツ (Firearms & Tactical Smart Fallback)
    -- -----------------------------------------------------------------------
    -- ※バラ弾（Loose Ammo）は買取対象外のため、明示的に除外して nil を返す
    local isLooseAmmo = (string.find(itemId, "Bullet") or string.find(itemId, "Shell") or string.find(itemId, "Round")
        or string.find(itemId, "Cartridge") or string.find(itemId, "Ammo"))
        and not string.find(itemId, "Box") and not string.find(itemId, "Can") and not string.find(itemId, "Crate")
        and not string.find(itemId, "Strap") and not string.find(itemId, "Clip") and not string.find(itemId, "Mag")
    if isLooseAmmo then
        return nil
    end

    -- 弾薬箱 (Ammo Box: 18 CR)
    if (string.find(itemId, "Box") or string.find(itemId, "Can"))
        and (string.find(itemId, "Bullet") or string.find(itemId, "Shell") or string.find(itemId, "Ammo")
        or string.find(itemId, "9mm") or string.find(itemId, "45") or string.find(itemId, "44") or string.find(itemId, "38") or string.find(itemId, "357")
        or string.find(itemId, "223") or string.find(itemId, "308") or string.find(itemId, "556") or string.find(itemId, "3030") or string.find(itemId, "Shotgun")) then
        return { id = itemId, name = "Ammunition Box", basePricePerUnit = 18, category = "AmmoBox" }
    end

    -- 弾倉・マガジン (Magazine: 8 CR)
    if string.find(itemId, "Clip") or string.find(itemId, "Magazine") or string.find(itemId, "Mag_") or string.find(itemId, "_Mag") then
        return { id = itemId, name = "Firearm Magazine", basePricePerUnit = 8, category = "Magazine" }
    end

    -- 銃器パーツ・アタッチメント (Gun Parts: 12 CR)
    if string.find(itemId, "Scope") or string.find(itemId, "Choke") or string.find(itemId, "Sling") or string.find(itemId, "Laser")
        or string.find(itemId, "RedDot") or string.find(itemId, "RecoilPad") or string.find(itemId, "FiberglassStock")
        or string.find(itemId, "GunLight") or string.find(itemId, "Suppressor") or string.find(itemId, "Silencer") or string.find(itemId, "Compensator") then
        return { id = itemId, name = "Firearm Part / Accessory", basePricePerUnit = 12, category = "GunPart" }
    end

    -- 銃器本体 (Firearms: Handgun 25 CR / Long Guns 45 CR)
    if string.find(itemId, "Pistol") or string.find(itemId, "Revolver") or string.find(itemId, "Handgun")
        or string.find(itemId, "Glock") or string.find(itemId, "Beretta") or string.find(itemId, "Derringer") then
        return { id = itemId, name = "Handgun / Sidearm", basePricePerUnit = 25, category = "Firearm" }
    elseif string.find(itemId, "Shotgun") or string.find(itemId, "Rifle") or string.find(itemId, "Sniper")
        or string.find(itemId, "Assault") or string.find(itemId, "Carbine") or string.find(itemId, "SMG") or string.find(itemId, "Submachine") then
        return { id = itemId, name = "Long Firearm / Rifle", basePricePerUnit = 45, category = "Firearm" }
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: バラ弾 (Loose Ammo) の判定と対応弾種の特定
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_IsLooseAmmo(item, itemType)
    local s = itemType or (item and item.getFullType and item:getFullType()) or ""
    if s == "" then return false, nil end

    -- 箱・ケース・弾帯・マガジン等は除外
    if string.find(s, "Box") or string.find(s, "Can") or string.find(s, "Crate")
        or string.find(s, "Strap") or string.find(s, "Clip") or string.find(s, "Mag")
        or string.find(s, "Case") or string.find(s, "Bag_") then
        return false, nil
    end

    if string.find(s, "Bullets9mm") or string.find(s, "9mmBullet") then return true, "Base.Bullets9mm" end
    if string.find(s, "Bullets45") or string.find(s, "45Bullet") then return true, "Base.Bullets45" end
    if string.find(s, "Bullets44") or string.find(s, "44Bullet") then return true, "Base.Bullets44" end
    if string.find(s, "Bullets38") or string.find(s, "38Bullet") then return true, "Base.Bullets38" end
    if string.find(s, "ShotgunShells") or string.find(s, "ShotgunShell") then return true, "Base.ShotgunShells" end
    if string.find(s, "223Bullets") or string.find(s, "223Bullet") then return true, "Base.223Bullets" end
    if string.find(s, "308Bullets") or string.find(s, "308Bullet") then return true, "Base.308Bullets" end
    if string.find(s, "556Bullets") or string.find(s, "556Bullet") then return true, "Base.556Bullets" end

    -- 一般弾丸キーワード
    if string.find(s, "Bullet") or string.find(s, "Shell") or string.find(s, "Round") or string.find(s, "Cartridge") then
        return true, s
    end

    return false, nil
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: 近接武器・刃物 (HandWeapon / Melee) の動的査定
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessMeleeWeapon(item, fallbackId)
    local id = fallbackId or (item and item.getFullType and item:getFullType()) or ""
    local name = (item and item.getName and item:getName()) or "Melee Weapon"
    local searchStr = string.lower(id .. " " .. name)

    -- 1. 最高級・レア大型刃物・大型打撃 (Tier 1: 28〜45 CR)
    if string.find(searchStr, "katana") then
        return { id = id, name = name, basePricePerUnit = 45, category = "Melee" }
    elseif string.find(searchStr, "machete") then
        return { id = id, name = name, basePricePerUnit = 35, category = "Melee" }
    elseif string.find(searchStr, "axe") and not string.find(searchStr, "head") and not string.find(searchStr, "handaxe") then
        return { id = id, name = name, basePricePerUnit = 28, category = "Melee" }
    elseif string.find(searchStr, "sledgehammer") or string.find(searchStr, "pickaxe") then
        return { id = id, name = name, basePricePerUnit = 28, category = "Melee" }
    elseif string.find(searchStr, "axehead") or string.find(searchStr, "axe_head") or string.find(searchStr, "head") then
        return { id = id, name = name, basePricePerUnit = 15, category = "Melee" }

    -- 2. 実用中型近接・戦術刃物 (Tier 2: 10〜16 CR)
    elseif string.find(searchStr, "huntingknife") or string.find(searchStr, "combatknife") or string.find(searchStr, "survival_knife") then
        return { id = id, name = name, basePricePerUnit = 16, category = "Melee" }
    elseif string.find(searchStr, "handaxe") then
        return { id = id, name = name, basePricePerUnit = 15, category = "Melee" }
    elseif string.find(searchStr, "crowbar") then
        return { id = id, name = name, basePricePerUnit = 14, category = "Melee" }
    elseif string.find(searchStr, "baseballbat") or string.find(searchStr, "bat") then
        return { id = id, name = name, basePricePerUnit = 12, category = "Melee" }
    elseif string.find(searchStr, "shovel") then
        return { id = id, name = name, basePricePerUnit = 12, category = "Melee" }
    elseif string.find(searchStr, "gardenfork") or string.find(searchStr, "gardenhoe") then
        return { id = id, name = name, basePricePerUnit = 10, category = "Melee" }

    -- 3. 一般・小型刃物・簡易近接 (Tier 3: 3〜8 CR)
    elseif string.find(searchStr, "cleaver") or string.find(searchStr, "meatcleaver") then
        return { id = id, name = name, basePricePerUnit = 8, category = "Melee" }
    elseif string.find(searchStr, "kitchenknife") or string.find(searchStr, "knife") then
        return { id = id, name = name, basePricePerUnit = 6, category = "Melee" }
    elseif string.find(searchStr, "golfclub") or string.find(searchStr, "pipe") or string.find(searchStr, "metalbar") then
        return { id = id, name = name, basePricePerUnit = 8, category = "Melee" }
    elseif string.find(searchStr, "spear") then
        return { id = id, name = name, basePricePerUnit = 6, category = "Melee" }
    elseif string.find(searchStr, "nightstick") or string.find(searchStr, "icepick") or string.find(searchStr, "scissors") then
        return { id = id, name = name, basePricePerUnit = 6, category = "Melee" }
    elseif string.find(searchStr, "mallet") or string.find(searchStr, "clubhammer") then
        return { id = id, name = name, basePricePerUnit = 8, category = "Melee" }
    elseif string.find(searchStr, "plank") or string.find(searchStr, "stake") then
        return { id = id, name = name, basePricePerUnit = 3, category = "Melee" }

    -- 4. 簡易カトラリー (Tier 4: 2 CR)
    elseif string.find(searchStr, "butterknife") or string.find(searchStr, "fork")
        or string.find(searchStr, "spoon") or string.find(searchStr, "letteropener") or string.find(searchStr, "scalpel") then
        return { id = id, name = name, basePricePerUnit = 2, category = "Melee" }
    end

    -- 5. その他近接武器デフォルト (8 CR)
    return { id = id, name = name, basePricePerUnit = 8, category = "Melee" }
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: コンテナアイテム（バッグ・ケース・袋・箱類）の3段階一律査定
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessContainerItem(item, fallbackId)
    local id = fallbackId or (item and item.getFullType and item:getFullType()) or ""
    local name = (item and item.getName and item:getName()) or "Container"
    local searchStr = string.lower(id .. " " .. name)

    -- 1. 簡易袋・小箱・ポーチ類 (基準 2 CR -> デフォルト0.5倍で 1 CR)
    if string.find(searchStr, "garbage") or string.find(searchStr, "trash")
        or string.find(searchStr, "plasticbag") or string.find(searchStr, "grocery")
        or string.find(searchStr, "paperbag") or string.find(searchStr, "lunchbag")
        or string.find(searchStr, "sack") or string.find(searchStr, "sandbag")
        or string.find(searchStr, "seedbag") or string.find(searchStr, "lunchbox")
        or string.find(searchStr, "wallet") or string.find(searchStr, "purse")
        or string.find(searchStr, "fannypack") or string.find(searchStr, "pouch")
        or string.find(searchStr, "pencilcase") or string.find(searchStr, "cookiejar") then
        return { id = id, name = name, basePricePerUnit = 2, category = "Container" }
    end

    -- 2. 大型バックパック・弾薬缶・ハードケース類 (基準 8 CR -> デフォルト0.5倍で 4 CR)
    if string.find(searchStr, "bighiking") or string.find(searchStr, "survivorbag")
        or string.find(searchStr, "ammobox") or string.find(searchStr, "protectivecase")
        or string.find(searchStr, "guncase") or string.find(searchStr, "riflecase")
        or string.find(searchStr, "shotguncase") or string.find(searchStr, "revolvercase")
        or string.find(searchStr, "pistolcase") or string.find(searchStr, "military") then
        return { id = id, name = name, basePricePerUnit = 8, category = "Container" }
    end

    -- 3. 一般バッグ・リュック・工具箱・救急箱・クーラー・木箱類 (基準 4 CR -> デフォルト0.5倍で 2 CR)
    return { id = id, name = name, basePricePerUnit = 4, category = "Container" }
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: スキル本・レシピ雑誌・文庫本の動的査定 (Literature Appraisal)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessLiterature(item, itemType)
    if not item then return nil end
    local typeStr = itemType or (item.getFullType and item:getFullType()) or ""
    local dispCat = item.getDisplayCategory and item:getDisplayCategory()
    local name = (item.getName and item:getName()) or "Book"

    -- 1. スキル本 (SkillBook: Vol 1〜5)
    -- B42では LvlSkillTrained が 1 (Vol1), 3 (Vol2), 5 (Vol3), 7 (Vol4), 9 (Vol5)
    local isSkillBook = (dispCat == "SkillBook")
        or (item.getSkillTrained and item:getSkillTrained() ~= nil and item:getSkillTrained() ~= "")
        or string.find(typeStr, "Book[A-Z]")
        or (string.find(typeStr, "Book") and (string.find(typeStr, "1") or string.find(typeStr, "2") or string.find(typeStr, "3") or string.find(typeStr, "4") or string.find(typeStr, "5")))

    local lvlTrained = (item.getLvlSkillTrained and item:getLvlSkillTrained()) or 0

    if isSkillBook or lvlTrained > 0 then
        local price = 6 -- デフォルト

        -- LvlSkillTrained による厳密判定
        if lvlTrained == 1 then
            price = 4  -- Vol 1 (初級)
        elseif lvlTrained == 3 or lvlTrained == 2 then
            price = 6  -- Vol 2 (中級)
        elseif lvlTrained == 5 or lvlTrained == 4 then
            price = 8  -- Vol 3 (上級)
        elseif lvlTrained == 7 or lvlTrained == 6 then
            price = 10 -- Vol 4 (熟練)
        elseif lvlTrained >= 8 then
            price = 12 -- Vol 5 (達人)
        else
            -- ID末尾やVol表記によるフォールバック
            if string.find(typeStr, "1$") or string.find(typeStr, "Vol1") or string.find(typeStr, "Vol%.%s*1") then
                price = 4
            elseif string.find(typeStr, "2$") or string.find(typeStr, "Vol2") or string.find(typeStr, "Vol%.%s*2") then
                price = 6
            elseif string.find(typeStr, "3$") or string.find(typeStr, "Vol3") or string.find(typeStr, "Vol%.%s*3") then
                price = 8
            elseif string.find(typeStr, "4$") or string.find(typeStr, "Vol4") or string.find(typeStr, "Vol%.%s*4") then
                price = 10
            elseif string.find(typeStr, "5$") or string.find(typeStr, "Vol5") or string.find(typeStr, "Vol%.%s*5") then
                price = 12
            end
        end

        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = price,
            category         = "Archives",
        }
    end

    -- 2. レシピ雑誌・技術解禁マニュアル (RecipeResource)
    local hasLearnedRecipes = false
    if item.getLearnedRecipes then
        local lr = item:getLearnedRecipes()
        if lr and not lr:isEmpty() then hasLearnedRecipes = true end
    end
    if not hasLearnedRecipes and item.getTeachedRecipes then
        local tr = item:getTeachedRecipes()
        if tr and not tr:isEmpty() then hasLearnedRecipes = true end
    end

    local isRecipeMag = (dispCat == "RecipeResource") or hasLearnedRecipes
        or string.find(typeStr, "Mag%d") or string.find(typeStr, "Magazine%d")
        or string.find(typeStr, "Recipe") or string.find(typeStr, "Manual")

    if isRecipeMag then
        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = 10, -- 一律 10 CR
            category         = "Archives",
        }
    end

    -- 3. 一般文庫本・文学小説 (Literature)
    if (instanceof and instanceof(item, "Literature")) or dispCat == "Literature" or string.find(typeStr, "Book") then
        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = 10,
            category         = "Archives",
        }
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- ユーティリティ: なめし革・皮革資材の3段階動的査定 (Tanned Leather Appraisal)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_AssessLeather(item, itemType)
    if not item then return nil end
    local typeStr = itemType or (item.getFullType and item:getFullType()) or ""
    local name = (item.getName and item:getName()) or "Leather"

    -- 未完成の濡れた状態（_Wet）や革ひも・革端切れ（Strips）は無限量産防止のため除外
    if string.find(typeStr, "_Wet") or string.find(typeStr, "Strips") then return nil end

    -- 1. 大（本格資材: 25 CR）
    -- 成牛・鹿・成豚フルサイズ、大型なめし粗皮
    if string.find(typeStr, "Large_Tan")
        or (string.find(typeStr, "CowLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "DeerLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "PigLeather") and string.find(typeStr, "Full")) then
        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = 25,
            category         = "Industrial",
        }
    end

    -- 2. 中（安価資材: 12 CR）
    -- 中型なめし粗皮、子牛・羊・子豚・小鹿フルサイズ、中判毛皮
    if string.find(typeStr, "Medium_Tan") or string.find(typeStr, "Tan_Medium")
        or (string.find(typeStr, "CalfLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "SheepLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "LambLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "PigletLeather") and string.find(typeStr, "Full"))
        or (string.find(typeStr, "FawnLeather") and string.find(typeStr, "Full")) then
        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = 12,
            category         = "Industrial",
        }
    end

    -- 3. 小（はした金 / 小型動物皮革: 3 CR）
    -- 小型なめし粗皮、ウサギ・アライグマ革、小判毛皮
    if string.find(typeStr, "Small_Tan") or string.find(typeStr, "Tan_Small")
        or string.find(typeStr, "RabbitLeather")
        or string.find(typeStr, "RaccoonLeather") then
        return {
            id               = typeStr,
            name             = name,
            basePricePerUnit = 3,
            category         = "Industrial",
        }
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
-- 弾薬庫: 日替わり弾薬箱在庫プール抽選関数 (1日1回更新・0〜5箱・0または1が高確率)
-- ---------------------------------------------------------------------------
function RadioTrader_ItemsTable_RollDailyAmmoStock()
    local pool = {}
    local ammoList = (RadioTrader_Shop and RadioTrader_Shop.Ammo) or {}
    for _, entry in ipairs(ammoList) do
        local key = entry.poolKey or entry.id
        local roll = (ZombRand and ZombRand(100)) or math.random(0, 99)
        local stock = 0
        -- 確率分布: 0箱(40%), 1箱(30%), 2箱(15%), 3箱(8%), 4箱(4%), 5箱(3%) -> 0または1が計70%
        if roll < 40 then
            stock = 0
        elseif roll < 70 then
            stock = 1
        elseif roll < 85 then
            stock = 2
        elseif roll < 93 then
            stock = 3
        elseif roll < 97 then
            stock = 4
        else
            stock = 5
        end
        pool[key] = stock
    end
    return pool
end

-- ---------------------------------------------------------------------------
-- カテゴリ表示定義（UI用 / キー名で管理し、表示はUI側で多言語化）
-- ---------------------------------------------------------------------------
RadioTrader_ShopCategories = {
    { key = "Daily", label = "[Daily] Daily Deals"           },
    { key = "Crops", label = "[Crops] Produce Exchange"      },
    { key = "Ammo",  label = "[Ammo] Ammo Depot"             },
    { key = "Bags",  label = "[Bags] Supply Bags"            },
    { key = "Misc",  label = "[Misc] Machinery & Gear"       },
}

-- ---------------------------------------------------------------------------
-- 共通: LZ座標取得ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_GetLZCoords(player)
    if not player then return nil end
    local cfg = RadioTrader_Config
    local uname = cfg and cfg.getPlayerKey and cfg.getPlayerKey(player) or "singleplayer"
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

    -- ロット・重量集計用グループ
    local meatFishGroup  = { items = {}, totalWeight = 0 }
    local eggGroup       = { items = {}, count = 0, effectiveUnits = 0 }
    local produceGroup   = { items = {}, count = 0, totalEffectiveCredits = 0 }
    local looseAmmoGroup = { items = {}, counts = {} } -- バラ弾ロット集計

    local function isValidJavaContainer(cont)
        if not cont or type(cont) == "string" then return false end
        local s = tostring(cont)
        if not s or s == "null" or s == "nil" then return false end
        return cont.getItems ~= nil
    end

    local function scanInventory(targetContainer)
        if not isValidJavaContainer(targetContainer) then return end
        local ok, items = pcall(function() return targetContainer:getItems() end)
        if not ok or not items or tostring(items) == "null" then return end

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and tostring(item) ~= "null" then
                local itemType = item:getFullType()
                local sellEntry = nil
                local isContainerItem = (instanceof and instanceof(item, "InventoryContainer"))
                    or (item.IsInventoryContainer and item:IsInventoryContainer() == true)

                -- 0. バラ弾（Loose Ammo: ロット集計グループへ優先振り分け）
                local isLoose, ammoType = RadioTrader_ItemsTable_IsLooseAmmo(item, itemType)
                if isLoose then
                    table.insert(looseAmmoGroup.items, { item = item, container = targetContainer, ammoType = ammoType })
                    looseAmmoGroup.counts[ammoType] = (looseAmmoGroup.counts[ammoType] or 0) + 1
                else
                    -- 持ち運べる家具・設備（Moveable）の動的査定を優先チェック
                    local isFurniture = (instanceof and instanceof(item, "Moveable")) or
                                        string.find(itemType, "^Moveables") or
                                        string.find(itemType, "Mov_")
                    if isFurniture then
                        sellEntry = RadioTrader_ItemsTable_AssessFurniture(item, itemType)
                    else
                        -- スカベンジャー募集チラシ（討伐褒章・一次資料）の特別査定
                        local isFlyer = false
                        if item.getModData then
                            local md = item:getModData()
                            if md and md.bRadioTraderFlyer then
                                isFlyer = true
                            end
                        end

                        if isFlyer then
                            sellEntry = {
                                id               = itemType,
                                name             = getTextOrNull and getTextOrNull("UI_RadioTrader_Flyer_Title") or "Scavenger Flyer",
                                basePricePerUnit = 100,
                                category         = "Archives",
                            }
                        else
                            -- 記録メディア（VHSビデオテープ・音楽CD）動的査定（スキルビデオ判定等）
                            local mediaEntry = RadioTrader_ItemsTable_AssessRecordedMedia(item, itemType)
                            if mediaEntry then
                                sellEntry = mediaEntry
                            else
                                sellEntry = RadioTrader_ItemsTable_GetSellEntry(itemType)
                                if not sellEntry then
                                    sellEntry = RadioTrader_ItemsTable_GetSellEntry(item:getType())
                                end
                            end
                            -- Build 42 書籍・スキル本・レシピ雑誌（Literature）オブジェクト動的査定フォールバック
                            if not sellEntry and ((instanceof and instanceof(item, "Literature")) or string.find(itemType, "Book") or string.find(itemType, "Mag")) then
                                sellEntry = RadioTrader_ItemsTable_AssessLiterature(item, itemType)
                            end
                            -- 銃器および近接武器（HandWeapon）オブジェクトフォールバック
                            if not sellEntry and (instanceof and instanceof(item, "HandWeapon")) then
                                if item.isRanged and item:isRanged() then
                                    local swingAnim = (item.getSwingAnim and item:getSwingAnim()) or ""
                                    local isHandgun = (swingAnim == "Handgun" or string.find(itemType, "Pistol") or string.find(itemType, "Revolver"))
                                    if isHandgun then
                                        sellEntry = { id = itemType, name = item:getName() or "Handgun", basePricePerUnit = 25, category = "Firearm" }
                                    else
                                        sellEntry = { id = itemType, name = item:getName() or "Firearm", basePricePerUnit = 45, category = "Firearm" }
                                    end
                                else
                                    -- 近接武器・刃物（HandWeapon / not isRanged）
                                    sellEntry = RadioTrader_ItemsTable_AssessMeleeWeapon(item, itemType)
                                end
                            end
                            -- 銃器パーツ（WeaponPart）オブジェクトフォールバック
                            if not sellEntry and (instanceof and instanceof(item, "WeaponPart")) then
                                sellEntry = { id = itemType, name = item:getName() or "Gun Part", basePricePerUnit = 12, category = "GunPart" }
                            end
                            -- コンテナ（バッグ・ケース・箱・袋類）オブジェクト一律査定フォールバック
                            if not sellEntry and isContainerItem then
                                sellEntry = RadioTrader_ItemsTable_AssessContainerItem(item, itemType)
                            end
                            -- なめし革・皮革資材（Leather）動的査定フォールバック
                            if not sellEntry and (string.find(itemType, "Leather") or string.find(itemType, "Hide")) then
                                sellEntry = RadioTrader_ItemsTable_AssessLeather(item, itemType)
                            end
                        end
                    end
                end

                -- バッグ（コンテナ内に入ったカバン等）の中身を先に再帰的に走査！
                -- ※中に回収対象外のアイテムが1つでも残っている場合、カバン自体を買い取って消してしまうと
                --   中の対象外アイテムまで消滅してしまうため、カバン自体の売却を保留（スキップ）する安全保護
                local childUnacceptedBefore = #unacceptedItems
                if isContainerItem then
                    local innerInv = nil
                    if item.getItemContainer then
                        innerInv = item:getItemContainer()
                    elseif item.getInventory then
                        innerInv = item:getInventory()
                    end
                    if isValidJavaContainer(innerInv) then
                        scanInventory(innerInv)
                    end
                end
                local hasUnacceptedInside = (#unacceptedItems > childUnacceptedBefore)
                if hasUnacceptedInside then
                    sellEntry = nil
                end

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

                    if sellEntry.category == "Seed" then
                        -- 契約農園: 種・種袋（クレジット0 CR、プール加算用）
                        table.insert(assessedItems, {
                            item      = item,
                            container = targetContainer,
                            name      = sellEntry.name,
                            credits   = 0,
                            condition = 1.0,
                            isSeed    = true,
                            poolKey   = sellEntry.poolKey,
                            poolCount = sellEntry.poolCount or 1,
                        })
                    elseif freshness > 0 and condition >= cfg.MIN_SELL_CONDITION then
                        -- カテゴリ別分岐: ロット・重量集計対象
                        if sellEntry.category == "MeatFish" then
                            local w = 0.3
                            if item.getActualWeight then
                                w = item:getActualWeight() or 0.3
                            end
                            local effectiveW = w * freshness
                            meatFishGroup.totalWeight = meatFishGroup.totalWeight + effectiveW
                            table.insert(meatFishGroup.items, { item = item, container = targetContainer, name = sellEntry.name, condition = condition })

                        elseif sellEntry.category == "Egg" then
                            eggGroup.count = eggGroup.count + 1
                            eggGroup.effectiveUnits = eggGroup.effectiveUnits + freshness
                            table.insert(eggGroup.items, { item = item, container = targetContainer, name = sellEntry.name, condition = condition })

                        elseif sellEntry.category == "Produce" then
                            produceGroup.count = produceGroup.count + 1
                            -- 満腹度（Hunger）に基づく動的査定（満腹度10あたり1.0 CR）
                            local hungVal = 0
                            if item.getHungChange then
                                hungVal = math.abs(item:getHungChange() or 0)
                            end
                            -- 0.24 などの割合表現（100で割られた値）の場合は 100倍して 24 に換算
                            if hungVal < 3.0 and hungVal > 0 then
                                hungVal = hungVal * 100
                            end
                            local hungCR = hungVal / 10.0

                            -- 満腹度ベース ＋ 最低保証 (1.0 CR)
                            local baseVal = hungCR
                            if baseVal <= 0 then
                                baseVal = sellEntry.basePricePerUnit or 1.0
                            else
                                baseVal = math.max(1.0, baseVal)
                            end

                            -- 新鮮度乗算 (新鮮: 1.0倍 / 鮮度落ち: 0.5倍)
                            local itemCR = baseVal * freshness
                            produceGroup.totalEffectiveCredits = produceGroup.totalEffectiveCredits + itemCR
                            table.insert(produceGroup.items, { item = item, container = targetContainer, name = sellEntry.name, condition = condition })

                        else
                            local basePrice = sellEntry.basePricePerUnit
                            if sellEntry.isRandom or string.find(itemType, "CreditCard") then
                                local seed = (item.getID and item:getID()) or 0
                                basePrice = 1 + (math.abs(seed) % 5)
                            end

                            local condValue = condition * cfg.CONDITION_WEIGHT
                            local freshValue = freshness * cfg.FRESHNESS_WEIGHT
                            local totalWeight = cfg.CONDITION_WEIGHT + cfg.FRESHNESS_WEIGHT
                            local qualityMultiplier = (condValue + freshValue) / totalWeight
                            if sellEntry.category == "Currency" or sellEntry.category == "Electronics"
                                or sellEntry.category == "AmmoBox" or sellEntry.category == "Magazine" or sellEntry.category == "GunPart"
                                or sellEntry.category == "CannedFood" or sellEntry.category == "Container" then
                                qualityMultiplier = 1.0
                            elseif sellEntry.category == "Furniture" then
                                qualityMultiplier = condition
                            elseif sellEntry.category == "Firearm" or sellEntry.category == "Melee" then
                                -- 耐久度9割以上で満額(1.0)、5割以上で7割(0.7)、5割未満で4割(0.4)
                                if condition >= 0.90 then
                                    qualityMultiplier = 1.0
                                elseif condition >= 0.50 then
                                    qualityMultiplier = 0.7
                                else
                                    qualityMultiplier = 0.4
                                end
                            end

                            -- 消耗品・残量アイテム（Drainable: 糸・より糸・針金等）の残量補正
                            if item.getUsedDelta then
                                local delta = item:getUsedDelta() or 1.0
                                if delta > 0 then
                                    qualityMultiplier = qualityMultiplier * math.min(1.0, math.max(0.1, delta))
                                end
                            end

                            local sellMult = RadioTrader_Config.getSellPriceMultiplier and RadioTrader_Config.getSellPriceMultiplier() or 1.0
                            local itemCredits = math.max(1, math.floor(basePrice * qualityMultiplier * sellMult + 0.5))

                            -- マガジン（弾倉）の装填弾薬を集計して合算
                            local ammoRounds = 0
                            if sellEntry.category == "Magazine" or string.find(itemType, "Clip") or string.find(itemType, "Magazine") or string.find(itemType, "Mag") then
                                if item.getCurrentAmmoCount then
                                    ammoRounds = item:getCurrentAmmoCount() or 0
                                end
                                if ammoRounds > 0 then
                                    local aType = nil
                                    if item.getAmmoType then
                                        local rawAmmo = item:getAmmoType()
                                        if rawAmmo then
                                            if type(rawAmmo) == "string" then
                                                aType = rawAmmo
                                            elseif rawAmmo.getItemKey then
                                                aType = rawAmmo:getItemKey()
                                            else
                                                local s = tostring(rawAmmo)
                                                if s and s ~= "" and s ~= "null" and s ~= "nil" and not string.find(s, "^userdata:") then
                                                    aType = s
                                                end
                                            end
                                        end
                                    end
                                    if not aType or aType == "" or aType == "null" or aType == "nil" then
                                        if string.find(itemType, "9mm") then aType = "Base.Bullets9mm"
                                        elseif string.find(itemType, "45") then aType = "Base.Bullets45"
                                        elseif string.find(itemType, "44") then aType = "Base.Bullets44"
                                        elseif string.find(itemType, "223") then aType = "Base.223Bullets"
                                        elseif string.find(itemType, "308") or string.find(itemType, "M14") then aType = "Base.308Bullets"
                                        elseif string.find(itemType, "556") then aType = "Base.556Bullets"
                                        elseif string.find(itemType, "Shotgun") or string.find(itemType, "Shell") then aType = "Base.ShotgunShells"
                                        else aType = "Base.Bullets9mm" end
                                    end
                                    local pricePerRound = RadioTrader_Config.getAmmoPrice(aType)
                                    local ammoCredits = math.floor(ammoRounds * pricePerRound * sellMult + 0.5)
                                    if ammoCredits <= 0 and ammoRounds > 0 then ammoCredits = 1 end
                                    itemCredits = itemCredits + ammoCredits
                                end
                            end

                            if itemCredits > 0 then
                                local displayName = sellEntry.name
                                if sellEntry.category == "Furniture" and sellEntry.tier then
                                    local w = sellEntry.actualWeight or (item.getActualWeight and item:getActualWeight()) or 0
                                    displayName = string.format("[%s] %s (%.1fkg)", sellEntry.tier, sellEntry.name, w)
                                elseif sellEntry.category == "Firearm" or sellEntry.category == "Melee" then
                                    local qTag = (condition >= 0.90) and (getTextOrNull and getTextOrNull("UI_RadioTrader_Quality_Mint") or "Mint")
                                        or ((condition >= 0.50) and (getTextOrNull and getTextOrNull("UI_RadioTrader_Quality_Used") or "Used")
                                        or (getTextOrNull and getTextOrNull("UI_RadioTrader_Quality_Worn") or "Worn"))
                                    displayName = string.format("[%s] %s", qTag, displayName)
                                end

                                if ammoRounds > 0 then
                                    displayName = string.format("%s [%d rnds]", displayName, ammoRounds)
                                end

                                table.insert(assessedItems, {
                                    item      = item,
                                    container = targetContainer,
                                    name      = displayName,
                                    credits   = itemCredits,
                                    condition = condition,
                                })
                                totalCredits = totalCredits + itemCredits
                            end
                        end
                    else
                        if not hasUnacceptedInside then
                            table.insert(unacceptedItems, item:getName() or itemType)
                        end
                    end
                else
                    if not hasUnacceptedInside then
                        table.insert(unacceptedItems, item:getName() or itemType)
                    end
                end
            end
        end
    end

    scanInventory(container)

    local sellMult = RadioTrader_Config.getSellPriceMultiplier and RadioTrader_Config.getSellPriceMultiplier() or 1.0

    -- 1. 切り身・生肉ロット計算（0.5kg単位ブロック買取 20 CR、端数合計1 CR）
    if #meatFishGroup.items > 0 and meatFishGroup.totalWeight > 0 then
        local blocks = math.floor(meatFishGroup.totalWeight / 0.5)
        local remainder = meatFishGroup.totalWeight - (blocks * 0.5)
        local blockPrice = math.max(1, math.floor(20 * sellMult + 0.5))
        local meatCredits = blocks * blockPrice
        if remainder >= 0.01 or (blocks == 0 and meatFishGroup.totalWeight > 0) then
            meatCredits = meatCredits + 1
        end
        totalCredits = totalCredits + meatCredits
        for _, entry in ipairs(meatFishGroup.items) do
            table.insert(assessedItems, {
                item      = entry.item,
                container = entry.container,
                name      = entry.name,
                credits   = 0,
                condition = entry.condition,
            })
        end
    end

    -- 2. 朝採れ卵ロット計算（1個3 CR、6個パックごとに +10 CRボーナス）
    if eggGroup.count > 0 then
        local baseEggPrice = math.max(1, math.floor(3 * sellMult + 0.5))
        local bonus6Pack = math.max(1, math.floor(10 * sellMult + 0.5))
        local packs = math.floor(eggGroup.count / 6)
        local eggCredits = math.floor(eggGroup.effectiveUnits * baseEggPrice) + (packs * bonus6Pack)
        if eggCredits <= 0 and eggGroup.count > 0 then eggCredits = 1 end
        totalCredits = totalCredits + eggCredits
        for _, entry in ipairs(eggGroup.items) do
            table.insert(assessedItems, {
                item      = entry.item,
                container = entry.container,
                name      = entry.name,
                credits   = 0,
                condition = entry.condition,
            })
        end
    end

    -- 3. 農作物・果物ロット計算（満腹度・新鮮度連動 ＋ 10個ロットごとにボーナス）
    if produceGroup.count > 0 then
        local bonus10Lot = math.max(1, math.floor(10 * sellMult + 0.5))
        local lots = math.floor(produceGroup.count / 10)
        local baseCredits = math.floor(produceGroup.totalEffectiveCredits * sellMult + 0.5)
        local produceCredits = baseCredits + (lots * bonus10Lot)
        if produceCredits <= 0 and produceGroup.count > 0 then produceCredits = 1 end
        totalCredits = totalCredits + produceCredits
        for _, entry in ipairs(produceGroup.items) do
            table.insert(assessedItems, {
                item      = entry.item,
                container = entry.container,
                name      = entry.name,
                credits   = 0,
                condition = entry.condition,
            })
        end
    end

    -- 4. バラ弾（Loose Ammo）ロット計算（弾種ごとの集計・四捨五入計算）
    if #looseAmmoGroup.items > 0 then
        for aType, count in pairs(looseAmmoGroup.counts) do
            local pricePerRound = RadioTrader_Config.getAmmoPrice(aType)
            local ammoCredits = math.max(1, math.floor(count * pricePerRound * sellMult + 0.5))
            totalCredits = totalCredits + ammoCredits

            local cleanName = string.gsub(aType, "^Base%.", "")
            local dispName = string.format("%s x%d", cleanName, count)

            local first = true
            for _, entry in ipairs(looseAmmoGroup.items) do
                if entry.ammoType == aType then
                    table.insert(assessedItems, {
                        item      = entry.item,
                        container = entry.container,
                        name      = dispName,
                        credits   = first and ammoCredits or 0,
                        condition = 1.0,
                    })
                    first = false
                end
            end
        end
    end

    -- 5. 買取品実重量マイルストーンボーナス (Bulk Cargo Weight Milestones)
    -- 実際に買取（削除）対象となった物理アイテムの総実重量を集計
    local totalSoldWeight = 0.0
    for _, entry in ipairs(assessedItems) do
        if entry.item then
            local w = 0.1
            if entry.item.getActualWeight then
                w = entry.item:getActualWeight() or 0.1
            end
            totalSoldWeight = totalSoldWeight + w
        end
    end

    local cargoBonus = 0
    local milestoneKey = nil
    local minMilestone = 0
    if RadioTrader_Config and RadioTrader_Config.getCargoWeightBonus then
        cargoBonus, milestoneKey, minMilestone = RadioTrader_Config.getCargoWeightBonus(totalSoldWeight)
    end

    if cargoBonus > 0 then
        totalCredits = totalCredits + cargoBonus

        local milestoneText = tostring(math.floor(minMilestone)) .. "kg"
        local bonusTitle = getTextOrNull and getTextOrNull(milestoneKey)
        if not bonusTitle then
            if minMilestone >= 45.0 then
                bonusTitle = string.format("[Cargo Bonus] %s Cargo Milestone (Drone Offset)", milestoneText)
            else
                bonusTitle = string.format("[Cargo Bonus] %s Cargo Milestone", milestoneText)
            end
        end
        local bonusDisplayName = string.format("%s (%.1f kg)", bonusTitle, totalSoldWeight)

        table.insert(assessedItems, {
            item      = nil, -- 物理アイテムなし（ボーナス表示用・削除ループで安全にスキップ）
            isBonus   = true,
            name      = bonusDisplayName,
            credits   = cargoBonus,
            condition = 1.0,
        })
    end

    return assessedItems, totalCredits, nil, #unacceptedItems, unacceptedItems, totalSoldWeight, cargoBonus
end


-- ---------------------------------------------------------------------------
-- 共通: 買取対象外アイテムの品名別集計ヘルパー
-- ---------------------------------------------------------------------------
function RadioTrader_SummarizeUnacceptedItems(unacceptedItems)
    if not unacceptedItems or #unacceptedItems == 0 then
        return {}
    end
    local counts = {}
    local order = {}
    for _, name in ipairs(unacceptedItems) do
        local safeName = tostring(name or "Unknown")
        if not counts[safeName] then
            counts[safeName] = 0
            table.insert(order, safeName)
        end
        counts[safeName] = counts[safeName] + 1
    end
    local result = {}
    for _, name in ipairs(order) do
        table.insert(result, {
            name  = name,
            count = counts[name],
        })
    end
    table.sort(result, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.name < b.name
    end)
    return result
end
