-- Widget helpers shared by every panel (메이플 키우기-style look, WoW client textures only).
local ADDON, ns = ...
local W = {}
ns.W = W

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

W.COLORS = {
    gold = { 1, 0.82, 0 },
    white = { 1, 1, 1 },
    gray = { 0.6, 0.6, 0.6 },
    green = { 0.3, 1, 0.3 },
    red = { 1, 0.3, 0.3 },
    blue = { 0.4, 0.7, 1 },
    purple = { 0.75, 0.45, 1 },
    orange = { 1, 0.55, 0.1 },
}

-- grade colors (노말 → 이터니티), WoW item-quality flavored
W.GRADE_COLORS = {
    [1] = { 0.85, 0.85, 0.85 }, [2] = { 0.25, 0.6, 1 }, [3] = { 0.65, 0.35, 1 }, [4] = { 1, 0.75, 0.15 },
    [5] = { 0.45, 1, 0.35 }, [6] = { 1, 0.5, 0.1 }, [7] = { 0.9, 0.8, 0.5 }, [8] = { 0.35, 0.95, 1 },
}

function W.GradeColor(g)
    local c = W.GRADE_COLORS[g] or W.COLORS.white
    return c[1], c[2], c[3]
end

function W.Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- 메이플 키우기-style theme: dark navy rounded panels, cyan action buttons, green confirm buttons,
-- orange 도전, gray when disabled. Only client textures (WHITE8X8 + tooltip border for round corners).
W.THEME = {
    panel = { 0.11, 0.13, 0.17, 0.96 }, panelBorder = { 0.27, 0.31, 0.38, 1 },
    header = { 0.07, 0.08, 0.11, 0.98 }, card = { 0.17, 0.2, 0.25, 0.97 }, cardBorder = { 0.27, 0.31, 0.38, 1 },
    cyan = { 0.11, 0.69, 0.84 }, green = { 0.53, 0.78, 0.12 }, orange = { 0.97, 0.58, 0.12 },
    gray = { 0.36, 0.38, 0.42 }, red = { 0.85, 0.22, 0.2 }, dim = { 0.72, 0.74, 0.78 },
}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROUND = "Interface\\Tooltips\\UI-Tooltip-Border"

