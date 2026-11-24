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

local STAT_ORDER = { "Attack", "MaxHp", "MaxMp", "Defence", "Str", "Dex", "Int", "Luk", "MainDamagePower",
    "AttackPower", "FinalDamage", "CriticalChance", "CriticalPower", "MinDamageRatio", "MaxDamageRatio",
    "AttackPowerToBoss", "AttackPowerExcludeBoss", "BaseAttackPower", "SkillPower", "AttackSpeed", "PiercePower",
    "Toughness", "HitChance", "AvoidChance", "CoolTimeReduceRatio", "BonusExpPercent", "BonusGoldPercent" }

---------------------------------------------------------------------------
-- 캐릭터
---------------------------------------------------------------------------
UI.RegisterPanel("character", {
    title = "캐릭터", order = 10,
    build = function(p)
        p.rows = {}
        for i, stat in ipairs(STAT_ORDER) do
            local col, row = math.floor((i - 1) / 9), (i - 1) % 9
            local l = W.Text(p, 12, W.COLORS.gray, "LEFT")
            l:SetPoint("TOPLEFT", 10 + col * 310, -10 - row * 22)
            l:SetText(ns.StatLabels[stat] or stat)
            local v = W.Text(p, 12, W.COLORS.white, "RIGHT")
            v:SetPoint("TOPLEFT", 160 + col * 310, -10 - row * 22)
            v:SetWidth(130)
            p.rows[stat] = v
        end
        p.hint = W.Text(p, 11, W.COLORS.gray, "LEFT")
        p.hint:SetPoint("BOTTOMLEFT", 10, 6)
    end,
    refresh = function(p, hero)
        local b = ns.Game.battle
        local c = b and b.heroCreature
        if not c then return end
        for stat, fs in pairs(p.rows) do fs:SetText(ns.FormatStat(stat, c:Stat(stat))) end
        local job = ns.Hero.Job(hero)
        local skin = ns.Skin.Job(job)
        p.hint:SetText(string.format("%s · 주스탯 %s / 부스탯 %s · 처치 %s · 플레이 %s",
            skin.display or "", job.mainStat, job.subStat, U.Comma(hero.stats.kills or 0),
            U.FormatDuration(hero.stats.playSeconds or 0)))
    end,
})

---------------------------------------------------------------------------
-- 스킬
---------------------------------------------------------------------------
local CAT = { basic = "기본 공격", active = "액티브", passive = "패시브" }

