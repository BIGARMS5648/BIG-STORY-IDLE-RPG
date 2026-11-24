-- 보상 panel: daily / weekly missions, daily pass, attendance, free claims,
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

local SECTIONS = { "일일 미션", "주간 미션", "패스·출석", "무료·상점", "신규 14일" }

-- rows of the 미션 window: clear header, the missions, 일괄 수령
local function missionRows(rows, hero, weekly)
    local I = ns.Income
    local list, done = (weekly and I.WeeklyMissions or I.DailyMissions)(hero)
    local clear = weekly and D.WeeklyMissionClear or D.DailyMissionClear
    local claimed = (weekly and hero.income.week.claimed or hero.income.dayClaimed).__clear
    local text = string.format("%s 미션 클리어 (%d/%d)  %s", weekly and "주간" or "일일", math.min(done, clear.need),
        clear.need, rewardText(clear.rewards))
    if clear.relocated then text = text .. "  |cffa0a0a0+ 구 길드 보상|r" end
    rows[#rows + 1] = { text, claimed and "완료" or (done >= clear.need and "보상수령" or "진행 중"),
        not claimed and done >= clear.need,
        function() act(weekly and I.ClaimWeeklyClear or I.ClaimDailyClear, hero) end }
    for _, m in ipairs(list) do
        rows[#rows + 1] = { string.format("   %s  (%s/%s)  %s", m.def.text, U.Comma(m.progress), U.Comma(m.def.goal),
            rewardText(m.def.rewards)), m.claimed and "완료" or (m.done and "보상수령" or "진행 중"),
            m.done and not m.claimed,
            function() act(weekly and I.ClaimWeeklyMission or I.ClaimMission, hero, m.def.id) end }
    end
    rows[#rows + 1] = { "", "일괄 수령", true, function() act(I.ClaimAllMissions, hero, weekly) end }
end

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
        if sec == 1 or sec == 2 then
            missionRows(rows, hero, sec == 2)
        elseif sec == 3 then
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
        elseif sec == 4 then
            local fc = hero.income.freeClaimed
            for _, f in ipairs(D.FreeDaily) do
                rows[#rows + 1] = { "매일 무료: " .. f.text, fc[f.id] and "완료" or "받기", not fc[f.id],
                    function() act(I.ClaimFree, hero, f.id) end }
            end
            for _, key in ipairs({ "expBooster", "expBooster50" }) do
                local n = ns.Hero.Count(hero, key)
                local active = hero.expBoosterBuff and ns.U.Now() < (hero.expBoosterBuff.untilTime or 0)
                rows[#rows + 1] = { string.format("부스터: %s 보유 %d%s", D.CurrencyName(key), n,
                    active and "  |cff40ff40(사용 중)|r" or ""), "사용", n > 0, function() act(I.UseBooster, hero, key) end }
            end
            if ns.Relocated and D.WorldBossShop then
                local s2 = hero.relocated or {}
                for i, r in ipairs(D.WorldBossShop) do
                    local lim = r.weekly and string.format("주 %d/%d", (s2.wbShopWeek or {})[i] or 0, r.weekly)
                        or (r.perChar and string.format("%d/%d", (s2.wbShopTotal or {})[i] or 0, r.perChar)) or "∞"
                    rows[#rows + 1] = { string.format("월드보스 상점: %s  %s  (%s)", r.name, (W.Money("worldBossCoin", r.price)), lim),
                        "구매", true, function() act(ns.Relocated.BuyWB, hero, i) end }
                end
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