local function backdrop(f, bg, border, edge)
    if not f.SetBackdrop then return end
    f:SetBackdrop({ bgFile = WHITE, edgeFile = ROUND, tile = false, edgeSize = edge or 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end
W.Backdrop = backdrop

---------------------------------------------------------------------------
-- UI kit art (the user's own assets, Media/UI/*.tga; Data/UIArt.lua)
---------------------------------------------------------------------------
local function art(name) return ns.Data.UIArt and ns.Data.UIArt[name] end
W.ArtInfo = art

-- a plain texture showing a whole piece
function W.Art(parent, name, layer, sub)
    local a = art(name)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub)
    if a then
        t:SetTexture(a.file)
        t:SetTexCoord(0, a.w / a.cw, 0, a.h / a.ch)
    end
    return t
end

function W.SetArt(t, name)
    local a = art(name)
    if not a then return end
    t:SetTexture(a.file)
    t:SetTexCoord(0, a.w / a.cw, 0, a.h / a.ch)
end

-- nine-slice frame from a piece with slice = {l, r, t, b}; top / bottom ornaments (ot / ob wide) keep
-- their size in the middle of the edge. scale = screen pixels per texture pixel.
function W.Slice(f, name, scale, opts)
    local a = art(name)
    if not a or not a.slice then return end
    opts = opts or {}
    scale = scale or 0.5
    if f.slices then for _, t in ipairs(f.slices) do t:Hide() end end
    local pieces = {}
    f.slices = pieces
    local W_, H_, CW, CH = a.w, a.h, a.cw, a.ch
    local l, r, t, b = a.slice[1], a.slice[2], a.slice[3], a.slice[4]
    local layer = opts.layer or "BACKGROUND"
    local function piece(u0, u1, v0, v1, sub)
        local tx = f:CreateTexture(nil, layer, nil, sub or 0)
        tx:SetTexture(a.file)
        tx:SetTexCoord(u0 / CW, u1 / CW, v0 / CH, v1 / CH)
        pieces[#pieces + 1] = tx
        return tx
    end
    local tl = piece(0, l, 0, t, 1); tl:SetSize(l * scale, t * scale); tl:SetPoint("TOPLEFT")
    local tr = piece(W_ - r, W_, 0, t, 1); tr:SetSize(r * scale, t * scale); tr:SetPoint("TOPRIGHT")
    local bl = piece(0, l, H_ - b, H_, 1); bl:SetSize(l * scale, b * scale); bl:SetPoint("BOTTOMLEFT")
    local br = piece(W_ - r, W_, H_ - b, H_, 1); br:SetSize(r * scale, b * scale); br:SetPoint("BOTTOMRIGHT")
    local function edge(rowTop, rowH, v0, v1, orn, anchorL, anchorR, sideV)
        if orn and orn > 0 then
            local mid = piece((W_ - orn) / 2, (W_ + orn) / 2, v0, v1, 1)
            mid:SetSize(orn * scale, rowH * scale)
            mid:SetPoint(sideV, f, sideV, 0, 0)
            local lf = piece(l, (W_ - orn) / 2, v0, v1)
            lf:SetPoint(sideV .. "LEFT", anchorL, sideV .. "RIGHT")
            lf:SetPoint(sideV .. "RIGHT", mid, sideV .. "LEFT")
            lf:SetHeight(rowH * scale)
            local rf = piece((W_ + orn) / 2, W_ - r, v0, v1)
            rf:SetPoint(sideV .. "LEFT", mid, sideV .. "RIGHT")
            rf:SetPoint(sideV .. "RIGHT", anchorR, sideV .. "LEFT")
            rf:SetHeight(rowH * scale)
        else
            local e = piece(l, W_ - r, v0, v1)
            e:SetPoint(sideV .. "LEFT", anchorL, sideV .. "RIGHT")
            e:SetPoint(sideV .. "RIGHT", anchorR, sideV .. "LEFT")
            e:SetHeight(rowH * scale)
        end
    end
    edge(true, t, 0, t, a.ot, tl, tr, "TOP")
    edge(false, b, H_ - b, H_, a.ob, bl, br, "BOTTOM")
    local le = piece(0, l, t, H_ - b); le:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); le:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); le:SetWidth(l * scale)
    local re = piece(W_ - r, W_, t, H_ - b); re:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); re:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); re:SetWidth(r * scale)
    if opts.center ~= false then
        local c = piece(l, W_ - r, t, H_ - b, -1)
        c:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT")
        c:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")
    end
    if f.SetBackdrop and opts.keepBackdrop ~= true then f:SetBackdrop(nil) end
    return pieces
end

-- horizontal three-slice (buttons, bars): caps keep their width, the middle stretches
function W.Slice3(f, name, height, layer)
    local a = art(name)
    if not a or not a.slice then return end
    local s = height / a.h
    local l, r = a.slice[1], a.slice[2]
    f.slices = f.slices or {}
    local function piece(u0, u1)
        local tx = f:CreateTexture(nil, layer or "BACKGROUND")
        tx:SetTexture(a.file)
        tx:SetTexCoord(u0 / a.cw, u1 / a.cw, 0, a.h / a.ch)
        f.slices[#f.slices + 1] = tx
        return tx
    end
    local L = piece(0, l); L:SetSize(l * s, height); L:SetPoint("LEFT")
    local R = piece(a.w - r, a.w); R:SetSize(r * s, height); R:SetPoint("RIGHT")
    local M = piece(l, a.w - r); M:SetPoint("TOPLEFT", L, "TOPRIGHT"); M:SetPoint("BOTTOMRIGHT", R, "BOTTOMLEFT")
    return { L, M, R }
end

function W.SetSlice3(pieces, name)
    local a = art(name)
    if not (a and pieces) then return end
    local l, r = a.slice[1], a.slice[2]
    local cuts = { { 0, l }, { l, a.w - r }, { a.w - r, a.w } }
    for i, tx in ipairs(pieces) do
        tx:SetTexture(a.file)
        tx:SetTexCoord(cuts[i][1] / a.cw, cuts[i][2] / a.cw, 0, a.h / a.ch)
    end
end

function W.Panel(parent, w, h, alpha)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    if w then f:SetSize(w, h) end
    local c = W.THEME.panel
    backdrop(f, { c[1], c[2], c[3], alpha or c[4] }, W.THEME.panelBorder, 14)
    if art("frame_big") then W.Slice(f, "frame_big", 0.42) end
    return f
end

-- light card on a panel (list rows, slots)
function W.Card(parent, w, h)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    if w then f:SetSize(w, h) end
    backdrop(f, W.THEME.card, W.THEME.cardBorder, 10)
    if art("box_row") then W.Slice(f, "box_row", 0.55) end
    return f
end

function W.Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font = fs:GetFont()
    fs:SetFont(font or "Fonts\\2002.TTF", size or 12, "")
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.9) end
    local c = color or W.COLORS.white
    fs:SetTextColor(c[1], c[2], c[3])
    if justify then fs:SetJustifyH(justify) end
    return fs
