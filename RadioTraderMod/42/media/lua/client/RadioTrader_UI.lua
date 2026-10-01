-- =============================================================================
-- RadioTrader_UI.lua
-- [Client] 取引パネル画面 (ISPanel / B42 準拠)
-- =============================================================================

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"

RadioTrader_UI = ISPanel:derive("RadioTrader_UI")

-- ---------------------------------------------------------------------------
-- 翻訳ヘルパー
-- ---------------------------------------------------------------------------
-- 多言語化ヘルパー（可変長引数・pcall安全版・文字列化保証）
-- ---------------------------------------------------------------------------
local function tr(key, defaultText, ...)
    local rawArgs = {...}
    local args = {}
    for i, v in ipairs(rawArgs) do
        table.insert(args, tostring(v))
    end
    if #args > 0 then
        if getTextOrNull then
            local ok, val = pcall(getTextOrNull, key, unpack(args))
            if ok and val then return val end
        end
        if getText then
            local ok, val = pcall(getText, key, unpack(args))
            if ok and val and val ~= key then return val end
        end
        if defaultText then
            local safeDefault = string.gsub(defaultText, "%%d", "%%s")
            local ok, res = pcall(string.format, safeDefault, unpack(args))
            if ok then return res end
            return defaultText
        end
        return key
    else
        if getTextOrNull then
            local ok, val = pcall(getTextOrNull, key)
            if ok and val then return val end
        end
        if getText then
            local ok, val = pcall(getText, key)
            if ok and val and val ~= key then return val end
        end
        return defaultText or key
    end
end

-- ---------------------------------------------------------------------------
-- アイテム表示名取得ヘルパー（PZ公式翻訳を優先取得）
-- ---------------------------------------------------------------------------
local function getItemDisplayName(fullType, fallbackName)
    local i18nKey = "UI_RadioTrader_Item_" .. tostring(fullType)
    local i18nName = tr(i18nKey, nil)
    if i18nName and i18nName ~= i18nKey and i18nName ~= "" then
        return i18nName
    end
    if string.find(tostring(fullType), "%.") and getItemNameFromFullType then
        local ok, name = pcall(getItemNameFromFullType, fullType)
        if ok and name and name ~= "" and name ~= fullType then
            return name
        end
    end
    if getItem then
        local itemScript = getItem(fullType)
        if itemScript and itemScript.getDisplayName then
            local name = itemScript:getDisplayName()
            if name and name ~= "" then return name end
        end
    end
    return fallbackName or fullType
end

-- ---------------------------------------------------------------------------
-- 定数
-- ---------------------------------------------------------------------------
local PANEL_W  = 780
local PANEL_H  = 520
local TAB_W    = 120
local LIST_W   = 360
local INFO_W   = PANEL_W - TAB_W - LIST_W - 40  -- 右パネル
local MARGIN   = 10
local ROW_H    = 28
local LOG_H    = 90
local BTN_H    = 32
local FONT     = UIFont.Small

local COLOR_BG_DARK  = { r=0.10, g=0.10, b=0.12, a=0.97 }
local COLOR_BG_PANEL = { r=0.14, g=0.14, b=0.18, a=1.0  }
local COLOR_ACCENT   = { r=0.20, g=0.80, b=0.50, a=1.0  }  -- グリーン
local COLOR_SUCCESS  = { r=0.20, g=0.85, b=0.40, a=1.0  }  -- 明るい緑（成功・ボーナス）
local COLOR_WARN     = { r=0.90, g=0.60, b=0.10, a=1.0  }  -- 黄
local COLOR_DANGER   = { r=0.90, g=0.20, b=0.20, a=1.0  }  -- 赤
local COLOR_TEXT     = { r=0.85, g=0.90, b=0.85, a=1.0  }
local COLOR_TEXT_DIM = { r=0.60, g=0.65, b=0.60, a=1.0  }  -- ガイド用控えめテキスト

-- ---------------------------------------------------------------------------
-- コンストラクタ
-- ---------------------------------------------------------------------------
function RadioTrader_UI:new(player)
    local x = (getCore():getScreenWidth()  - PANEL_W) / 2
    local y = (getCore():getScreenHeight() - PANEL_H) / 2
    local o  = ISPanel.new(self, x, y, PANEL_W, PANEL_H)
    o.player           = player
    o.selectedCategory = RadioTrader_ShopCategories[1].key
    o.selectedItem     = nil
    local initialCredits = 0
    if ModData and ModData.exists then
        local uname = (player and player.getUsername and player:getUsername()) or "singleplayer"
        if uname == "" then uname = "singleplayer" end
        if ModData.exists("RadioTrader_" .. uname) then
            local gmd = ModData.get("RadioTrader_" .. uname)
            if gmd and gmd[RadioTrader_Config.KEY_CREDITS] then
                initialCredits = tonumber(gmd[RadioTrader_Config.KEY_CREDITS]) or 0
            end
        end
    end

    o.credits          = initialCredits
    o.assessedCredits  = 0
    o.deliveryState    = RadioTrader_Config.STATE_NONE
    o.deliveryRemaining= 0
    o.logLines         = {}
    o.cart             = {}
    return o
end

-- ---------------------------------------------------------------------------
-- 初期化
-- ---------------------------------------------------------------------------
function RadioTrader_UI:initialise()
    ISPanel.initialise(self)
    self:buildUI()
    -- サーバーにステート照会を送信
    sendClientCommand(self.player, "RadioTrader", "requestState", {})
    sendClientCommand(self.player, "RadioTrader", "requestAssessment", {})
