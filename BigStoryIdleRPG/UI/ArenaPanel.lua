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
        -- my card
        local me = W.InfoCard(p, 300, 406, { plain = true })
        me:SetPoint("TOPLEFT", 0, 0)
        p.me = me
        p.emblem = W.Icon(me, 72, "Interface\\Icons\\INV_BannerPVP_02")
        p.emblem:SetPoint("TOP", 0, -18)
        p.tier = W.Text(me, 18, W.COLORS.gold, "CENTER")
        p.tier:SetPoint("TOP", p.emblem, "BOTTOM", 0, -8)
        p.head = W.Text(me, 12, W.COLORS.white, "CENTER")
        p.head:SetPoint("TOP", p.tier, "BOTTOM", 0, -6)
        p.head:SetWidth(276)
        p.tickets = W.Counter(me, 250)
        p.tickets:SetPoint("TOP", p.head, "BOTTOM", 0, -10)
        p.sub = W.Text(me, 11, W.COLORS.gray, "LEFT")
        p.sub:SetPoint("TOPLEFT", 18, -196)
        p.sub:SetWidth(264)
        p.sub:SetJustifyV("TOP")
        p.hello = W.Button(me, "상대 찾기", 128, 30, function()
            A.SayHello()
            W.Toast("주변 애드온 사용자에게 정보를 알렸습니다.")
        end, "cyan")
        p.hello:SetPoint("BOTTOMLEFT", 16, 14)
        p.refresh = W.Button(me, "상대 새로고침", 128, 30, function()
            local ok, err = A.Refresh(ns.Hero.Active())
            if not ok then W.Toast(err) end
            UI.RefreshPanel()
        end, "cyan")
        p.refresh:SetPoint("BOTTOMRIGHT", -16, 14)

        -- opponents
        p.opps = {}
        for i = 1, 3 do
            local box = W.InfoCard(p, 212, 236, { plain = true })
            box:SetPoint("TOPLEFT", 308 + (i - 1) * 218, 0)
            box.icon = W.Icon(box, 64)
            box.icon:SetPoint("TOP", 0, -18)
            box.name = W.Text(box, 15, W.COLORS.white, "CENTER")
            box.name:SetPoint("TOP", box.icon, "BOTTOM", 0, -8)
            box.name:SetWidth(196)
            box.info = W.Text(box, 12, W.COLORS.gray, "CENTER")
            box.info:SetPoint("TOP", box.name, "BOTTOM", 0, -6)
            box.info:SetWidth(196)
            box.go = W.Button(box, "도전", 180, 32, nil, "orange")
            box.go:SetPoint("BOTTOM", 0, 14)
            p.opps[i] = box
        end
        p.empty = W.Text(p, 12, W.COLORS.gray, "CENTER")
        p.empty:SetPoint("TOPLEFT", 320, -90)
        p.empty:SetWidth(630)
        p.empty:SetText("아직 알려진 상대가 없습니다.\n같은 애드온을 쓰는 길드원·파티원이나 전용 채널 사용자가 접속하면 자동으로 나타납니다.")

        -- shop + log
        local shopBox = W.InfoCard(p, 654, 164, { plain = true })
        shopBox:SetPoint("TOPLEFT", 308, -242)
        p.shopBox = shopBox
        local st = W.Text(shopBox, 13, W.SECTION, "LEFT")
        st:SetPoint("TOPLEFT", 18, -12)
        st:SetText("결투장 상점 (주간)")
        p.coins = W.Text(shopBox, 12, W.COLORS.white, "RIGHT")
        p.coins:SetPoint("TOPRIGHT", -18, -12)
        p.shop = {}
        for i, row in ipairs(A.SHOP) do
            local col, r = (i - 1) % 2, math.floor((i - 1) / 2)
            local b = W.Button(shopBox, "", 304, 30, function()
                local ok, err = A.Buy(ns.Hero.Active(), i, 1)
                if not ok then W.Toast(err) end
                UI.RefreshPanel()
            end, "cyan")
            b:SetPoint("TOPLEFT", 16 + col * 314, -34 - r * 36)
            p.shop[i] = b
        end
        p.log = W.Text(shopBox, 11, W.COLORS.white, "LEFT")
        p.log:SetPoint("BOTTOMLEFT", 18, 12)
        p.log:SetWidth(620)
    end,
    refresh = function(p, hero)
        local A = ns.Arena
        A.UpdateRefresh(hero)
        local ar = hero.arena
        local idx, row, rank, total = A.Tier(hero)
        p.tier:SetText(row.name)
        p.head:SetText(string.format("점수 %d · %d위 / %d명\n%d승 %d패 · 방어 %d승 %d패", ar.score, rank, total, ar.wins, ar.losses,
            ar.defWins or 0, ar.defLosses or 0))
        p.tickets.text:SetText(string.format("입장권 |cffffffff%d|r / %d · 무료 새로고침 %d", ar.tickets, A.TICKET_CAP, ar.refresh))
        local se = ar.season or { weeks = 0, wins = 0 }
        local sr = A.SeasonRewards(hero, idx)
        p.sub:SetText(string.format("|cffffd100일일 보상|r %s\n|cffffd100주간 보상|r %s + 별빛 강화 주문서 %d\n\n"
            .. "|cffffd100시즌|r %d/%d주 · 공격 승리 %d\n시즌 보상(예상): 별빛 강화 %d, 잠재 큐브 %d, 추가 잠재 큐브 %d%s",
            (W.Money("arenaCoin", row.daily)), (W.Money("arenaCoin", row.weekly)), row.sf,
            (se.weeks or 0) + 1, A.SEASON_WEEKS, se.wins or 0, sr.starforceScroll or 0, sr.cubeMiracle or 0,
            sr.cubeAdditional or 0, sr.meso and (", 골드 " .. U.FormatNumber(sr.meso)) or ""))
        local opps = A.Opponents(hero)
        p.empty:SetShown(#opps == 0)
        for i, box in ipairs(p.opps) do
            local o = opps[i]
            if o then
                box:Show()
                local job = o.job and ns.SkillBook.JobByKey(o.job)
                box.icon.icon:SetTexture(job and ns.Skin.Job(job).icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                box.name:SetText(o.name)
                box.info:SetText(string.format("%s Lv.%d\n전투력 |cffffd100%s|r\n점수 %d", jobName(o.job), o.level or 0,
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
        p.coins:SetText("보유 " .. (W.Money("arenaCoin", ns.Hero.Count(hero, "arenaCoin"))))
        for i, b in ipairs(p.shop) do
            local row2 = A.SHOP[i]
            b:SetText(string.format("%s ×%d  ·  %s  ·  %d/%d", D.CurrencyName(row2.key), row2.n, (W.Money("arenaCoin", row2.price)),
                ar.bought[row2.key] or 0, row2.weekly))
        end
        local lines = {}
        for i = 1, math.min(3, #ar.log) do
            local l = ar.log[i]
            lines[#lines + 1] = string.format("%s %s %s (%+d)", l.kind == "attack" and "공격" or "방어", l.opp,
                l.won and "|cff40ff40승리|r" or "|cffff4040패배|r", l.delta or 0)
        end
        p.log:SetText(#lines > 0 and ("|cffffd100최근 전투|r  " .. table.concat(lines, "  ·  ")) or "|cff808080최근 전투 기록이 없습니다.|r")
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