end

-- button colour by label (original: 보상수령 / 일괄 / 승급 / 입장 green, 도전 orange, others cyan)
local GREEN_WORDS = { "받기", "수령", "승급", "일괄", "입장", "확인", "선택", "구매", "변환", "출석", "개방", "강화", "소환", "장착", "도전하기" }
local function styleFor(text)
    text = tostring(text or "")
    if text:find("도전") and not text:find("도전하기") then return "orange" end
    for _, w in ipairs(GREEN_WORDS) do if text:find(w, 1, true) then return "green" end end
    return "cyan"
end

local BUTTON_ART = { cyan = "btn_bronze", green = "btn_red", orange = "btn_gold", gray = "btn_gray" }

local function paintButton(b)
    if b.artPieces then
        W.SetSlice3(b.artPieces, BUTTON_ART[b.enabledState == false and "gray" or (b.style or "cyan")] or "btn_bronze")
        if b.label then
            local t = b.enabledState == false and 0.7 or 1
            b.label:SetTextColor(t, t * (b.style == "orange" and 0.92 or 1), t * (b.style == "orange" and 0.8 or 1))
        end
        return
    end
    local c = b.enabledState == false and W.THEME.gray or W.THEME[b.style or "cyan"] or W.THEME.cyan
    if b.SetBackdropColor then
        b:SetBackdropColor(c[1], c[2], c[3], 1)
        b:SetBackdropBorderColor(math.min(1, c[1] + 0.18), math.min(1, c[2] + 0.18), math.min(1, c[3] + 0.18), 1)
    end
    if b.label then
        local t = b.enabledState == false and 0.78 or 1
        b.label:SetTextColor(t, t, t)
    end
end

function W.Button(parent, text, w, h, onClick, style)
    local b = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    b:SetSize(w or 100, h or 24)
    if art("btn_bronze") and (text ~= "X") then
        b.artPieces = W.Slice3(b, "btn_bronze", h or 24)
    elseif text == "X" and art("btn_close") then
        b.closeArt = W.Art(b, "btn_close", "BACKGROUND")
        b.closeArt:SetAllPoints()
    else
        backdrop(b, W.THEME.cyan, W.THEME.cyan, 10)
    end
    b.shine = b:CreateTexture(nil, "ARTWORK")
    b.shine:SetTexture(WHITE)
    b.shine:SetPoint("TOPLEFT", 3, -3)
    b.shine:SetPoint("TOPRIGHT", -3, -3)
    b.shine:SetHeight(math.max(2, math.floor((h or 24) / 2) - 3))
    b.shine:SetVertexColor(1, 1, 1, 0.12)
    b.label = W.Text(b, math.max(10, math.min(14, math.floor((h or 24) * 0.5))), W.COLORS.white, "CENTER")
    b.label:SetPoint("CENTER", 0, 0)
    if b.closeArt then b.label:Hide(); b.shine:Hide() end
    if b.artPieces then b.shine:SetVertexColor(1, 1, 1, 0) end
    if b.SetFontString then b:SetFontString(b.label) end
    b.fixedStyle = style
    local origSetText, origSetEnabled = b.SetText, b.SetEnabled
    function b:SetText(t)
        self.style = self.fixedStyle or styleFor(t)
        self.label:SetText(t or "")
        if origSetText then origSetText(self, t) end
        paintButton(self)
    end
    function b:SetEnabled(v)
        self.enabledState = v and true or false
        if origSetEnabled then origSetEnabled(self, v) end
        paintButton(self)
    end
    function b:SetStyle(st) self.fixedStyle = st; self.style = st; paintButton(self) end
    b:SetText(text or "")
    b:SetScript("OnEnter", function(self) if self.shine then self.shine:SetVertexColor(1, 1, 1, self.artPieces and 0.1 or 0.22) end end)
    b:SetScript("OnLeave", function(self) if self.shine then self.shine:SetVertexColor(1, 1, 1, self.artPieces and 0 or 0.12) end end)
    if onClick then b:SetScript("OnClick", function(self, ...) onClick(self, ...) end) end
    return b
end

