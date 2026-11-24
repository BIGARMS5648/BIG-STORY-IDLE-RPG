-- Very small WoW UI API stub: every frame/region method exists and returns
-- something harmless, so UI code paths can be executed headless.
local Stub = {}

local function noop() end
local frameMT = {}
frameMT.__index = function(t, k)
    local v = rawget(frameMT, k)
    if v ~= nil then return v end
    -- unknown WoW methods (CamelCase) return a no-op; data fields stay nil
    if type(k) == "string" and k:match("^%u") then
        return function(self, ...) return nil end
    end
    return nil
end

local function newObject(kind)
    local o = setmetatable({ _kind = kind, _shown = true, _scripts = {}, _w = 100, _h = 100, _text = "" }, frameMT)
    return o
end

function frameMT.CreateTexture(self) return newObject("Texture") end
function frameMT.CreateFontString(self) return newObject("FontString") end
function frameMT.GetFont(self) return "Fonts\\2002.TTF", 12, "" end
function frameMT.SetScript(self, name, fn) self._scripts[name] = fn end
function frameMT.GetScript(self, name) return self._scripts[name] end
function frameMT.HookScript(self, name, fn) self._scripts[name] = fn end
function frameMT.Show(self) self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
function frameMT.Hide(self) self._shown = false end
function frameMT.SetShown(self, v) if v then self:Show() else self:Hide() end end
function frameMT.IsShown(self) return self._shown end
function frameMT.IsVisible(self) return self._shown end
function frameMT.SetSize(self, w, h) self._w, self._h = w, h end
function frameMT.SetWidth(self, w) self._w = w end
function frameMT.SetHeight(self, h) self._h = h end
function frameMT.GetWidth(self) return self._w end
function frameMT.GetHeight(self) return self._h end
function frameMT.SetText(self, t) self._text = t end
function frameMT.GetText(self) return self._text end
function frameMT.GetStringWidth(self) return #(self._text or "") * 6 end
function frameMT.GetFontString(self) return self._fs or newObject("FontString") end
function frameMT.GetChecked(self) return self._checked end
function frameMT.SetChecked(self, v) self._checked = v end
function frameMT.GetFrameLevel(self) return 1 end
function frameMT.GetCenter(self) return 0, 0 end
function frameMT.GetEffectiveScale(self) return 1 end
function frameMT.Click(self) if self._scripts.OnClick then self._scripts.OnClick(self, "LeftButton") end end

function Stub.Install()
    CreateFrame = function(kind, name, parent, template)
        local f = newObject(kind)
        f._fs = newObject("FontString")
        if name then _G[name] = f end
        return f
    end
    UIParent = newObject("Frame")
    Minimap = newObject("Frame")
    GameTooltip = newObject("GameTooltip")
    UIErrorsFrame = { AddMessage = function(_, msg) print("TOAST", msg) end }
    UISpecialFrames = {}
    StaticPopupDialogs = {}
    StaticPopup_Show = function(name)
        local d = StaticPopupDialogs[name]
        if d and d.OnAccept then d.OnAccept() end
    end
    BackdropTemplateMixin = {}
    GetTime = function() return os.clock() end
    GetCursorPosition = function() return 0, 0 end
    tinsert = table.insert
    C_Timer = {
        After = function(sec, fn) Stub.timers[#Stub.timers + 1] = fn end,
        NewTicker = function(sec, fn) Stub.ticker = fn; return { Cancel = noop } end,
    }
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function() return true end,
        SendAddonMessage = function(prefix, msg, chan, target)
            Stub.sent[#Stub.sent + 1] = { prefix = prefix, msg = msg, chan = chan, target = target }
        end,
    }
    GetSpellInfo = function(id) return "주문" .. tostring(id), nil, 136000 + (id % 1000) end
    IsInGuild = function() return true end
    IsInGroup = function() return false end
    IsInRaid = function() return false end
    UnitClass = function() return "전사", "WARRIOR" end
    Stub.timers = {}
    Stub.sent = {}
end

function Stub.RunTimers()
    local list = Stub.timers
    Stub.timers = {}
    for _, fn in ipairs(list) do fn() end
end

return Stub
