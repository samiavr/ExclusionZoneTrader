# 実装計画: RadioTrader_UI のバニラウィンドウ移行 (ISCollapsableWindow) ＆ ドラッグ・リサイズ対応 ＆ 左ペイン文字鮮明化

## 1. 概要
- **目的**: 
  1. `RadioTrader_UI` の基底クラスを `ISPanel` からバニラ標準の `ISCollapsableWindow` に移行し、ドラッグ移動、右上の閉じる[×]ボタン、ピン留め、バニラ風タイトルバーに対応する。
  2. リサイズ機能（`self.resizable = true`）を有効化し、ウィンドウ伸縮時に全UIコンポーネントが追従するレスポンシブ配置計算（`layoutChildren()` / `onResize()`）を導入する。
  3. `render()` でカテゴリタブボタン列の上に描画されていた半透明矩形（子要素上塗りバグ）を解消し、背景を `prerender()` に移動して左ペインの文字をクッキリ鮮明化する。また選択中タブの視認性を高める。
- **対象バージョン**: v1.0.0.64

---

## 2. 変更対象ファイル
- [RadioTrader_UI.lua](file:///d:/VSCODE/project/zomboid/radio_trading_mod/RadioTraderMod/42/media/lua/client/RadioTrader_UI.lua)
- [task.md](file:///d:/VSCODE/project/zomboid/radio_trading_mod/task.md)

---

## 3. 実装詳細手順

### 3.1 クラス継承とコンストラクタの改修
- `require "ISUI/ISCollapsableWindow"` を追加。
- `RadioTrader_UI = ISCollapsableWindow:derive("RadioTrader_UI")`
- `RadioTrader_UI:new(player)`:
  - `ISCollapsableWindow.new(self, x, y, width, height)` を呼び出し。
  - `self.resizable = true`
  - `self.minimumWidth = 720`
  - `self.minimumHeight = 460`
  - `self.pin = true`（画面外マウスアウトでの勝手な折りたたみを防止）
  - `self:setDrawFrame(true)`

### 3.2 子要素構築 (`createChildren` / `initialise`)
- `ISCollapsableWindow` のライフサイクルに適合：
  - `initialise()`: `ISCollapsableWindow.initialise(self)`
  - `createChildren()`: `ISCollapsableWindow.createChildren(self)` を実行後、各子コントロール（タブボタン、アイテムリスト、右パネル情報ラベル、カートリスト、下部ログボックス、ボタンバー）を生成。
  - 生成後に `self:layoutChildren()` を呼び出して全座標とサイズを整合。

### 3.3 レスポンシブレイアウト動的計算 (`layoutChildren`, `onResize`)
- `layoutChildren()` メソッドの新設：
  - ウィンドウの現在幅 `self.width` と現在高さ `self.height` を取得。
  - タイトルバー高さ `th = self:titleBarHeight()`、リサイズバー高さ `rh` を考慮。
  - リスト高さ `listH = self.height - th - LOG_H - BTN_H - MARGIN * 4 - rh` を計算。
  - アイテムリスト幅 `listW = self.width - MARGIN * 3 - TAB_W - INFO_W` を計算。
  - 各要素（左ペインタブ、中央リスト、右ペイン詳細・カート、下部ログ、最下部ボタンバー）の座標とサイズを動的更新。
- `onResize()` メソッドのオーバーライド：
  - `ISCollapsableWindow.onResize(self)` を呼び出し。
  - `self:layoutChildren()` を実行して全要素を再配置。

### 3.4 左ペインの文字鮮明化 ＆ スタイル改善
- **原因特定**: 現在の `render()` 内でボタン（子要素）が描画された後に `self:drawRect(MARGIN - 2, 30, TAB_W, listH, 0.85, ...)` が実行され、ボタンの上に濃い矩形が上塗りされていた。
- **修正**:
  - タブ背景の `drawRect` を `prerender()` に移動（子要素描画前に下地として描画）。
  - ボタンのテキスト色を白 `r=1, g=1, b=1` に保証。
  - 選択中のカテゴリボタンは背景色や枠線でアクティブ状態を視覚的にハイライト（`updateCategoryTabStyles()`）。

### 3.5 描画ループ (`prerender`, `render`)
- `prerender()`:
  - `ISCollapsableWindow.prerender(self)`
  - タブ列の背景描画（子要素の前）
  - タイトル文字列の更新（`self:setTitle(...)` でバニラ標準タイトルバーへ表示）
- `render()`:
  - `ISCollapsableWindow.render(self)`
  - アイテムリスト選択変更の検出と定期 ModData 同期のみを実行（上塗り矩形は全廃）

### 3.6 閉じる動作 (`close`)
- 右上の「×」ボタンおよび下部の「[閉じる]」ボタンの双方で `self:close()` を呼ぶ。
- `function RadioTrader_UI:close()` で `self:setVisible(false); self:removeFromUIManager()`。

---

## 4. 検証手順
1. 静的検査スクリプト `check_mod_health.py` を実行（構文エラー・エンコーディング・多言語キー等 0エラー確認）。
2. 配布用ZIPパッケージを `build_release_zip.py` でリビルド。
