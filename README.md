# Exclusion Zone Trader (B42) - 隔離地域外トレーダー

![Project Zomboid B42](https://img.shields.io/badge/Project%20Zomboid-Build%2042-orange?style=flat-square)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Multiplayer Supported](https://img.shields.io/badge/Multiplayer-Single%20%26%20Server-green?style=flat-square)
![Language: EN & JP](https://img.shields.io/badge/Language-English%20%7C%20%E6%97%A5%E6%9C%AC%E8%AA%9E-brightgreen?style=flat-square)

**Exclusion Zone Trader** は、ノックス州（隔離地域）封鎖線の外にいる外部組織・商人・有志補給部隊と無線通信を行い、物資の売買および輸送ヘリコプターによる支援物資投下・回収を行う **Project Zomboid Build 42 対応** の本格交易＆拠点防衛 MOD です。

---

## 📻 世界観・背景ストーリー (Lore & Background)

> **「ノックス州の封鎖線は維持された。だが、檻の中の俺たちは見捨てられた。」**
>
> 感染の封じ込め（隔離）自体は成功し、隔離線の向こう側――「外の世界」には辛うじて政府や軍、市民社会の文明と経済が保たれている。
> しかし、隔離地域（ノックス郡全域）があまりにも広大すぎるため、外の政府も電気や水道といったライフラインを復旧させることはできず、ワクチンや治療法も存在しないため地上部隊を派遣しての救出・奪還も不可能と判断された。
> 
> さらに、感染拡大パニックを防ぐ情報統制と外部連携遮断のため、隔離地域全域には**強力な電波隔離（ジャミング）**が敷かれている。
> 
> あなたは偶然、軍や検問の監視をかいくぐる**特定の秘密周波数（104.8 MHz）**を見つけ出した。
> そのノイズの向こう側にいたのは、外の世界で生きる密輸業者や有志の補給部隊だった。
> 地上への立ち入りは感染リスクが高すぎるため、取引は**「ヘリコプターによる超短時間の物資投下（LZ指定）」**しか行えない。
> 
> 遠く離れた外の世界と命がけで繋がり、ヘリの爆音に引き寄せられるゾンビの群れを迎え撃ちながら、この巨大な隔離地域を生き延びろ。

---

## 🚁 主要機能と特徴 (Key Features)

### 1. 隔離地域外との無線通信トレード (Radio Communication)
- HAMラジオやトランシーバーの周波数を **`104.8 MHz`** に合わせることで、外部交易ネットワークに接続。
- 食料、医療品、弾薬、工具、建材、発電機などのライフライン物資、日替わりレア品を発注可能。
- 屋外に設置したコンテナを「**ランディングゾーン（LZ）**」として登録し、安全に取引を行います。

### 2. 輸送ヘリコプター投下 ＆ 臨場感あふれるサーチライト演出 (Heli Delivery & Searchlight)
- 発注後、ゲーム内時間に応じて支援ヘリが指定の LZ へ飛来。
- **夜間・薄暗い時間帯のサーチライト照射**:
  ヘリが LZ 直上に到着してホバリングしている間、上空から地上を強烈に照らすサーチライトが点灯。

### 3. 動的防衛戦とリスク＆リターン (Zombie Wave & Popman Integration)
- **リポップOFF環境の救世主**:
  ヘリのローター音（音響半径 400〜600 タイル）により、広域のゾンビが投下地点へ引き寄せられます。
- **遠隔仮想ホード（Popman）＋近接コーンスポーンのハイブリッド波状突撃**:
  遠方から行進してくる仮想ホードと、進行方向のコーン状から現れる先駆けゾンビが連携。ヘリ到着前後に外周から一気に雪崩れ込んでくるスリリングな波（ウェーブ）が発生します。
- **大規模ホード（Mega Horde）危機イベント**:
  低確率（設定可能）で通常の 2.5 倍の超巨大ホードと緊迫無線通信が発生！

### 4. 経済バランス ＆ ドロップボックス換金・ロット出荷 (Balanced Economy & Lot Trading)
- 物資の価値が高いバランス（購入高め・買取適正）により、サバイバルゲームの緊張感を維持します。
- ゾンビや財布から手に入る **「現金」「札束」「クレジットカード」** や貴金属・アンティーク時計は、ドロップボックスに入れて無線機から換金可能！
- **生鮮品・農作物のロット出荷**:
  魚の切り身・生肉、朝採れ卵、農作物等、腐らせてしまう前にドロップボックスに入れて換金！足りない資材を購入する元手に。

### 5. 「他に何かないか？」日替わり物資 ＆ おまけ同封 (Daily Deals & Perks)
- 毎日午前0時に更新される日替わり特売枠。
- 少額の CR を支払って「他に何かないか？」と無線で打診（リロール）可能。
- 気前のいい商人が注文箱にランダムな「おまけアイテム」を同封してくれることも！

---

## 🎮 クイックスタート・遊び方 (Quick Start Guide)

```text
[1. LZ登録]           [2. 不用品を投入]         [3. 無線機で発注]         [4. ヘリ到着・防衛]
屋外のコンテナを   ──> ドロップボックスに   ──> 周波数を 104.8 MHz  ──> サーチライトが点灯！
右クリックして登録      不用品・資材を投入       下取り相殺でまとめ発注！   ゾンビを撃退し物資回収！
```

1. **ドロップボックス（LZ）の指定**:
   - 屋外にある木箱や金属キャビネットなどのコンテナを右クリックし、`[交易ドロップボックス/LZに指定]` を選択します。
2. **不用品の下取り投入**:
   - ドロップボックスに、探索で拾った現金・カード、指輪・貴金属、中古工具、車両パーツ、家具、軍用品、農作物などを投入します。
3. **無線機から発注（下取り相殺）**:
   - HAMラジオまたはトランシーバー（Walkie-Talkie）の電源を入れ、周波数を **`104.8 MHz`** に合わせます。
   - 無線機を右クリックして `[無線取引ネットワークに接続]` を開きます。
   - 右パネルに「所持CR ＋ ドロップボックス査定額 ＝ 合計利用可能予算」がリアルタイム表示されます。
   - 欲しい物資（または回収のみの『不用品回収依頼』）をカートに入れて `[発注 ＆ 不用品回収]` をクリック！
4. **投下と回収**:
   - 配達予定時刻が近づくと無線で警報が届きます。
   - LZ周辺（50タイル以内）で `[投下要請]` を行うとヘリが飛来し、サーチライトの下で物資が投下されます。
   - 押し寄せるゾンビを撃退し、支援バッグやクルーからの差し入れを回収しましょう！

---

## ⚙️ サンドボックス設定一覧 (Sandbox Options)

サンドボックス設定から、プレイスタイルに合わせて細かく難易度をカスタマイズ可能です：

| 設定項目 (Option) | 選択肢・デフォルト | 説明 |
| :--- | :--- | :--- |
| **HeliZombieAttractRadius** | 100〜1000 (標準: 400) | ヘリの飛行音による周囲ゾンビの誘引半径（タイル）。 |
| **HeliHordeEnabled** | 有効 (True) / 無効 (False) | ヘリ飛来時に追従ゾンビをスポーンさせるかどうか。 |
| **HeliHordeSize** | None / Small / **Medium** / Large / Insane | スポーンするゾンビの規模（狂気: 150〜200体）。 |
| **HeliHordeRemoteRatio** | 近接のみ / **バランス(50:50)** / 遠隔のみ | 遠隔仮想ホード（135タイル先から進撃）と近接スポーンの配分比率。 |
| **MegaHordeChance** | なし(0%) / 低い(5%) / **標準(15%)** / 高い(25%) / 毎回(100%) | 通常の2.5倍の巨大ホードが発生する確率。 |
| **DeliveryTimeHours** | 1〜2h / 3〜6h / **6〜12h** / 12〜24h / 24〜72h | 発注からヘリが到着するまでの所要時間。 |
| **BuyPriceMultiplier** | 0.2〜100.0 (標準: 2.0倍) | 商品の購入価格倍率。 |
| **SellPriceMultiplier** | 0.1〜5.0 (標準: 1.0倍) | アイテムの売却買取価格倍率。 |
| **RequireOutdoorLZ** | 有効 (True) [推奨] | LZコンテナの屋外設置を必須とするかどうか。 |
| **LZMaxRange** | 50〜2000 (標準: 500) | プレイヤーから登録可能なLZまでの最大距離。 |

---

## 📁 フォルダ構成 (Repository Structure)

```text
radio_trading_mod/
├── README.md                         # 本ドキュメント
├── LICENSE                           # MIT License
├── .gitignore                        # Git除外設定
├── .github/                          # GitHub Issue/PR テンプレート
├── docs/                             # 仕様書・全バージョンの作業ログ
│   ├── spec_radio_trader.md          # システム総合仕様書
│   └── logs/                         # 詳細な開発・検証ログ
└── RadioTraderMod/                   # Mod ソースコード本体 (B42対応構造)
    └── 42/
        ├── mod.info
        ├── poster.png
        └── media/
            ├── lua/
            │   ├── client/           # UI、右クリックメニュー、演出ブリッジ
            │   ├── server/           # サーバーコア、ヘリイベント、配達タイマー
            │   └── shared/           # 設定、価格テーブル、多言語辞書
            └── sandbox/              # サンドボックス設定UI定義
```

---

## 🤖 Development Notice (AI-Assisted Development) / 開発体制について

> [!NOTE]
> **English**:  
> Please note that this mod's code, scripts, and initial architecture were realized and developed with the active assistance of **Generative AI (LLM pair-programming)**, directed by the creator's original gameplay concepts, lore, balance design, and rigorous testing. While every release is audited and verified for Build 42 compatibility, please be aware of this development approach. Feel free to report any edge cases or suggestions via GitHub Issues!
> 
> **日本語**:  
> 本MODのLuaコード、各種スクリプト、およびシステム実装は、製作者のゲームプレイ構想・公式背景ストーリー・バランス調整方針に基づき、**生成AI（LLMによるペアプログラミング支援）を活用して具現化・制作**されています。  
> 動作検証および整合性チェックを行いBuild 42に準拠した品質を保つよう制作しておりますが、AI支援を取り入れたプロジェクトである点をご認識・ご理解の上でお楽しみいただけますと幸いです。予期せぬ不具合や改善案がございましたら、お気軽に [GitHub Issues](https://github.com/samiavr/ExclusionZoneTrader/issues) までお寄せください！

---

## ☕ Support the Creator / 開発者を支援

If you enjoy **Exclusion Zone Trader** and would like to support ongoing development, updates, and future Project Zomboid mods, consider buying me a coffee or stopping by my Twitch stream! Any support is deeply appreciated! ❤️

もしこのMODを気に入っていただけましたら、今後の機能追加やアップデート、新作MOD開発の励みになりますので、Ko-fiでのご支援やTwitchのフォロー・サブスクをいただけると大変嬉しいです！

<p align="left">
  <a href="https://ko-fi.com/samiavr" target="_blank">
    <img src="https://img.shields.io/badge/Ko--fi-Support%20Me-F16061?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi" />
  </a>
  <a href="https://www.twitch.tv/samiavr" target="_blank">
    <img src="https://img.shields.io/badge/Twitch-Follow%20%2F%20Subscribe-9146FF?style=for-the-badge&logo=twitch&logoColor=white" alt="Twitch" />
  </a>
</p>

- ☕ **Ko-fi**: [https://ko-fi.com/samiavr](https://ko-fi.com/samiavr)
- 🟣 **Twitch**: [https://www.twitch.tv/samiavr](https://www.twitch.tv/samiavr)

---

## 🛠️ 開発・品質管理 (Quality Assurance)

本 MOD は Project Zomboid Build 42 の厳格な仕様に準拠しており、専用の検証スクリプトによって品質を担保しています：
- **UTF-8 BOM 完全排除**（Kahlua Lexer クラッシュ防止）
- **Lua 5.1 / Kahlua 互換性チェック**
- **Java Formatter エスケープ検証**（`%%` の例外クラッシュ防止）
- **シングルプレイ ＆ マルチプレイ（Dedicated Server / 画面分割）完全対応**

---

## 📜 ライセンス (License)

このプロジェクトは [MIT License](LICENSE) の下で公開されています。商用・非商用問わず、クレジット表記を行っていただければ自由に利用、改変、フォークが可能です。

---

*Enjoy the Exclusion Zone Trader! Stay safe behind the quarantine lines, survivor.*
