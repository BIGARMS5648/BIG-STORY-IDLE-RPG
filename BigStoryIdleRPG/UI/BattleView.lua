-- Battle view: the player's own character (DressUpModel, wearing the addon gear
-- looks), creature models for monsters, floating damage, HP bars, skill cooldowns.
local ADDON, ns = ...
local W = ns.W
local U = ns.U

local BV = {}
ns.BattleView = BV

local MM_PER_PIXEL = 18          -- battle x (mm) -> screen pixels
local GROUND_Y = 150             -- ground line from the bottom of the view (the HUD sits below it)
local HERO_SCREEN_X = 0.34       -- hero anchor (fraction of width)
local MAX_MONSTER_MODELS = 14

-- WoW animation ids
local ANIM = { stand = 0, death = 1, walk = 4, run = 5, hit = 9, attack1H = 17, attack2H = 18,
    unarmed = 16, spellDirected = 53, spellOmni = 54, bow = 46, rifle = 49, ready = 26, dead = 6,
    jumpStart = 37, jump = 38, jumpEnd = 39, fall = 40 }

local FACE_RIGHT = math.rad(70)
local FACE_LEFT = math.rad(-70)

local function safe(fn, ...)
    local ok, r = pcall(fn, ...)
    if ok then return r end
end

---------------------------------------------------------------------------
-- Creation
---------------------------------------------------------------------------
function BV.Create(parent)
    local v = CreateFrame("Frame", nil, parent)
    v:SetAllPoints()
    v:SetClipsChildren(true)
    BV.frame = v

    v.bg = v:CreateTexture(nil, "BACKGROUND")
    v.bg:SetAllPoints()
    v.bg:SetColorTexture(0.08, 0.1, 0.12, 1)
    v.bgArt = v:CreateTexture(nil, "BACKGROUND", nil, 1)
    v.bgArt:SetAllPoints()
    v.bgArt:SetTexCoord(0, 1, 0.12, 0.82)
    v.bgArt:SetAlpha(0.85)
    -- platforms + ground (UI/BattleMap.lua)
    if ns.BattleMap then ns.BattleMap.Create(v, GROUND_Y, MM_PER_PIXEL) end

    -- hero model (player character wearing addon gear)
    local hero = CreateFrame("DressUpModel", nil, v)
    hero:SetSize(150, 196)
    hero:SetPoint("BOTTOM", v, "BOTTOMLEFT", 0, GROUND_Y - 20)
    BV.heroModel = hero
    BV.SetupHeroModel()

    -- monster model pool
    BV.mobs = {}
    for i = 1, MAX_MONSTER_MODELS do
        local m = CreateFrame("PlayerModel", nil, v)
        m:SetSize(110, 132)
        m:Hide()
        m.hp = W.Bar(m, 70, 5, 0.85, 0.15, 0.15)
        m.hp:SetPoint("BOTTOM", m, "TOP", 0, -18)
        m.hp.text:Hide()
        BV.mobs[i] = m
    end

    -- dressed character models: arena opponent + companions
    BV.allies = {}
    for i = 1, 5 do
        local m = CreateFrame("DressUpModel", nil, v)
        m:SetSize(150, 200)
        m:Hide()
        m.hp = W.Bar(m, 70, 5, 0.2, 0.8, 0.2)
        m.hp:SetPoint("BOTTOM", m, "TOP", 0, -18)
        m.hp.text:Hide()
        m.label = W.Text(m, 10, W.COLORS.white, "CENTER")
        m.label:SetPoint("BOTTOM", m.hp, "TOP", 0, 1)
        BV.allies[i] = m
    end

    -- boss bar (below the stage block of the HUD)
    v.bossBar = W.Bar(v, 440, 16, 0.85, 0.12, 0.12)
    v.bossBar:SetPoint("TOP", 0, -132)
    v.bossBar:Hide()
    v.bossName = W.Text(v.bossBar, 13, W.COLORS.gold, "CENTER")
    v.bossName:SetPoint("BOTTOM", v.bossBar, "TOP", 0, 2)

    -- floating combat text pool
    v.texts = {}
    v.textIndex = 0
    for i = 1, 40 do
        local t = W.Text(v, 14, W.COLORS.white, "CENTER")
        t:Hide()
        v.texts[i] = t
    end

    v:SetScript("OnUpdate", function(_, elapsed) BV.OnUpdate(elapsed) end)
    BV.HookGame()
    return v
