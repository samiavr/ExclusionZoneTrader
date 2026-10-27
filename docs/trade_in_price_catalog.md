# 交易ドロップボックス 買取品価格カタログ (Trade-In Price Catalog)

**MOD名**: Exclusion Zone Trader (Project Zomboid Build 42)  
**対象バージョン**: v1.1.9 以降  
**更新日**: 2026-10-22  

拠点屋外に設置した「交易ドロップボックス（回収用コンテナ）」にアイテムを投入し、無線機から査定・回収を要請した際に買い取られるアイテムの一覧です。

---

## 目次
1. [買取査定の基本ルールと倍率](#1-買取査定の基本ルールと倍率)
2. [動的査定アイテム（スキル本・メディア・武器・カバン等）](#2-動的査定アイテム動的算出)
3. [静的買取品目一覧（カテゴリ別）](#3-静的買取品目一覧)
   - [一次資料・記録・書籍・メディア (Archives)](#31-一次資料記録書籍メディア-archives--literature)
   - [貴金属・宝石・高級時計 (Jewelry)](#32-貴金属宝石高級時計-jewelry)
   - [現金・紙幣・金融カード (Currency)](#33-現金紙幣金融カード-currency--financials)
   - [電線・電子部品・通信機器 (Electronics)](#34-電線電子部品通信機器-electronics--components)
   - [銃器・弾薬箱・マガジン (Firearms)](#35-銃器弾薬箱マガジン-firearms--tactical)
   - [新鮮な農作物 (Produce)](#36-新鮮な農作物-fresh-farm-produce)
4. [買取対象外アイテム（回収スキップ）](#4-買取対象外アイテム回収スキップ)

---

## 1. 買取査定の基本ルールと計算式

最終査定額は以下の計算式で決定されます：
$$\text{合計獲得CR} = \sum (\text{基準単価} \times \text{買取倍率 (既定: 0.5)} \times \text{耐久度係数} \times \text{新鮮度係数}) + \text{積載重量固定ボーナス}$$

- **サンドボックス買取倍率**: デフォルトは `0.5`（基準単価の50%）。サンドボックス設定で調整可能。
- **コンディション（耐久度）**: 破損しているアイテムは耐久残量に応じて減額（最低0.1倍）。
- **新鮮度（食品・農作物）**: 新鮮な状態は1.0倍、鮮度が落ちた食品（not fresh）は0.5倍、腐敗（rotten）は0 CR。
- **積載重量マイルストーン固定ボーナス (Bulk Cargo Weight Milestones)**:
  実際に売却・削除されたアイテムの**総実重量（kg）**に応じて、査定額に固定の追加CRが付与されます（※売却対象外のゴミは除外されるため水増し不可）：
  - **25.0 kg** 以上: **+60 CR**（小型貨物ボーナス）
  - **35.0 kg** 以上: **+120 CR**（標準貨物ボーナス）
  - **45.0 kg** 以上: **+200 CR**（木箱満杯達成・**ドローン配送料 200 CR を全額相殺！**）
  - **55.0 kg** 以上: **+280 CR**（「整理整頓」特性時の限界満載特大ボーナス）

---

## 2. 動的査定アイテム（動的算出）

静的リストに載っていないアイテムでも、以下の条件に該当するものはJava/Luaエンジンが動的に種別や状態を判定して適正価格で買い取ります。

### ① 技能スキル本 (Skill Books Vol 1〜5)
| 段階 | 対象レベル | 基準単価 (CR) | 備考 |
| :--- | :--- | :---: | :--- |
| **Vol 1 (初級)** | レベル 1〜2 | **4 CR** | Carpentry, Cooking, Farming, Mechanics, Electricity 等全種 |
| **Vol 2 (中級)** | レベル 3〜4 | **6 CR** | 初級に続く技能修得書 |
| **Vol 3 (上級)** | レベル 5〜6 | **8 CR** | 専門技能書 |
| **Vol 4 (熟練)** | レベル 7〜8 | **10 CR** | 高度な専門書 |
| **Vol 5 (達人)** | レベル 9〜10 | **12 CR** | 達人級の学術技術書 |
| **未知・MODスキル本** | 不明 | **6 CR** | 判定フォールバック |

### ② レシピ雑誌・クラフト解禁マニュアル (Recipes & Manuals)
| アイテム分類 | 基準単価 (CR) | 備考 |
| :--- | :---: | :--- |
| **レシピ雑誌全種 (全86種)** | **10 CR** | 発電機取扱説明書 (`ElectronicsMag4`)、鍛冶・金属加工 (`SmithingMag1〜11`)、防具、料理、罠、車両マニュアル等すべて対象（転売防止のため一律10 CR） |
| **一般文庫本・文学小説** | **10 CR** | `Base.Book` および文庫本オブジェクト（一次資料枠） |

### ③ 記録メディア (VHSビデオテープ & 音楽CD)
| メディア種別 | 基準単価 (CR) | 備考 |
| :--- | :---: | :--- |
| **技能スキルVHSテープ** | **15 CR** | Woodcraft, Cook Show, Exposure Survival, Carzone, Tailoring 101 等全72種（番組データまたはタイトル判定で高額買取） |
| **一般映画・ホームビデオ** | **6 CR** | `Base.VHS_Retail`, `Base.VHS_Home`（娯楽文化記録） |
| **音楽CD (Disc)** | **4 CR** | `Base.Disc_Retail`（音楽ディスク） |
| **ポータブルCDプレイヤー** | **12 CR** | オーディオ・電化製品枠 |

### ④ 銃器・装填マガジン・バラ弾・パーツ
| 種別 | 基準単価 (CR) | 備考 |
| :--- | :---: | :--- |
| **ライフル / ショットガン** | **45 CR** | M16, M14, レミントン, ダブルバレル等長物銃器 |
| **ハンドガン / リボルバー** | **25 CR** | M9, コルト, マグナム, .38等ピストル類 |
| **マガジン (弾薬装填済)** | **マガジン単価 + 中身弾薬** | 中身の弾薬数を自動合算して査定（空マガジンは10〜15 CR） |
| **バラ弾 (Loose Ammo)** | **ロット集計** | 種類ごとにコンテナ内の全バラ弾を集計して適正単価で換金 |
| **銃器アタッチメント・パーツ** | **12 CR** | スコープ、チョーク、スリング、レーザーサイト等 |

### ⑤ 近接武器・工具・刃物 (Melee Weapons - v1.2.3 最大耐久度・鋭さ連動査定)
| 武器ランク | 基準単価 (CR) | 主な対象アイテム |
| :--- | :---: | :--- |
| **Tier 1: 超希少・大型・高威力** | **28〜45 CR** | 日本刀 (45), マチェット (35), 消防斧・両手斧 (28), スレッジハンマー・ツルハシ (28), 斧頭 (15) |
| **Tier 2: 実用近接・中型道具** | **10〜16 CR** | 狩猟ナイフ・軍用ナイフ (16), 手斧 (15), バール (14), 野球バット (12), シャベル (12), 園芸フォーク・鍬 (10) |
| **Tier 3: 一般日用品・小型刃物・鈍器** | **6〜8 CR** | 肉切り包丁 (8), 鉄パイプ・金属棒 (8), 金槌・木槌 (8), ゴルフクラブ (8), キッチン包丁 (6), 手製槍 (6), 警棒・アイスピック・ハサミ (6) |
| **Tier 4: 杭・木板** | **3 CR** | 木の杭 (3), 木板 (3) |
| **Tier 5: 簡易カトラリー** | **2 CR** | バターナイフ (2), スプーン・フォーク (2), レターオープナー (2), メス (2) 等 |
| **フォールバック（上記以外の全近接武器）** | **8 CR** | フライパン, 鍋, ギター, ローリングピン, ペン, 各種MOD近接武器など |

> **v1.2.3 状態査定・手入れ補正**:
> - **最大耐久度劣化補正（リペア劣化と名工品）**:
>   - ダクトテープ等の修理で最大耐久度が落ちた武器は、基本最大耐久度に対する比率で減額（修理による満額偽装を防止）。
>   - 鍛冶・木工の達人が製作した高品質武器（標準以上の最大耐久度）は、最大 1.3倍 までプレミア加算。
> - **刃物の鋭さ補正（B42 Sharpness / 砥石手入れボーナス）**:
>   - 研ぎ澄まされた刃（Sharpness $\ge$ 0.9）: **+20% 査定ボーナス (1.2倍)**（表示名に `+` タグ付与）
>   - 通常切れ味（Sharpness 0.5〜0.8）: **標準価格 (1.0倍)**
>   - ナマクラ・刃こぼれ（Sharpness $<$ 0.5）: **-20% 減額 (0.8倍)**（表示名に `-` タグ付与）

### ⑥ カバン・コンテナ類 (Bags & Containers)
| コンテナランク | 基準単価 (CR) | 主な対象アイテム |
| :--- | :---: | :--- |
| **Tier 1: 大型バッグ・ハードケース** | **8 CR** | 大型登山リュック, 軍用アリスパック, サバイバーバッグ, ガンケース, 弾薬缶等 |
| **Tier 2: 一般バッグ・木箱・工具箱** | **4 CR** | スクールバッグ, ダッフルバッグ, トートバッグ, 工具箱, 救急箱, クーラーボックス等 |
| **Tier 3: 簡易袋・ポーチ・小箱** | **2 CR** | ごみ袋, レジ袋, 麻袋, サッチェル, ウエストポーチ, 財布, ランチボックス等 |
※**安全保護機能**: カバンの中に「回収対象外のアイテム」が残っている場合、プレイヤーの大切な私物を誤消滅させないよう、カバン自体の売却が自動的にスキップされます。

### ⑦ 家具・設備 (Moveables)
- プレイヤーが製作・運搬可能な木工家具、椅子、テーブル、箱などは、解体素材以上の価値として動的に査定・買取されます。

### ⑧ スカベンジャー募集チラシ (討伐褒章・特別一次資料)
- **基準単価**: **100 CR**
- ゾンビ討伐数や生存日数などの戦果が記録された募集チラシは、本土の軍部・民間軍事会社への貴重な戦闘データとして高額買取されます。

### ⑨ 新鮮な農作物 (Fresh Farm Produce: 満腹度・新鮮度連動動的査定)
- **満腹度（Hunger）連動**: 食品の満腹度ポイント（`HungerChange`）に応じて基礎価格を動的算出（**満腹度 10 あたり 1.0 CR**）。
  - スイカ (丸ごと / 満腹度 120): **12.0 CR**
  - カボチャ (丸ごと / 満腹度 80): **8.0 CR**
  - キャベツ (満腹度 24): **2.4 CR**
  - ジャガイモ (満腹度 18): **1.8 CR**
  - トマト (満腹度 12): **1.2 CR**
  - スライスカットしたスイカ (1切れ / 満腹度 15): **1.5 CR**（8切れで丸ごと1玉と完全一致）
- **ハーブ・調味料・軽量作物の最低保証**: 満腹度が低いハーブ類やベリー類でも、生鮮品として **最低 1.0 CR** を保証。
- **新鮮度（Freshness）の乗算**: 朝採れ・新鮮（1.0倍） / 鮮度落ち（0.5倍・半額） / 腐敗（0 CR・回収対象外）。
- **農協一括出荷ボーナス**: 農作物の出荷個数が **10個ごとに +10 CR** の固定ロットボーナスが合算。
- **重量のダブル恩恵**: 重量のあるスイカやカボチャは、それ自体の満腹度CRに加え、**積載重量マイルストーン固定ボーナス（25kg〜55kgで +60〜280 CR）**の達成にも貢献。

### ⑩ なめし革・皮革資材 (Tanned Leathers - 3段階動的査定)
B42で追加された畜産・狩猟・革なめしの成果物を3段階で適正査定します（※未完成の濡れた`_Wet`状態、およびゾンビ服解体による`LeatherStrips`は無限量産防止のため除外）：
| 段階・規模 | 基準単価 (CR) | 実効買取額 (0.5倍) | 主な対象アイテム |
| :--- | :---: | :---: | :--- |
| **大（本格資材）** | **25 CR** | 12.5 CR | 成牛革 (`CowLeather_*_Full`), 鹿革 (`DeerLeather_Full`), 成豚革 (`PigLeather_*_Full`), 大型なめし粗皮 (`Leather_Crude_Large_Tan`) |
| **中（安価資材）** | **12 CR** | 6.0 CR | 中型なめし粗皮 (`Medium_Tan`), 子牛革, 羊革, 子羊革, 子豚革, 小鹿革 (`*_Full`) |
| **小（はした金 / 小型動物皮）** | **3 CR** | 1.5 CR | 小型なめし粗皮 (`Small_Tan`), ウサギ革, アライグマ革 (`*_Full`) |

### ⑪ 繊維・布・裁縫資材 (Textiles & Cordage)
野戦病院の包帯原料、軍用テント・防護服の縫製資材としての需要（※糸・より糸は使用残量連動）：
| アイテム名 | アイテムID | 基準単価 (CR) | 実効買取額 (0.5倍) | 備考 |
| :--- | :--- | :---: | :---: | :--- |
| **手縫い糸** | `Base.Thread` | **4 CR** | 2.0 CR | 残量（`UsedDelta`）に比例（満タンで4 CR） |
| **より糸** | `Base.Twine` | **3 CR** | 1.5 CR | 残量比例（満タンで3 CR） |
| **シーツ** | `Base.Sheet` | **5 CR** | 2.5 CR | まとまった綿布資材 |
| **ロープ** | `Base.Rope` | **8 CR** | 4.0 CR | 結束・牽引資材 |
| **防水シート (タープ)** | `Base.Tarp` | **15 CR** | 7.5 CR | 工業用厚手防水布 |

### ⑫ 貴金属・宝石・時計・地金経済 (Precious Metals, Gems, Watches & Ingots - v1.2.2)
B42バニラのクラフト機能（プライヤー等でアクセサリーを分解して宝石を取り外し、金属スクラップを精錬する）に合わせ、**「そのまま売るより、分解・クラフトした方が2倍以上高く売れる」**経済インセンティブ設計を採用しています：
- **アクセサリー完成品（買い叩きペナルティ）**: 未分解のまま売ると、鑑定・解体手間賃が引かれ安価（金ダイヤ指輪 25 CR、金指輪 12 CR、銀指輪 6 CR）。
- **分解した宝石（ルース宝石 / 高額買取）**: ダイヤモンド (50 CR)、ルビー (35 CR)、サファイア (30 CR)、エメラルド (30 CR)、アメジスト (25 CR)。
- **金属スクラップ・地金インゴット（クラフト成果換金）**: 金インゴット (120 CR)、銀インゴット (60 CR)、小型金インゴット (30 CR)、金スクラップ (3 CR)。
- **時計類（引き締め適正化）**: 高級・金時計 (20〜25 CR)、ミリタリーウォッチ (12 CR)、一般クラシック時計 (6 CR)。

> **クラフト実例**:
> - **金ダイヤ指輪をそのまま売却**: 25 CR（実効 12.5 CR）
> - **プライヤーで分解して売却**: ダイヤモンド (50 CR) + 金スクラップ (3 CR) = **53 CR（実効 26.5 CR / +28 CRのクラフトボーナス！）**

---

## 3. 静的買取品目一覧

### 3.1 一次資料・記録・書籍・メディア (Archives & Literature)
登録件数: **28 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Diary | `Base.Diary1` | **40 CR** | 20 CR |
| Diary | `Base.Diary2` | **40 CR** | 20 CR |
| Journal | `Base.Journal` | **40 CR** | 20 CR |
| Handwritten Letter | `Base.LetterHandwritten` | **30 CR** | 15 CR |
| Notebook | `Base.Notebook` | **25 CR** | 12.5 CR |
| Notepad | `Base.Notepad` | **25 CR** | 12.5 CR |
| Official Document | `Base.OfficialDocument` | **25 CR** | 12.5 CR |
| Sheet Music | `Base.SheetMusic` | **20 CR** | 10 CR |
| Stock Certificate | `Base.StockCertificate` | **20 CR** | 10 CR |
| Postal Mail | `Base.GenericMail` | **17 CR** | 8.5 CR |
| Survivor Note | `Base.Note` | **17 CR** | 8.5 CR |
| Adult Magazine | `Base.HottieZ` | **15 CR** | 7.5 CR |
| Postcard | `Base.Postcard` | **15 CR** | 7.5 CR |
| Brochure / Flyer | `Base.Brochure` | **12 CR** | 6 CR |
| Comic Book | `Base.ComicBook` | **12 CR** | 6 CR |
| Paperwork / File | `Base.Paperwork` | **12 CR** | 6 CR |
| Book | `Base.Book` | **10 CR** | 5 CR |
| Piece of Paper | `Base.SheetPaper2` | **7 CR** | 3.5 CR |
| Crossword Magazine | `Base.MagazineCrossword` | **6 CR** | 3 CR |
| Magazine | `Base.Magazine` | **6 CR** | 3 CR |
| Mail Order Catalog | `Base.Catalog` | **6 CR** | 3 CR |
| TV Guide Magazine | `Base.TVMagazine` | **6 CR** | 3 CR |
| VHS Tape (Home) | `Base.VHS_Home` | **6 CR** | 3 CR |
| VHS Tape (Retail) | `Base.VHS_Retail` | **6 CR** | 3 CR |
| Wordsearch Magazine | `Base.MagazineWordsearch` | **6 CR** | 3 CR |
| CD Disc (Music) | `Base.Disc_Retail` | **4 CR** | 2 CR |
| Receipt | `Base.Receipt` | **4 CR** | 2 CR |
| Newspaper | `Base.Newspaper` | **3 CR** | 1.5 CR |

### 3.2 貴金属・アクセサリー (Jewelry: 完成品・買い叩き価格)
登録件数: **42 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Gold Diamond Ring | `Base.Ring_Right_RingFinger_GoldDiamond` | **25 CR** | 12.5 CR |
| Gold Diamond Ring | `Base.Ring_Left_RingFinger_GoldDiamond` | **25 CR** | 12.5 CR |
| Gold Diamond Ring | `Base.Ring_Right_MiddleFinger_GoldDiamond` | **25 CR** | 12.5 CR |
| Gold Diamond Ring | `Base.Ring_Left_MiddleFinger_GoldDiamond` | **25 CR** | 12.5 CR |
| Gold Diamond Necklace | `Base.Necklace_GoldDiamond` | **25 CR** | 12.5 CR |
| Gold Diamond Necklace | `Base.NecklaceLong_GoldDiamond` | **25 CR** | 12.5 CR |
| Diamond Choker | `Base.Necklace_Choker_Diamond` | **25 CR** | 12.5 CR |
| Gold Ruby Ring | `Base.Ring_Right_RingFinger_GoldRuby` | **20 CR** | 10 CR |
| Gold Ruby Ring | `Base.Ring_Left_RingFinger_GoldRuby` | **20 CR** | 10 CR |
| Gold Ruby Ring | `Base.Ring_Right_MiddleFinger_GoldRuby` | **20 CR** | 10 CR |
| Gold Ruby Ring | `Base.Ring_Left_MiddleFinger_GoldRuby` | **20 CR** | 10 CR |
| Pearl Necklace | `Base.Necklace_Pearl` | **20 CR** | 10 CR |
| Gold Ruby Necklace | `Base.Necklace_GoldRuby` | **20 CR** | 10 CR |
| Silver Diamond Ring | `Base.Ring_Right_RingFinger_SilverDiamond` | **15 CR** | 7.5 CR |
| Silver Diamond Ring | `Base.Ring_Left_RingFinger_SilverDiamond` | **15 CR** | 7.5 CR |
| Silver Diamond Ring | `Base.Ring_Right_MiddleFinger_SilverDiamond` | **15 CR** | 7.5 CR |
| Silver Diamond Ring | `Base.Ring_Left_MiddleFinger_SilverDiamond` | **15 CR** | 7.5 CR |
| Silver Diamond Necklace | `Base.Necklace_SilverDiamond` | **15 CR** | 7.5 CR |
| Gold Ring | `Base.Ring_Right_RingFinger_Gold` | **12 CR** | 6 CR |
| Gold Ring | `Base.Ring_Left_RingFinger_Gold` | **12 CR** | 6 CR |
| Gold Ring | `Base.Ring_Right_MiddleFinger_Gold` | **12 CR** | 6 CR |
| Gold Ring | `Base.Ring_Left_MiddleFinger_Gold` | **12 CR** | 6 CR |
| Gold Necklace | `Base.Necklace_Gold` | **12 CR** | 6 CR |
| Gold Necklace | `Base.NecklaceLong_Gold` | **12 CR** | 6 CR |
| Silver Sapphire Necklace | `Base.Necklace_SilverSapphire` | **12 CR** | 6 CR |
| Signet Ring | `Base.Ring_Right_RingFinger_Signet` | **10 CR** | 5 CR |
| Signet Ring | `Base.Ring_Left_RingFinger_Signet` | **10 CR** | 5 CR |
| Signet Ring | `Base.Ring_Right_MiddleFinger_Signet` | **10 CR** | 5 CR |
| Signet Ring | `Base.Ring_Left_MiddleFinger_Signet` | **10 CR** | 5 CR |
| Gold Hoop Earrings | `Base.Earring_LoopLrg_Gold` | **10 CR** | 5 CR |
| Gold Hoop Earrings | `Base.Earring_LoopMed_Gold` | **8 CR** | 4 CR |
| Silver Crucifix | `Base.Necklace_SilverCrucifix` | **8 CR** | 4 CR |
| Gold Stud Earrings | `Base.Earring_LoopSmall_Gold_Both` | **6 CR** | 3 CR |
| Silver Necklace | `Base.Necklace_Silver` | **6 CR** | 3 CR |
| Silver Necklace | `Base.NecklaceLong_Silver` | **6 CR** | 3 CR |
| Silver Ring | `Base.Ring_Right_RingFinger_Silver` | **6 CR** | 3 CR |
| Silver Ring | `Base.Ring_Left_RingFinger_Silver` | **6 CR** | 3 CR |
| Silver Ring | `Base.Ring_Right_MiddleFinger_Silver` | **6 CR** | 3 CR |
| Silver Ring | `Base.Ring_Left_MiddleFinger_Silver` | **6 CR** | 3 CR |
| Silver Hoop Earrings | `Base.Earring_LoopLrg_Silver` | **5 CR** | 2.5 CR |
| Silver Hoop Earrings | `Base.Earring_LoopMed_Silver` | **4 CR** | 2 CR |
| Crucifix Necklace | `Base.Necklace_Crucifix` | **4 CR** | 2 CR |

### 3.3 単体宝石類 (Gems: ルース宝石・高額買取)
登録件数: **5 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Cut Diamond | `Base.Diamond` | **50 CR** | 25 CR |
| Cut Ruby | `Base.Ruby` | **35 CR** | 17.5 CR |
| Cut Sapphire | `Base.Sapphire` | **30 CR** | 15 CR |
| Cut Emerald | `Base.Emerald` | **30 CR** | 15 CR |
| Cut Amethyst | `Base.Amethyst` | **25 CR** | 12.5 CR |

### 3.4 地金・インゴット・金属スクラップ (Ingots & Metal Scrap)
登録件数: **10 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Gold Ingot (Large) | `Base.GoldBar` | **120 CR** | 60 CR |
| Silver Ingot (Large) | `Base.SilverBar` | **60 CR** | 30 CR |
| Gold Ingot (Small) | `Base.SmallGoldBar` | **30 CR** | 15 CR |
| Steel Ingot | `Base.SteelIngot` | **20 CR** | 10 CR |
| Silver Ingot (Small) | `Base.SmallSilverBar` | **15 CR** | 7.5 CR |
| Brass Ingot | `Base.BrassIngot` | **15 CR** | 7.5 CR |
| Copper Ingot | `Base.CopperIngot` | **12 CR** | 6 CR |
| Iron Ingot | `Base.IronIngot` | **8 CR** | 4 CR |
| Gold Scrap | `Base.GoldScrap` | **3 CR** | 1.5 CR |
| Silver Scrap | `Base.SilverScrap` | **1.5 CR** | 0.75 CR |

### 3.5 時計・懐中時計・アンティーク (Antiques & Watches)
登録件数: **10 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Antique Pocketwatch | `Base.Pocketwatch` | **25 CR** | 12.5 CR |
| Luxury Watch | `Base.WristWatch_Right_Expensive` | **25 CR** | 12.5 CR |
| Classic Gold Watch | `Base.WristWatch_Right_ClassicGold` | **20 CR** | 10 CR |
| Classic Gold Watch | `Base.WristWatch_Left_ClassicGold` | **20 CR** | 10 CR |
| Military Watch | `Base.WristWatch_Right_ClassicMilitary` | **12 CR** | 6 CR |
| Military Watch | `Base.WristWatch_Left_ClassicMilitary` | **12 CR** | 6 CR |
| Classic Watch | `Base.WristWatch_Right_ClassicBlack` | **6 CR** | 3 CR |
| Classic Watch | `Base.WristWatch_Left_ClassicBlack` | **6 CR** | 3 CR |
| Classic Watch | `Base.WristWatch_Right_ClassicBrown` | **6 CR** | 3 CR |
| Classic Watch | `Base.WristWatch_Left_ClassicBrown` | **6 CR** | 3 CR |

### 3.6 現金・紙幣・金融カード (Currency & Financials)
登録件数: **4 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Money Bundle | `Base.MoneyBundle` | **50 CR** | 25 CR |
| Credit Card | `Base.CreditCard` | **2 CR** | 1 CR |
| Stolen Credit Card | `Base.CreditCard_Stolen` | **2 CR** | 1 CR |
| Cash (Bill/Coin) | `Base.Money` | **1 CR** | 0.5 CR |

### 3.7 金属素材・工業資源 (Industrial Materials)
登録件数: **5 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Tarp | `Base.Tarp` | **15 CR** | 7.5 CR |
| Rope | `Base.Rope` | **8 CR** | 4 CR |
| Sheet | `Base.Sheet` | **5 CR** | 2.5 CR |
| Thread | `Base.Thread` | **4 CR** | 2 CR |
| Twine | `Base.Twine` | **3 CR** | 1.5 CR |

### 3.8 電線・電子部品・通信機器 (Electronics & Components)
登録件数: **9 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Motion Sensor | `Base.MotionSensor` | **25 CR** | 12.5 CR |
| Radio Transmitter Unit | `Base.RadioTransmitter` | **25 CR** | 12.5 CR |
| Radio Receiver Unit | `Base.RadioReceiver` | **20 CR** | 10 CR |
| Signal Amplifier | `Base.Amplifier` | **20 CR** | 10 CR |
| Receiver Board | `Base.Receiver` | **15 CR** | 7.5 CR |
| CD Player | `Base.CDPlayer` | **12 CR** | 6 CR |
| Electronics Scrap | `Base.ElectronicsScrap` | **5 CR** | 2.5 CR |
| Electric Wire | `Base.ElectricWire` | **4 CR** | 2 CR |
| Scrap Metal | `Base.ScrapMetal` | **2 CR** | 1 CR |

### 3.9 銃器・弾薬箱・マガジン (Firearms & Tactical)
登録件数: **16 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Double Barrel Shotgun | `Base.DoubleBarrelShotgun` | **45 CR** | 22.5 CR |
| Hunting Rifle | `Base.HuntingRifle` | **45 CR** | 22.5 CR |
| L92 Lever-Action Carbine | `Base.L92_Carbine` | **45 CR** | 22.5 CR |
| L94 Lever-Action Rifle | `Base.L94_Rifle` | **45 CR** | 22.5 CR |
| M14 Rifle | `Base.AssaultRifle2` | **45 CR** | 22.5 CR |
| M16 Assault Rifle | `Base.AssaultRifle` | **45 CR** | 22.5 CR |
| Sawnoff Double Barrel | `Base.DoubleBarrelShotgunSawnoff` | **45 CR** | 22.5 CR |
| Sawnoff Shotgun | `Base.ShotgunSawnoff` | **45 CR** | 22.5 CR |
| Shotgun | `Base.Shotgun` | **45 CR** | 22.5 CR |
| Varmint Rifle | `Base.VarmintRifle` | **45 CR** | 22.5 CR |
| Magnum Pistol (.44) | `Base.Pistol3` | **25 CR** | 12.5 CR |
| Magnum Revolver (.44) | `Base.Revolver_Long` | **25 CR** | 12.5 CR |
| Pistol (.45) | `Base.Pistol2` | **25 CR** | 12.5 CR |
| Pistol (9mm) | `Base.Pistol` | **25 CR** | 12.5 CR |
| Revolver (.38) | `Base.Revolver` | **25 CR** | 12.5 CR |
| Snubnose Revolver | `Base.Revolver_Short` | **25 CR** | 12.5 CR |

### 3.10 新鮮な農作物 (Fresh Farm Produce)
登録件数: **34 品目**

| アイテム名 (DisplayName) | アイテムID (FullType) | 基準単価 (CR) | 実効買取額目安 (0.5倍) |
| :--- | :--- | :---: | :---: |
| Ginseng | `Base.Ginseng` | **3 CR** | 1.5 CR |
| Lemongrass | `Base.Lemongrass` | **3 CR** | 1.5 CR |
| Black Sage | `Base.BlackSage` | **2 CR** | 1 CR |
| Common Mallow | `Base.CommonMallow` | **2 CR** | 1 CR |
| Fresh Apple | `Base.Apple` | **2 CR** | 1 CR |
| Fresh Avocado | `Base.Avocado` | **2 CR** | 1 CR |
| Fresh Banana | `Base.Banana` | **2 CR** | 1 CR |
| Fresh Bell Pepper | `Base.BellPepper` | **2 CR** | 1 CR |
| Fresh Broccoli | `Base.Broccoli` | **2 CR** | 1 CR |
| Fresh Cabbage | `Base.Cabbage` | **2 CR** | 1 CR |
| Fresh Carrots | `Base.Carrots` | **2 CR** | 1 CR |
| Fresh Cherry | `Base.Cherry` | **2 CR** | 1 CR |
| Fresh Corn | `Base.Corn` | **2 CR** | 1 CR |
| Fresh Eggplant | `Base.Eggplant` | **2 CR** | 1 CR |
| Fresh Grapes | `Base.Grapes` | **2 CR** | 1 CR |
| Fresh Leek | `Base.Leek` | **2 CR** | 1 CR |
| Fresh Lemon | `Base.Lemon` | **2 CR** | 1 CR |
| Fresh Lettuce | `Base.Lettuce` | **2 CR** | 1 CR |
| Fresh Lime | `Base.Lime` | **2 CR** | 1 CR |
| Fresh Onion | `Base.Onion` | **2 CR** | 1 CR |
| Fresh Orange | `Base.Orange` | **2 CR** | 1 CR |
| Fresh Peach | `Base.Peach` | **2 CR** | 1 CR |
| Fresh Pineapple | `Base.Pineapple` | **2 CR** | 1 CR |
| Fresh Potato | `Base.Potato` | **2 CR** | 1 CR |
| Fresh Pumpkin | `Base.Pumpkin` | **2 CR** | 1 CR |
| Fresh Radish | `Base.RedRadish` | **2 CR** | 1 CR |
| Fresh Strawberry | `Base.Strewberrie` | **2 CR** | 1 CR |
| Fresh Tomato | `Base.Tomato` | **2 CR** | 1 CR |
| Fresh Watermelon | `Base.Watermelon` | **2 CR** | 1 CR |
| Fresh Zucchini | `Base.Zucchini` | **2 CR** | 1 CR |
| Plantain | `Base.Plantain` | **2 CR** | 1 CR |
| Sweet Potato | `Base.SweetPotato` | **2 CR** | 1 CR |
| Wild Garlic | `Base.WildGarlic` | **2 CR** | 1 CR |
| Wild Onion | `Base.WildOnion` | **2 CR** | 1 CR |

---

## 4. 買取対象外アイテム（回収スキップ）

以下のアイテムは、ドロップボックスに投入されていても**回収されずにコンテナ内に安全に残存**します（UIログに黄色で残存リストが表示されます）：

1. **腐敗した食品 (Rotten Food)**: 衛生上、回収対象外となります。
2. **回収対象外アイテムが入ったままのカバン**: 内部アイテムの誤消滅を防ぐためスキップされます。
3. **一般的な生活ゴミ・汚れた衣服・布切れ・革ひも・鍵**: ゾンビ服破きによる布切れ（`RippedSheets`）、革端切れ（`LeatherStrips`）、汚れた包帯、不要な鍵など。
4. **リスト未定義のアイテム**: 本一覧および動的査定条件のいずれにも合致しないMODアイテムなど。