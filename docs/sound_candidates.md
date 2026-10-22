# Radio Trader Mod - SE（効果音）仕様および候補リスト

本ドキュメントは、Radio Trader Mod における通知音・SEの現状調査結果と、今後のサウンド調整・差し替えに向けたバニラ実在サウンド（B41/B42共通）の候補一覧をまとめた恒久仕様書です。

---

## 1. 現状の通知音の仕様調査

### Q. 「投下準備完了」になったタイミングの通知音は、スキルレベルアップ音になっているか？
**A. はい、スキルレベルアップ音になっています。**

`RadioTrader_ClientBridge.lua` の 397行目にて、サーバーから手動投下可能通知（`CMD_REQUEST_DROP`）を受信した際、以下の通り `GainExperienceLevel` が再生されています。

```lua
-- RadioTrader_ClientBridge.lua (L.392-399)
-- === 投下準備完了通知 (手動投下待ち) ===
elseif command == RadioTrader_Config.CMD_REQUEST_DROP then
    local expH = args and args.expireHours or 48
    local msg  = tr("UI_RadioTrader_Say_ReadyForDrop", "Incoming transmission: Supplies ready. Request drop near LZ.")
    showRadioText(player, msg)
    playSound("GainExperienceLevel") -- ★ バニラのスキルレベルアップ音
    log("READY_FOR_DROP received. Expire in " .. expH .. " hrs.")
```

バニラ内部定義（`media/scripts/generated/sounds/player/sounds_player_levelup.txt`）：
```
sound GainExperienceLevel
{
    category = Player,
    clip
    {
        event = Game/LevelUp, -- FMODイベント: レベルアップ時のファンファーレ
    }
}
```

#### 全イベントにおける最新SE割り当て一覧（v1.0.0.57〜）
ヘリ音（環境音）およびエラー警告音を除き、通信・通知・取引系SEをバニラ無線音声 `RadioTalk` に統一しました。

| イベント / 状態 | 実行関数 | 再生サウンド名 | FMOD Event / 音の内容 | 備考 |
|---|---|---|---|---|
| **投下準備完了** (`CMD_REQUEST_DROP`) | `playSound` | `RadioTalk` | `Object/Radio/Program`（無線音声） | 旧 `GainExperienceLevel` から変更 |
| **売却成功** (`sellSuccess`) | `playSound` | `RadioTalk` | `Object/Radio/Program`（無線音声） | 旧 `GainExperienceLevel` から変更 |
| **発注受付** (`CMD_TRADE_ACCEPTED`) | `playSound` | `RadioTalk` | `Object/Radio/Program`（無線音声） | 旧 `RadioStatic` から変更 |
| **ヘリ接近警告** (`CMD_HELI_APPROACH`) | `playSound` | `RadioTalk` | `Object/Radio/Program`（無線音声） | 旧 `RadioStatic` から変更 |
| **リロール成功** (`rerollSuccess`) | `playSound` | `RadioTalk` | `Object/Radio/Program`（無線音声） | 旧 `RadioStatic` から変更 |
| **物資投下完了** (`CMD_DELIVERY_DONE`) | `playSound` | `Helicopter` | `Meta/Helicopter`（ヘリ通過・ホバリング） | 現行維持 |
| **エラー / 注文期限切れ** (`error`, `CMD_ORDER_EXPIRED`) | `playSound` | `AccessDenied` | エラービープ音 | 現行維持 |

> [!NOTE]
> **RadioTalk の再生時間・挙動仕様**:
> - PZの `player:playSound("RadioTalk")` は内部で `FMODSoundEmitter.playSoundImpl` を呼び出すため、**ワンショット（One-Shot / 単発）** 再生となります。
> - ループ再生ではないため、オーディオクリップ（約1〜2秒の無線人の声）が終わると自動的に停止し、鳴りっぱなしになることはありません。
> - ModのLua側での強制停止タイマー等は不要で、バニラの音源長さに従い自然に鳴り止みます。

---

## 2. 代替サウンド候補リスト (バニラ実在サウンド)

Project Zomboid（B41 / B42）の内部サウンドスクリプトから、通信機・通知・サバイバル・取引の雰囲気に適したバニラ公式SEを抽出・分類しました。

### カテゴリA: 無線・通信・電子機器系（世界観重視・おすすめ）

無線機からの着信や通信確立を演出するのに最も自然な候補群です。

| サウンド名 (`soundName`) | カテゴリ | FMOD Event | 特徴・適用イメージ |
|---|---|---|---|
| `TelevisionTestBeep` | Object | `Object/Television/TestTone` | **特におすすめ**。緊急警報放送（EAS）やテストパターンの「ピーーッ」というトーン。通知として非常に明瞭で、ミリタリー／非常時通信の緊迫感がある。 |
| `RadioTalk` | Object | `Object/Radio/Program` | 無線機から微かに人の喋り声が聞こえる音声。通信が入ったことが直感的にわかる。 |
| `TuneIn` | Object | `Object/Radio/TuneIn` | チューニングダイヤルを合わせたときの「キュルルッ」という音。周波数が合致して通信が入った演出向き。 |
| `RadioButton` | Object | `Object/Radio/Toggle` | 無線機のPTTスイッチや電源ボタンを押し込む「カチッ」というメカニカル音。 |
| `RadioZap` | Object | `Object/Radio/Zap` | 電波障害や高電圧ノイズ。 |