end

-- ---------------------------------------------------------------------------
-- UI 構築
-- ---------------------------------------------------------------------------
function RadioTrader_UI:buildUI()
    local x, y, w = MARGIN, 30, self.width
    local listH = PANEL_H - 30 - LOG_H - BTN_H - MARGIN * 4

    -- ===== カテゴリタブ =====
    self.tabButtons = {}
    local tabY = y
    local catCount = #RadioTrader_ShopCategories
    local tabGap = 3
    local tabBtnH = math.min(32, math.max(18, math.floor((listH - (catCount - 1) * tabGap) / catCount)))
    for i, cat in ipairs(RadioTrader_ShopCategories) do
        local catLabel = tr("UI_RadioTrader_Cat_" .. cat.key, cat.label)
        local btn = ISButton:new(MARGIN, tabY + (i-1) * (tabBtnH + tabGap), TAB_W - 4, tabBtnH,
            catLabel, self, RadioTrader_UI.onCategoryClick)
        btn.internal = cat.key
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.tabButtons[i] = btn
    end

    -- ===== アイテムリスト =====
    local listX = MARGIN + TAB_W
    self.itemList = ISScrollingListBox:new(listX, y, LIST_W, listH)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.font        = FONT
    self.itemList.itemheight  = ROW_H
    self.itemList.selected    = 1
    self.itemList.joypadParent = self

    -- アイテムリストの独自カスタム描画（アイコン＋上下中央揃え）
    function self.itemList:doDrawItem(y, item, alt)
        if not item.height then item.height = self.itemheight end
        if (y + self:getYScroll() + item.height < 0) or (y + self:getYScroll() >= self.height) then
            return y + item.height
        end

        local entry = item.item
        local isSelected = (self.selected == item.index)

        -- 選択ハイライト
        if isSelected then
            self:drawRect(0, y, self:getWidth(), item.height, 0.45, 0.25, 0.50, 0.35)
        elseif (self.mouseoverselected == item.index) and self:isMouseOver() then
            self:drawRect(0, y, self:getWidth(), item.height, 0.20, 0.35, 0.35, 0.35)
        end
        -- 行区切り線
        self:drawRect(0, y + item.height - 1, self:getWidth(), 1, 0.25, 0.3, 0.3, 0.4)

        -- アイテムアイコン描画
        local iconSize = item.height - 4
        local iconX = 6
        if entry and entry.id then
            local iconTarget = entry.id
            if RadioTrader_CrateDefinitions and RadioTrader_CrateDefinitions[entry.id] then
                iconTarget = RadioTrader_CrateDefinitions[entry.id].container or "Base.Bag_DuffelBag"
            elseif entry.id == "RadioTrader_Mystery_Furniture" then
                iconTarget = "Base.Mov_AntiqueStove"
            end
            local itemScript = getItem(iconTarget)
            local texture = itemScript and itemScript:getNormalTexture()
            if not texture or (texture.getName and texture:getName() == "default") then
                if entry.id == "Base.Mov_RoadBarrier" then
                    texture = getTexture("construction_01_8")
                elseif entry.id == "Base.Mov_LightConstruction" then
                    texture = getTexture("lighting_outdoor_01_49")
                elseif iconTarget == "Base.Mov_AntiqueStove" then
                    texture = getTexture("appliances_cooking_01_16")
                end
            end
            if texture then
                self:drawTextureScaledAspect(texture, iconX, y + 2, iconSize, iconSize, 1.0, 1, 1, 1)
            end
        end

        -- テキスト描画（行の中央揃え）
        local fontHgt = getTextManager():getFontHeight(self.font)
        local textY = y + math.floor((item.height - fontHgt) / 2)
        local textX = iconX + iconSize + 8
        local textColor = isSelected and {r=1.0, g=1.0, b=1.0, a=1.0} or {r=0.85, g=0.88, b=0.85, a=1.0}
        self:drawText(item.text, textX, textY, textColor.r, textColor.g, textColor.b, textColor.a, self.font)

        return y + item.height
    end

    self:addChild(self.itemList)

    -- ===== 右パネル：LZ状態 =====
    local infoX = listX + LIST_W + MARGIN
    local infoY = y

    -- クレジット残高ラベル
    local credText = tr("UI_RadioTrader_Credits", "Credits") .. ": -- CR"
    self.labelCredits = ISLabel:new(infoX, infoY, ROW_H, credText, 1, 1, 1, 1, FONT, true)
    self.labelCredits:initialise()
    self:addChild(self.labelCredits)
    infoY = infoY + ROW_H + 4

    -- LZ 査定額ラベル
    local assessText = tr("UI_RadioTrader_Assess", "Drop Box Value") .. ": -- CR"
    self.labelAssess = ISLabel:new(infoX, infoY, ROW_H, assessText, 1, 1, 1, 1, FONT, true)
    self.labelAssess:initialise()
    self:addChild(self.labelAssess)
    infoY = infoY + ROW_H + 4

    -- 配達ステートラベル
    local delText = tr("UI_RadioTrader_Delivery", "Delivery") .. ": " .. tr("UI_RadioTrader_StateNone", "None")
    self.labelDelivery = ISLabel:new(infoX, infoY, ROW_H * 2, delText, 1, 1, 1, 1, FONT, true)
    self.labelDelivery:initialise()
    self:addChild(self.labelDelivery)
    infoY = infoY + ROW_H * 2 + 4

    -- 選択アイテム詳細ラベル
    local selectText = tr("UI_RadioTrader_SelectItem", "Select an item to view details")
    local itemDetailH = 46
    self.labelItemDetail = ISLabel:new(infoX, infoY, itemDetailH,
        selectText,
        COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, COLOR_TEXT.a, FONT, true)
    self.labelItemDetail.wrap = true
    self.labelItemDetail:initialise()
    self:addChild(self.labelItemDetail)
    infoY = infoY + itemDetailH + 4

    -- [＋カートに追加] ボタン
    local addCartLabel = tr("UI_RadioTrader_AddToCart", "[+] Add to Cart")
    self.btnAddToCart = ISButton:new(infoX, infoY, 150, 24,
        addCartLabel, self, RadioTrader_UI.onAddToCartClick)
    self.btnAddToCart:initialise()
    self.btnAddToCart:instantiate()
    self:addChild(self.btnAddToCart)

    -- [カートを空にする] ボタン
    local clearCartLabel = tr("UI_RadioTrader_ClearCart", "Clear")
    self.btnClearCart = ISButton:new(infoX + 155, infoY, 70, 24,
        clearCartLabel, self, RadioTrader_UI.onClearCartClick)
    self.btnClearCart:initialise()
    self.btnClearCart:instantiate()
    self:addChild(self.btnClearCart)
    infoY = infoY + 28

    -- カート状態 / ヘッダーラベル
    self.labelCartTitle = ISLabel:new(infoX, infoY, 18,
        tr("UI_RadioTrader_CartTitle", "Order Cart (Empty)"),
        COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 1.0, FONT, true)
    self.labelCartTitle:initialise()
    self:addChild(self.labelCartTitle)
    infoY = infoY + 20

    -- カートリスト (カートにアイテムがある時に表示)
    local cartH = listH - (infoY - y) - 4
    self.cartList = ISScrollingListBox:new(infoX, infoY, INFO_W, cartH)
    self.cartList:initialise()
    self.cartList:instantiate()
    self.cartList.font = FONT
    self.cartList.itemheight = 22
    self.cartList.joypadParent = self

    function self.cartList:doDrawItem(y, item, alt)
        if not item.height then item.height = self.itemheight end
        if (y + self:getYScroll() + item.height < 0) or (y + self:getYScroll() >= self.height) then
            return y + item.height
        end
        local entry = item.item
        local isSelected = (self.selected == item.index)
        if isSelected then
            self:drawRect(0, y, self:getWidth(), item.height, 0.35, 0.25, 0.45, 0.35)
        end
        self:drawRect(0, y + item.height - 1, self:getWidth(), 1, 0.15, 0.2, 0.2, 0.3)
        local fontHgt = getTextManager():getFontHeight(self.font)
        local textY = y + math.floor((item.height - fontHgt) / 2)
        local lineText = ("%s x%d (%d CR) [x]"):format(entry.name, entry.quantity, entry.price * entry.quantity)
        self:drawText(lineText, 6, textY, 0.9, 0.95, 0.9, 1.0, self.font)
        return y + item.height
    end

    function self.cartList:onMouseDown(x, y)
        local row = self:rowAt(x, y)
        if row and row >= 1 and row <= #self.items then
            local parent = self.parent
            if parent and parent.onCartItemClick then
                parent:onCartItemClick(row)
            end
        end
    end

    self.cartList:setVisible(false)
    self:addChild(self.cartList)

    -- 買取ガイド（カート空時に表示）
    local guideBody = tr("UI_RadioTrader_GuideBody", "- Records (Journals, Notes, Music)\n- Jewelry (Gold/Silver/Diamond Rings)\n- Cash (1 CR), Money Bundle (100 CR)\n- Credit Cards (1-10 CR random)\n- Gems, Ingots & Fresh Produce\n* Select items & click [+] Add to Cart\n  to place a batch delivery order!")
    self.labelGuideBody = ISLabel:new(infoX, infoY, cartH,
        guideBody,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, 1.0, FONT, true)
    self.labelGuideBody.wrap = true
    self.labelGuideBody:initialise()
    self:addChild(self.labelGuideBody)

    -- ===== 無線通信ログ =====
    local logY = 30 + listH + MARGIN
    self.logBox = ISScrollingListBox:new(MARGIN, logY, PANEL_W - MARGIN * 2, LOG_H)
    self.logBox:initialise()
    self.logBox:instantiate()
    self.logBox.font       = FONT
    self.logBox.itemheight = 18
    self:addChild(self.logBox)

    -- ===== ボタンバー =====
    local btnY = logY + LOG_H + MARGIN
    local orderW = 260

    local orderLabel = tr("UI_RadioTrader_OrderBtn", "[Trade] Place Order & Pickup")
    self.btnOrder = ISButton:new(MARGIN, btnY, orderW, BTN_H,
        orderLabel, self, RadioTrader_UI.onOrderClick)
    self.btnOrder:initialise()
    self.btnOrder:instantiate()
    self:addChild(self.btnOrder)

    local rerollW = 210
    local rerollLabel = tr("UI_RadioTrader_RerollBtn", "[Inquire] Got anything else? (50 CR)")
    self.btnReroll = ISButton:new(MARGIN + orderW + MARGIN, btnY, rerollW, BTN_H,
        rerollLabel, self, RadioTrader_UI.onRerollClick)
    self.btnReroll:initialise()
    self.btnReroll:instantiate()
    self:addChild(self.btnReroll)

    local closeLabel = tr("UI_RadioTrader_CloseBtn", "[Close]")
    self.btnClose = ISButton:new(PANEL_W - MARGIN - 100, btnY, 100, BTN_H,
        closeLabel, self, RadioTrader_UI.onCloseClick)
    self.btnClose:initialise()
    self.btnClose:instantiate()
    self:addChild(self.btnClose)

    -- 初期カテゴリをロード
    self:loadCategory(self.selectedCategory)
    self:updateStatusDisplay()
