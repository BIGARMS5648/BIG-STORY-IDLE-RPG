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

-- layout recording (used by tools/preview to draw the UI headless)
Stub.order = 0
local function child(self, o)
    Stub.order = Stub.order + 1
    o._order = Stub.order
    o._parent = self
    self._regions = self._regions or {}
    self._regions[#self._regions + 1] = o
    return o
end
function frameMT.CreateTexture(self, name, layer)
    local t = child(self, newObject("Texture"))
    t._layer = layer or "ARTWORK"
    return t
end
function frameMT.CreateFontString(self, name, layer, inherits)
    local t = child(self, newObject("FontString"))
    t._layer = layer or "ARTWORK"
    t._fontObj = inherits
    t._fontSize = 12
    return t
end
function frameMT.SetPoint(self, point, a, b, c, d)
    local rel, relPoint, x, y
    if type(a) == "number" or a == nil then rel, relPoint, x, y = nil, point, a, b
    elseif type(b) == "number" or b == nil then rel, relPoint, x, y = a, point, b, c
    else rel, relPoint, x, y = a, b, c, d end
    if type(rel) == "string" then rel = _G[rel] end
    self._points = self._points or {}
    for i = #self._points, 1, -1 do if self._points[i].point == point then table.remove(self._points, i) end end
    self._points[#self._points + 1] = { point = point, rel = rel, relPoint = relPoint or point, x = x or 0, y = y or 0 }
end
function frameMT.ClearAllPoints(self) self._points = nil; self._allPoints = nil end
function frameMT.SetAllPoints(self, rel) self._points = nil; self._allPoints = rel or true end
function frameMT.GetPoint(self, i)
    local p = self._points and self._points[i or 1]
    if p then return p.point, p.rel, p.relPoint, p.x, p.y end
end
function frameMT.GetNumPoints(self) return self._points and #self._points or 0 end
function frameMT.SetBackdrop(self, bd) self._backdrop = bd end
function frameMT.SetBackdropColor(self, r, g, b, a) self._bdColor = { r, g, b, a or 1 } end
function frameMT.SetBackdropBorderColor(self, r, g, b, a) self._bdBorder = { r, g, b, a or 1 } end
function frameMT.SetColorTexture(self, r, g, b, a) self._color = { r, g, b, a or 1 }; self._file = nil end
function frameMT.SetTexture(self, f, ...)
    if type(f) == "number" and select("#", ...) >= 2 then self._color = { f, ... }; return end
    self._file = f; self._color = nil
end
function frameMT.GetTexture(self) return self._file end
function frameMT.SetVertexColor(self, r, g, b, a) self._vertex = { r, g, b, a or 1 } end
function frameMT.SetTexCoord(self, ...) self._texCoord = { ... } end
function frameMT.SetDesaturated(self, v) self._desat = v end
function frameMT.SetAlpha(self, a) self._alpha = a end
function frameMT.GetAlpha(self) return self._alpha or 1 end
function frameMT.SetTextColor(self, r, g, b, a) self._textColor = { r, g, b, a or 1 } end
function frameMT.SetFont(self, path, size, flags) self._fontSize = size or self._fontSize; self._fontFlags = flags; return true end
function frameMT.SetFontObject(self, o) self._fontObj = o end
function frameMT.SetJustifyH(self, v) self._justifyH = v end
function frameMT.SetJustifyV(self, v) self._justifyV = v end
function frameMT.SetWordWrap(self, v) self._wrap = v end
function frameMT.SetMinMaxValues(self, lo, hi) self._min, self._max = lo, hi end
function frameMT.GetMinMaxValues(self) return self._min or 0, self._max or 1 end
function frameMT.SetValue(self, v) self._value = v end
function frameMT.GetValue(self) return self._value or 0 end
function frameMT.SetStatusBarColor(self, r, g, b, a) self._barColor = { r, g, b, a or 1 } end
function frameMT.SetStatusBarTexture(self, t) self._barTexture = t end
function frameMT.SetFrameStrata(self, s) self._strata = s end
function frameMT.GetFrameStrata(self) return self._strata or "MEDIUM" end
function frameMT.SetFrameLevel(self, l) self._level = l end
function frameMT.SetScale(self, s) self._scale = s end
function frameMT.GetScale(self) return self._scale or 1 end
function frameMT.SetDisplayInfo(self, id) self._model = "display " .. tostring(id) end
function frameMT.SetCreature(self, id) self._model = "npc " .. tostring(id) end
function frameMT.SetUnit(self, u) self._model = "unit " .. tostring(u) end
function frameMT.SetCustomRace(self, r, s) self._model = "race " .. tostring(r) end
function frameMT.GetParent(self) return self._parent end
function frameMT.SetEnabled(self, v) self._enabled = v and true or false end
function frameMT.Enable(self) self._enabled = true end
function frameMT.Disable(self) self._enabled = false end
function frameMT.IsEnabled(self) return self._enabled ~= false end
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
    UIParent = newObject("Frame")
    UIParent._w, UIParent._h = 1600, 900
    CreateFrame = function(kind, name, parent, template)
        local f = newObject(kind)
        f._fs = newObject("FontString")
        f._fs._parent = f
        f._template = template
        Stub.order = Stub.order + 1
        f._order = Stub.order
        f._parent = parent or UIParent
        local p = f._parent
        if type(p) == "table" then
            p._children = p._children or {}
            p._children[#p._children + 1] = f
        end
        if name then _G[name] = f end
        return f
    end
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
