-- 보상 panel: daily missions, weekly gauge, daily pass, attendance, free claims,
-- red-diamond shop, 14-day newcomer missions.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local function rewardText(rw)
    local parts = {}
    for k, v in pairs(rw or {}) do parts[#parts + 1] = (W.Money(k, v)) end
    return table.concat(parts, " ")
end

local function act(fn, ...)
    local ok, err = fn(...)
    if not ok and err then W.Toast(err) end
    UI.RefreshPanel()
end

local SECTIONS = { "미션", "패스·출석", "무료·상점", "신규 14일" }

UI.RegisterPanel("income", {
    title = "보상", order = 3,
    build = function(p)
        p.section = 1
        p.tabs = {}
        for i, name in ipairs(SECTIONS) do
            local b = W.Button(p, name, 90, 20, function() p.section = i; UI.RefreshPanel() end)
            b:SetPoint("TOPLEFT", (i - 1) * 94, 0)
            p.tabs[i] = b
        end
        p.lines = {}
        for i = 1, 9 do
            local r = CreateFrame("Frame", nil, p)
            r:SetSize(930, 22)
            r:SetPoint("TOPLEFT", 0, -24 - (i - 1) * 24)
            r.text = W.Text(r, 12, W.COLORS.white, "LEFT")
            r.text:SetPoint("LEFT", 4, 0)
            r.text:SetWidth(700)
            r.btn = W.Button(r, "받기", 90, 20)
            r.btn:SetPoint("RIGHT", -4, 0)
            p.lines[i] = r
        end
        p.page = 0
        p.prev = W.Button(p, "<", 30, 20, function() p.page = math.max(0, p.page - 1); UI.RefreshPanel() end)
        p.prev:SetPoint("TOPRIGHT", -36, 0)
        p.next = W.Button(p, ">", 30, 20, function() p.page = p.page + 1; UI.RefreshPanel() end)
        p.next:SetPoint("TOPRIGHT", 0, 0)
    end,
    refresh = function(p, hero)
        local I = ns.Income
        local rows = {}
        local sec = p.section
        if sec == 1 then
            local list, done = I.DailyMissions(hero)
            for _, m in ipairs(list) do
                rows[#rows + 1] = { string.format("%s  (%d/%d)  %s", string.format(m.def.text, m.def.goal), m.progress,
                    m.def.goal, rewardText(m.def.rewards)), m.claimed and "완료" or "받기", not m.claimed and m.done,
                    function() act(I.ClaimMission, hero, m.def.id) end }
            end
            rows[#rows + 1] = { string.format("일일 미션 클리어 (%d/%d)  %s", done, D.DailyMissionClear.need,
                rewardText(D.DailyMissionClear.rewards)), "받기", true, function() act(I.ClaimDailyClear, hero) end }
            local wk = hero.income.week
            for i, st in ipairs(D.WeeklyMission.stages) do
                rows[#rows + 1] = { string.format("주간 미션 %d단계 (%d/%d)  %s", i, math.min(wk.points, st.need), st.need,
                    rewardText(st.rewards)), wk.claimed[i] and "완료" or "받기", not wk.claimed[i] and wk.points >= st.need,
                    function() act(I.ClaimWeekly, hero, i) end }
            end
        elseif sec == 2 then
            local kills, reached, claimed = I.PassState(hero)
            local nextStep = D.DailyPass[reached + 1]
            rows[#rows + 1] = { string.format("데일리 패스: 오늘 처치 %s · %d/%d단계 달성 (다음 %s마리)", U.Comma(kills), reached,
                #D.DailyPass, nextStep and U.Comma(nextStep.kills) or "-"), "받기", reached > claimed,
                function() act(I.ClaimPass, hero) end }
            local a = I.AttendanceState(hero)
            local nx = a.next
            rows[#rows + 1] = { string.format("월간 출석 %d/%d일 · 다음 보상 %s", a.claimed, #D.Attendance.days,
                nx and (W.Money(nx[1], nx[2])) or "-"), "출석", a.canClaim, function() act(I.ClaimAttendance, hero) end }
            for i = 1, #D.Attendance.days do
                if i > a.claimed and i <= a.claimed + 6 then
                    local d = D.Attendance.days[i]
                    rows[#rows + 1] = { string.format("   %d일차: %s", i, (W.Money(d[1], d[2]))), "", false, nil }
                end
            end
        elseif sec == 3 then
            local fc = hero.income.freeClaimed
            for _, f in ipairs(D.FreeDaily) do
                rows[#rows + 1] = { "매일 무료: " .. f.text, fc[f.id] and "완료" or "받기", not fc[f.id],
                    function() act(I.ClaimFree, hero, f.id) end }
            end
            for i, r in ipairs(D.RedShop) do
                local bought = hero.income.weekShop[i] or 0
                local unlocked = I.ShopUnlocked(hero, r)
                rows[#rows + 1] = { string.format("상점: %s  %s  (%s/%s)%s", r.name, (W.Money("redDia", r.price)), bought,
                    r.limit or "∞", unlocked and "" or "  |cffff6060잠김|r"), "구매", unlocked, function() act(I.BuyRed, hero, i) end }
            end
        else
            local list, total, dayNo = I.Newcomer(hero)
            rows[#rows + 1] = { string.format("14일 특별 미션: %d일차 · 완료 %d개 (79개 달성 시 유니크 동료)", math.min(dayNo, 14), total),
                "", false, nil }
            for d, day in ipairs(list) do
                for i, r in ipairs(day.rows) do
                    local label = r.spec:gsub("^free:", "")
                    rows[#rows + 1] = { string.format("%d일차  %s  (%s/%s)", d, label, U.FormatNumber(r.cur or 0), U.FormatNumber(r.goal or 0)),
                        r.claimed and "완료" or "받기", day.open and r.done and not r.claimed,
                        function() act(I.ClaimNewcomer, hero, d, i) end }
                end
                rows[#rows + 1] = { string.format("%d일차 모두 완료: %s", d, rewardText(day.clear)),
                    day.clearClaimed and "완료" or "받기", day.open and not day.clearClaimed,
                    function() act(I.ClaimNewcomerDay, hero, d) end }
            end
        end
        local per = #p.lines
        local pages = math.max(1, math.ceil(#rows / per))
        if p.page >= pages then p.page = pages - 1 end
        p.prev:SetShown(pages > 1)
        p.next:SetShown(pages > 1)
        for i, line in ipairs(p.lines) do
            local r = rows[p.page * per + i]
            if r then
                line:Show()
                line.text:SetText(r[1])
                line.btn:SetShown(r[2] ~= "")
                line.btn:SetText(r[2])
                line.btn:SetEnabled(r[3] and true or false)
                line.btn:SetScript("OnClick", r[4])
            else
                line:Hide()
            end
        end
        for i, b in ipairs(p.tabs) do
            if i == sec then b:LockHighlight() else b:UnlockHighlight() end
        end
    end,
})