-- round red notification dot (original: red dot on menus that have something to claim)
function W.Dot(parent)
    local d = parent:CreateTexture(nil, "OVERLAY")
    d:SetTexture("Interface\\COMMON\\Indicator-Red")
    d:SetSize(14, 14)
    d:SetPoint("TOPRIGHT", 4, 4)
    d:Hide()
    return d
end

-- icon cell with a grade-coloured rounded frame (item / weapon / companion slots)
function W.Icon(parent, size, texture)
    local f = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(size, size)
    backdrop(f, { 0.08, 0.09, 0.12, 1 }, { 0.3, 0.33, 0.4, 1 }, math.max(8, math.floor(size / 4)))
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 3, -3)
    f.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if texture then f.icon:SetTexture(texture) end
    f.border = f:CreateTexture(nil, "OVERLAY")   -- kept for API compatibility (grade glow)
    f.border:SetTexture(WHITE)
    f.border:SetPoint("BOTTOMLEFT", 3, 3)
    f.border:SetPoint("BOTTOMRIGHT", -3, 3)
    f.border:SetHeight(3)
    f.border:Hide()
    f.count = W.Text(f, math.max(9, math.floor(size / 3)), W.COLORS.white, "RIGHT")
    f.count:SetPoint("BOTTOMRIGHT", -3, 3)
    if art("slot_bronze") then
        if f.SetBackdrop then f:SetBackdrop(nil) end
        f.slotBg = f:CreateTexture(nil, "BACKGROUND")
        f.slotBg:SetColorTexture(0.06, 0.05, 0.05, 1)
        f.slotBg:SetPoint("TOPLEFT", size * 0.08, -size * 0.08)
        f.slotBg:SetPoint("BOTTOMRIGHT", -size * 0.08, size * 0.08)
        f.icon:ClearAllPoints()
        f.icon:SetPoint("TOPLEFT", size * 0.12, -size * 0.12)
        f.icon:SetPoint("BOTTOMRIGHT", -size * 0.12, size * 0.12)
        f.frameArt = W.Art(f, "slot_bronze", "OVERLAY", 1)
        f.frameArt:SetPoint("TOPLEFT", -size * 0.04, size * 0.04)
        f.frameArt:SetPoint("BOTTOMRIGHT", size * 0.04, -size * 0.04)
        f.count:SetDrawLayer("OVERLAY", 2)
    end
    return f
end

local GRADE_ART = { [1] = "slot_g1", [2] = "slot_g2", [3] = "slot_g3", [4] = "slot_g4", [5] = "slot_g5",
    [6] = "slot_g6", [7] = "slot_g4", [8] = "slot_g8" }

function W.SetBorderGrade(icon, grade)
    if icon.frameArt then
        W.SetArt(icon.frameArt, grade and GRADE_ART[grade] or "slot_bronze")
        icon.border:Hide()
        return
    end
    if not grade then
        icon.border:Hide()
        if icon.SetBackdropBorderColor then icon:SetBackdropBorderColor(0.3, 0.33, 0.4, 1) end
        return
    end
    local r, g, b = W.GradeColor(grade)
    icon.border:SetVertexColor(r, g, b, 0.9)
    icon.border:Show()
    if icon.SetBackdropBorderColor then icon:SetBackdropBorderColor(r, g, b, 1) end
    if icon.SetBackdropColor then icon:SetBackdropColor(r * 0.25, g * 0.25, b * 0.25, 1) end
end

function W.Bar(parent, w, h, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(w, h)
    bar:SetStatusBarTexture(WHITE)
    bar:SetStatusBarColor(r or 0.2, g or 0.8, b or 0.2)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.03, 0.04, 0.06, 0.75)
    local fill = W.FillFor(r or 0.2, g or 0.8, b or 0.2)
    if fill and art(fill) and h >= 6 then
        local a = art(fill)
        bar:SetStatusBarTexture(a.file)
        local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
        if tex and tex.SetTexCoord then tex:SetTexCoord(0, a.w / a.cw, 0, a.h / a.ch) end
        bar:SetStatusBarColor(1, 1, 1)
        if h >= 9 and art("bar_trough") then
            bar.frame = CreateFrame("Frame", nil, bar)
            bar.frame:SetPoint("TOPLEFT", -4, 3)
            bar.frame:SetPoint("BOTTOMRIGHT", 4, -3)
            bar.frame:SetFrameLevel(bar:GetFrameLevel() + 1)
            W.Slice3(bar.frame, "bar_trough", h + 6, "OVERLAY")
            for _, t in ipairs(bar.frame.slices) do t:SetVertexColor(1, 1, 1, 1) end
            -- keep the trough inside visible: only the rim of the art is drawn over the fill
            bar.bg:SetColorTexture(0.05, 0.03, 0.02, 0.9)
        end
    end
    bar.text = W.Text(bar.frame or bar, math.max(9, h - 3), W.COLORS.white, "CENTER")
    bar.text:SetPoint("CENTER", bar, "CENTER")
    return bar
