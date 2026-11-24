-- WoW skin: maps the original jobs / skills / chapters / monsters / gear to WoW
-- classes, spells, zones, creatures and item appearances (Data/SkinData.lua).
-- Numbers never change here - only names, icons and models.
local ADDON, ns = ...
local D = ns.Data
local Compat = ns.Compat

local S = {}
ns.Skin = S

local CLASS_ICON = {
    WARRIOR = "Interface\\Icons\\INV_Sword_27", PALADIN = "Interface\\Icons\\Spell_Holy_HolyBolt",
    HUNTER = "Interface\\Icons\\INV_Weapon_Bow_07", ROGUE = "Interface\\Icons\\INV_ThrowingKnife_04",
    PRIEST = "Interface\\Icons\\Spell_Holy_PowerWordShield", SHAMAN = "Interface\\Icons\\Spell_Nature_BloodLust",
    MAGE = "Interface\\Icons\\Spell_Frost_IceStorm", WARLOCK = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    DRUID = "Interface\\Icons\\Spell_Nature_Regeneration",
}

local function icon(path)
    if not path then return nil end
    if type(path) == "number" then return path end
    if path:find("\\", 1, true) then return path end
    return "Interface\\Icons\\" .. path
end

---------------------------------------------------------------------------
-- Jobs
---------------------------------------------------------------------------
function S.Job(job)
    if not job then return {} end
    local sj = D.SkinJobs and D.SkinJobs[job.key]
    if not sj then
        return { display = job.mapleNameKo, icon = "Interface\\Icons\\INV_Misc_QuestionMark" }
    end
    return {
        display = sj.display,
        classToken = sj.classToken,
        specKo = sj.specKo,
        icon = icon(sj.specIcon) or CLASS_ICON[sj.classToken or ""],
        classIcon = icon(sj.classIcon) or CLASS_ICON[sj.classToken or ""],
    }
end

