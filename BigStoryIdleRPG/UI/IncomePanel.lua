-- 보상 panel: daily / weekly missions, special requests, daily pass, attendance, free claims,
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

local SECTIONS = { "일일 미션", "주간 미션", "특별 의뢰", "패스·출석", "무료·상점", "신규 14일" }

local IC = "Interface\\Icons\\"
local TRACK_ICON = {
    kill = "Ability_Warrior_Cleave", elite = "Ability_Warrior_BattleShout", summon_weapon = "INV_Sword_27",
    dungeon_weapon = "INV_Misc_Key_03", dungeon_exp = "INV_Misc_Key_04", dungeon_gear = "INV_Misc_Key_05",
    dungeon_enhance = "INV_Misc_Key_06", dungeon_training = "INV_Misc_Key_07", ad = "INV_Misc_Gift_02",
    booster = "INV_Potion_83", worldboss = "INV_Misc_Head_Dragon_01",
}
local function trackIcon(track) return IC .. (TRACK_ICON[track] or "INV_Misc_Note_01") end

-- rows of the 미션 window: clear header, then the missions
local function missionRows(rows, hero, weekly)
    local I = ns.Income
    local list, done = (weekly and I.WeeklyMissions or I.DailyMissions)(hero)
    local clear = weekly and D.WeeklyMissionClear or D.DailyMissionClear
    local claimed = (weekly and hero.income.week.claimed or hero.income.dayClaimed).__clear
    rows[#rows + 1] = { header = true, icon = IC .. "INV_Misc_Bag_10",
        title = string.format("%s 미션 클리어", weekly and "주간" or "일일") .. (clear.relocated and "  |cffa0a0a0(+ 구 길드 보상)|r" or ""),
        cur = done, goal = clear.need, rewards = clear.rewards, claimed = claimed,
        btn = "보상수령", enabled = done >= clear.need,
        fn = function() act(weekly and I.ClaimWeeklyClear or I.ClaimDailyClear, hero) end }
    for _, m in ipairs(list) do
        rows[#rows + 1] = { icon = trackIcon(m.def.track), title = m.def.text, cur = m.progress, goal = m.def.goal,
            rewards = m.def.rewards, claimed = m.claimed, btn = m.done and "보상수령" or "진행 중", enabled = m.done,
            fn = function() act(weekly and I.ClaimWeeklyMission or I.ClaimMission, hero, m.def.id) end }
    end
end

local ROWS, ROW_H = 7, 50

