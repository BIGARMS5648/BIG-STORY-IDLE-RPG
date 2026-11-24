-- 훈장 panel: medal list by category with progress, 수령 / 착용, totals of 보유 효과.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local function effText(eff)
    local parts = {}
    for k, v in pairs(eff) do
        if k == "MainStat" then parts[#parts + 1] = "주 스탯 +" .. v
        elseif k == "AttackPowerToBoss" then parts[#parts + 1] = string.format("보스 몬스터 데미지 +%d%%", v / 10)
        elseif k == "FinalDamage" then parts[#parts + 1] = string.format("최종 데미지 +%d%%", v / 10)
        else parts[#parts + 1] = k .. " +" .. v end
    end
    return table.concat(parts, ", ")
end

local function act(fn, ...)
    local ok, err = fn(...)
    if not ok and err then W.Toast(err) end
    UI.RefreshPanel()
end

UI.RegisterPanel("medals", {
    title = "훈장", order = 13,
    build = function(p)
        p.cat = 1
        p.tabs = {}
        for i, name in ipairs(D.MedalCategories) do
            local b = W.Button(p, name, 80, 20, function() p.cat = i; p.page = 0; UI.RefreshPanel() end)
            b:SetPoint("TOPLEFT", (i - 1) * 84, 0)
            p.tabs[i] = b
        end
        p.claimAll = W.Button(p, "모두 받기", 90, 20, function() act(ns.Medals.ClaimAll, ns.Hero.Active()) end)
        p.claimAll:SetPoint("TOPLEFT", #D.MedalCategories * 84 + 8, 0)
        p.summary = W.Text(p, 12, W.COLORS.gold, "LEFT")
        p.summary:SetPoint("LEFT", p.claimAll, "RIGHT", 10, 0)
        p.lines = {}
        for i = 1, 9 do
            local r = CreateFrame("Frame", nil, p)
            r:SetSize(930, 22)
            r:SetPoint("TOPLEFT", 0, -24 - (i - 1) * 24)
            r.text = W.Text(r, 12, W.COLORS.white, "LEFT")
            r.text:SetPoint("LEFT", 4, 0)
            r.text:SetWidth(760)
            r.btn = W.Button(r, "수령", 90, 20)
            r.btn:SetPoint("RIGHT", -4, 0)
            W.Tooltip(r, function(tt)
                local d = r.def
                if not d then return end
                tt:AddLine(d.name, 1, 0.82, 0)
                tt:AddLine(d.text, 1, 1, 1)
                tt:AddLine("보유 효과: " .. effText(d.eff), 0.3, 1, 0.3)
                tt:AddLine("원본: " .. d.maple, 0.6, 0.6, 0.6)
            end)
            p.lines[i] = r
        end
        p.page = 0
        p.prev = W.Button(p, "<", 30, 20, function() p.page = math.max(0, p.page - 1); UI.RefreshPanel() end)
        p.prev:SetPoint("TOPRIGHT", -36, 0)
        p.next = W.Button(p, ">", 30, 20, function() p.page = p.page + 1; UI.RefreshPanel() end)
        p.next:SetPoint("TOPRIGHT", 0, 0)
    end,
    refresh = function(p, hero)
        local M = ns.Medals
        M.Check(hero)
        local s = hero.medals
        local t = M.Totals(hero)
        local owned, total = 0, #D.Medals
        for _, d in ipairs(D.Medals) do if s.claimed[d.id] then owned = owned + 1 end end
        local eq = M.Equipped(hero)
        p.summary:SetText(string.format("보유 %d/%d · 주 스탯 +%d/%s · 착용: %s", owned, total, t.MainStat,
            U.Comma(D.MedalMainStatCap), eq and eq.name or "없음"))
        for i, b in ipairs(p.tabs) do b:SetEnabled(i ~= p.cat) end
        local rows = {}
        for _, d in ipairs(D.Medals) do
            if d.cat == p.cat then rows[#rows + 1] = d end
        end
        local per = #p.lines
        local pages = math.max(1, math.ceil(#rows / per))
        if p.page >= pages then p.page = pages - 1 end
        p.prev:SetShown(pages > 1)
        p.next:SetShown(pages > 1)
        for i, line in ipairs(p.lines) do
            local d = rows[p.page * per + i]
            line.def = d
            if d then
                line:Show()
                local cur, need = M.Progress(hero, d)
                local got, done = s.claimed[d.id], s.achieved[d.id]
                local color = got and "|cff40ff40" or (done and "|cffffd100" or "|cffa0a0a0")
                local prog = (done or got) and "달성" or string.format("%s/%s", U.Comma(math.min(cur, need)), U.Comma(need))
                line.text:SetText(string.format("%s%s|r  %s  (%s)  |cff80c0ff%s|r", color, d.name, d.text, prog, effText(d.eff)))
                if not got then
                    line.btn:SetText(done and "수령" or "진행 중")
                    line.btn:SetEnabled(done and true or false)
                    line.btn:SetScript("OnClick", function() act(M.Claim, hero, d.id) end)
                elseif s.equipped == d.id then
                    line.btn:SetText("해제")
                    line.btn:SetEnabled(true)
                    line.btn:SetScript("OnClick", function() act(M.Equip, hero, nil) end)
                else
                    line.btn:SetText("착용")
                    line.btn:SetEnabled(true)
                    line.btn:SetScript("OnClick", function() act(M.Equip, hero, d.id) end)
                end
            else
                line:Hide()
            end
        end
    end,
})

ns.On("MEDAL_ACHIEVED", function() if UI.current == "medals" then UI.RefreshPanel() end end)