end

---------------------------------------------------------------------------
-- Hero model + gear looks
---------------------------------------------------------------------------
function BV.SetupHeroModel()
    local m = BV.heroModel
    if not m then return end
    safe(m.SetUnit, m, "player")
    safe(m.SetFacing, m, FACE_RIGHT)
    safe(m.SetCamDistanceScale, m, 1.25)
    BV.ApplyLooks()
end

-- Equipped addon gear -> WoW item appearances (ns.Skin.GearLooks returns {itemId,...})
function BV.ApplyLooks()
    local m = BV.heroModel
    local hero = ns.Hero.Active()
    if not (m and hero and ns.Skin and ns.Skin.GearLooks) then return end
    local looks = ns.Skin.GearLooks(hero)
    if not looks or #looks == 0 then return end
    safe(m.Undress, m)
    for _, id in ipairs(looks) do
        if C_Item and C_Item.RequestLoadItemDataByID then safe(C_Item.RequestLoadItemDataByID, id) end
        safe(m.TryOn, m, "item:" .. id)
    end
end

ns.On("HERO_CHANGED", function(hero, what)
    if what == "equipment" or what == "weapon" or what == "looks" then
        if ns.Compat then ns.Compat.After(0.2, BV.ApplyLooks) else BV.ApplyLooks() end
    end
end)

-- item data arrives asynchronously the first time an id is used
if ns.RegisterEvent then
    ns.RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
        if BV.looksTimer then return end
        BV.looksTimer = true
        ns.Compat.After(0.5, function() BV.looksTimer = nil; BV.ApplyLooks() end)
    end)
end

---------------------------------------------------------------------------
-- Monster models
---------------------------------------------------------------------------
local function setCreatureModel(m, c)
    local model = c.def.model or {}
    if m.modelKey == (model.displayId or model.npcId or "none") then return end
    m.modelKey = model.displayId or model.npcId or "none"
    safe(m.ClearModel, m)
    local ok = false
    if model.displayId and m.SetDisplayInfo then ok = safe(m.SetDisplayInfo, m, model.displayId) ~= false end
    if (not ok or not model.displayId) and model.npcId and m.SetCreature then safe(m.SetCreature, m, model.npcId) end
    if not model.displayId and not model.npcId then
        safe(m.SetDisplayInfo, m, 4626) -- fallback look
    end
    safe(m.SetCamDistanceScale, m, c.isBoss and 1.6 or 1.2)
end

