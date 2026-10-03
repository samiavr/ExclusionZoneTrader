-- =============================================================================
-- ISRadioTrader_RequestDropAction.lua
-- [Client] 投下要請アクション (約10秒のボックス操作・ごそごそモーション)
-- =============================================================================

require "TimedActions/ISBaseTimedAction"

ISRadioTrader_RequestDropAction = ISBaseTimedAction:derive("ISRadioTrader_RequestDropAction")

function ISRadioTrader_RequestDropAction:isValid()
    if not self.character then return false end
    local cfg = RadioTrader_Config
    local deliveryState = nil
    local uname = self.character.getUsername and self.character:getUsername()
    if not uname or uname == "" then uname = "singleplayer" end
    local timerKey = "RadioTrader_Timer_" .. uname
    if ModData and ModData.exists and ModData.exists(timerKey) then
        local tdata = ModData.get(timerKey)
        if tdata and tdata.state then
            deliveryState = tdata.state
        end
    end
    return deliveryState == cfg.STATE_READY_FOR_DROP
end

function ISRadioTrader_RequestDropAction:update()
    if self.containerObj and self.containerObj:getSquare() then
        self.character:faceLocation(self.containerObj:getX(), self.containerObj:getY())
    end
end

function ISRadioTrader_RequestDropAction:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISRadioTrader_RequestDropAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISRadioTrader_RequestDropAction:perform()
    local cfg = RadioTrader_Config
    sendClientCommand(self.character, "RadioTrader", cfg.CMD_REQUEST_DROP, {})
    -- ユーザー指定: 完了時の吹き出し（Say）は無し
    ISBaseTimedAction.perform(self)
end

function ISRadioTrader_RequestDropAction:new(character, containerObj)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.containerObj = containerObj
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 500 -- 約10秒 (50fps * 10 = 500 ticks)
    return o
end