end

-- nearest kit fill strip for a bar colour
function W.FillFor(r, g, b)
    local fills = { fill_red = { 0.85, 0.2, 0.2 }, fill_green = { 0.3, 0.8, 0.2 }, fill_blue = { 0.2, 0.45, 1 },
        fill_cyan = { 0.2, 0.75, 0.9 }, fill_purple = { 0.6, 0.3, 0.9 }, fill_orange = { 1, 0.7, 0.15 } }
    local best, bd
    for k, c in pairs(fills) do
        local d = (c[1] - r) ^ 2 + (c[2] - g) ^ 2 + (c[3] - b) ^ 2
        if not bd or d < bd then best, bd = k, d end
    end
    return best
end

---------------------------------------------------------------------------
-- 메이플 키우기-style item card: grade tinted card with "티어 Lv.N" band, framed icon, awakening
-- stars and a copies bar (weapons, companions, equipment, artifacts)
---------------------------------------------------------------------------
function W.GradeCard(parent, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    b:SetSize(w, h)
    backdrop(b, { 0.1, 0.1, 0.12, 1 }, { 0.3, 0.33, 0.4, 1 }, 10)
    b.band = b:CreateTexture(nil, "BORDER")
    b.band:SetTexture(WHITE)
    b.band:SetPoint("TOPLEFT", 3, -3)
    b.band:SetPoint("TOPRIGHT", -3, -3)
    b.band:SetHeight(13)
    b.band:SetVertexColor(0, 0, 0, 0.45)
    b.tier = W.Text(b, 9, W.COLORS.white, "LEFT")
    b.tier:SetPoint("TOPLEFT", 5, -4)
    b.level = W.Text(b, 9, W.COLORS.white, "RIGHT")
    b.level:SetPoint("TOPRIGHT", -5, -4)
    local isz = math.min(w - 14, h - 34)
    b.icon = W.Icon(b, isz)
    b.icon:SetPoint("TOP", 0, -17)
    b.icon:EnableMouse(false)
    b.over = CreateFrame("Frame", nil, b)
    b.over:SetAllPoints(b.icon)
    b.over:SetFrameLevel(b.icon:GetFrameLevel() + 2)
    b.stars = W.Text(b.over, 8, W.COLORS.gold, "CENTER")
    b.stars:SetPoint("BOTTOM", b.icon, "BOTTOM", 0, 2)
    b.bar = W.Bar(b, w - 12, 7, 0.3, 0.8, 0.2)
    b.bar:SetPoint("BOTTOM", 0, 5)
    b.bar.text:SetFont(b.bar.text:GetFont() or "Fonts\\2002.TTF", 8, "OUTLINE")
    b.tag = W.Text(b.over, 9, W.COLORS.green, "LEFT")
    b.tag:SetPoint("TOPLEFT", b.icon, "TOPLEFT", 4, -3)
    b.sel = b:CreateTexture(nil, "OVERLAY", nil, 3)
    b.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    b.sel:SetBlendMode("ADD")
    b.sel:SetPoint("TOPLEFT", -4, 4)
    b.sel:SetPoint("BOTTOMRIGHT", 4, -4)
    b.sel:Hide()
    b.dot = W.Dot(b)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    if onClick then b:SetScript("OnClick", function(self, ...) onClick(self, ...) end) end
    return b
end

-- grade colours and owned state of a card
function W.SetCardGrade(b, grade, owned)
    local r, g, bl = W.GradeColor(grade or 1)
    local k = owned and 0.34 or 0.16
    if b.SetBackdropColor then
        b:SetBackdropColor(r * k + 0.03, g * k + 0.03, bl * k + 0.04, 1)
        b:SetBackdropBorderColor(r * (owned and 1 or 0.5), g * (owned and 1 or 0.5), bl * (owned and 1 or 0.5), 1)
    end
    W.SetBorderGrade(b.icon, grade)
    b.icon.icon:SetDesaturated(not owned)
    b.icon:SetAlpha(owned and 1 or 0.55)
    b.tier:SetTextColor(r, g, bl)
end

function W.Stars(n, max, big)
    local s = ""
    for i = 1, max do s = s .. (i <= n and "|cffffd100★|r" or (big and "|cff4a4a4a★|r" or "|cff555555☆|r")) end
    return s
end

---------------------------------------------------------------------------
-- 메이플 키우기-style detail card (the dark item info window): stars, name, icon block, then sections
-- ("장착 효과", "보유 효과") with label / value rows. card:SetLines({ { header = "..." },
-- { "공격력", "6,240%" [, valueColor] }, { gap = 6 } ... }) lays the body out from the top.
---------------------------------------------------------------------------
W.SECTION = { 0.78, 0.86, 0.32 }

function W.InfoCard(parent, w, h, opts)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(w, h)
    backdrop(f, { 0.06, 0.07, 0.09, 0.96 }, W.THEME.panelBorder, 12)
    if art("frame_rivet") then W.Slice(f, "frame_rivet", 0.42, { keepBackdrop = true }) end
    if f.slices then for _, t in ipairs(f.slices) do t:SetVertexColor(0.85, 0.85, 0.85, 1) end end
    if f.SetBackdropColor then f:SetBackdropColor(0.06, 0.07, 0.09, 0.96) end
    f.stars = W.Text(f, 15, W.COLORS.gold, "CENTER")
    f.stars:SetPoint("TOP", 0, -14)
    f.name = W.Text(f, 15, W.COLORS.white, "CENTER")
    f.name:SetPoint("TOP", 0, -34)
    f.name:SetWidth(w - 30)
    f.icon = W.Icon(f, 56)
    f.icon:SetPoint("TOPLEFT", 20, -58)
    f.line1 = W.Text(f, 13, W.COLORS.white, "LEFT")
    f.line1:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 10, -2)
    f.line2 = W.Text(f, 12, W.COLORS.white, "LEFT")
    f.line2:SetPoint("TOPLEFT", f.line1, "BOTTOMLEFT", 0, -5)
    f.line3 = W.Text(f, 12, W.COLORS.white, "LEFT")
    f.line3:SetPoint("TOPLEFT", f.line2, "BOTTOMLEFT", 0, -5)
    f.tag = W.Text(f, 12, W.COLORS.green, "RIGHT")
    f.tag:SetPoint("TOPRIGHT", -20, -60)
    f.bodyTop = 124
    if opts and opts.plain then
        for _, r in ipairs({ f.stars, f.name, f.icon, f.line1, f.line2, f.line3, f.tag }) do r:Hide() end
        f.bodyTop = opts.top or 14
    end
    f.pool = {}
    local inner = w - 24
    function f:SetLines(list)
        local y = self.bodyTop
        local used = 0
        for _, it in ipairs(list) do
            if it.gap then
                y = y + it.gap
            else
                used = used + 1
                local ln = self.pool[used]
                if not ln then
                    ln = {}
                    ln.band = self:CreateTexture(nil, "ARTWORK")
                    ln.band:SetTexture(WHITE)
                    ln.l = W.Text(self, 12, W.COLORS.white, "LEFT")
                    ln.r = W.Text(self, 12, W.COLORS.white, "RIGHT")
                    self.pool[used] = ln
                end
                ln.band:ClearAllPoints(); ln.l:ClearAllPoints(); ln.r:ClearAllPoints()
                if it.header then
                    ln.band:SetPoint("TOPLEFT", 12, -y)
                    ln.band:SetSize(inner, 20)
                    ln.band:SetVertexColor(1, 1, 1, 0.07)
                    ln.band:Show()
                    ln.l:SetPoint("TOPLEFT", 18, -y - 4)
                    ln.l:SetText(it.header)
                    ln.l:SetTextColor(W.SECTION[1], W.SECTION[2], W.SECTION[3])
                    ln.r:SetPoint("TOPRIGHT", -18, -y - 4)
                    ln.r:SetText(it.right or "")
                    ln.r:SetTextColor(0.7, 0.7, 0.7)
                    y = y + 24
                else
                    ln.band:Hide()
                    ln.l:SetPoint("TOPLEFT", 20, -y)
                    ln.l:SetWidth(inner * 0.5)
                    ln.l:SetText(it[1] or "")
                    local lc = it.labelColor or { 0.86, 0.86, 0.86 }
                    ln.l:SetTextColor(lc[1], lc[2], lc[3])
                    ln.r:SetPoint("TOPRIGHT", -20, -y)
                    ln.r:SetWidth(inner * 0.62)
                    ln.r:SetText(it[2] or "")
                    local c = it[3] or W.COLORS.white
                    ln.r:SetTextColor(c[1], c[2], c[3])
                    y = y + 18
                end
                ln.l:Show(); ln.r:Show()
            end
        end
        for i = used + 1, #self.pool do
            local ln = self.pool[i]
            ln.band:Hide(); ln.l:Hide(); ln.r:Hide()
        end
        return y
    end
    return f