end

-- ---------------------------------------------------------------------------
-- カテゴリロード（アイテムリストを更新）
-- ---------------------------------------------------------------------------
function RadioTrader_UI:loadCategory(categoryKey)
    self.selectedCategory = categoryKey
    self.itemList:clear()
    local items = RadioTrader_ItemsTable_GetShopCategory(categoryKey)
    for i, entry in ipairs(items) do
        local dispName = getItemDisplayName(entry.id, entry.name)
        local effPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(entry.price) or entry.price
        local label
        if categoryKey == "Daily" then
            if entry.subCat == "TraderStash" then
                local stashPrefix = tr("UI_RadioTrader_StashPrefix", "[★Stash] ")
                label = ("%s%s x %d  -  %d CR"):format(stashPrefix, dispName, entry.count or 1, effPrice)
            else
                label = ("%s x %d  -  %d CR"):format(dispName, entry.count or 1, effPrice)
            end
        elseif entry.count and entry.count > 1 then
            label = ("%s x %d  -  %d CR"):format(dispName, entry.count, effPrice)
        else
            label = ("%s  -  %d CR"):format(dispName, effPrice)
        end
        self.itemList:addItem(label, entry)
    end
    self.itemList.selected = 1
    self:onItemSelect()
end

-- ---------------------------------------------------------------------------
-- アイテム選択時の詳細更新
-- ---------------------------------------------------------------------------
function RadioTrader_UI:onItemSelect()
    if not self.itemList or not self.labelItemDetail then return end
    local item = nil
    if self.itemList.items and self.itemList.selected and self.itemList.items[self.itemList.selected] then
        item = self.itemList.items[self.itemList.selected]
    elseif self.itemList.getItem then
        item = self.itemList:getItem(self.itemList.selected)
    end

    if item and item.item then
        local entry = item.item
        self.selectedItem = entry
        local dispName   = getItemDisplayName(entry.id, entry.name)
        local effPrice   = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(entry.price) or entry.price
        local priceLabel = tr("UI_RadioTrader_Price", "Price")
        local qtyLabel   = tr("UI_RadioTrader_Quantity", "Quantity")
        local unitLabel  = tr("UI_RadioTrader_Units", "units")
        local titleText  = (entry.count and entry.count > 1) and ("%s x %d"):format(dispName, entry.count) or dispName
        self.labelItemDetail:setName(
            ("[%s]\n%s: %d CR\n%s: %d %s\nID: %s"):format(
                titleText, priceLabel, effPrice, qtyLabel, entry.count or 1, unitLabel, entry.id))
    else
        self.selectedItem = nil
        self.labelItemDetail:setName(tr("UI_RadioTrader_SelectItem", "Select an item to view details"))
    end
    self:refreshCartUI()
