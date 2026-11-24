-- Headless UI preview: resolves the anchors recorded by tools/test/wowstub.lua into absolute
-- rectangles and writes draw operations (one per line, tab separated) for tools/preview/render.py.
-- Usage (from a scenario script): local L = require("layout"); L.Dump(path)
local L = {}

local SW, SH = 1600, 900
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local LAYER = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 9 }

local cache
local function textWidth(t, size)
    if type(t) ~= "string" then return 0 end
    t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "WW")
    local w = 0
    for c in t:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        w = w + (#c > 1 and size * 0.92 or size * 0.55)
    end
    return w
end

local function anchorXY(l, b, r, t, p)
    local x = p:find("LEFT") and l or (p:find("RIGHT") and r or (l + r) / 2)
    local y = p:find("TOP") and t or (p:find("BOTTOM") and b or (b + t) / 2)
    return x, y
end

local rect
rect = function(f)
    if f == UIParent or f == nil then return 0, 0, SW, SH end
    if cache[f] then return unpack(cache[f]) end
    cache[f] = { 0, 0, 0, 0 }   -- cycle guard
    local parent = f._parent or UIParent
    local sc = f._scale or 1
    local w, h = (f._w or 0) * sc, (f._h or 0) * sc
    if f._kind == "FontString" and (not f._wset) then
        local tw = textWidth(f._text, f._fontSize or 12)
        if (f._w or 100) == 100 then w = tw else w = math.max(f._w, 0) end
        if (f._h or 100) == 100 then h = (f._fontSize or 12) + 2 end
    end
    local l, b, r, t
    if f._allPoints then
        local rel = f._allPoints == true and parent or f._allPoints
        l, b, r, t = rect(rel)
    elseif f._points and #f._points > 0 then
        local L_, R_, CX, T_, B_, CY
        for _, p in ipairs(f._points) do
            local rl, rb, rr, rt = rect(p.rel or parent)
            local ax, ay = anchorXY(rl, rb, rr, rt, p.relPoint)
            ax, ay = ax + p.x, ay + p.y
            local pt = p.point
            if pt:find("LEFT") then L_ = ax elseif pt:find("RIGHT") then R_ = ax else CX = ax end
            if pt:find("TOP") then T_ = ay elseif pt:find("BOTTOM") then B_ = ay else CY = ay end
        end
        if L_ and R_ then l, r = L_, R_ elseif L_ then l, r = L_, L_ + w elseif R_ then l, r = R_ - w, R_
        elseif CX then l, r = CX - w / 2, CX + w / 2 else l, r = 0, w end
        if T_ and B_ then b, t = B_, T_ elseif T_ then b, t = T_ - h, T_ elseif B_ then b, t = B_, B_ + h
        elseif CY then b, t = CY - h / 2, CY + h / 2 else b, t = 0, h end
    else
        return nil
    end
    cache[f] = { l, b, r, t }
    return l, b, r, t
end

local function visible(f)
    while f and f ~= UIParent do
        if f._shown == false then return false end
        f = f._parent
    end
    return true
end

local function col(c, default)
    c = c or default
    return string.format("%.3f,%.3f,%.3f,%.3f", c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
end

local function clean(s) return (tostring(s or ""):gsub("[\t\n]", function(c) return c == "\n" and "\\n" or " " end)) end

function L.Rect(f) cache = cache or {}; return rect(f) end

function L.Dump(path)
    cache = {}
    local out = {}
    local function emit(...) out[#out + 1] = table.concat({ ... }, "\t") end
    local function alphaOf(f)
        local a = 1
        while f and f ~= UIParent do a = a * (f._alpha or 1); f = f._parent end
        return a
    end
    local function drawRegion(rg)
        if rg._shown == false then return end
        local l, b, r, t = rect(rg)
        if not l then return end
        local a = alphaOf(rg)
        if rg._kind == "Texture" then
            if rg._color then
                emit("fill", l, b, r, t, col(rg._color), a)
            elseif rg._file then
                local tc = rg._texCoord and table.concat(rg._texCoord, ",") or ""
                emit("tex", l, b, r, t, clean(rg._file), col(rg._vertex, { 1, 1, 1, 1 }), a, rg._desat and 1 or 0, tc)
            end
        elseif rg._kind == "FontString" and rg._text and rg._text ~= "" then
            emit("text", l, b, r, t, rg._fontSize or 12, col(rg._textColor, { 1, 0.82, 0, 1 }), a,
                rg._justifyH or "CENTER", rg._justifyV or "MIDDLE", rg._fontFlags or "", clean(rg._text))
        end
    end
    local function drawFrame(f, depth)
        if f._shown == false then return end
        local l, b, r, t = rect(f)
        local a = alphaOf(f)
        if l then
            if f._backdrop then
                local bd = f._backdrop
                emit("backdrop", l, b, r, t, col(f._bdColor, { 0, 0, 0, 1 }), col(f._bdBorder, { 1, 1, 1, 1 }), a,
                    clean(bd.bgFile), clean(bd.edgeFile), bd.edgeSize or 0)
            end
            if f._kind == "StatusBar" then
                local lo, hi = f._min or 0, f._max or 1
                local frac = hi > lo and ((f._value or 0) - lo) / (hi - lo) or 0
                emit("bar", l, b, r, t, math.max(0, math.min(1, frac)), col(f._barColor, { 0.2, 0.8, 0.2, 1 }), a,
                    clean(f._barTexture))
            end
            if f._model then emit("model", l, b, r, t, clean(f._model), a) end
            if (f._kind == "Button" or f._kind == "CheckButton") and f._template == "UIPanelButtonTemplate" then
                emit("wowbutton", l, b, r, t, a, f._enabled == false and 0 or 1)
            end
        end
        -- regions by layer, then children by strata / level / creation
        local regs = {}
        for _, rg in ipairs(f._regions or {}) do regs[#regs + 1] = rg end
        table.sort(regs, function(x, y)
            local lx, ly = LAYER[x._layer] or 3, LAYER[y._layer] or 3
            if lx ~= ly then return lx < ly end
            return (x._order or 0) < (y._order or 0)
        end)
        for _, rg in ipairs(regs) do if (LAYER[rg._layer] or 3) < 9 then drawRegion(rg) end end
        if l and f._template == "UIPanelButtonTemplate" and f._text and f._text ~= "" then
            local fs = f._fs
            emit("text", l, b, r, t, fs and fs._fontSize or 12, col(fs and fs._textColor, { 1, 0.82, 0, 1 }), a,
                "CENTER", "MIDDLE", "", clean(f._text))
        end
        local kids = {}
        for _, c in ipairs(f._children or {}) do kids[#kids + 1] = c end
        table.sort(kids, function(x, y)
            local sx, sy = STRATA[x._strata or ""] or 0, STRATA[y._strata or ""] or 0
            if sx ~= sy then return sx < sy end
            if (x._level or 0) ~= (y._level or 0) then return (x._level or 0) < (y._level or 0) end
            return (x._order or 0) < (y._order or 0)
        end)
        for _, c in ipairs(kids) do drawFrame(c, depth + 1) end
    end
    emit("screen", SW, SH)
    drawFrame(UIParent, 0)
    local fh = assert(io.open(path, "w"))
    fh:write(table.concat(out, "\n"), "\n")
    fh:close()
    return #out
end

return L