UI.RegisterPanel("skills", {
    title = "스킬", order = 20,
    build = function(p)
        p.list = W.ScrollList(p, 940, 230, 30, function(parent)
            local r = CreateFrame("Frame", nil, parent)
            r:SetHeight(28)
            r.icon = W.Icon(r, 24)
            r.icon:SetPoint("LEFT", 2, 0)
            r.name = W.Text(r, 12, W.COLORS.white, "LEFT")
            r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
            r.name:SetWidth(260)
            r.info = W.Text(r, 11, W.COLORS.gray, "LEFT")
            r.info:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
            r.info:SetWidth(460)
            r.toggle = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
            r.toggle:SetSize(22, 22)
            r.toggle:SetPoint("RIGHT", -6, 0)
            return r
        end, function(r, e)
            local hero = ns.Hero.Active()
            r.icon.icon:SetTexture(ns.Skin.SkillIcon(e.row.SkillIndex))
            local lvText = e.unlocked and ("Lv." .. e.level)
                or (e.needJob and string.format("|cffff6060%d차 전직 필요|r", e.needJob))
                or string.format("|cffff6060%d레벨 해금|r", e.unlock)
            r.name:SetText(string.format("%s  |cffffd100%s|r", ns.Skin.SkillName(e.row.SkillIndex), lvText))
            local s = D.Skills[e.row.SkillIndex]
            local cd = s and s.CoolTimeMs and string.format(" · 재사용 %.0f초", s.CoolTimeMs / 1000) or ""
            r.info:SetText(string.format("%d차 · %s%s", e.row.JobStep or 0, CAT[e.cat] or e.cat, cd))
            r.icon.icon:SetDesaturated(not e.unlocked)
            r.toggle:SetShown(e.cat == "active" and e.unlocked)
            r.toggle:SetChecked(not (hero.disabledActives and hero.disabledActives[e.row.SkillIndex]))
            r.toggle:SetScript("OnClick", function(self)
                hero.disabledActives = hero.disabledActives or {}
                hero.disabledActives[e.row.SkillIndex] = (not self:GetChecked()) or nil
                ns.Hero.Changed(hero, "skills")
            end)
            W.Tooltip(r.icon, function(tt)
                tt:AddLine(ns.Skin.SkillName(e.row.SkillIndex), 1, 0.82, 0)
                if s and s.Mp then tt:AddLine("MP " .. s.Mp, 0.4, 0.7, 1) end
            end)
        end)
        p.list:SetPoint("TOPLEFT", 0, 0)
    end,
    refresh = function(p, hero)
        local job = ns.Hero.Job(hero)
        local list = {}
        for _, row in ipairs(job.rows) do
            local unlocked = ns.SkillBook.RowUnlocked(row, hero.level, hero.jobStep)
            local unlock = math.max(D.SkillRules.stepUnlockLevel[row.JobStep or 0] or 1, row.RequireLevel or 0)
            local needJob = (row.JobStep or 0) > (hero.jobStep or 4) and hero.level >= unlock
            list[#list + 1] = { row = row, unlocked = unlocked, unlock = unlock, needJob = needJob and row.JobStep,
                cat = ns.SkillBook.Category(row),
                level = ns.SkillBook.RowLevel(row, hero.level, {}) }
        end
        p.list:SetData(list)
    end,
})

