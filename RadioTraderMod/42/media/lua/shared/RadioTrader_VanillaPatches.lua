-- =============================================================================
-- RadioTrader_VanillaPatches.lua
-- [Shared] Project Zomboid B42 バニラ既知重大バグの自動安全ホットフィックス
-- =============================================================================
-- 本ファイルは、B42バニラ本体のコードに存在する進行不能・大量エラーループ不具合を
-- 安全に検知・自動修復（モンキーパッチ）します。
-- =============================================================================

local function applyVanillaHotfixes()
    -- -------------------------------------------------------------------------
    -- Patch 1: ISReloadWeaponAction.setReloadSpeed における strap nil 参照クラッシュの防止
    -- -------------------------------------------------------------------------
    -- 【原因】
    -- B42バニラ (ISReloadWeaponAction.lua:100, 102) において、
    -- アモストラップを未装備の状態でリロード速度向上タグ（RELOAD_FAST_*）を持つ装備を着けていると、
    -- strap が nil のまま strap:getClothingItemName() を呼び出してクラッシュする。
    -- その結果、ReloadSpeed 変数が初期化されず毎フレーム update() で大量例外（__sub not defined）が発生する。
    -- -------------------------------------------------------------------------
    if ISReloadWeaponAction and not ISReloadWeaponAction._RT_Patched then
        local original_setReloadSpeed = ISReloadWeaponAction.setReloadSpeed

        ISReloadWeaponAction.setReloadSpeed = function(character, rack)
            if not character then return end

            local baseReloadSpeed = 0.8
            if rack then
                baseReloadSpeed = baseReloadSpeed + (character:getPerkLevel(Perks.Reloading) * 0.04)
            else
                baseReloadSpeed = baseReloadSpeed + (character:getPerkLevel(Perks.Reloading) * 0.10)
                if character.getMoodles and character:getMoodles() then
                    local panicLevel = character:getMoodles():getMoodleLevel(MoodleType.PANIC) or 0
                    baseReloadSpeed = baseReloadSpeed - (panicLevel * 0.05)
                end
            end

            -- 安全なアモストラップ・タグ判定
            local gun = character:getPrimaryHandItem()
            local strap = nil
            if character.getWornItem and ItemBodyLocation and ItemBodyLocation.AMMO_STRAP then
                strap = character:getWornItem(ItemBodyLocation.AMMO_STRAP)
            end

            local reloadFast = false
            if ItemTag then
                if ItemTag.RELOAD_FAST_SHELLS and character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_SHELLS) then reloadFast = true end
                if ItemTag.RELOAD_FAST_BULLETS and character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_BULLETS) then reloadFast = true end
                if ItemTag.RELOAD_FAST_MAGAZINES and character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_MAGAZINES) then reloadFast = true end
            end

            local strapFound = false
            local hasWornMagTag = (ItemTag and ItemTag.RELOAD_FAST_MAGAZINES and character.hasWornTag and character:hasWornTag(ItemTag.RELOAD_FAST_MAGAZINES))
            local hasValidStrap = (strap and strap.getClothingItem and strap:getClothingItem())

            if gun and (reloadFast or hasWornMagTag or hasValidStrap) then
                local shell = false
                local magazine = false
                if AmmoType and AmmoType.SHOTGUN_SHELLS and gun.getAmmoType and gun:getAmmoType() == AmmoType.SHOTGUN_SHELLS then
                    shell = true
                elseif gun.getMagazineType and gun:getMagazineType() then
                    magazine = true
                end

                local strapName = (strap and strap.getClothingItemName and strap:getClothingItemName()) or ""

                if magazine and (hasWornMagTag or (ItemTag and ItemTag.RELOAD_FAST_MAGAZINES and character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_MAGAZINES))) then
                    strapFound = true
                elseif shell and ((ItemTag and ItemTag.RELOAD_FAST_SHELLS and ((character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_SHELLS)) or (character.hasWornTag and character:hasWornTag(ItemTag.RELOAD_FAST_SHELLS)))) or strapName == "AmmoStrap_Shells") then
                    strapFound = true
                elseif not shell and not magazine and ((ItemTag and ItemTag.RELOAD_FAST_BULLETS and ((character.hasEquippedTag and character:hasEquippedTag(ItemTag.RELOAD_FAST_BULLETS)) or (character.hasWornTag and character:hasWornTag(ItemTag.RELOAD_FAST_BULLETS)))) or strapName == "AmmoStrap_Bullets") then
                    strapFound = true
                end
            end

            if strapFound then
                baseReloadSpeed = baseReloadSpeed * 1.15
            end

            if character.getVehicle and character:getVehicle() and character:getVehicle():getDriver() == character then
                baseReloadSpeed = baseReloadSpeed * 0.8
            end

            -- 確実に ReloadSpeed を設定（nil や未定義による後続アクションのクラッシュを完全防止）
            if character.setVariable then
                character:setVariable("ReloadSpeed", math.max(0.1, baseReloadSpeed))
            end
        end

        ISReloadWeaponAction._RT_Patched = true
        print("[RadioTrader][Patch] Successfully applied safe hotfix for ISReloadWeaponAction.setReloadSpeed.")
    end
end

-- 複数タイミングで確実に登録・適用
applyVanillaHotfixes()
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(applyVanillaHotfixes)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(applyVanillaHotfixes)
end
