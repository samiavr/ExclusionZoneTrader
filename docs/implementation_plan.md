# 実装計画: 銃器ダッフルバッグの銃器・マガジン・弾薬ワンセット充填システム (v1.1.6)

## 1. 概要・目標
プレイヤーが「銃器ダッフルバッグ（Arms & Ammo Duffel Bag）」を購入した際、従来は完全ランダム抽選により「銃本体が出てもマガジンがない」「マガジンが一切出ない」という事態が発生していた。
これを改善し、**銃本体が当選した瞬間に対応マガジン（1個）＋対応バラ弾（5〜20発）をセットで同梱して充填を完了する**スマートな充填システムを実装する。

---

## 2. 仕様詳細

### (1) 充填フロー設計 (`RadioTrader_ItemsTable_FillWeaponsBag`)
1. **充填目標数**: `targetCount` (minItems=3 〜 maxItems=8) を決定。
2. **抽選ループ**: 最大 `targetCount` 回まで、アイテムを1品ずつ抽選（ProceduralDistributions または customItems）。
3. **銃器当選判定 (`isGun`)**:
   - 当選アイテムが遠隔武器（`isRanged` または `RadioTrader_WeaponSpecs` に登録された銃器）か判定。
   - **銃器当選時**:
     1. その銃本体をダッフルバッグに追加。
     2. その銃に対応するマガジン（`spec.mag`）が定義されている場合、マガジンを **1個** 生成してバッグに追加。
     3. その銃に対応する弾丸（`spec.ammo`）を **5〜20発（ランダム）** 生成してバッグに追加。
     4. **充填ループを即座に終了（break）**。
   - **銃器非当選時**:
     - 抽選されたアイテム（弾薬箱、バラ弾、マガジン等）をそのままバッグに追加し、ループを継続。
4. **銃器が出なかった場合**:
   - `targetCount`（3〜8個）に達するまで通常アイテム（弾薬、パーツ、予備マガジン等）が充填されて終了。

### (2) 銃器スペックマッピングテーブル (`RadioTrader_WeaponSpecs`)
PZ B42の主要銃器に対応するマガジンIDおよびバラ弾IDを定義：
```lua
RadioTrader_WeaponSpecs = {
    ["Base.Pistol"]                     = { mag = "Base.9mmClip",  ammo = "Base.Bullets9mm" },
    ["Base.Pistol2"]                    = { mag = "Base.45Clip",   ammo = "Base.Bullets45" },
    ["Base.Pistol3"]                    = { mag = "Base.44Clip",   ammo = "Base.Bullets44" },
    ["Base.AssaultRifle"]               = { mag = "Base.556Clip",  ammo = "Base.556Bullets" },
    ["Base.AssaultRifle2"]              = { mag = "Base.M14Clip",  ammo = "Base.308Bullets" },
    ["Base.HuntingRifle"]               = { mag = "Base.308Clip",  ammo = "Base.308Bullets" },
    ["Base.VarmintRifle"]               = { mag = "Base.223Clip",  ammo = "Base.223Bullets" },
    ["Base.Revolver"]                   = { mag = nil,             ammo = "Base.Bullets38" },
    ["Base.Revolver_Short"]             = { mag = nil,             ammo = "Base.Bullets38" },
    ["Base.Revolver_Long"]              = { mag = nil,             ammo = "Base.Bullets44" },
    ["Base.Shotgun"]                    = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.DoubleBarrelShotgun"]        = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.ShotgunSawnoff"]             = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.DoubleBarrelShotgunSawnoff"] = { mag = nil,             ammo = "Base.ShotgunShells" },
    ["Base.L94_Rifle"]                  = { mag = nil,             ammo = "Base.3030Bullets" },
    ["Base.L92_Carbine"]                = { mag = nil,             ammo = "Base.Bullets357" },
}
```
※未知のMOD銃器の場合でも、`item:isRanged()` および `item:getMagazineType()`, `item:getAmmoType()` で動的フォールバック。

### (3) クレート定義へのフラグ追加 (`RadioTrader_Crate_Weapons`)
- `isWeaponsBag = true` を設定。
- `RadioTrader_ItemsTable_FillDuffelBag` 内で `crateDef.isWeaponsBag` の場合に `RadioTrader_ItemsTable_FillWeaponsBag` を呼び出す。

---

## 3. 影響範囲
- `RadioTraderMod/42/media/lua/shared/RadioTrader_ItemsTable.lua`
- `RadioTraderMod/common/mod.info` (v1.1.6 へのバージョンアップ)
- `RadioTraderMod/42/mod.info`
- `task.md`

---

## 4. 検証手順
1. **Pythonシミュレーションテスト (`tmp/test_weapon_bag.py`)**:
   - 銃器当選時に銃＋マガジン1個＋弾丸5〜20発が正確に同梱されて即時終了すること。
   - 銃器非当選時に3〜8個の物資が充填されること。
   - 10,000回シミュレーションし、銃当選率、マガジン同梱率、弾丸数分布を検証。
   - オフ・コンテキスト・ロギング（レポート保存 ＆ 1行通知）。
2. **MOD整合性チェック (`scripts/check_mod_health.py`)**:
   - 構文エラー、未定義参照、I18N警告がないことを確認。