end

-- ---------------------------------------------------------------------------
-- ModData から直接クレジット・ステートを同期（SP環境・最新化保証）
-- ---------------------------------------------------------------------------
function RadioTrader_UI:refreshDataFromModData()
    local uname = (self.player and self.player.getUsername and self.player:getUsername()) or "singleplayer"
    if uname == "" then uname = "singleplayer" end

    -- クレジット同期
    local gmdKey = "RadioTrader_" .. uname
    if ModData and ModData.exists and ModData.exists(gmdKey) then
        local gmd = ModData.get(gmdKey)
        if gmd and gmd[RadioTrader_Config.KEY_CREDITS] ~= nil then
            self.credits = tonumber(gmd[RadioTrader_Config.KEY_CREDITS]) or self.credits
        end
    end

    -- タイマーステート同期
    local timerKey = "RadioTrader_Timer_" .. uname
    if ModData and ModData.exists and ModData.exists(timerKey) then
        local tdata = ModData.get(timerKey)
        if tdata then
            if tdata.state then
                self.deliveryState = tdata.state
            end
            if tdata.targetHour then
                local gt = getGameTime()
                if gt then
                    self.deliveryRemaining = math.max(0, tdata.targetHour - gt:getWorldAgeHours())
                end
            else
                self.deliveryRemaining = 0
            end
        end
    end

    -- ドロップボックス査定額のリアルタイム直接同期（クライアント即時計算）
    if RadioTrader_AssessContainer then
        local assessedItems, totalCredits, err = RadioTrader_AssessContainer(self.player)
        if not err then
            self.assessedCredits = totalCredits or 0
        else
            self.assessedCredits = 0
        end
    end
end