end

-- tab strip (sub menus / grade filters): selected tab gold, others gray
function W.Tabs(parent, labels, w, h, onSelect, vertical)
    local tabs = { buttons = {} }
    for i, text in ipairs(labels) do
        local b = W.Button(parent, text, w, h or 24, function() tabs:Select(i); if onSelect then onSelect(i) end end, "gray")
        if i > 1 then
            if vertical then b:SetPoint("TOP", tabs.buttons[i - 1], "BOTTOM", 0, -6)
            else b:SetPoint("LEFT", tabs.buttons[i - 1], "RIGHT", 4, 0) end
        end
        b.dot = W.Dot(b)
        tabs.buttons[i] = b
    end
    function tabs:Select(i)
        self.index = i
        for k, b in ipairs(self.buttons) do
            b:SetStyle(k == i and "orange" or "gray")
            if b.label then
                if k == i then b.label:SetTextColor(1, 0.95, 0.8) else b.label:SetTextColor(0.8, 0.8, 0.8) end
            end
        end
    end
    function tabs:SetPoint(...) self.buttons[1]:SetPoint(...) end
    tabs:Select(1)
    return tabs
end

-- ON / OFF switch (kit toggle art); toggle.value, toggle:SetValue(v), onChange(v)
function W.Toggle(parent, w, h, onChange)
    local b = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    b:SetSize(w or 40, h or 18)
    b.art = b:CreateTexture(nil, "ARTWORK")
    b.art:SetAllPoints()
    b.text = W.Text(b, math.max(8, math.floor((h or 18) * 0.5)), W.COLORS.white, "CENTER")
    if not art("toggle_on") then
        backdrop(b, W.THEME.gray, W.THEME.gray, 8)
        b.text:SetPoint("CENTER")
    end
    function b:SetValue(v)
        self.value = v and true or false
        if art("toggle_on") then
            W.SetArt(self.art, self.value and "toggle_on" or "toggle_off")
            self.text:SetText("")
        else
            local c = self.value and W.THEME.cyan or W.THEME.gray
            if self.SetBackdropColor then self:SetBackdropColor(c[1], c[2], c[3], 1) end
            self.text:SetText(self.value and "ON" or "OFF")
        end
    end
    b:SetScript("OnClick", function(self)
        self:SetValue(not self.value)
        if onChange then onChange(self.value) end
    end)
    b:SetValue(true)
    return b
