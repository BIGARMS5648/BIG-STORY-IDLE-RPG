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

local ROWS, ROW_H = 7, 50
local MEDAL_ICON = "Interface\\Icons\\INV_Misc_Ribbon_01"

UI.RegisterPanel("medals", {
    title = "훈장", order = 13,
    build = function(p)
        p.cat = 1
        p.tabs = W.Tabs(p, D.MedalCategories, 132, 36, function(i) p.cat = i; p.page = 0; UI.RefreshPanel() end, true)
        p.tabs:SetPoint("TOPLEFT", 0, 0)
        local sum = W.InfoCard(p, 132, 196, { plain = true })
        sum:SetPoint("BOTTOMLEFT", 0, 0)
        p.sumBox = sum
        p.summary = W.Text(sum, 11, W.COLORS.white, "CENTER")
        p.summary:SetPoint("TOP", 0, -14)
        p.summary:SetWidth(116)
        p.summary:SetJustifyV("TOP")
        p.claimAll = W.Button(sum, "모두 받기", 112, 28, function() act(ns.Medals.ClaimAll, ns.Hero.Active()) end, "green")
        p.claimAll:SetPoint("BOTTOM", 0, 10)
        p.lines = {}
        for i = 1, ROWS do
            local r = W.RowCard(p, 820, ROW_H)
            r:SetPoint("TOPLEFT", 142, -(i - 1) * (ROW_H + 4))
            r:EnableMouse(true)
            W.Tooltip(r, function(tt)
                local d = r.def
                if not d then return end
                tt:AddLine(d.name, 1, 0.82, 0)
                tt:AddLine(d.text, 1, 1, 1)
                tt:AddLine("보유 효과: " .. effText(d.eff), 0.3, 1, 0.3)
            end)
            p.lines[i] = r
        end
        p.page = 0
        p.pageText = W.Text(p, 12, W.COLORS.white, "CENTER")
        p.pageText:SetPoint("BOTTOMRIGHT", -46, 9)
        p.pageText:SetWidth(60)
        p.prev = W.Button(p, "<", 34, 28, function() p.page = math.max(0, p.page - 1); UI.RefreshPanel() end, "cyan")
        p.prev:SetPoint("RIGHT", p.pageText, "LEFT", -4, 0)
        p.next = W.Button(p, ">", 34, 28, function() p.page = p.page + 1; UI.RefreshPanel() end, "cyan")
        p.next:SetPoint("LEFT", p.pageText, "RIGHT", 4, 0)
    end,
    refresh = function(p, hero)
        local M = ns.Medals
        M.Check(hero)
        local s = hero.medals
        local t = M.Totals(hero)
        local owned, total = 0, #D.Medals
        for _, d in ipairs(D.Medals) do if s.claimed[d.id] then owned = owned + 1 end end
        local eq = M.Equipped(hero)
        p.summary:SetText(string.format("|cffffd100보유 훈장|r\n%d / %d\n\n|cffffd100주 스탯|r\n+%d / %s\n\n|cffffd100착용|r\n%s", owned, total,
            t.MainStat, U.Comma(D.MedalMainStatCap), eq and eq.name or "없음"))
        for i, b in ipairs(p.tabs.buttons) do
            local any = false
            for _, d in ipairs(D.Medals) do if d.cat == i and s.achieved[d.id] and not s.claimed[d.id] then any = true end end
            b.dot:SetShown(any)
        end
        local rows = {}
        for _, d in ipairs(D.Medals) do
            if d.cat == p.cat then rows[#rows + 1] = d end
        end
        local per = #p.lines
        local pages = math.max(1, math.ceil(#rows / per))
        if p.page >= pages then p.page = pages - 1 end
        p.prev:SetShown(pages > 1)
        p.next:SetShown(pages > 1)
        p.prev:SetEnabled(p.page > 0)
        p.next:SetEnabled(p.page < pages - 1)
        p.pageText:SetText(pages > 1 and string.format("%d / %d", p.page + 1, pages) or "")
        for i, line in ipairs(p.lines) do
            local d = rows[p.page * per + i]
            line.def = d
            if d then
                line:Show()
                local cur, need = M.Progress(hero, d)
                local got, done = s.claimed[d.id], s.achieved[d.id]
                local row = { icon = MEDAL_ICON, grade = got and 4 or nil,
                    title = (got and "|cff40ff40" or (done and "|cffffd100" or "|cffffffff")) .. d.name .. "|r  |cffa0a0a0" .. d.text .. "|r",
                    cur = (not (done or got)) and cur or nil, goal = (not (done or got)) and need or nil,
                    sub = (done or got) and "|cff9be05a달성|r" or nil,
                    right = "|cff80c0ff" .. effText(d.eff) .. "|r" }
                if not got then
                    row.btn, row.enabled = done and "수령" or "진행 중", done and true or false
                    row.fn = function() act(M.Claim, hero, d.id) end
                elseif s.equipped == d.id then
                    row.btn, row.enabled, row.dot = "해제", true, false
                    row.fn = function() act(M.Equip, hero, nil) end
                else
                    row.btn, row.enabled, row.dot = "착용", true, false
                    row.fn = function() act(M.Equip, hero, d.id) end
                end
                line:Set(row)
                line.icon.icon:SetDesaturated(not got)
            else
                line:Hide()
            end
        end
    end,
})

ns.On("MEDAL_ACHIEVED", function() if UI.current == "medals" then UI.RefreshPanel() end end)