---------------------------------------------------------------------------
-- 마스터리
---------------------------------------------------------------------------
UI.RegisterPanel("mastery", {
    title = "마스터리", order = 25,
    build = function(p)
        p.status = W.Text(p, 12, W.COLORS.gold, "LEFT")
        p.status:SetPoint("TOPLEFT", 4, -2)
        p.list = W.ScrollList(p, 940, 210, 28, function(parent)
            local r = CreateFrame("Frame", nil, parent)
            r:SetHeight(26)
            r.icon = W.Icon(r, 22)
            r.icon:SetPoint("LEFT", 2, 0)
            r.name = W.Text(r, 12, W.COLORS.white, "LEFT")
            r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
            r.name:SetWidth(380)
            r.cost = W.Text(r, 11, W.COLORS.gray, "LEFT")
            r.cost:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
            r.cost:SetWidth(330)
            r.btn = W.Button(r, "배우기", 80, 20)
            r.btn:SetPoint("RIGHT", -6, 0)
            return r
        end, function(r, e)
            local n = e.node
            local icon = n.ParentSkillIndex and ns.Skin.SkillIcon(n.ParentSkillIndex) or "Interface\\Icons\\Spell_Holy_MagicalSentry"
            r.icon.icon:SetTexture(icon)
            local entry = ns.Skin.SkillEntry(n.MasteryIndex)
            local name = (entry and (entry.nameKo or entry.nameEn)) or n.nameKo or tostring(n.MasteryIndex)
            if n.ParentSkillIndex and not entry then
                name = ns.Skin.SkillName(n.ParentSkillIndex) .. " 숙련"
            end
            local color = ({ learned = "|cff40ff40", learning = "|cffffd100", available = "|cffffffff" })[e.state] or "|cff808080"
            r.name:SetText(string.format("%s%s|r  |cff999999Lv.%d|r", color, name, n.RequireCreatureLevel or 0))
            local key, cnt = ns.Mastery.Cost(n)
            local t = e.state == "learning" and ("남은 시간 " .. U.FormatDuration(e.remain or 0))
                or string.format("%s · 학습 %s", (W.Money(key, cnt)), U.FormatDuration(n.LearnedDelaySeconds or 0))
            r.cost:SetText(t)
            r.btn:SetShown(e.state == "available" or e.state == "learning")
            r.btn:SetText(e.state == "learning" and "단축" or "배우기")
            r.btn:SetScript("OnClick", function()
                local hero = ns.Hero.Active()
                if e.state == "learning" then
                    if not ns.Mastery.Skip(hero, math.huge) then W.Toast("시간 단축권이 없습니다.") end
                else
                    local ok, err = ns.Mastery.Learn(hero, n.MasteryIndex)
                    if not ok then W.Toast(err) end
                end
                UI.RefreshPanel()
            end)
        end)
        p.list:SetPoint("TOPLEFT", 0, -20)
    end,
    refresh = function(p, hero)
        local nodes = ns.Mastery.Nodes(hero)
        local learned = 0
        for _, e in ipairs(nodes) do if e.state == "learned" then learned = learned + 1 end end
        p.status:SetText(string.format("습득 %d / %d", learned, #nodes))
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
        p.chList = W.ScrollList(p, 260, 230, 24, function(parent)
            local b = W.Button(parent, "", 230, 22)
            return b
        end, function(b, e)
            b:SetText(string.format("%d. %s", e.ch, ns.Skin.ChapterName(e.ch) or ("챕터 " .. e.ch)))
            b:SetEnabled(e.unlocked)
            b:SetScript("OnClick", function() p.selected = e.ch; UI.RefreshPanel() end)
        end)
        p.chList:SetPoint("TOPLEFT", 0, 0)
        p.stages = {}
        for i = 1, 20 do
            local b = W.Button(p, tostring(i), 120, 24)
            b:SetPoint("TOPLEFT", 280 + ((i - 1) % 5) * 126, -10 - math.floor((i - 1) / 5) * 30)
            p.stages[i] = b
        end
        p.info = W.Text(p, 12, W.COLORS.white, "LEFT")
        p.info:SetPoint("TOPLEFT", 280, -140)
        p.info:SetWidth(640)
        p.info:SetJustifyV("TOP")
    end,
    refresh = function(p, hero)
        local cp = hero.campaign
        local chs = {}
        for ch = 1, #D.Chapters do chs[#chs + 1] = { ch = ch, unlocked = ch <= cp.maxChapter } end
        p.chList:SetData(chs)
        local ch = p.selected or cp.chapter
        local cd = D.Chapters[ch]
        for i, b in ipairs(p.stages) do
            local sd = cd and cd.stages[i]
            if sd then
                b:Show()
                local isBoss = sd.boss or sd.bossFight
                b:SetText(string.format("%d-%d%s", ch, i, isBoss and " 보스" or ""))
                local unlocked = ns.Campaign.IsUnlocked(hero, ch, i) and not isBoss
                b:SetEnabled(unlocked)
                if ch == cp.chapter and i == cp.stage then b:LockHighlight() else b:UnlockHighlight() end
                b:SetScript("OnClick", function() ns.Campaign.SetStage(hero, ch, i) end)
            else
                b:Hide()
            end
        end
        local sd = ns.Campaign.StageData(cp.chapter, cp.stage)
        local lines = {}
        if sd and sd.hunt then
            lines[#lines + 1] = string.format("현재 사냥터: %s", ns.Campaign.StageName(cp.chapter, cp.stage))
            lines[#lines + 1] = string.format("몬스터 HP %s · 공격력 %s · 방어력 %s · 회피 %s (필요 명중)",
                U.FormatNumber(sd.hunt.hp), U.FormatNumber(sd.hunt.atk), U.FormatNumber(sd.hunt.def), sd.hunt.avoid or 0)
            lines[#lines + 1] = string.format("처치당 경험치 %s · %d마리 / %d초", U.FormatNumber(sd.exp or 0),
                sd.spawn and sd.spawn.n or 0, sd.spawn and sd.spawn.cycle or 0)
        end
        local nch, nst, kind = ns.Campaign.NextChallenge(hero)
        if nch then
            lines[#lines + 1] = string.format("다음 목표: %s %s", kind == "boss" and "보스" or "도전", ns.Campaign.StageName(nch, nst))
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