function BV.AssignModels(b)
    -- map creatures to pooled models by screen proximity
    local hero = b.heroCreature
    local used = {}
    local list = {}
    for _, c in ipairs(b.creatures) do
        if c.side == 2 and not c.isHero and (c.alive or (c.deathAt and b.time - c.deathAt < 900)) and not c.isServant then
            list[#list + 1] = c
        end
    end
    table.sort(list, function(a, c2) return math.abs(a.x - (hero and hero.x or 0)) < math.abs(c2.x - (hero and hero.x or 0)) end)
    for _, m in ipairs(BV.mobs) do m.inUse = false end
    for i, c in ipairs(list) do
        if i > MAX_MONSTER_MODELS then break end
        local m = c.viewModel
        if not m or m.owner ~= c then
            for _, cand in ipairs(BV.mobs) do
                if not cand.inUse and (cand.owner == nil or not cand.owner.alive or cand.owner.battle ~= b) then
                    m = cand
                    break
                end
            end
        end
        if m then
            m.inUse = true
            m.owner = c
            c.viewModel = m
            used[m] = true
        end
    end
    for _, m in ipairs(BV.mobs) do
        if not used[m] then
            m:Hide()
            if m.owner then m.owner.viewModel = nil end
            m.owner = nil
        end
    end
end

---------------------------------------------------------------------------
-- Character models for creatures that are "people" (arena opponent, companions)
---------------------------------------------------------------------------
local screenX   -- defined below (used by UpdatePeople before its definition)

local RACE_IDS = { Human = 1, Orc = 2, Dwarf = 3, NightElf = 4, Scourge = 5, Tauren = 6, Gnome = 7, Troll = 8 }
local CLASS_RACES = {
    WARRIOR = { 1, 2, 3, 4, 6, 8 }, PALADIN = { 1, 3 }, HUNTER = { 2, 3, 4, 6, 8 }, ROGUE = { 1, 2, 3, 4, 5, 7, 8 },
    PRIEST = { 1, 3, 4, 5, 8 }, SHAMAN = { 2, 6, 8 }, MAGE = { 1, 5, 7, 8 }, WARLOCK = { 1, 2, 5, 7 }, DRUID = { 4, 6 },
}

local function dressPerson(m, c)
    local key = c.id
    if m.dressedFor == key then return end
    m.dressedFor = key
    local race, sex, looks
    if c.def.arenaLooks then
        looks = c.def.arenaLooks
        race = RACE_IDS[c.def.arenaRace or ""] or 1
        sex = (c.def.arenaSex == 3) and 1 or 0
    else
        local info = c.def.companion or {}
        looks = ns.Skin and ns.Skin.CompanionLooks and ns.Skin.CompanionLooks(info) or {}
        local cls = ns.Skin and ns.Skin.JobClass and ns.Skin.JobClass(info.jobKey) or "WARRIOR"
        local opts = CLASS_RACES[cls] or { 1 }
        race = opts[((info.sid or 1) % #opts) + 1]
        sex = (info.sid or 0) % 2
    end
    if m.SetCustomRace then
        safe(m.SetCustomRace, m, race, sex)
    else
        safe(m.SetUnit, m, "player")
    end
    safe(m.Undress, m)
    for _, id in ipairs(looks or {}) do safe(m.TryOn, m, "item:" .. id) end
    safe(m.SetCamDistanceScale, m, 1.3)
end

function BV.UpdatePeople(b)
    local v = BV.frame
    local list = {}
    for _, c in ipairs(b.creatures) do
        if c.alive and ((c.side == 2 and c.isHero) or c.isSupporter) then list[#list + 1] = c end
    end
    for i, m in ipairs(BV.allies) do
        local c = list[i]
        if c then
            local x = screenX(c, b)
            dressPerson(m, c)
            m:ClearAllPoints()
            m:SetPoint("BOTTOM", v, "BOTTOMLEFT", x, GROUND_Y - 20)
            safe(m.SetFacing, m, c.facing > 0 and FACE_RIGHT or FACE_LEFT)
            m.hp:SetValue(c.hp / math.max(1, c:Stat("MaxHp")))
            m.label:SetText(c.name or "")
            if c.isSupporter then m:SetSize(120, 160) else m:SetSize(170, 220) end
            if not m:IsShown() then m:Show(); safe(m.SetAnimation, m, ANIM.ready) end
            if c.castUntil and c.castUntil > b.time and m.lastCast ~= c.castUntil then
                m.lastCast = c.castUntil
                safe(m.SetAnimation, m, ns.Skin and ns.Skin.AttackAnim and ns.Skin.AttackAnim(c.job, true) or ANIM.attack1H)
            end
        else
            m:Hide()
            m.dressedFor = nil
        end
    end
end

---------------------------------------------------------------------------
-- Floating combat text
---------------------------------------------------------------------------
function BV.FloatText(x, y, text, r, g, b, size)
    local v = BV.frame
    if not v or not v:IsVisible() then return end
    v.textIndex = v.textIndex % #v.texts + 1
    local t = v.texts[v.textIndex]
    local font = t:GetFont()
    t:SetFont(font, size or 14, "OUTLINE")
    t:SetText(text)
    t:SetTextColor(r, g, b)
    t:ClearAllPoints()
    t:SetPoint("CENTER", v, "BOTTOMLEFT", x + math.random(-12, 12), y)
    t.x, t.y, t.life = x, y, 1.0
    t:SetAlpha(1)
    t:Show()
end

function screenX(c, b)
    local v = BV.frame
    local hero = b.heroCreature
    local anchor = v:GetWidth() * HERO_SCREEN_X
    return anchor + (c.x - (hero and hero.x or 0)) / MM_PER_PIXEL
end

---------------------------------------------------------------------------
-- Game hooks
---------------------------------------------------------------------------
function BV.HookGame()
    local H = ns.Game.uiHooks
    H.onDamage = function(b, att, tgt, amount, crit, info)
        if not (ns.db.settings.showDamageText and BV.frame and BV.frame:IsVisible()) then return end
        local x = screenX(tgt, b)
        local y = GROUND_Y + (tgt.isHero and 150 or 120) + (tgt.mapY or 0)
        if tgt.isHero then
            BV.FloatText(x, y, "-" .. U.FormatNumber(amount), 1, 0.25, 0.25, 13)
        elseif crit then
            BV.FloatText(x, y + 10, U.FormatNumber(amount), 1, 0.55, 0.1, 18)
        else
            BV.FloatText(x, y, U.FormatNumber(amount), 1, 0.95, 0.5, 14)
        end
        if tgt.viewModel and not tgt.isBoss then safe(tgt.viewModel.SetAnimation, tgt.viewModel, ANIM.hit) end
    end
    H.onMiss = function(b, att, tgt)
        if not (BV.frame and BV.frame:IsVisible()) then return end
        BV.FloatText(screenX(tgt, b), GROUND_Y + 120 + (tgt.mapY or 0), "MISS", 0.7, 0.7, 0.7, 12)
    end
    H.onDeath = function(b, c)
        c.deathAt = b.time
        if c.viewModel then safe(c.viewModel.SetAnimation, c.viewModel, ANIM.death) end
        if c.isHero and BV.heroModel then safe(BV.heroModel.SetAnimation, BV.heroModel, ANIM.death) end
    end
    H.onRevive = function(b, c)
        if c.isHero and BV.heroModel then safe(BV.heroModel.SetAnimation, BV.heroModel, ANIM.stand) end
    end
    H.onCast = function(b, c, sid, isBasic)
        if c.isHero and BV.heroModel and BV.frame and BV.frame:IsVisible() then
            local anim = ns.Skin and ns.Skin.AttackAnim and ns.Skin.AttackAnim(c.job, isBasic) or ANIM.attack1H
            safe(BV.heroModel.SetAnimation, BV.heroModel, anim)
            BV.heroAnimUntil = GetTime and (GetTime() + 0.6) or 0
            if not isBasic then
                local name = ns.Skin and ns.Skin.SkillName and ns.Skin.SkillName(sid) or ""
                BV.FloatText(screenX(c, b), GROUND_Y + 200 + (c.mapY or 0), name, 0.6, 0.85, 1, 13)
                -- real spell effect on the nearest enemy in front
                local best, bd
                for _, t in ipairs(b.creatures) do
                    if t.alive and t.side ~= c.side then
                        local d = math.abs(t.x - c.x)
                        if not bd or d < bd then best, bd = t, d end
                    end
                end
                if best and ns.BattleMap then
                    local hx = screenX(c, b)
                    ns.BattleMap.CastEffect(b, c, sid, screenX(best, b), GROUND_Y + 70 + (best.mapY or 0),
                        hx + (c.facing or 1) * 30, GROUND_Y + 90 + (c.mapY or 0))
                end
            end
        end
    end
    H.onEnd = function(b, reason)
        local msg = ({ clear = "|cff40ff40클리어!|r", fail = "|cffff4040실패|r", timeout = "|cffff8040시간 초과|r" })[reason]
        if msg and BV.frame and BV.frame:IsVisible() then
            BV.FloatText(BV.frame:GetWidth() / 2, BV.frame:GetHeight() / 2, msg, 1, 1, 1, 24)
        end
    end
end

ns.On("BATTLE_STARTED", function(b, mode)
    BV.lastBattle = b
    if not BV.frame then return end
    for _, m in ipairs(BV.mobs) do m:Hide(); m.owner = nil end
    local hero = ns.Hero.Active()
    if hero and ns.BattleMap then
        local ctl = b.opts and b.opts.controller
        local ch, st = hero.campaign.chapter, hero.campaign.stage
        if ctl and ctl.ch then ch, st = ctl.ch, ctl.st or st end
        if mode ~= "hunt" and mode ~= "challenge" and mode ~= "boss" then
            st = U.HashString and (U.HashString(tostring(ctl and (ctl.modeKey or ctl.kind) or mode)) % 20 + 1) or 1
        end
        ns.BattleMap.SetStage(ch, st, mode)
    end
    if hero and ns.Skin and ns.Skin.Background then
        local tex = ns.Skin.Background(hero, mode, b)
        if tex then BV.frame.bgArt:SetTexture(tex); BV.frame.bgArt:Show() else BV.frame.bgArt:Hide() end
    end
end)

---------------------------------------------------------------------------
-- Per-frame update
---------------------------------------------------------------------------
local refreshAcc = 0

function BV.OnUpdate(elapsed)
    local v = BV.frame
    local b = ns.Game.battle
    if not (v and b) then return end
    local hero = b.heroCreature
    local width = v:GetWidth()

    -- map (platforms scroll with the hero) and a slow parallax on the zone art
    if hero and ns.BattleMap then ns.BattleMap.Update(b, hero.x, width * HERO_SCREEN_X) end
    if hero and v.bgArt:IsShown() then
        local px = (hero.x / 600000) % 0.2
        v.bgArt:SetTexCoord(px, px + 0.8, 0.1, 0.8)
    end
    -- hero
    if hero then
        local hx = width * HERO_SCREEN_X
        local hy, air = 0, "ground"
        if ns.BattleMap then hy, air = ns.BattleMap.UpdateHero(b, hero, elapsed) end
        BV.heroModel:ClearAllPoints()
        BV.heroModel:SetPoint("BOTTOM", v, "BOTTOMLEFT", hx, GROUND_Y - 20 + hy)
        local now = GetTime and GetTime() or 0
        if air ~= "ground" then BV.landedAt = now end
        if hero.alive and (not BV.heroAnimUntil or now > BV.heroAnimUntil) then
            local moving = hero.lastX and math.abs(hero.x - hero.lastX) > 1
            local anim = moving and ANIM.run or ANIM.ready
            if air == "up" then anim = ANIM.jump
            elseif air == "down" then anim = ANIM.fall
            elseif BV.landedAt and now - BV.landedAt < 0.15 then anim = ANIM.jumpEnd end
            if BV.heroAnim ~= anim then
                safe(BV.heroModel.SetAnimation, BV.heroModel, anim)
                BV.heroAnim = anim
            end
        else
            BV.heroAnim = nil
        end
        hero.lastX = hero.x
        safe(BV.heroModel.SetFacing, BV.heroModel, hero.facing > 0 and FACE_RIGHT or FACE_LEFT)
    end

    -- monsters and people
    BV.AssignModels(b)
    BV.UpdatePeople(b)
    local boss
    for _, m in ipairs(BV.mobs) do
        local c = m.owner
        if c and m.inUse then
            local x = screenX(c, b)
            if x < -80 or x > width + 80 then
                m:Hide()
            else
                setCreatureModel(m, c)
                m:ClearAllPoints()
                local yOff = ns.BattleMap and ns.BattleMap.OffsetFor(c) or 0
                m:SetPoint("BOTTOM", v, "BOTTOMLEFT", x, GROUND_Y - 18 + yOff)
                if not m:IsShown() then
                    m:Show()
                    safe(m.SetAnimation, m, ANIM.stand)
                end
                safe(m.SetFacing, m, c.facing > 0 and FACE_RIGHT or FACE_LEFT)
                m.hp:SetValue(c.hp / math.max(1, c:Stat("MaxHp")))
                m.hp:SetShown(c.alive and not c.isBoss)
                if c.isBoss then m:SetSize(190, 230) else m:SetSize(110, 132) end
            end
            if c.isBoss and c.alive then boss = c end
        end
    end
    if boss then
        v.bossBar:Show()
        v.bossBar:SetValue(boss.hp / math.max(1, boss:Stat("MaxHp")))
        v.bossBar.text:SetText(U.FormatNumber(math.max(0, boss.hp)) .. " / " .. U.FormatNumber(boss:Stat("MaxHp")))
        v.bossName:SetText(boss.name)
    else
        v.bossBar:Hide()
    end

    -- floating text
    for _, t in ipairs(v.texts) do
        if t:IsShown() then
            t.life = t.life - elapsed
            t.y = t.y + elapsed * 40
            t:ClearAllPoints()
            t:SetPoint("CENTER", v, "BOTTOMLEFT", t.x, t.y)
            t:SetAlpha(math.max(0, math.min(1, t.life * 1.5)))
            if t.life <= 0 then t:Hide() end
        end
    end

    -- labels / timer / skills (4x per second)
    refreshAcc = refreshAcc + elapsed
    if refreshAcc > 0.25 then
        refreshAcc = 0
        BV.RefreshLabels(b)
    end
end

function BV.RefreshLabels(b)
    if ns.UI and ns.UI.RefreshLive then ns.UI.RefreshLive() end
end