---------------------------------------------------------------------------
-- Skills: exact entry, else the owning row (sub-skills share the owner's look)
---------------------------------------------------------------------------
local skillIndex -- [sid] = entry
local function buildSkillIndex()
    skillIndex = {}
    if not D.SkinJobs then return end
    for _, sj in pairs(D.SkinJobs) do
        for sid, e in pairs(sj.skills or {}) do skillIndex[tonumber(sid)] = e end
        for mid, e in pairs(sj.masteries or {}) do skillIndex[tonumber(mid)] = e end
    end
    -- linked sub-skills inherit their owning row's look
    for _, sj in pairs(D.SkinJobs) do
        for sub, owner in pairs(sj.linked or {}) do
            if not skillIndex[sub] and skillIndex[owner] then skillIndex[sub] = skillIndex[owner] end
        end
    end
end

local function skillEntry(sid)
    if not skillIndex then buildSkillIndex() end
    sid = tonumber(sid)
    if not sid then return nil end
    if skillIndex[sid] then return skillIndex[sid] end
    -- sub skills: 14051 -> 14050, 120301 -> 12030, 1310110 -> 131010 ...
    local s = sid
    for _ = 1, 3 do
        local base = math.floor(s / 10) * 10
        if skillIndex[base] then return skillIndex[base] end
        s = math.floor(s / 10)
        if skillIndex[s] then return skillIndex[s] end
        if skillIndex[s * 10] then return skillIndex[s * 10] end
    end
    return nil
end
S.SkillEntry = skillEntry

local nameCache, iconCache = {}, {}

function S.SkillName(sid)
    if nameCache[sid] then return nameCache[sid] end
    local e = skillEntry(sid)
    local name
    if e then
        if e.wowSpellId and Compat and Compat.GetSpellNameIcon then
            name = Compat.GetSpellNameIcon(e.wowSpellId)
        end
        name = name or e.nameKo or e.nameEn
    end
    if not name then
        local s = D.Skills[tonumber(sid) or 0]
        name = s and s.nameKo or tostring(sid)
    end
    nameCache[sid] = name
    return name
end

function S.SkillIcon(sid)
    if iconCache[sid] then return iconCache[sid] end
    local e = skillEntry(sid)
    local tex
    if e then
        if e.wowSpellId and Compat and Compat.GetSpellNameIcon then
            local _, ic = Compat.GetSpellNameIcon(e.wowSpellId)
            tex = ic
        end
        tex = tex or icon(e.icon)
    end
    tex = tex or "Interface\\Icons\\INV_Misc_QuestionMark"
    iconCache[sid] = tex
    return tex
end

-- attack animation by class weapon style
local ANIM_BY_CLASS = { WARRIOR = 18, PALADIN = 17, ROGUE = 17, HUNTER = 46, MAGE = 53, PRIEST = 53, WARLOCK = 53,
    SHAMAN = 53, DRUID = 16 }
function S.AttackAnim(job, isBasic)
    local sj = job and D.SkinJobs and D.SkinJobs[job.key]
    local a = sj and ANIM_BY_CLASS[sj.classToken or ""] or 17
    if not isBasic and (a == 17 or a == 18 or a == 16) then return 57 end -- Special1H for skills
    if not isBasic and a == 53 then return 54 end
    return a
end

---------------------------------------------------------------------------
-- World: chapters, monsters, bosses, backgrounds
---------------------------------------------------------------------------
local function chapter(ch)
    return D.SkinWorld and D.SkinWorld.chapters and D.SkinWorld.chapters[ch]
end

function S.ChapterName(ch)
    local c = chapter(ch)
    return c and c.zoneKo or nil
end

local function monsterEntry(ch, st, variant)
    local c = chapter(ch)
    if not c or not c.monsters or #c.monsters == 0 then return nil end
    local n = #c.monsters
    -- spread the zone's creatures over the stages, variants pick neighbours
    local idx = ((st - 1) + (variant or 1) - 1) % n + 1
    return c.monsters[idx]
end

function S.MonsterName(ch, st, variant)
    local m = monsterEntry(ch, st, variant)
    return m and (m.nameKo or m.nameEn) or "몬스터"
end

function S.MonsterModel(ch, st, variant, isBoss)
    local e
    if isBoss then
        local c = chapter(ch)
        e = c and c.boss
    end
    e = e or monsterEntry(ch, st, variant)
    if not e then return nil end
    return { displayId = e.displayId, npcId = e.npcId }
end

function S.BossName(ch)
    local c = chapter(ch)
    return c and c.boss and (c.boss.nameKo or c.boss.nameEn) or "보스"
end

function S.Background(hero, mode, battle)
    local ch = hero.campaign.chapter
    local ctl = battle and battle.opts.controller
    if ctl and ctl.background then return ctl.background end
    if ctl and ctl.ch then ch = ctl.ch end
    local c = chapter(ch)
    return c and c.loadingScreen or nil
end

function S.ContentModel(kind, key)
    local cont = D.SkinWorld and D.SkinWorld.content
    if not cont then return nil end
    local e = cont[kind]
    if key and type(e) == "table" then e = e[key] end
    if type(e) == "table" and e[1] then e = e[1] end
    if type(e) ~= "table" then return nil end
    return { displayId = e.displayId, npcId = e.npcId }, (e.nameKo or e.nameEn)
end

---------------------------------------------------------------------------
-- Gear looks: equipped gear grade per visible slot -> WoW item appearance ids
---------------------------------------------------------------------------
local LOOK_SLOTS = { "Cap", "Shoulder", "Clothes", "Pants", "Glove", "Belt", "Shoes", "Cape" }

function S.GearLooks(hero)
    local looks = {}
    local L = D.SkinLooks
    if not L then return looks end
    local job = ns.Hero.Job(hero)
    local sj = job and D.SkinJobs and D.SkinJobs[job.key]
    local class = sj and sj.classToken
    local eq = ns.Equipment and ns.Equipment.EquippedGrades and ns.Equipment.EquippedGrades(hero) or {}
    for _, slot in ipairs(LOOK_SLOTS) do
        local grade = eq[slot]
        if grade then
            local e
            if slot == "Cape" then
                e = L.cape and L.cape[grade]
            else
                e = L.armor and class and L.armor[class] and L.armor[class][slot] and L.armor[class][slot][grade]
            end
            if e and e.id then looks[#looks + 1] = e.id end
        end
    end
    -- weapon look from the equipped weapon grade
    local wgrade = ns.Weapons and ns.Weapons.EquippedGrade and ns.Weapons.EquippedGrade(hero)
    local wl = job and L.weapons and L.weapons[job.key]
    if wgrade and wl then
        local key = "Grade" .. wgrade
        local mh = wl.mainHand and wl.mainHand[key]
        local oh = wl.offHand and wl.offHand[key]
        if mh and mh.id then looks[#looks + 1] = mh.id end
        if oh and oh.id then looks[#looks + 1] = oh.id end
    end
    return looks
end