---

### カテゴリB: タイマー・時計・電子アラーム系（通知の明瞭さ重視）

ゲームプレイ中に聞き逃しにくく、時間経過による準備完了を知らせるのに適した候補群です。

| サウンド名 (`soundName`) | カテゴリ | FMOD Event | 特徴・適用イメージ |
|---|---|---|---|
| `TrapTimerExpired` | Item | `Weapon/Throwable/Timer/Expired` | **おすすめ**。タイマー爆弾のタイマー終了時の作動音（カチッ＋機械的クリック音）。短く主張しすぎない。 |
| `TrapTimerLoop` | Item | `Weapon/Throwable/Timer/Beep` | 電子タイマーのピピピッという単発ビープ音。 |
| `MicrowaveTimerExpired` | Object | `Object/Microwave/Finished` | 電子レンジの「チン！」あるいは完了チャイム。コミカルだが非常に分かりやすい。 |
| `StoveTimerExpired` | Object | `Object/Stove/Finished` | オーブン／コンロのタイマー完了チャイム。 |
| `WatchAlarmLoop` | Player | `Character/Survival/AlarmWatchRinging` | デジタル腕時計のアラーム音。 |

---

### カテゴリC: 取引・経済・UI系（報酬感・達成感重視）

「物資の準備ができた」「売却が完了した」というポジティブなフィードバックを与える候補群です。

| サウンド名 (`soundName`) | カテゴリ | FMOD Event | 特徴・適用イメージ |
|---|---|---|---|
| `CashRegisterOpen` | Object | `Object/LargeContainers/CashRegister/Open` | **売却成功時におすすめ**。レジスターが開く「チーン、ガシャン！」という音。売買成立の満足度が高い。 |
| `CashRegisterTransferItem` | Object | `Object/LargeContainers/CashRegister/TransferItem` | レジで小銭やお札を扱う音。 |
| `UIActivatePlayButton` | UI | `UI/ClickPlay` | メインメニューの「PLAY」を押したときの低音の効いた確定音。 |
| `UIClickToStart` | UI | `UI/ClickToStart` | タイトル画面「Click to start」のクリック音。 |
| `GainExperienceLevel` (現行) | Player | `Game/LevelUp` | 現行のスキルレベルアップ音。派手で確実に気づくが、自身のスキルが上がったと誤認しやすい欠点がある。 |

---

### カテゴリD: 警報・ホーン・合図系（緊迫感・屋外伝達重視）

| サウンド名 (`soundName`) | カテゴリ | FMOD Event | 特徴・適用イメージ |
|---|---|---|---|
| `BlowWhistle` | Player | `Character/Survival/Whistle/Blow` | 審判・警察用ホイッスル「ピピーッ！」 |
| `VehicleBackUpBeeper` | Vehicle | `Vehicle/BackUpBeeper` | トラック等のバック警告音「ピー、ピー」 |
| `VehicleHorn` | Vehicle | `Vehicle/Horn` | 車両のクラクション |

---

## 3. 推奨プリセット構成案

ユーザーがスキルレベルアップと混同せず、かつ雰囲気（無線サバイバル）を損なわないための提案：

### パターン1: 【ミリタリー無線・世界観重視】（イチオシ）
- **投下準備完了**: `TelevisionTestBeep`（緊急警報の短トーン）または `RadioTalk`（無線着信）
- **売却完了**: `CashRegisterOpen`（レジスター音）
- **投下完了**: `Helicopter`（現行維持）
- **エラー/拒否**: `AccessDenied`（現行維持）
- **メリット**: スキルアップとの誤認がゼロになり、無線機を介した密輸・取引のロールプレイ感が大幅に向上。

### パターン2: 【電子機器・通知実用重視】
- **投下準備完了**: `TrapTimerExpired` または `WatchAlarmLoop`
- **売却完了**: `CashRegisterTransferItem` または `CashRegisterOpen`
- **投下完了**: `Helicopter`（現行維持）
- **エラー/拒否**: `AccessDenied`（現行維持）
- **メリット**: 耳障りにならず、かつ作業中でも明瞭に認識可能。

---

## 4. 実装・切り替え方法

コード内の音名を変更する場合、以下の箇所を書き換えるだけで即座に反映されます。

`RadioTrader_ClientBridge.lua`:
```lua
-- === 投下準備完了通知 ===
elseif command == RadioTrader_Config.CMD_REQUEST_DROP then
    ...
    playSound("TelevisionTestBeep") -- 例: EASビープに変更
```
```lua
-- === 売却成功通知 ===
elseif command == "sellSuccess" then
    ...
    playSound("CashRegisterOpen")   -- 例: レジ音に変更
```

将来的には `RadioTrader_Config.lua` や SandboxOptions にサウンド選択オプション（例: `SoundPreset = "Military" | "Classic" | "Electronic"`）を追加することも容易です。
