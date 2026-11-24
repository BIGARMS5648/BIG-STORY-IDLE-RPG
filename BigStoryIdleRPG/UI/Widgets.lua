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

function W.Panel(parent, w, h, alpha)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    if w then f:SetSize(w, h) end
    local c = W.THEME.panel
    backdrop(f, { c[1], c[2], c[3], alpha or c[4] }, W.THEME.panelBorder, 14)
    return f
end

-- light card on a panel (list rows, slots)
function W.Card(parent, w, h)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    if w then f:SetSize(w, h) end
    backdrop(f, W.THEME.card, W.THEME.cardBorder, 10)
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

local function paintButton(b)
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
    backdrop(b, W.THEME.cyan, W.THEME.cyan, 10)
    b.shine = b:CreateTexture(nil, "ARTWORK")
    b.shine:SetTexture(WHITE)
    b.shine:SetPoint("TOPLEFT", 3, -3)
    b.shine:SetPoint("TOPRIGHT", -3, -3)
    b.shine:SetHeight(math.max(2, math.floor((h or 24) / 2) - 3))
    b.shine:SetVertexColor(1, 1, 1, 0.12)
    b.label = W.Text(b, math.max(10, math.min(14, math.floor((h or 24) * 0.5))), W.COLORS.white, "CENTER")
    b.label:SetPoint("CENTER", 0, 0)
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
    b:SetScript("OnEnter", function(self) if self.shine then self.shine:SetVertexColor(1, 1, 1, 0.22) end end)
    b:SetScript("OnLeave", function(self) if self.shine then self.shine:SetVertexColor(1, 1, 1, 0.12) end end)
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
    return f
end

function W.SetBorderGrade(icon, grade)
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
    bar.text = W.Text(bar, math.max(9, h - 3), W.COLORS.white, "CENTER")
    bar.text:SetPoint("CENTER")
    return bar
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