-- ---------------------------------------------------------------------------
-- 表示更新
-- ---------------------------------------------------------------------------
function RadioTrader_UI:updateStatusDisplay()
    -- 最新の ModData 情報を反映
    self:refreshDataFromModData()

    -- クレジット
    if self.labelCredits then
        local credLabel = tr("UI_RadioTrader_Credits", "Credits")
        self.labelCredits:setName(("%s: %d CR"):format(credLabel, self.credits))
    end

    -- 下取り査定額 ＆ 利用可能予算合計
    if self.labelAssess then
        local assessLabel = tr("UI_RadioTrader_Assess", "Drop Box Value")
        local totalBudget = self.credits + (self.assessedCredits or 0)
        self.labelAssess:setName(("%s: +%d CR (Total: %d CR)"):format(assessLabel, self.assessedCredits, totalBudget))
    end

    -- 配達ステート
    if self.labelDelivery then
        local delLabel = tr("UI_RadioTrader_Delivery", "Delivery")
        local state = self.deliveryState
        local cfg   = RadioTrader_Config
        if state == cfg.STATE_PENDING then
            local remH = math.floor(self.deliveryRemaining)
            local remM = math.floor((self.deliveryRemaining - remH) * 60)
            self.labelDelivery:setName(("%s: PENDING (%dh %02dm)"):format(delLabel, remH, remM))
        elseif state == cfg.STATE_APPROACHING then
            self.labelDelivery:setName(("%s: [!] APPROACHING"):format(delLabel))
        elseif state == cfg.STATE_READY_FOR_DROP then
            self.labelDelivery:setName(("%s: READY (Request at LZ)"):format(delLabel))
        elseif state == cfg.STATE_DELIVERING then
            self.labelDelivery:setName(("%s: [AIR] DELIVERING..."):format(delLabel))
        elseif state == cfg.STATE_COMPLETED then
            self.labelDelivery:setName(("%s: [OK] COMPLETED"):format(delLabel))
        else
            self.labelDelivery:setName(("%s: %s"):format(delLabel, tr("UI_RadioTrader_StateNone", "None")))
        end
    end

    -- 発注ボタンの有効・無効
    if self.btnOrder then
        local canOrder = (self.deliveryState == RadioTrader_Config.STATE_NONE
                       or self.deliveryState == RadioTrader_Config.STATE_COMPLETED)
        self.btnOrder.enable = canOrder
    end
end

-- ---------------------------------------------------------------------------
-- 無線通信ログへのテキスト追加
-- ---------------------------------------------------------------------------
function RadioTrader_UI:addLog(msg, r, g, b)
    if not self.logBox then return end
    r = r or COLOR_ACCENT.r
    g = g or COLOR_ACCENT.g
    b = b or COLOR_ACCENT.b
    self.logBox:addItem("> " .. msg, { r=r, g=g, b=b })

    -- 最新ログへの自動スクロール（最下部へ自動追従）
    local count = #self.logBox.items
    self.logBox.selected = count
    if self.logBox.ensureVisible then
        self.logBox:ensureVisible(count)
    end
    local totalH = count * (self.logBox.itemheight or 18)
    if totalH > self.logBox:getHeight() then
        self.logBox:setYScroll(self.logBox:getHeight() - totalH)
    end
end

-- ---------------------------------------------------------------------------
-- ボタンハンドラ
-- ---------------------------------------------------------------------------
function RadioTrader_UI:onCategoryClick(btn)
    self:loadCategory(btn.internal)
end

