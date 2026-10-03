# 実装計画: 契約農園・種プール ＆ 作物交換配達システム (Phase 7)

## 1. 概要
探索で得た種（バラ種、種袋）をラジオトレーダーのドロップボックス経由で預け入れ（プール）し、プールされた種を消費して「農作物用の箱(大)」に入った新鮮な作物をヘリ投下で受け取るシステム。
作物の収穫量はプレイヤーの耕作スキルレベル（Farming Lv）に連動し、配達時に実際の収穫と同等の農業経験値（Farming XP）を獲得できる。

---

## 2. 仕様定義

### 2.1 種の買取 ＆ プール蓄積
- **対象アイテムマッピング**:
  - **B42 全55種作物** の種袋（5個分）およびバラ種（1個分）を完全網羅。
  - イチゴについて:
    - 作物: `Base.Strewberrie`（表示名: `Strawberries` / `イチゴ`）
    - バラ種 (1個分): `Base.StrewberrieSeed`
    - 種袋 (5個分): `Base.StrewberrieBagSeed2`
  - 旧種袋ID（`Base.CabbageBagSeed`, `Base.CarrotBagSeed` 等）も互換性エイリアスとして +5個分 換算で対応。
- **買取ルール**:
  - ドロップボックス内の査定時、種アイテムは売却クレジット **0 CR**（プール専用）として扱われ、売却実行時にボックスから回収（削除）。
  - プレイヤーの永続ModData（`gmd.seedPool`）に種類ごとの個数を加算。
  - クライアントへの同期イベント（`CMD_SYNC_SEED_POOL`）でUI側でも即座に最新個数を反映。

### 2.2 取引UI ＆ 注文メニュー
- **新設カテゴリ**:
  - `[Crops] 農作物交換` タブを追加。
- **リスト表示**:
  - B42の全55作物を網羅。
  - `キャベツ (8個) - 5 CR` のように、現在の預け入れプール数を品名横に直接表示。
- **選択時詳細**:
  - ユーザー要望に基づきシンプルに **「預け入れプール数: X個」** のみ表示。
- **発注コスト ＆ 制約**:
  - 1個あたり **5 CR** ＋ **種プール 1個** を消費。
  - 種プールが 0 の場合はカート追加・発注ボタンを無効化（残数不足警告）。

### 2.3 収穫量計算 ＆ 農業経験値（Farming XP）付与
- **発注数に応じた収穫シミュレーション**:
  - 例: キャベツを 3 個発注した場合、3回分の収穫計算を実施。
  - プレイヤーの耕作Lv `farmingLevel = player:getPerkLevel(Perks.Farming)` (0〜10) を取得。
  - 1回あたりの基本収穫量:
    - バニラ基準（`farming_vegetableconf.props`、フォールバック付き）:
      - `minVal = prop.minVeg + (farmingLevel / 10) * (prop.minVegAutorized - prop.minVeg)`
      - `maxVal = prop.maxVeg + (farmingLevel / 10) * (prop.maxVegAutorized - prop.maxVeg)`
      - `fullYield = ZombRand(math.floor(minVal), math.ceil(maxVal) + 1)`
    - 指定の乱数比率（30%〜75%）を乗算:
      - `ratio = ZombRand(30, 76) / 100`
      - `yield = math.max(1, math.floor(fullYield * ratio + 0.5))`
  - 3回分合算した個数を算出。
- **農業経験値の付与**:
  - 発注数と同回数（上記例なら3回分）の収穫XPをプレイヤーに付与:
    - `player:getXp():AddXP(Perks.Farming, 6 * orderCount)`（1回あたりバニラ基準 6 XP）

### 2.4 配達コンテナ
- **農作物用の箱(大) (`Base.ProduceBox_Large`)**:
  - 作物発注時は木箱ではなく「農作物用の箱(大)」を生成し、その中に収穫した新鮮な作物を格納してLZコンテナへ配達。

---

## 3. 実装対象ファイル一覧
1. `RadioTraderMod/42/media/lua/shared/RadioTrader_ItemsTable.lua`
   - `RadioTrader_Shop.Crops` (全55作物の品目定義, 5 CR)
   - `RadioTrader_SeedMapping` (全55作物のバラ種・種袋マッピング, 117エントリ)
   - `RadioTrader_CropYieldDefaults` (全55作物の収穫パラメータ定義)
   - `RadioTrader_CalculateCropYield` (30%〜75%乱数計算)
2. `RadioTraderMod/42/media/lua/server/RadioTrader_ServerEngine.lua`
   - 種プールModData管理、0 CR売却（預託）処理、口数分XP付与、`ProduceBox_Large` 格納配達
3. `RadioTraderMod/42/media/lua/client/RadioTrader_UI.lua`
   - メニュー名横のプール数表示、選択時詳細のプール数のみ表示、プール残数チェック
4. `Translate/JP/UI.json`, `Translate/EN/UI.json`
   - 多言語UIテキスト
