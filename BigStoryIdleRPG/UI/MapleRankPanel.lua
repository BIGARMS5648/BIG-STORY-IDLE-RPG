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
    title = "메이플 등급", order = 12,
    build = function(p)
        p.head = W.Text(p, 14, W.COLORS.gold, "LEFT")
        p.head:SetPoint("TOPLEFT", 4, -2)
        p.bar = W.Bar(p, 520, 14, 1, 0.75, 0.2)
        p.bar:SetPoint("TOPLEFT", 4, -24)
        p.points = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.points:SetPoint("LEFT", p.bar, "RIGHT", 12, 0)
        p.auto = W.Button(p, "자동 강화", 90, 22, function() ns.MapleRank.AutoUpgrade(ns.Hero.Active()); UI.RefreshPanel() end)
        p.auto:SetPoint("TOPRIGHT", -4, -20)
        p.cards = {}
        for i, st in ipairs(STATS) do
            local card = W.Panel(p, 200, 86, 0.9)
            card:SetPoint("TOPLEFT", 4 + (i - 1) * 206, -46)
            card.name = W.Text(card, 13, W.COLORS.white, "CENTER")
            card.name:SetPoint("TOP", 0, -8)
            card.value = W.Text(card, 16, W.COLORS.green, "CENTER")
            card.value:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
            card.count = W.Text(card, 12, W.COLORS.orange, "RIGHT")
            card.count:SetPoint("TOPRIGHT", -8, -8)
            card.btn = W.Button(card, "능력치 강화", 120, 22, function() act(ns.MapleRank.Upgrade, ns.Hero.Active(), st.key, 1) end)
            card.btn:SetPoint("BOTTOM", 0, 8)
            p.cards[i] = card
        end
        p.special = {}
        for i, d in ipairs(D.MapleRank.special) do
            local row = W.Panel(p, 300, 36, 0.8)
            local col, r = (i - 1) % 3, math.floor((i - 1) / 3)
            row:SetPoint("TOPLEFT", 4 + col * 306, -140 - r * 40)
            row.text = W.Text(row, 11, W.COLORS.white, "LEFT")
            row.text:SetPoint("LEFT", 8, 0)
            row.text:SetWidth(200)
            row.btn = W.Button(row, "능력치 개방", 84, 20, function() act(ns.MapleRank.UpgradeSpecial, ns.Hero.Active(), i) end)
            row.btn:SetPoint("RIGHT", -6, 0)
            p.special[i] = row
        end
        p.specialHead = W.Text(p, 12, W.COLORS.gold, "LEFT")
        p.specialHead:SetPoint("TOPLEFT", 4, -124)
    end,
    refresh = function(p, hero)
        local M = ns.MapleRank
        local st = M.State(hero)
        p.head:SetText(string.format("메이플 등급  %d 단계%s", st.rank, st.maxed and "  (최대)" or ""))
        p.bar:SetValue(st.inRank / math.max(1, st.need))
        p.bar.text:SetText(string.format("%d/%d", st.inRank, st.need))
        p.points:SetText(string.format("능력치 포인트 %d · 특별 능력치 포인트 %d", st.pointsFree, st.specialFree))
        for i, s in ipairs(STATS) do
            local card = p.cards[i]
            card.name:SetText(s.label)
            card.value:SetText("+" .. U.FormatNumber(s.per(st.rank)))
            card.count:SetText(string.format("%d/%d", st.spent[s.key], st.caps[s.key]))
            local full = st.spent[s.key] >= st.caps[s.key]
            card.btn:SetText(full and "최대 레벨" or "능력치 강화 (1)")
            card.btn:SetEnabled(not full and st.pointsFree > 0)
        end
        p.specialHead:SetText("특별 능력치")
        for i, d in ipairs(D.MapleRank.special) do
            local row = p.special[i]
            local lv = hero.mapleRank.special[i] or 0
            local function fmt(v) return d.flat and tostring(v) or string.format("%.1f%%", v / 10) end
            local cur, nxt = M.SpecialValue(d, lv), M.SpecialValue(d, lv + 1)
            local locked = hero.level < d.unlock
            row.text:SetText(string.format("%s %d/%d  %s » %s%s", d.label, lv, d.max, fmt(lv > 0 and cur or d.base),
                fmt(lv > 0 and nxt or d.base + d.step), locked and string.format("  |cffff6060%d 레벨 필요|r", d.unlock) or ""))
            row.btn:SetText(lv == 0 and "능력치 개방" or "강화")
            row.btn:SetEnabled(not locked and lv < d.max and st.specialFree > 0)
        end
    end,
})

ns.On("HERO_LEVEL_UP", function() if UI.current == "mapleRank" then UI.RefreshPanel() end end)