end

-- list row card (missions, requests, shop, medals, dungeons): icon, title, progress bar, rewards, button.
-- row:Set({ icon, title, sub, cur, goal, rewards = { key = n }, right, btn, enabled, fn, claimed, header, grade })
function W.RowCard(parent, w, h)
    local r = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    r:SetSize(w, h)
    backdrop(r, { 0.1, 0.08, 0.07, 0.95 }, { 0.42, 0.33, 0.22, 1 }, 10)
    r.icon = W.Icon(r, h - 12)
    r.icon:SetPoint("LEFT", 6, 0)
    r.icon:EnableMouse(false)
    r.title = W.Text(r, 13, W.COLORS.white, "LEFT")
    r.title:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -3)
    r.title:SetWidth(w * 0.46)
    r.sub = W.Text(r, 11, W.COLORS.gray, "LEFT")
    r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 10, 3)
    r.sub:SetWidth(w * 0.46)
    r.bar = W.Bar(r, math.floor(w * 0.3), 9, 0.3, 0.8, 0.2)
    r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 10, 3)
    r.barText = W.Text(r, 10, W.COLORS.white, "LEFT")
    r.barText:SetPoint("LEFT", r.bar, "RIGHT", 8, 0)
    r.rewards = W.Text(r, 12, W.COLORS.white, "RIGHT")
    r.rewards:SetPoint("RIGHT", -112, 0)
    r.rewards:SetWidth(w * 0.3)
    r.btn = W.Button(r, "받기", 92, math.min(28, h - 14))
    r.btn:SetPoint("RIGHT", -10, 0)
    r.check = W.Text(r, 13, W.COLORS.green, "CENTER")
    r.check:SetPoint("CENTER", r.btn, "CENTER")
    r.dot = W.Dot(r.btn)
    function r:Set(d)
        self.data = d
        if d.icon then self.icon:Show(); self.icon.icon:SetTexture(d.icon) else self.icon:Hide() end
        W.SetBorderGrade(self.icon, d.grade)
        self.title:SetText(d.title or "")
        if d.goal and d.goal > 0 then
            self.bar:Show(); self.barText:Show(); self.sub:Hide()
            self.bar:SetValue(math.min(1, (d.cur or 0) / d.goal))
            self.bar.text:SetText("")
            self.barText:SetText(string.format("%s / %s", ns.U.Comma(math.min(d.cur or 0, d.goal)), ns.U.Comma(d.goal)))
        else
            self.bar:Hide(); self.barText:Hide()
            self.sub:SetShown(d.sub ~= nil)
            self.sub:SetText(d.sub or "")
        end
        local parts = {}
        if d.rewards then
            local keys = {}
            for k in pairs(d.rewards) do keys[#keys + 1] = k end
            table.sort(keys)
            for _, k in ipairs(keys) do parts[#parts + 1] = (W.Money(k, d.rewards[k])) end
        end
        if d.right then parts[#parts + 1] = d.right end
        self.rewards:SetText(table.concat(parts, "  "))
        if d.claimed then
            self.btn:Hide()
            self.check:SetText("완료")
            self.check:Show()
            self:SetAlpha(0.6)
        else
            self.check:Hide()
            self:SetAlpha(1)
            if d.btn and d.btn ~= "" then
                self.btn:Show()
                self.btn:SetText(d.btn)
                self.btn:SetEnabled(d.enabled and true or false)
                self.btn:SetScript("OnClick", d.fn)
                self.dot:SetShown(d.enabled and d.dot ~= false or false)
            else
                self.btn:Hide()
            end
        end
        if self.SetBackdropBorderColor then
            if d.header then self:SetBackdropBorderColor(1, 0.8, 0.3, 1); self:SetBackdropColor(0.2, 0.14, 0.06, 0.95)
            else self:SetBackdropBorderColor(0.42, 0.33, 0.22, 1); self:SetBackdropColor(0.1, 0.08, 0.07, 0.95) end
        end
    end
    return r
end

-- currency counter capsule (icon + have / need) used under detail cards
function W.Counter(parent, w)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(w, 22)
    backdrop(f, { 0.03, 0.03, 0.04, 0.9 }, { 0.25, 0.27, 0.3, 1 }, 8)
    if art("box_dark") then W.Slice(f, "box_dark", 0.5) end
    f.text = W.Text(f, 11, W.COLORS.white, "CENTER")
    f.text:SetPoint("CENTER", 0, 0)
    return f
end

function W.Tooltip(frame, fn)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        fn(GameTooltip, self)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Scrollable vertical list. rows are created lazily; update(rowFrame, data, index).
function W.ScrollList(parent, w, h, rowHeight, createRow, updateRow)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetSize(w - 24, h)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(w - 24, h)
    sf:SetScrollChild(child)
    sf.rows = {}
    function sf:SetData(list)
        self.data = list
        for i, item in ipairs(list) do
            local row = self.rows[i]
            if not row then
                row = createRow(child, i)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
                row:SetWidth(w - 26)
                self.rows[i] = row
            end
            row:Show()
            updateRow(row, item, i)
        end
        for i = #list + 1, #self.rows do self.rows[i]:Hide() end
        child:SetHeight(math.max(h, #list * rowHeight))
    end
    return sf
end

-- confirm dialog
function W.Confirm(text, onAccept)
    StaticPopupDialogs["BIGSTORY_CONFIRM"] = {
        text = text, button1 = "확인", button2 = "취소",
        OnAccept = function() onAccept() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("BIGSTORY_CONFIRM")
end

function W.Toast(text, color)
    if UIErrorsFrame then
        local c = color or W.COLORS.gold
        UIErrorsFrame:AddMessage(text, c[1], c[2], c[3])
    else
        ns.Print(text)
    end
end

function W.Money(key, n)
    local name = ns.Data.CurrencyName(key)
    local icon = ns.Data.CurrencyIcon(key)
    return string.format("|T%s:14:14|t %s", icon, ns.U.FormatNumber(n or 0)), name
end