UI.RegisterPanel("income", {
    title = "보상", order = 3,
    build = function(p)
        p.section = 1
        p.tabs = W.Tabs(p, SECTIONS, 132, 38, function(i) p.section = i; p.page = 0; UI.RefreshPanel() end, true)
        p.tabs:SetPoint("TOPLEFT", 0, 0)
        p.lines = {}
        for i = 1, ROWS do
            local r = W.RowCard(p, 820, ROW_H)
            r:SetPoint("TOPLEFT", 142, -(i - 1) * (ROW_H + 4))
            p.lines[i] = r
        end
        p.page = 0
        p.allBtn = W.Button(p, "일괄 수령", 120, 28, function()
            local hero = ns.Hero.Active()
            if hero then act(ns.Income.ClaimAllMissions, hero, p.section == 2) end
        end, "green")
        p.allBtn:SetPoint("BOTTOMLEFT", 142, 2)
        p.pageText = W.Text(p, 12, W.COLORS.white, "CENTER")
        p.pageText:SetPoint("BOTTOMRIGHT", -46, 9)
        p.pageText:SetWidth(60)
        p.prev = W.Button(p, "<", 34, 28, function() p.page = math.max(0, p.page - 1); UI.RefreshPanel() end, "cyan")
        p.prev:SetPoint("RIGHT", p.pageText, "LEFT", -4, 0)
        p.next = W.Button(p, ">", 34, 28, function() p.page = p.page + 1; UI.RefreshPanel() end, "cyan")
        p.next:SetPoint("LEFT", p.pageText, "RIGHT", 4, 0)
    end,
    refresh = function(p, hero)
        local I = ns.Income
        local rows = {}
        local sec = p.section
        if sec == 1 or sec == 2 then
            missionRows(rows, hero, sec == 2)
        elseif sec == 3 then
            for _, r in ipairs(ns.Requests.List(hero)) do
                local d = r.def
                local gate = d.gate and (d.gate.level and (d.gate.level .. " 레벨") or ns.Content.GateText(d.gate.ch, d.gate.st or 1))
                rows[#rows + 1] = { icon = IC .. "INV_Misc_Note_06", title = d.npc .. ": " .. d.text,
                    sub = (not r.open) and ("|cffa0a0a0" .. (gate or "") .. " 후 개방|r") or nil,
                    cur = r.open and r.progress or nil, goal = r.open and r.need or nil,
                    rewards = d.rewards, right = d.gear and "+ 장비" or nil, claimed = r.claimed,
                    btn = "받기", enabled = r.complete and not r.claimed,
                    fn = function() act(ns.Requests.Claim, hero, d.id) end }
            end
        elseif sec == 4 then
            local kills, reached, claimed = I.PassState(hero)
            local nextStep = D.DailyPass[reached + 1]
            rows[#rows + 1] = { header = true, icon = IC .. "INV_Misc_Ticket_Tarot_Stack_01", title = "데일리 패스",
                sub = string.format("오늘 처치 %s · %d/%d단계 달성", U.Comma(kills), reached, #D.DailyPass),
                cur = nextStep and kills or nil, goal = nextStep and nextStep.kills or nil,
                right = string.format("%d / %d단계", reached, #D.DailyPass),
                btn = "받기", enabled = reached > claimed, fn = function() act(I.ClaimPass, hero) end }
            local a = I.AttendanceState(hero)
            local nx = a.next
            rows[#rows + 1] = { header = true, icon = IC .. "INV_Misc_Book_09", title = "월간 출석",
                sub = string.format("%d / %d일 출석", a.claimed, #D.Attendance.days),
                rewards = nx and { [nx[1]] = nx[2] } or nil, btn = "출석", enabled = a.canClaim,
                fn = function() act(I.ClaimAttendance, hero) end }
            for i = 1, #D.Attendance.days do
                if i > a.claimed and i <= a.claimed + 5 then
                    local d = D.Attendance.days[i]
                    rows[#rows + 1] = { icon = D.CurrencyIcon(d[1]), title = string.format("%d일차 출석 보상", i),
                        sub = i == a.claimed + 1 and "다음 보상" or nil, rewards = { [d[1]] = d[2] } }
                end
            end
        elseif sec == 5 then
            local fc = hero.income.freeClaimed
            for _, f in ipairs(D.FreeDaily) do
                rows[#rows + 1] = { icon = IC .. "INV_Misc_Gift_02", title = "매일 무료: " .. f.text, sub = "매일 오전 0시 초기화",
                    claimed = fc[f.id], btn = "받기", enabled = not fc[f.id], fn = function() act(I.ClaimFree, hero, f.id) end }
            end
            for _, key in ipairs({ "expBooster", "expBooster50" }) do
                local n = ns.Hero.Count(hero, key)
                local active = hero.expBoosterBuff and ns.U.Now() < (hero.expBoosterBuff.untilTime or 0)
                rows[#rows + 1] = { icon = D.CurrencyIcon(key), title = D.CurrencyName(key),
                    sub = string.format("보유 %d개%s", n, active and "  |cff40ff40(사용 중)|r" or ""),
                    btn = "사용", enabled = n > 0, fn = function() act(I.UseBooster, hero, key) end }
            end
            if ns.Relocated and D.WorldBossShop then
                local s2 = hero.relocated or {}
                for i, r in ipairs(D.WorldBossShop) do
                    local lim = r.weekly and string.format("주 %d/%d", (s2.wbShopWeek or {})[i] or 0, r.weekly)
                        or (r.perChar and string.format("%d/%d", (s2.wbShopTotal or {})[i] or 0, r.perChar)) or "∞"
                    rows[#rows + 1] = { icon = D.CurrencyIcon("worldBossCoin"), title = "월드보스 상점: " .. r.name,
                        sub = "구매 한도 " .. lim, right = (W.Money("worldBossCoin", r.price)), btn = "구매", enabled = true,
                        fn = function() act(ns.Relocated.BuyWB, hero, i) end }
                end
            end
            for i, r in ipairs(D.RedShop) do
                local bought = hero.income.weekShop[i] or 0
                local unlocked = I.ShopUnlocked(hero, r)
                rows[#rows + 1] = { icon = D.CurrencyIcon("redDia"), title = "상점: " .. r.name,
                    sub = string.format("구매 %s/%s%s", bought, r.limit or "∞", unlocked and "" or "  |cffff6060잠김|r"),
                    right = (W.Money("redDia", r.price)), btn = "구매", enabled = unlocked,
                    fn = function() act(I.BuyRed, hero, i) end }
            end
        else
            local list, total, dayNo = I.Newcomer(hero)
            rows[#rows + 1] = { header = true, icon = IC .. "INV_Misc_Book_11", title = "14일 특별 미션",
                sub = string.format("%d일차 · 완료 %d개 (79개 달성 시 유니크 동료)", math.min(dayNo, 14), total) }
            for d, day in ipairs(list) do
                for i, r in ipairs(day.rows) do
                    local label = r.spec:gsub("^free:", "")
                    rows[#rows + 1] = { icon = IC .. "INV_Misc_Note_01", title = string.format("%d일차  %s", d, label),
                        cur = r.cur or 0, goal = (r.goal or 0) > 0 and r.goal or nil, claimed = r.claimed,
                        btn = "받기", enabled = day.open and r.done and not r.claimed,
                        fn = function() act(I.ClaimNewcomer, hero, d, i) end }
                end
                rows[#rows + 1] = { header = true, icon = IC .. "INV_Misc_Bag_10", title = string.format("%d일차 모두 완료", d),
                    rewards = day.clear, claimed = day.clearClaimed, btn = "받기", enabled = day.open and not day.clearClaimed,
                    fn = function() act(I.ClaimNewcomerDay, hero, d) end }
            end
        end
        local per = #p.lines
        local pages = math.max(1, math.ceil(#rows / per))
        if p.page >= pages then p.page = pages - 1 end
        p.prev:SetShown(pages > 1)
        p.next:SetShown(pages > 1)
        p.prev:SetEnabled(p.page > 0)
        p.next:SetEnabled(p.page < pages - 1)
        p.pageText:SetText(pages > 1 and string.format("%d / %d", p.page + 1, pages) or "")
        p.allBtn:SetShown(sec == 1 or sec == 2)
        for i, line in ipairs(p.lines) do
            local r = rows[p.page * per + i]
            if r then line:Show(); line:Set(r) else line:Hide() end
        end
        -- section dots: something to claim
        if ns.UI.Badge then
            local d1 = false
            local list1 = I.DailyMissions(hero)
            for _, m in ipairs(list1) do if m.done and not m.claimed then d1 = true end end
            p.tabs.buttons[1].dot:SetShown(d1)
        end
    end,
})
