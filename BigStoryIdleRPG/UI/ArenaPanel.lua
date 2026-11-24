-- 결투장 panel: tier, tickets, opponents (addon users), shop, battle log.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

local function jobName(jobKey)
    local job = jobKey and ns.SkillBook.JobByKey(jobKey)
    return job and ns.Skin.Job(job).display or "?"
end

UI.RegisterPanel("arena", {
    title = "결투장", order = 50,
    build = function(p)
        local A = ns.Arena
        p.head = W.Text(p, 13, W.COLORS.gold, "LEFT")
        p.head:SetPoint("TOPLEFT", 4, -2)
        p.sub = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.sub:SetPoint("TOPLEFT", p.head, "BOTTOMLEFT", 0, -3)

        p.refresh = W.Button(p, "상대 새로고침", 110, 22, function()
            local ok, err = A.Refresh(ns.Hero.Active())
            if not ok then W.Toast(err) end
            UI.RefreshPanel()
        end)
        p.refresh:SetPoint("TOPRIGHT", -4, -2)
        p.hello = W.Button(p, "상대 찾기", 90, 22, function()
            A.SayHello()
            W.Toast("주변 애드온 사용자에게 정보를 알렸습니다.")
        end)
        p.hello:SetPoint("RIGHT", p.refresh, "LEFT", -4, 0)

        -- opponents
        p.opps = {}
        for i = 1, 3 do
            local box = W.Panel(p, 300, 120, 0.85)
            box:SetPoint("TOPLEFT", 4 + (i - 1) * 306, -50)
            box.icon = W.Icon(box, 36)
            box.icon:SetPoint("TOPLEFT", 8, -8)
            box.name = W.Text(box, 13, W.COLORS.white, "LEFT")
            box.name:SetPoint("TOPLEFT", box.icon, "TOPRIGHT", 8, 0)
            box.info = W.Text(box, 11, W.COLORS.gray, "LEFT")
            box.info:SetPoint("TOPLEFT", box.name, "BOTTOMLEFT", 0, -4)
            box.info:SetWidth(240)
            box.go = W.Button(box, "도전", 90, 22)
            box.go:SetPoint("BOTTOMRIGHT", -8, 8)
            p.opps[i] = box
        end
        p.empty = W.Text(p, 12, W.COLORS.gray, "LEFT")
        p.empty:SetPoint("TOPLEFT", 8, -60)
        p.empty:SetWidth(900)
        p.empty:SetText("아직 알려진 상대가 없습니다. 같은 애드온을 쓰는 길드원·파티원이나 전용 채널 사용자가 접속하면 자동으로 나타납니다.")

        -- shop
        p.shop = {}
        for i, row in ipairs(A.SHOP) do
            local b = W.Button(p, "", 200, 22)
            b:SetPoint("BOTTOMLEFT", 4 + (i - 1) * 206, 30)
            b:SetScript("OnClick", function()
                local ok, err = A.Buy(ns.Hero.Active(), i, 1)
                if not ok then W.Toast(err) end
                UI.RefreshPanel()
            end)
            p.shop[i] = b
        end
        p.log = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.log:SetPoint("BOTTOMLEFT", 4, 4)
        p.log:SetWidth(920)
    end,
    refresh = function(p, hero)
        local A = ns.Arena
        A.UpdateRefresh(hero)
        local ar = hero.arena
        local idx, row, rank, total = A.Tier(hero)
        p.head:SetText(string.format("%s  ·  점수 %d  ·  %d위 / %d명  ·  %d승 %d패 (방어 %d승 %d패)", row.name, ar.score,
            rank, total, ar.wins, ar.losses, ar.defWins or 0, ar.defLosses or 0))
        local se = ar.season or { weeks = 0, wins = 0 }
        local sr = A.SeasonRewards(hero, idx)
        p.sub:SetText(string.format("입장권 %d/%d · 무료 새로고침 %d · 일일 보상 %s · 주간 보상 %s + 스타포스 주문서 %d\n"
            .. "시즌 %d/%d주 · 시즌 공격 승리 %d · 시즌 보상(예상): 스타포스 %d, 미라클 큐브 %d, 에디셔널 큐브 %d%s",
            ar.tickets, A.TICKET_CAP, ar.refresh, (W.Money("arenaCoin", row.daily)), (W.Money("arenaCoin", row.weekly)), row.sf,
            (se.weeks or 0) + 1, A.SEASON_WEEKS, se.wins or 0, sr.starforceScroll or 0, sr.cubeMiracle or 0,
            sr.cubeAdditional or 0, sr.meso and (", 메소 " .. U.FormatNumber(sr.meso)) or ""))
        local opps = A.Opponents(hero)
        p.empty:SetShown(#opps == 0)
        for i, box in ipairs(p.opps) do
            local o = opps[i]
            if o then
                box:Show()
                local job = o.job and ns.SkillBook.JobByKey(o.job)
                box.icon.icon:SetTexture(job and ns.Skin.Job(job).icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                box.name:SetText(o.name)
                box.info:SetText(string.format("%s Lv.%d\n전투력 %s · 점수 %d", jobName(o.job), o.level or 0,
                    U.FormatNumber(o.cp or 0), o.score or 0))
                box.go:SetEnabled(ar.tickets > 0 and ns.Game.mode == "hunt")
                box.go:SetScript("OnClick", function()
                    local ok, err = A.Challenge(hero, o.name)
                    if not ok then W.Toast(err) end
                end)
            else
                box:Hide()
            end
        end
        for i, b in ipairs(p.shop) do
            local row2 = A.SHOP[i]
            b:SetText(string.format("%s ×%d  (%d)  %d/%d", D.CurrencyName(row2.key), row2.n, row2.price,
                ar.bought[row2.key] or 0, row2.weekly))
        end
        local lines = {}
        for i = 1, math.min(3, #ar.log) do
            local l = ar.log[i]
            lines[#lines + 1] = string.format("%s %s %s (%+d)", l.kind == "attack" and "공격" or "방어", l.opp,
                l.won and "|cff40ff40승리|r" or "|cffff4040패배|r", l.delta or 0)
        end
        p.log:SetText(#lines > 0 and ("최근: " .. table.concat(lines, "  ·  ")) or ("보유 " .. (W.Money("arenaCoin", ns.Hero.Count(hero, "arenaCoin")))))
    end,
})

ns.On("ARENA_RESULT", function(hero, opp, won, delta)
    W.Toast(string.format("결투장 %s: %s (%+d)", won and "승리" or "패배", opp, delta), won and W.COLORS.green or W.COLORS.red)
end)
ns.On("ARENA_DEFENSE", function(hero, opp, defWon)
    ns.Print("결투장 방어 %s: %s의 도전", defWon and "성공" or "실패", opp)
end)
ns.On("ARENA_PEERS", function()
    if UI.current == "arena" then UI.RefreshPanel() end
end)