function RadioTrader_UI:onSellClick()
    -- 最新のコンテナ状態を同期
    self:refreshDataFromModData()
    if (self.assessedCredits or 0) <= 0 then
        self:addLog(tr("UI_RadioTrader_Err_NO_SELLABLE_ITEMS", "No sellable items in the LZ container."),
            COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        local sm = getSoundManager()
        if sm then sm:playUISound("AccessDenied") end
        return
    end

    self:addLog(tr("UI_RadioTrader_Log_Selling", "Sending sell request..."),
        COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
    print("[RadioTrader][UI] onSellClick: Requesting sell from server...")
    sendClientCommand(self.player, "RadioTrader", RadioTrader_Config.CMD_REQUEST_SELL, {})
end

function RadioTrader_UI:refreshCartUI()
    if not self.cartList then return end
    self.cartList:clear()
    local totalCost = 0
    local totalCount = 0

    for _, it in ipairs(self.cart) do
        self.cartList:addItem(it.name, it)
        totalCost = totalCost + it.price * it.quantity
        totalCount = totalCount + it.quantity
    end

    if #self.cart > 0 then
        self.cartList:setVisible(true)
        if self.labelGuideBody then self.labelGuideBody:setVisible(false) end
        if self.labelCartTitle then
            local titleText = tr("UI_RadioTrader_CartTitleWithCost", "Order Cart: %s items (%s CR)", tostring(totalCount), tostring(totalCost))
            self.labelCartTitle:setName(titleText)
        end
        if self.btnOrder then
            local batchOrderText = tr("UI_RadioTrader_OrderBatchBtn", "[Trade] Batch Order & Pickup (%s CR)", tostring(totalCost))
            self.btnOrder:setTitle(batchOrderText)
        end
    else
        self.cartList:setVisible(false)
        if self.labelGuideBody then self.labelGuideBody:setVisible(true) end
        if self.labelCartTitle then
            self.labelCartTitle:setName(tr("UI_RadioTrader_CartTitle", "Order Cart (Empty)"))
        end
        if self.btnOrder then
            if self.selectedItem then
                local effPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(self.selectedItem.price) or self.selectedItem.price
                self.btnOrder:setTitle(tr("UI_RadioTrader_OrderBtn", "[Trade] Order & Pickup") .. (" (%s CR)"):format(tostring(effPrice)))
            else
                self.btnOrder:setTitle(tr("UI_RadioTrader_OrderBtn", "[Trade] Order & Pickup"))
            end
        end
    end
end

function RadioTrader_UI:onAddToCartClick()
    if not self.selectedItem then
        self:addLog(tr("UI_RadioTrader_Log_SelectFirst", "Please select an item."),
            COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        return
    end
    local entry = self.selectedItem
    local dispName = getItemDisplayName(entry.id, entry.name)
    local effPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(entry.price) or entry.price

    local found = false
    for _, it in ipairs(self.cart) do
        if it.itemId == entry.id then
            it.quantity = it.quantity + 1
            found = true
            break
        end
    end
    if not found then
        table.insert(self.cart, {
            itemId   = entry.id,
            name     = dispName,
            price    = effPrice,
            quantity = 1,
        })
    end

    self:refreshCartUI()
    local sm = getSoundManager()
    if sm then sm:playUISound("UIAddItemToInventory") end
    self:addLog(tr("UI_RadioTrader_Log_CartAdded", "Added to cart: %s (%s CR)", dispName, tostring(effPrice)),
        COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b)
end

function RadioTrader_UI:onClearCartClick()
    self.cart = {}
    self:refreshCartUI()
    self:addLog(tr("UI_RadioTrader_Log_CartCleared", "Cart cleared."),
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b)
end

function RadioTrader_UI:onCartItemClick(index)
    local it = self.cart[index]
    if not it then return end
    if it.quantity > 1 then
        it.quantity = it.quantity - 1
    else
        table.remove(self.cart, index)
    end
    self:refreshCartUI()
    local sm = getSoundManager()
    if sm then sm:playUISound("UIRemoveItemFromInventory") end
end

function RadioTrader_UI:onOrderClick()
    if self.deliveryState ~= RadioTrader_Config.STATE_NONE
    and self.deliveryState ~= RadioTrader_Config.STATE_COMPLETED then
        self:addLog(tr("UI_RadioTrader_Log_DeliveryInProgress", "Delivery in progress. Please wait."),
            COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        return
    end

    if #self.cart > 0 then
        -- カート一括発注
        local totalCost = 0
        local itemsArg = {}
        for _, it in ipairs(self.cart) do
            totalCost = totalCost + it.price * it.quantity
            table.insert(itemsArg, {
                itemId   = it.itemId,
                quantity = it.quantity,
            })
        end

        local orderMsg = tr("UI_RadioTrader_Log_OrderingBatch", "Ordering %s items (Total: %s CR)...", tostring(#self.cart), tostring(totalCost))
        self:addLog(orderMsg, COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        print(("[RadioTrader][UI] onOrderClick: Placing batch order for %d items (%d CR)"):format(#self.cart, totalCost))
        sendClientCommand(self.player, "RadioTrader", RadioTrader_Config.CMD_REQUEST_TRADE, {
            items = itemsArg,
        })
        self.cart = {}
        self:refreshCartUI()
    else
        -- 単一アイテム発注
        if not self.selectedItem then
            self:addLog(tr("UI_RadioTrader_Log_SelectFirst", "Please select an item."),
                COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
            return
        end
        local entry = self.selectedItem
        local dispName = getItemDisplayName(entry.id, entry.name)
        local effPrice = RadioTrader_ItemsTable_GetEffectiveBuyPrice and RadioTrader_ItemsTable_GetEffectiveBuyPrice(entry.price) or entry.price
        local orderMsg = tr("UI_RadioTrader_Log_Ordering", "Ordering: %s (%s CR)...", dispName, tostring(effPrice))
        self:addLog(orderMsg, COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        print(("[RadioTrader][UI] onOrderClick: Placing order for %s (%s CR)"):format(entry.id, tostring(effPrice)))
        sendClientCommand(self.player, "RadioTrader", RadioTrader_Config.CMD_REQUEST_TRADE, {
            itemId   = entry.id,
            quantity = 1,
        })
    end
end

function RadioTrader_UI:onCloseClick()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ---------------------------------------------------------------------------
-- レンダリング（フレームごとに呼ばれる）
-- ---------------------------------------------------------------------------
function RadioTrader_UI:render()
    ISPanel.render(self)

    -- タイトルバー（多言語対応）
    self:drawRect(0, 0, self.width, 28, 1,
        COLOR_BG_DARK.r, COLOR_BG_DARK.g, COLOR_BG_DARK.b)
    local titleText = tr("UI_RadioTrader_Title", "Radio Trading Network") .. " | "
        .. tr("UI_RadioTrader_Credits", "Credits") .. (": %d CR"):format(self.credits)
    self:drawTextCentre(titleText, self.width / 2, 6, 0.2, 0.9, 0.5, 1, FONT)

    -- カテゴリタブ列の背景（下部ログ欄に被らないよう中央リストの高さ listH までに制限）
    local listH = PANEL_H - 30 - LOG_H - BTN_H - MARGIN * 4
    self:drawRect(MARGIN - 2, 30, TAB_W, listH,
        0.85, COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b)

    -- リストボックス選択ハイライト（アイテムリストの onItemSelect を毎フレームチェック）
    if self.itemList and self.itemList.selected ~= self._lastSelected then
        self._lastSelected = self.itemList.selected
        self:onItemSelect()
    end

    -- 定期的な ModData 同期（30フレームごと）
    self._tickCount = (self._tickCount or 0) + 1
    if self._tickCount % 30 == 0 then
        self:refreshDataFromModData()
        self:updateStatusDisplay()
    end
end

-- ---------------------------------------------------------------------------
-- 周波数再探索（リロール）ボタン クリック
-- ---------------------------------------------------------------------------
function RadioTrader_UI:onRerollClick()
    local rerollCost = 50
    if self.credits < rerollCost then
        local errText = tr("UI_RadioTrader_Err_NOT_ENOUGH_CREDITS_REROLL",
            "Not enough credits to inquire for other supplies (Need 50 CR).")
        self:addLog("[!] " .. errText, COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        return
    end

    if not isClient() then
        -- シングルプレイヤー即時処理
        if RadioTrader_ServerEngine and RadioTrader_ServerEngine.deductCredits and RadioTrader_ServerEngine.getOrUpdateDailyShop then
            RadioTrader_ServerEngine.deductCredits(self.player, rerollCost)
            local newDaily = RadioTrader_ServerEngine.getOrUpdateDailyShop(true)
            self.credits = RadioTrader_ServerEngine.getCredits(self.player)
            self:onServerNotify("rerollSuccess", { items = newDaily, cost = rerollCost })
            return
        end
    end

    sendClientCommand(self.player, "RadioTrader", "rerollDaily", {})
end

-- ---------------------------------------------------------------------------
-- サーバーからの通知受信（ClientBridge から呼ばれる）
-- ---------------------------------------------------------------------------
function RadioTrader_UI:onServerNotify(cmd, args)
    local cfg = RadioTrader_Config

    if cmd == cfg.CMD_CREDIT_UPDATE or cmd == "creditUpdate" then
        if args and args.credits ~= nil then
            self.credits = tonumber(args.credits) or self.credits
        end
        self:updateStatusDisplay()

    elseif cmd == "sellSuccess" then
        local count      = args and tostring(args.count) or "0"
        local credits    = args and tostring(args.credits) or "0"
        local unaccepted = args and tonumber(args.unacceptedCount) or 0
        local logMsg
        if unaccepted > 0 then
            logMsg = tr("UI_RadioTrader_Log_SellSuccessWithLeftover",
                "Sale complete: Sold %s items for %s CR. (%s unaccepted items remain)",
                count, credits, tostring(unaccepted))
        else
            logMsg = tr("UI_RadioTrader_Log_SellSuccess",
                "Sale complete: Sold %s items for %s CR.", count, credits)
        end
        self:addLog(logMsg, COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b)
        self.assessedCredits = 0
        self:updateStatusDisplay()

    elseif cmd == cfg.CMD_TRADE_ACCEPTED then
        self.deliveryState = cfg.STATE_PENDING
        local itemName = args.itemId and getItemDisplayName(args.itemId, args.itemName) or (args.itemName or "Goods")
        self:addLog(tr("UI_RadioTrader_Log_Accepted", "Order accepted. Dispatched transport heli for %s.", itemName))
        if args.tradeInCount and args.tradeInCount > 0 then
            self:addLog(tr("UI_RadioTrader_Log_TradeInOffset", "Trade-in: Collected %s items (+%s CR offset applied).", tostring(args.tradeInCount), tostring(args.tradeInCredits or 0)),
                COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b)
        end
        if args.hasTraderStash then
            self:addLog(tr("UI_RadioTrader_Log_StashAccepted", "[Radio] '...That was my personal stash, you know.'"),
                COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        end
        if args.newCredits ~= nil then
            self.credits = tonumber(args.newCredits) or self.credits
        end
        self.assessedCredits = 0
        self:updateStatusDisplay()

    elseif cmd == cfg.CMD_HELI_APPROACH then
        self.deliveryState = cfg.STATE_APPROACHING
        local isMega = args and args.isMegaHorde
        if isMega then
            self:addLog(tr("UI_RadioTrader_Log_ApproachingMega", "[!] DANGER: Massive zombie horde converging on LZ!"),
                COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        else
            self:addLog(tr("UI_RadioTrader_Log_Approaching", "[!] Approaching drop point."),
                COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        end
        self:updateStatusDisplay()

    elseif cmd == cfg.CMD_REQUEST_DROP then
        self.deliveryState = cfg.STATE_READY_FOR_DROP
        self:addLog(tr("UI_RadioTrader_Log_ReadyForDrop", "Drop ready. Request air drop at LZ."),
            COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        self:updateStatusDisplay()

    elseif cmd == cfg.CMD_DELIVERY_DONE then
        self.deliveryState = cfg.STATE_COMPLETED
        local rawName   = args.itemId and getItemDisplayName(args.itemId, args.itemName) or (args.itemName or "Goods")
        local count     = args.count or 1
        local bonusId   = args.bonusItemName
        local bonusName = bonusId and getItemDisplayName(bonusId, bonusId)
        local isMega    = args and args.isMegaHorde

        local itemDisplay = rawName
        if not string.find(rawName, " x%d+") and not string.find(rawName, "%+%d+") then
            itemDisplay = rawName .. " x" .. tostring(count)
        end

        local logMsg
        if isMega then
            if bonusName then
                logMsg = tr("UI_RadioTrader_Log_DeliveredWithBonusMega",
                    "[!] Supply drop complete (+ %s)! Massive horde active! Grab %s and evacuate!", bonusName, itemDisplay)
            else
                logMsg = tr("UI_RadioTrader_Log_DeliveredMega",
                    "[!] Supply drop complete! Massive horde active! Grab %s and evacuate!", itemDisplay)
            end
            self:addLog(logMsg, COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)
        else
            if bonusName then
                logMsg = tr("UI_RadioTrader_Log_DeliveredWithBonus",
                    "Supply drop complete (%s). 'Threw in a little extra for ya!' (+ %s).",
                    itemDisplay, bonusName)
            else
                logMsg = tr("UI_RadioTrader_Log_Delivered",
                    "Supply drop complete. Check LZ for %s.", itemDisplay)
            end
            self:addLog(logMsg, COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b)
        end

        if args and args.hasLunchboxBonus then
            self:addLog(tr("UI_RadioTrader_Log_LunchboxBonus",
                "[Bonus] Crew appreciated your valuable salvage and packed a fresh lunchbox!"),
                COLOR_SUCCESS.r, COLOR_SUCCESS.g, COLOR_SUCCESS.b)
        end
        self:updateStatusDisplay()

    elseif cmd == "assessmentResult" then
        self.assessedCredits = tonumber(args.credits or args.assessed) or 0
        self:updateStatusDisplay()
        local accepted   = tonumber(args.acceptedCount) or 0
        local unaccepted = tonumber(args.unacceptedCount) or 0

        if accepted > 0 and unaccepted > 0 then
            self:addLog(tr("UI_RadioTrader_Log_AssessedMixed",
                "Assessment complete: %s CR (%s items accepted / %s items unaccepted)",
                tostring(self.assessedCredits), tostring(accepted), tostring(unaccepted)))
        elseif accepted > 0 then
            self:addLog(tr("UI_RadioTrader_Log_Assessed",
                "Assessment complete: Drop box contents valued at %s CR (%s items)",
                tostring(self.assessedCredits), tostring(accepted)))
        elseif unaccepted > 0 then
            self:addLog(tr("UI_RadioTrader_Log_AssessedAllUnaccepted",
                "Assessment: 0 CR (All %s items in drop box are unaccepted)",
                tostring(unaccepted)), COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b)
        else
            self:addLog(tr("UI_RadioTrader_Log_AssessedEmpty",
                "Assessment: 0 CR (Drop box is empty)"))
        end

    elseif cmd == "error" then
        local errMsg = args and args.message
        if args and args.errCode then
            errMsg = tr("UI_RadioTrader_Err_" .. args.errCode, args.message or args.errCode)
        end
        self:addLog(tr("UI_RadioTrader_Log_Error", "[!] Error: %s", tostring(errMsg or "Unknown Error")),
            COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b)

    elseif cmd == "stateRefresh" then
        self.deliveryState     = args.state or self.deliveryState
        self.deliveryRemaining = args.remaining or self.deliveryRemaining
        if args.credits ~= nil then
            self.credits = tonumber(args.credits) or self.credits
        end
        self:updateStatusDisplay()

    elseif cmd == "rerollSuccess" then
        if args and args.items and RadioTrader_Shop then
            RadioTrader_Shop.Daily = args.items
        end
        self:refreshDataFromModData()
        self:updateStatusDisplay()
        local cost = args and args.cost or 50
        self:addLog(tr("UI_RadioTrader_Log_RerollSuccess",
            "Asked 'Got anything else?' over the radio (-%s CR). Checked back stock.", tostring(cost)),
            COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b)
        if self.selectedCategory == "Daily" then
            self:loadCategory("Daily")
        end

    elseif cmd == "syncDailyShop" then
        if args and args.items and RadioTrader_Shop then
            RadioTrader_Shop.Daily = args.items
        end
        if self.selectedCategory == "Daily" then
            self:loadCategory("Daily")
        end
    end
end

-- ---------------------------------------------------------------------------
-- シングルトン UI インスタンスの表示・非表示制御
-- ---------------------------------------------------------------------------
RadioTrader_UI.instance = nil

function RadioTrader_UI.open(player)
    if not RadioTrader_UI.instance then
        RadioTrader_UI.instance = RadioTrader_UI:new(player)
        RadioTrader_UI.instance:initialise()
        RadioTrader_UI.instance:addToUIManager()
    else
        RadioTrader_UI.instance:refreshDataFromModData()
        RadioTrader_UI.instance:updateStatusDisplay()
        RadioTrader_UI.instance:setVisible(true)
        RadioTrader_UI.instance:addToUIManager()
    end
    -- 常に最新ステートと査定額・日替わり品をサーバーに照会
    if not isClient() and RadioTrader_ServerEngine and RadioTrader_ServerEngine.getOrUpdateDailyShop then
        RadioTrader_ServerEngine.getOrUpdateDailyShop(false)
        if RadioTrader_UI.instance.selectedCategory == "Daily" then
            RadioTrader_UI.instance:loadCategory("Daily")
        end
    else
        sendClientCommand(player, "RadioTrader", "requestDailyShop", {})
    end
    sendClientCommand(player, "RadioTrader", "requestState", {})
    sendClientCommand(player, "RadioTrader", "requestAssessment", {})
end
