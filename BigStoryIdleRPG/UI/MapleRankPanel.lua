-- 메이플 등급 panel: rank progress, 주 스탯 / 방어력 / 최대 HP upgrades, 특별 능력치.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local STATS = {
    { key = "main", label = "주 스탯", per = function(r) return D.MapleRank.mainPerPoint(r) end },
    { key = "defence", label = "방어력", per = function(r) return D.MapleRank.defencePerPoint[r] end },
    { key = "hp", label = "최대 HP", per = function(r) return D.MapleRank.hpPerPoint(r) end },
}

local function act(fn, ...)
    local ok, err = fn(...)
    if not ok and err then W.Toast(err) end
    UI.RefreshPanel()
end

UI.RegisterPanel("mapleRank", {
    title = "모험가 등급", order = 12,
    build = function(p)
        local head = W.InfoCard(p, 962, 62, { plain = true })
        head:SetPoint("TOPLEFT", 0, 0)
        p.badge = W.Icon(head, 44, "Interface\\Icons\\INV_BannerPVP_02")
        p.badge:SetPoint("LEFT", 12, 0)
        p.head = W.Text(head, 16, W.COLORS.gold, "LEFT")
        p.head:SetPoint("TOPLEFT", p.badge, "TOPRIGHT", 12, -2)
        p.bar = W.Bar(head, 460, 12, 1, 0.75, 0.2)
        p.bar:SetPoint("BOTTOMLEFT", p.badge, "BOTTOMRIGHT", 12, 2)
        p.points = W.Text(head, 12, W.COLORS.white, "LEFT")
        p.points:SetPoint("LEFT", p.bar, "RIGHT", 14, 0)
        p.auto = W.Button(head, "자동 강화", 110, 30, function() ns.MapleRank.AutoUpgrade(ns.Hero.Active()); UI.RefreshPanel() end, "green")
        p.auto:SetPoint("RIGHT", -14, 0)
        p.cards = {}
        local STAT_ICON = { "Spell_Holy_SealOfMight", "INV_Shield_06", "Spell_Holy_SealOfSacrifice" }
        for i, st in ipairs(STATS) do
            local card = W.InfoCard(p, 316, 124, { plain = true })
            card:SetPoint("TOPLEFT", (i - 1) * 323, -68)
            card.icon = W.Icon(card, 40, "Interface\\Icons\\" .. STAT_ICON[i])
            card.icon:SetPoint("TOPLEFT", 16, -14)
            card.name = W.Text(card, 14, W.COLORS.white, "LEFT")
            card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -2)
            card.value = W.Text(card, 18, W.COLORS.green, "LEFT")
            card.value:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
            card.count = W.Text(card, 13, W.COLORS.orange, "RIGHT")
            card.count:SetPoint("TOPRIGHT", -16, -16)
            card.btn = W.Button(card, "능력치 강화", 284, 30, function() act(ns.MapleRank.Upgrade, ns.Hero.Active(), st.key, 1) end, "green")
            card.btn:SetPoint("BOTTOM", 0, 12)
            p.cards[i] = card
        end
        p.specialBox = W.InfoCard(p, 962, 208, { plain = true })
        p.specialBox:SetPoint("TOPLEFT", 0, -198)
        p.special = {}
        for i, d in ipairs(D.MapleRank.special) do
            local row = CreateFrame("Frame", nil, p.specialBox, BackdropTemplateMixin and "BackdropTemplate" or nil)
            row:SetSize(304, 38)
            W.Backdrop(row, { 0.1, 0.08, 0.07, 0.95 }, { 0.42, 0.33, 0.22, 1 }, 10)
            local col, r = (i - 1) % 3, math.floor((i - 1) / 3)
            row:SetPoint("TOPLEFT", 14 + col * 314, -36 - r * 42)
            row.text = W.Text(row, 11, W.COLORS.white, "LEFT")
            row.text:SetPoint("TOPLEFT", 10, -5)
            row.text:SetWidth(196)
            row.val = W.Text(row, 10, W.COLORS.gray, "LEFT")
            row.val:SetPoint("BOTTOMLEFT", 10, 5)
            row.val:SetWidth(196)
            row.btn = W.Button(row, "능력치 개방", 90, 26, function() act(ns.MapleRank.UpgradeSpecial, ns.Hero.Active(), i) end, "cyan")
            row.btn:SetPoint("RIGHT", -6, 0)
            p.special[i] = row
        end
        p.specialHead = W.Text(p.specialBox, 13, W.SECTION, "LEFT")
        p.specialHead:SetPoint("TOPLEFT", 18, -12)
    end,
    refresh = function(p, hero)
        local M = ns.MapleRank
        local st = M.State(hero)
        p.head:SetText(string.format("모험가 등급  %d 단계%s", st.rank, st.maxed and "  (최대)" or ""))
        p.bar:SetValue(st.inRank / math.max(1, st.need))
        p.bar.text:SetText(string.format("%d/%d", st.inRank, st.need))
        p.points:SetText(string.format("능력치 포인트 %d · 특별 능력치 포인트 %d", st.pointsFree, st.specialFree))
        for i, s in ipairs(STATS) do
            local card = p.cards[i]
            card.name:SetText(s.label)
            card.value:SetText("+" .. U.FormatNumber(s.per(st.rank)))
            card.count:SetText(string.format("%d/%d", st.spent[s.key], st.caps[s.key]))
            local full = st.spent[s.key] >= st.caps[s.key]
            card.btn:SetText(full and "최대 레벨" or "능력치 강화 (포인트 1)")
            card.btn:SetEnabled(not full and st.pointsFree > 0)
        end
        p.specialHead:SetText("특별 능력치")
        for i, d in ipairs(D.MapleRank.special) do
            local row = p.special[i]
            local opened = hero.mapleRank.opened[i]
            local n = hero.mapleRank.special[i] or 0
            local function fmt(v) return d.flat and tostring(v) or string.format("%.1f%%", v / 10) end
            local cur = opened and M.SpecialValue(d, true, n) or d.base
            local nxt = opened and M.SpecialValue(d, true, n + 1) or d.base
            local locked = hero.level < d.unlock
            local cost = M.SpecialCost(hero, i)
            local maxed = opened and n >= d.max
            row.text:SetText(string.format("%s  |cffffd100%d/%d|r", d.label, n, d.max))
            row.val:SetText(string.format("%s%s%s", opened and fmt(cur) or "-",
                maxed and "" or (" |cff9be05a» " .. fmt(opened and nxt or cur) .. "|r"),
                locked and string.format("  |cffff6060%d 레벨 필요|r", d.unlock) or ""))
            row.btn:SetText(maxed and "최대" or string.format("%s (%d)", opened and "강화" or "능력치 개방", cost))
            row.btn:SetEnabled(not locked and not maxed and st.specialFree >= cost)
        end
    end,
})

ns.On("HERO_LEVEL_UP", function() if UI.current == "mapleRank" then UI.RefreshPanel() end end)
