-- Core panels: 캐릭터(스탯), 스킬, 마스터리, 챕터.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local D = ns.Data

ns.StatLabels = {
    Attack = "공격력", MaxHp = "최대 HP", MaxMp = "최대 MP", Defence = "방어력",
    Str = "STR", Dex = "DEX", Int = "INT", Luk = "LUK",
    AttackPower = "데미지", AttackPower2 = "데미지 증폭", MainDamagePower = "스탯 비례 데미지",
    CriticalChance = "크리티컬 확률", CriticalPower = "크리티컬 데미지",
    MinDamageRatio = "최소 데미지 배율", MaxDamageRatio = "최대 데미지 배율",
    FinalDamage = "최종 데미지", AttackPowerToBoss = "보스 몬스터 데미지", AttackPowerExcludeBoss = "일반 몬스터 데미지",
    BaseAttackPower = "기본 공격 데미지", SkillPower = "스킬 데미지", AttackSpeed = "공격 속도",
    PiercePower = "방어 관통", Toughness = "받는 피해 감소", HitChance = "명중", AvoidChance = "회피",
    CoolTimeReduceRatio = "재사용 대기시간 감소", CoolTimeReduce = "재사용 대기시간 감소(초)",
    BonusExpPercent = "경험치 획득량", BonusGoldPercent = "골드 획득량", BonusItemPercent = "아이템 획득량",
    AllSkillLevel = "모든 스킬 레벨", MpRegen = "MP 회복", CriticalResist = "크리티컬 저항",
    AttackPowerInCc = "상태이상 데미지", BuffDurationRatio = "버프 지속시간",
}
local PCT = {
    AttackPower = true, AttackPower2 = true, MainDamagePower = true, CriticalChance = true, CriticalPower = true,
    MinDamageRatio = true, MaxDamageRatio = true, FinalDamage = true, AttackPowerToBoss = true,
    AttackPowerExcludeBoss = true, BaseAttackPower = true, SkillPower = true, AttackSpeed = true, PiercePower = true,
    Toughness = true, CoolTimeReduceRatio = true, BonusExpPercent = true, BonusGoldPercent = true,
    BonusItemPercent = true, CriticalResist = true, AttackPowerInCc = true, BuffDurationRatio = true,
}
function ns.FormatStat(stat, v)
    if PCT[stat] then return string.format("%.1f%%", (v or 0) / 10) end
    return U.FormatNumber(v or 0)
end

-- 캐릭터 stat boxes (original 캐릭터 정보: 기본 / 공격 / 기타 sections)
local STAT_GROUPS = {
    { title = "기본 능력치", stats = { "Attack", "MaxHp", "MaxMp", "Defence", "Str", "Dex", "Int", "Luk", "MainDamagePower" } },
    { title = "공격 능력치", stats = { "AttackPower", "FinalDamage", "CriticalChance", "CriticalPower", "MinDamageRatio",
        "MaxDamageRatio", "AttackPowerToBoss", "AttackPowerExcludeBoss", "BaseAttackPower", "SkillPower" } },
    { title = "기타 능력치", stats = { "AttackSpeed", "PiercePower", "Toughness", "HitChance", "AvoidChance",
        "CoolTimeReduceRatio", "BonusExpPercent", "BonusGoldPercent" } },
}

