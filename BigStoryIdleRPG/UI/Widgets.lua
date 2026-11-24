-- Small widget helpers shared by every panel.
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

function W.Panel(parent, w, h, alpha)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    if w then f:SetSize(w, h) end
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.07, alpha or 0.92)
        f:SetBackdropBorderColor(0.45, 0.4, 0.3, 1)
    end
    return f
end

function W.Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font = fs:GetFont()
    fs:SetFont(font or "Fonts\\2002.TTF", size or 12, "OUTLINE")
    local c = color or W.COLORS.white
    fs:SetTextColor(c[1], c[2], c[3])
    if justify then fs:SetJustifyH(justify) end
    return fs
end

function W.Button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 100, h or 22)
    b:SetText(text or "")
    if onClick then b:SetScript("OnClick", function(self, ...) onClick(self, ...) end) end
    return b
end

function W.Icon(parent, size, texture)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(size, size)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if texture then f.icon:SetTexture(texture) end
    f.border = f:CreateTexture(nil, "OVERLAY")
    f.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    f.border:SetBlendMode("ADD")
    f.border:SetPoint("CENTER")
    f.border:SetSize(size * 1.8, size * 1.8)
    f.border:Hide()
    f.count = W.Text(f, math.max(9, math.floor(size / 3)), W.COLORS.white, "RIGHT")
    f.count:SetPoint("BOTTOMRIGHT", -1, 1)
    return f
end

function W.SetBorderGrade(icon, grade)
    if not grade then icon.border:Hide() return end
    icon.border:SetVertexColor(W.GradeColor(grade))
    icon.border:Show()
end

function W.Bar(parent, w, h, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(w, h)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r or 0.2, g or 0.8, b or 0.2)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.6)
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