---------------------------------------------------------------------------
-- 캐릭터: hero model + name plate on the left, stat boxes on the right
---------------------------------------------------------------------------
UI.RegisterPanel("character", {
    title = "캐릭터", order = 10,
    build = function(p)
        local left = W.InfoCard(p, 300, 406, { plain = true })
        left:SetPoint("TOPLEFT", 0, 0)
        p.left = left
        p.level = W.Text(left, 14, W.COLORS.gold, "CENTER")
        p.level:SetPoint("TOP", 0, -16)
        p.name = W.Text(left, 17, W.COLORS.white, "CENTER")
        p.name:SetPoint("TOP", 0, -36)
        p.job = W.Text(left, 12, W.COLORS.gray, "CENTER")
        p.job:SetPoint("TOP", 0, -60)
        local stage = left:CreateTexture(nil, "ARTWORK")
        stage:SetTexture("Interface\\Buttons\\WHITE8X8")
        stage:SetPoint("TOPLEFT", 16, -80)
        stage:SetPoint("BOTTOMRIGHT", -16, 96)
        stage:SetVertexColor(0.16, 0.2, 0.28, 0.55)
        local m = CreateFrame("DressUpModel", nil, left)
        m:SetPoint("TOPLEFT", 16, -80)
        m:SetPoint("BOTTOMRIGHT", -16, 96)
        p.model = m
        ns.BattleView.extraModels = ns.BattleView.extraModels or {}
        table.insert(ns.BattleView.extraModels, m)
        p.cp = W.Counter(left, 230)
        p.cp:SetPoint("BOTTOM", 0, 60)
        p.cp:SetHeight(28)
        p.cp.text:SetFont(p.cp.text:GetFont() or "Fonts\\2002.TTF", 15, "")
        p.info = W.Text(left, 11, W.COLORS.gray, "CENTER")
        p.info:SetPoint("BOTTOM", 0, 36)
        p.info:SetWidth(270)
        p.play = W.Text(left, 11, W.COLORS.gray, "CENTER")
        p.play:SetPoint("BOTTOM", 0, 16)
        p.play:SetWidth(270)

        p.boxes = {}
        for i, grp in ipairs(STAT_GROUPS) do
            local box = W.InfoCard(p, 214, 406, { plain = true })
            box:SetPoint("TOPLEFT", 306 + (i - 1) * 220, 0)
            box.group = grp
            p.boxes[i] = box
        end
    end,
    refresh = function(p, hero)
        local b = ns.Game.battle
        local c = b and b.heroCreature
        local job = ns.Hero.Job(hero)
        local skin = ns.Skin.Job(job)
        p.level:SetText("Lv." .. hero.level)
        p.name:SetText(hero.name or "")
        p.job:SetText(string.format("%s · %d차 전직", skin.display or "", hero.jobStep or 0))
        local cp = ns.Game.profile and ns.Hero.CombatPower(ns.Game.profile) or 0
        p.cp.text:SetText("|TInterface\\Icons\\INV_Sword_04:16:16|t 전투력 |cffffd100" .. U.Comma(cp) .. "|r")
        p.info:SetText(string.format("주스탯 %s · 부스탯 %s", job.mainStat or "-", job.subStat or "-"))
        p.play:SetText(string.format("처치 %s · 플레이 %s", U.Comma(hero.stats.kills or 0), U.FormatDuration(hero.stats.playSeconds or 0)))
        if not p.modelReady then
            p.modelReady = true
            pcall(p.model.SetUnit, p.model, "player")
            pcall(p.model.SetFacing, p.model, math.rad(20))
            ns.BattleView.ApplyLooks(p.model)
        end
        for _, box in ipairs(p.boxes) do
            local lines = { { header = box.group.title } }
            for _, stat in ipairs(box.group.stats) do
                lines[#lines + 1] = { ns.StatLabels[stat] or stat, c and ns.FormatStat(stat, c:Stat(stat)) or "-" }
            end
            box:SetLines(lines)
        end
    end,
})

---------------------------------------------------------------------------
-- 스킬: auto-use strip (장착중인 스킬, ON/OFF), job step tabs, skill cards, detail card
---------------------------------------------------------------------------
local CAT = { basic = "기본 공격", active = "액티브", passive = "패시브" }
local STEP_TABS = { "기본·1차", "2차", "3차", "4차" }
local function tabOf(step) return math.max(1, step or 0) end
local SK_CARD_W = 352

local function skillEntries(hero)
    local job = ns.Hero.Job(hero)
    local list = {}
    for _, row in ipairs(job.rows) do
        local unlocked = ns.SkillBook.RowUnlocked(row, hero.level, hero.jobStep)
        local unlock = math.max(D.SkillRules.stepUnlockLevel[row.JobStep or 0] or 1, row.RequireLevel or 0)
        local needJob = (row.JobStep or 0) > (hero.jobStep or 4) and hero.level >= unlock
        list[#list + 1] = { row = row, sid = row.SkillIndex, unlocked = unlocked, unlock = unlock,
            needJob = needJob and row.JobStep, cat = ns.SkillBook.Category(row),
            level = ns.SkillBook.RowLevel(row, hero.level, {}) }
    end
    return list
end

local function autoOn(hero, sid) return not (hero.disabledActives and hero.disabledActives[sid]) end
local function setAuto(hero, sid, on)
    hero.disabledActives = hero.disabledActives or {}
    hero.disabledActives[sid] = (not on) or nil
    ns.Hero.Changed(hero, "skills")
end

UI.RegisterPanel("skills", {
    title = "스킬", order = 20,
    build = function(p)
        p.tab = 1
        -- auto-use strip
        local strip = CreateFrame("Frame", nil, p, BackdropTemplateMixin and "BackdropTemplate" or nil)
        strip:SetPoint("TOPLEFT", 0, 0)
        strip:SetSize(600, 84)
        W.Backdrop(strip, { 0.04, 0.04, 0.05, 0.85 }, { 0.3, 0.3, 0.32, 1 }, 10)
        if W.ArtInfo("box_dark") then W.Slice(strip, "box_dark", 0.7) end
        local st = W.Text(strip, 11, W.COLORS.gold, "LEFT")
        st:SetPoint("TOPLEFT", 12, -7)
        st:SetText("자동 사용 스킬")
        p.autoSlots = {}
        for i = 1, 10 do
            local ic = W.Icon(strip, 38)
            ic:SetPoint("TOPLEFT", 12 + (i - 1) * 58, -22)
            ic.toggle = W.Toggle(strip, 42, 16, function(v)
                local hero = ns.Hero.Active()
                if hero and ic.sid then setAuto(hero, ic.sid, v); UI.RefreshPanel() end
            end)
            ic.toggle:SetPoint("TOP", ic, "BOTTOM", 0, -2)
            ic:SetScript("OnClick", function(self) if self.sid then p.selected = self.sid; UI.RefreshPanel() end end)
            p.autoSlots[i] = ic
        end
        p.tabs = W.Tabs(p, STEP_TABS, 90, 24, function(i) p.tab = i; UI.RefreshPanel() end)
        p.tabs:SetPoint("TOPLEFT", 0, -92)
        p.cards = {}
        for i = 1, 12 do
            local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local c = CreateFrame("Button", nil, p, BackdropTemplateMixin and "BackdropTemplate" or nil)
            c:SetSize(296, 44)
            c:SetPoint("TOPLEFT", col * 304, -122 - row * 47)
            W.Backdrop(c, { 0.08, 0.09, 0.11, 0.92 }, { 0.3, 0.32, 0.36, 1 }, 10)
            c.icon = W.Icon(c, 36)
            c.icon:SetPoint("LEFT", 4, 0)
            c.icon:EnableMouse(false)
            c.name = W.Text(c, 13, W.COLORS.white, "LEFT")
            c.name:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 8, -3)
            c.name:SetWidth(170)
            c.sub = W.Text(c, 11, W.COLORS.gray, "LEFT")
            c.sub:SetPoint("BOTTOMLEFT", c.icon, "BOTTOMRIGHT", 8, 3)
            c.sub:SetWidth(170)
            c.lv = W.Text(c, 13, W.COLORS.gold, "RIGHT")
            c.lv:SetPoint("RIGHT", -10, 0)
            c.sel = c:CreateTexture(nil, "OVERLAY")
            c.sel:SetTexture("Interface\\Buttons\\WHITE8X8")
            c.sel:SetPoint("TOPLEFT", 3, -3)
            c.sel:SetPoint("BOTTOMRIGHT", -3, 3)
            c.sel:SetVertexColor(0.3, 0.75, 1, 0.16)
            c:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            c:SetScript("OnClick", function(self) if self.sid then p.selected = self.sid; UI.RefreshPanel() end end)
            p.cards[i] = c
        end
        local card = W.InfoCard(p, SK_CARD_W, 406)
        card:SetPoint("TOPRIGHT", 0, 0)
        p.card = card
        card.desc = W.Text(card, 11, W.COLORS.gray, "LEFT")
        card.desc:SetPoint("TOPLEFT", 20, -300)
        card.desc:SetWidth(SK_CARD_W - 40)
        card.desc:SetJustifyV("TOP")
        p.autoBtn = W.Button(card, "자동 사용 ON", SK_CARD_W - 40, 30, function()
            local hero = ns.Hero.Active()
            if hero and p.selected then setAuto(hero, p.selected, not autoOn(hero, p.selected)); UI.RefreshPanel() end
        end, "green")
        p.autoBtn:SetPoint("BOTTOM", 0, 10)
    end,
    refresh = function(p, hero)
        local list = skillEntries(hero)
        local byId = {}
        for _, e in ipairs(list) do byId[e.sid] = e end
        if not (p.selected and byId[p.selected]) then
            p.selected = list[1] and list[1].sid
            p.tab = 1
            p.tabs:Select(1)
        end
        -- auto strip: unlocked actives
        local actives = {}
        for _, e in ipairs(list) do if e.cat == "active" and e.unlocked then actives[#actives + 1] = e end end
        for i, ic in ipairs(p.autoSlots) do
            local e = actives[i]
            ic.sid = e and e.sid
            if e then
                ic:Show(); ic.toggle:Show()
                ic.icon:SetTexture(ns.Skin.SkillIcon(e.sid))
                ic.icon:SetDesaturated(not autoOn(hero, e.sid))
                ic.count:SetText(tostring(e.level))
                ic.toggle:SetValue(autoOn(hero, e.sid))
                W.SetBorderGrade(ic, nil)
            else
                ic:Hide(); ic.toggle:Hide()
            end
        end
        -- tab dots: newly unlockable steps are not tracked; show red dot when a step needs job advancement
        for i, b in ipairs(p.tabs.buttons) do
            local need = false
            for _, e in ipairs(list) do if tabOf(e.row.JobStep) == i and e.needJob then need = true end end
            b.dot:SetShown(need)
        end
        -- cards for the current tab
        local shown = {}
        for _, e in ipairs(list) do if tabOf(e.row.JobStep) == p.tab then shown[#shown + 1] = e end end
        for i, c in ipairs(p.cards) do
            local e = shown[i]
            c.sid = e and e.sid
            if e then
                c:Show()
                c.icon.icon:SetTexture(ns.Skin.SkillIcon(e.sid))
                c.icon.icon:SetDesaturated(not e.unlocked)
                c.name:SetText(ns.Skin.SkillName(e.sid))
                c.name:SetTextColor(e.unlocked and 1 or 0.55, e.unlocked and 1 or 0.55, e.unlocked and 1 or 0.55)
                local s = D.Skills[e.sid]
                local cd = s and s.CoolTimeMs and string.format(" · %.0f초", s.CoolTimeMs / 1000) or ""
                c.sub:SetText(string.format("%s%s", CAT[e.cat] or e.cat, cd))
                if e.unlocked then
                    c.lv:SetText(e.row.DisableSkillLevel and "" or ("Lv." .. e.level))
                elseif e.needJob then
                    c.lv:SetText(string.format("|cffff6060%d차 전직|r", e.needJob))
                else
                    c.lv:SetText(string.format("|cffff6060Lv.%d 해금|r", e.unlock))
                end
                c.sel:SetShown(e.sid == p.selected)
                local cat = e.cat == "active" and { 0.3, 0.75, 1 } or (e.cat == "basic" and { 1, 0.82, 0 } or { 0.6, 0.6, 0.65 })
                if c.SetBackdropBorderColor then c:SetBackdropBorderColor(cat[1] * 0.7, cat[2] * 0.7, cat[3] * 0.7, 1) end
            else
                c:Hide()
            end
        end
        -- detail
        local e = byId[p.selected]
        if not e then return end
        local card = p.card
        local s = D.Skills[e.sid] or {}
        card.stars:SetText((e.cat == "active" and "|cff4dbfff" or (e.cat == "basic" and "|cffffd100" or "|cffb0b0b0")) .. (CAT[e.cat] or e.cat) .. " 스킬|r")
        card.name:SetText(ns.Skin.SkillName(e.sid))
        card.icon.icon:SetTexture(ns.Skin.SkillIcon(e.sid))
        card.icon.icon:SetDesaturated(not e.unlocked)
        W.SetBorderGrade(card.icon, nil)
        card.line1:SetText(string.format("%d차 스킬", e.row.JobStep or 0))
        card.line2:SetText(e.row.DisableSkillLevel and "레벨 없음" or string.format("Lv. |cffffffff%d|r", e.level))
        card.line3:SetText(e.unlocked and "|cff9be05a사용 가능|r" or (e.needJob and string.format("|cffff6060%d차 전직 필요|r", e.needJob)
            or string.format("|cffff6060Lv.%d에 해금|r", e.unlock)))
        if e.cat == "active" and e.unlocked then
            card.tag:SetText(autoOn(hero, e.sid) and "|cff9be05a자동 ON|r" or "|cffaaaaaa자동 OFF|r")
        else
            card.tag:SetText("")
        end
        local lines = { { header = "스킬 정보" },
            { "분류", CAT[e.cat] or e.cat },
            { "해금 레벨", "Lv." .. e.unlock },
        }
        if s.Mp then lines[#lines + 1] = { "MP 소모", U.Comma(s.Mp) } end
        if s.CoolTimeMs then lines[#lines + 1] = { "재사용 대기시간", string.format("%.1f초", s.CoolTimeMs / 1000) } end
        if s.TargetCount then lines[#lines + 1] = { "최대 대상 수", tostring(s.TargetCount) } end
        card:SetLines(lines)
        card.desc:SetText(e.cat == "passive" and "패시브 스킬은 해금되면 항상 적용됩니다."
            or (e.cat == "basic" and "기본 공격은 적이 사거리 안에 있으면 자동으로 사용합니다."
            or "액티브 스킬은 재사용 대기시간마다 자동으로 사용합니다. 끄면 전투에서 사용하지 않습니다."))
        p.autoBtn:SetShown(e.cat == "active")
        p.autoBtn:SetEnabled(e.unlocked and true or false)
        p.autoBtn:SetText(autoOn(hero, e.sid) and "자동 사용 끄기" or "자동 사용 켜기")
        p.autoBtn:SetStyle(autoOn(hero, e.sid) and "cyan" or "green")
    end,
})

---------------------------------------------------------------------------
-- 마스터리
---------------------------------------------------------------------------
UI.RegisterPanel("mastery", {
    title = "마스터리", order = 25,
    build = function(p)
        local head = W.InfoCard(p, 962, 40, { plain = true })
        head:SetPoint("TOPLEFT", 0, 0)
        p.status = W.Text(head, 14, W.COLORS.gold, "LEFT")
        p.status:SetPoint("LEFT", 16, 0)
        p.bar = W.Bar(head, 420, 10, 0.3, 0.8, 0.2)
        p.bar:SetPoint("LEFT", 160, 0)
        p.hint = W.Text(head, 11, W.COLORS.gray, "RIGHT")
        p.hint:SetPoint("RIGHT", -16, 0)
        p.hint:SetText("학습 중인 마스터리는 시간이 지나면 완료됩니다.")
        p.list = W.ScrollList(p, 962, 358, 54, function(parent)
            return W.RowCard(parent, 936, 50)
        end, function(r, e)
            local n = e.node
            local icon = n.ParentSkillIndex and ns.Skin.SkillIcon(n.ParentSkillIndex) or "Interface\\Icons\\Spell_Holy_MagicalSentry"
            local entry = ns.Skin.SkillEntry(n.MasteryIndex)
            local name = (entry and (entry.nameKo or entry.nameEn)) or n.nameKo or tostring(n.MasteryIndex)
            if n.ParentSkillIndex and not entry then
                name = ns.Skin.SkillName(n.ParentSkillIndex) .. " 숙련"
            end
            local color = ({ learned = "|cff40ff40", learning = "|cffffd100", available = "|cffffffff" })[e.state] or "|cff808080"
            local key, cnt = ns.Mastery.Cost(n)
            local stateText = ({ learned = "|cff40ff40습득 완료|r", learning = "|cffffd100학습 중 · 남은 시간 " .. U.FormatDuration(e.remain or 0) .. "|r",
                available = "학습 가능 · 학습 시간 " .. U.FormatDuration(n.LearnedDelaySeconds or 0) })[e.state]
                or (((ns.Hero.Active() or {}).level or 0) >= (n.RequireCreatureLevel or 0) and "|cffa0a0a0이전 마스터리를 먼저 배워야 합니다.|r"
                or string.format("|cffff6060Lv.%d 필요|r", n.RequireCreatureLevel or 0))
            r:Set({ icon = icon, title = string.format("%s%s|r  |cff999999Lv.%d|r", color, name, n.RequireCreatureLevel or 0),
                sub = stateText, right = e.state ~= "learned" and (W.Money(key, cnt)) or nil,
                btn = (e.state == "available" or e.state == "learning") and (e.state == "learning" and "단축" or "배우기") or "",
                enabled = true, dot = false, claimed = e.state == "learned",
                fn = function()
                    local hero = ns.Hero.Active()
                    if e.state == "learning" then
                        if not ns.Mastery.Skip(hero, math.huge) then W.Toast("시간 단축권이 없습니다.") end
                    else
                        local ok, err = ns.Mastery.Learn(hero, n.MasteryIndex)
                        if not ok then W.Toast(err) end
                    end
                    UI.RefreshPanel()
                end })
            r.icon.icon:SetDesaturated(e.state == "locked")
        end)
        p.list:SetPoint("TOPLEFT", 0, -48)
    end,
    refresh = function(p, hero)
        local nodes = ns.Mastery.Nodes(hero)
        local learned = 0
        for _, e in ipairs(nodes) do if e.state == "learned" then learned = learned + 1 end end
        p.status:SetText(string.format("습득 %d / %d", learned, #nodes))
        p.bar:SetValue(#nodes > 0 and learned / #nodes or 0)
        -- available / learning first
        table.sort(nodes, function(a, b)
            local order = { learning = 1, available = 2, locked = 3, learned = 4 }
            if order[a.state] ~= order[b.state] then return order[a.state] < order[b.state] end
            return (a.node.RequireCreatureLevel or 0) < (b.node.RequireCreatureLevel or 0)
        end)
        p.list:SetData(nodes)
    end,
})

---------------------------------------------------------------------------
-- 챕터
---------------------------------------------------------------------------
UI.RegisterPanel("chapters", {
    title = "챕터", order = 5,
    build = function(p)
        p.chList = W.ScrollList(p, 318, 406, 50, function(parent)
            local r = W.RowCard(parent, 292, 46)
            r.btn:SetWidth(70)
            return r
        end, function(r, e)
            local hero = ns.Hero.Active()
            local cp = hero and hero.campaign or {}
            local cur = e.ch == cp.chapter
            r:Set({ icon = "Interface\\Icons\\INV_Misc_Map_01", grade = cur and 4 or nil,
                title = string.format("%d. %s", e.ch, ns.Skin.ChapterName(e.ch) or ("챕터 " .. e.ch)),
                sub = not e.unlocked and "|cffa0a0a0잠김|r" or (cur and "|cff9be05a사냥 중|r" or (e.ch < (cp.maxChapter or 1) and "클리어" or "진행 중")),
                btn = "선택", enabled = e.unlocked, dot = false,
                fn = function() p.selected = e.ch; UI.RefreshPanel() end })
            r.icon.icon:SetDesaturated(not e.unlocked)
            if r.SetBackdropBorderColor and e.ch == p.selected then r:SetBackdropBorderColor(1, 0.82, 0.3, 1) end
        end)
        p.chList:SetPoint("TOPLEFT", 0, 0)
        local box = W.InfoCard(p, 630, 406, { plain = true })
        box:SetPoint("TOPLEFT", 332, 0)
        p.box = box
        box.art = box:CreateTexture(nil, "ARTWORK")
        box.art:SetPoint("TOPLEFT", 12, -12)
        box.art:SetPoint("TOPRIGHT", -12, -12)
        box.art:SetHeight(96)
        box.art:SetTexCoord(0, 1, 0.32, 0.6)
        box.shade = box:CreateTexture(nil, "ARTWORK", nil, 1)
        box.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        box.shade:SetAllPoints(box.art)
        box.shade:SetVertexColor(0, 0, 0, 0.35)
        p.chTitle = W.Text(box, 20, W.COLORS.gold, "LEFT")
        p.chTitle:SetPoint("BOTTOMLEFT", box.art, "BOTTOMLEFT", 14, 10)
        p.stages = {}
        for i = 1, 20 do
            local b = W.Button(box, tostring(i), 112, 30)
            b:SetPoint("TOPLEFT", 18 + ((i - 1) % 5) * 119, -120 - math.floor((i - 1) / 5) * 36)
            p.stages[i] = b
        end
        p.info = W.Text(box, 12, W.COLORS.white, "LEFT")
        p.info:SetPoint("TOPLEFT", 20, -272)
        p.info:SetWidth(590)
        p.info:SetJustifyV("TOP")
    end,
    refresh = function(p, hero)
        local cp = hero.campaign
        local chs = {}
        for ch = 1, #D.Chapters do chs[#chs + 1] = { ch = ch, unlocked = ch <= cp.maxChapter } end
        local ch = p.selected or cp.chapter
        p.selected = ch
        p.chList:SetData(chs)
        local cd = D.Chapters[ch]
        p.chTitle:SetText(string.format("%d. %s", ch, ns.Skin.ChapterName(ch) or ""))
        local sw = D.SkinWorld and D.SkinWorld.chapters and D.SkinWorld.chapters[ch]
        p.box.art:SetTexture(sw and sw.loadingScreen or "Interface\\Glues\\LoadingScreens\\LoadScreenEasternKingdom")
        for i, b in ipairs(p.stages) do
            local sd = cd and cd.stages[i]
            if sd then
                b:Show()
                local isBoss = sd.boss or sd.bossFight
                local here = ch == cp.chapter and i == cp.stage
                b:SetText(string.format("%s%d-%d%s", here and "▶ " or "", ch, i, isBoss and " 보스" or ""))
                local unlocked = ns.Campaign.IsUnlocked(hero, ch, i) and not isBoss
                b:SetStyle(here and "orange" or (isBoss and "green" or "cyan"))
                b:SetEnabled(unlocked or here)
                b:SetScript("OnClick", function() ns.Campaign.SetStage(hero, ch, i); UI.RefreshPanel() end)
            else
                b:Hide()
            end
        end
        local sd = ns.Campaign.StageData(cp.chapter, cp.stage)
        local lines = {}
        if sd and sd.hunt then
            lines[#lines + 1] = string.format("|cffffd100현재 사냥터|r  %s", ns.Campaign.StageName(cp.chapter, cp.stage))
            lines[#lines + 1] = string.format("몬스터 HP %s · 공격력 %s · 방어력 %s · 회피 %s (필요 명중)",
                U.FormatNumber(sd.hunt.hp), U.FormatNumber(sd.hunt.atk), U.FormatNumber(sd.hunt.def), sd.hunt.avoid or 0)
            lines[#lines + 1] = string.format("처치당 경험치 %s · %d마리 / %d초", U.FormatNumber(sd.exp or 0),
                sd.spawn and sd.spawn.n or 0, sd.spawn and sd.spawn.cycle or 0)
        end
        local nch, nst, kind = ns.Campaign.NextChallenge(hero)
        if nch then
            lines[#lines + 1] = string.format("|cffffd100다음 목표|r  %s %s", kind == "boss" and "보스" or "도전", ns.Campaign.StageName(nch, nst))
            local rw = ns.Campaign.FirstClearRewards(nch, nst, kind)
            if rw then
                local parts = {}
                for k, v in pairs(rw) do
                    if k == "exp" then parts[#parts + 1] = "경험치 " .. U.FormatNumber(v)
                    else parts[#parts + 1] = (W.Money(k, v)) end
                end
                lines[#lines + 1] = "첫 클리어 보상: " .. table.concat(parts, "  ")
            end
        end
        p.info:SetText(table.concat(lines, "\n"))
    end,
})
