-- Battle map (메이플 키우기-style side view): several floating platforms at different heights over a
-- ground strip, laid out per chapter / stage (deterministic seed) and themed with the chapter's WoW
-- zone terrain textures (Data/MapThemes.lua). Monsters stand on a platform above their position or on
-- the ground, and drop to the ground when they walk off an edge. The layout repeats every MAP_LEN mm so
-- the endless hunt keeps scrolling.
-- Skill effects: real WoW spell effect models (Data/SkillEffects.lua) played as missile / impact /
-- area on the targets when the hero casts.
--
-- API (used by UI/BattleView.lua)
--   BM.Create(view, groundY, mmPerPixel)   BM.SetStage(ch, st, mode)
--   BM.Update(b, heroX, anchorPx)          BM.OffsetFor(c) -> pixels above the ground
--   BM.UpdateHero(b, hero, dt) -> hero height (px), "ground" | "up" | "down"   BM.ResetHero()
--   BM.CastEffect(b, caster, sid, toX, toY, fromX, fromY)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data

local BM = {}
ns.BattleMap = BM

local MAP_LEN = 36000
local LEVEL_PX = { [0] = 0, 150, 250, 250 }
local THICK = 30          -- platform body thickness (px)
local TOP = 12            -- surface strip (px)
local MAX_PLATFORMS = 18
local MAX_EFFECTS = 14
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function safe(fn, ...) if fn then local ok, r = pcall(fn, ...); if ok then return r end end end

---------------------------------------------------------------------------
-- layout
---------------------------------------------------------------------------
function BM.Generate(ch, st, mode)
    local theme = D.MapThemes and D.MapThemes[ch] or { style = "field", top = { 0.4, 0.55, 0.2 }, bodyColor = { 0.3, 0.27, 0.24 } }
    local rng = U.NewRNG(ch * 1009 + st * 37 + (mode == "hunt" and 0 or 7))
    local list = {}
    local style = theme.style
    local maxLevel = 2
    local x = 900
    local last = 0
    while x < MAP_LEN - 2500 do
        local w = style == "raid" and rng:Int(7000, 12000) or (style == "dungeon" and rng:Int(5000, 9500) or rng:Int(3000, 7200))
        local level = rng:Int(1, maxLevel)
        if level == last and rng:Int(1, 3) > 1 then level = level % maxLevel + 1 end
        list[#list + 1] = { x0 = x, x1 = x + w, level = level }
        -- sometimes a second platform stacked above the first (maps with several floors)
        if style == "field" and level < maxLevel and rng:Int(1, 100) <= 40 then
            local w2 = math.floor(w * (0.45 + rng:Int(0, 30) / 100))
            local off = rng:Int(0, w - w2)
            list[#list + 1] = { x0 = x + off, x1 = x + off + w2, level = level + 1 }
        end
        last = level
        x = x + w + (style == "raid" and rng:Int(2500, 5000) or rng:Int(700, 2600))
    end
    return { theme = theme, platforms = list, len = MAP_LEN }
end

---------------------------------------------------------------------------
-- textures
---------------------------------------------------------------------------
local function tiled(tex, fileId, w, h, tile)
    tile = tile or 64
    if fileId then
        tex:SetTexture(fileId, "REPEAT", "REPEAT")
        tex:SetTexCoord(0, math.max(1, w / tile), 0, math.max(0.2, h / tile))
        tex:SetVertexColor(1, 1, 1, 1)
        return true
    end
    tex:SetTexture(nil)
    return false
end

local function newPlatform(parent)
    local p = CreateFrame("Frame", nil, parent)
    p.shadow = p:CreateTexture(nil, "BACKGROUND")
    p.shadow:SetTexture(WHITE)
    p.shadow:SetVertexColor(0, 0, 0, 0.35)
    p.shadow:SetPoint("TOPLEFT", 6, -8)
    p.shadow:SetPoint("BOTTOMRIGHT", 4, -6)
    p.base = p:CreateTexture(nil, "BORDER")
    p.base:SetTexture(WHITE)
    p.base:SetAllPoints()
    p.body = p:CreateTexture(nil, "ARTWORK")
    p.body:SetPoint("TOPLEFT", 0, -TOP + 2)
    p.body:SetPoint("BOTTOMRIGHT")
    p.topBase = p:CreateTexture(nil, "ARTWORK", nil, 1)
    p.topBase:SetTexture(WHITE)
    p.topBase:SetPoint("TOPLEFT")
    p.topBase:SetPoint("TOPRIGHT")
    p.topBase:SetHeight(TOP)
    p.top = p:CreateTexture(nil, "ARTWORK", nil, 2)
    p.top:SetPoint("TOPLEFT")
    p.top:SetPoint("TOPRIGHT")
    p.top:SetHeight(TOP)
    p.rim = p:CreateTexture(nil, "OVERLAY")
    p.rim:SetTexture(WHITE)
    p.rim:SetPoint("TOPLEFT")
    p.rim:SetPoint("TOPRIGHT")
    p.rim:SetHeight(2)
    p.under = p:CreateTexture(nil, "OVERLAY")
    p.under:SetTexture(WHITE)
    p.under:SetPoint("BOTTOMLEFT")
    p.under:SetPoint("BOTTOMRIGHT")
    p.under:SetHeight(5)
    p.under:SetVertexColor(0, 0, 0, 0.45)
    p:Hide()
    return p
end

local function paint(p, theme, w, h)
    local bc, tc = theme.bodyColor, theme.top
    p.base:SetVertexColor(bc[1], bc[2], bc[3], 1)
    p.topBase:SetVertexColor(tc[1], tc[2], tc[3], 1)
    p.rim:SetVertexColor(math.min(1, tc[1] + 0.25), math.min(1, tc[2] + 0.25), math.min(1, tc[3] + 0.25), 0.7)
    if tiled(p.body, theme.body, w, h - TOP) then p.body:SetVertexColor(0.85, 0.85, 0.85, 1) end
    tiled(p.top, theme.surface, w, TOP, 48)
end

function BM.Create(view, groundY, mmPerPixel)
    BM.view, BM.groundY, BM.mm = view, groundY, mmPerPixel
    local layer = CreateFrame("Frame", nil, view)
    layer:SetAllPoints()
    layer:SetFrameLevel(view:GetFrameLevel() + 1)
    BM.layer = layer
    -- ground strip
    local g = newPlatform(layer)
    g:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    g:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    g:SetHeight(groundY)
    g.shadow:Hide()
    g.under:Hide()
    g:Show()
    BM.ground = g
    BM.pool = {}
    for i = 1, MAX_PLATFORMS do BM.pool[i] = newPlatform(layer) end
    -- effect model pool (spell effects); above the creature models
    local fx = CreateFrame("Frame", nil, view)
    fx:SetAllPoints()
    fx:SetFrameLevel(view:GetFrameLevel() + 30)
    BM.fxLayer = fx
    BM.fx = {}
    for i = 1, MAX_EFFECTS do
        local m = CreateFrame("PlayerModel", nil, fx)
        m:SetSize(160, 160)
        m:Hide()
        BM.fx[i] = m
    end
    BM.fxIndex = 0
end

function BM.SetStage(ch, st, mode)
    if not BM.layer then return end
    BM.map = BM.Generate(ch or 1, st or 1, mode or "hunt")
    local theme = BM.map.theme
    local w = BM.view and BM.view:GetWidth() or 1100
    paint(BM.ground, theme, w, BM.groundY)
    for _, p in ipairs(BM.pool) do p.painted = nil; p:Hide() end
    BM.ResetHero()
end

---------------------------------------------------------------------------
-- per frame
---------------------------------------------------------------------------
local function screenX(worldX, heroX, anchorPx)
    return anchorPx + (worldX - heroX) / BM.mm
end

function BM.Update(b, heroX, anchorPx)
    local map = BM.map
    if not (map and BM.layer) then return end
    local width = BM.view:GetWidth()
    local viewL = heroX - anchorPx * BM.mm
    local viewR = viewL + width * BM.mm
    local used = 0
    local k0 = math.floor(viewL / map.len)
    for k = k0, k0 + 2 do
        for _, pl in ipairs(map.platforms) do
            local x0, x1 = k * map.len + pl.x0, k * map.len + pl.x1
            if x1 > viewL - 500 and x0 < viewR + 500 and used < MAX_PLATFORMS then
                used = used + 1
                local f = BM.pool[used]
                local pw = (x1 - x0) / BM.mm
                if f.painted ~= pl then paint(f, map.theme, pw, THICK); f.painted = pl end
                f:ClearAllPoints()
                f:SetSize(pw, THICK)
                f:SetPoint("TOPLEFT", BM.view, "BOTTOMLEFT", screenX(x0, heroX, anchorPx), BM.groundY + LEVEL_PX[pl.level])
                f:Show()
            end
        end
    end
    for i = used + 1, MAX_PLATFORMS do BM.pool[i]:Hide() end
    BM.UpdateEffects(b and b.time)
end

-- pixels above the ground for a creature (platform it stands on), sticky until it walks off
function BM.OffsetFor(c)
    local map = BM.map
    if not map or c.side ~= 2 or c.isBoss then return 0 end
    local plat = c.mapPlat
    if plat == nil then
        local k = math.floor(c.x / map.len)
        local lx = c.x - k * map.len
        local cands = {}
        for _, pl in ipairs(map.platforms) do
            if lx >= pl.x0 + 300 and lx <= pl.x1 - 300 then cands[#cands + 1] = pl end
        end
        local pick = ((c.id or 1) * 7919) % (#cands + 1)
        if pick == 0 then
            c.mapPlat = false
        else
            local pl = cands[pick]
            c.mapPlat = { x0 = k * map.len + pl.x0, x1 = k * map.len + pl.x1, level = pl.level }
        end
        plat = c.mapPlat
        c.mapY = plat and LEVEL_PX[plat.level] or 0
    end
    local target = 0
    if plat and c.x >= plat.x0 and c.x <= plat.x1 then
        target = LEVEL_PX[plat.level]
    elseif plat then
        c.mapPlat = false   -- walked off the edge: falls to the ground
    end
    c.mapY = c.mapY or target
    if c.mapY > target then c.mapY = math.max(target, c.mapY - 14) else c.mapY = target end
    return c.mapY
end

---------------------------------------------------------------------------
-- hero jumping (visual only: the battle engine moves along x, the map decides the height)
-- The hero jumps up onto the platform its target stands on, drops through a platform to reach a
-- target below (one-way platforms) and falls when it runs off an edge.
---------------------------------------------------------------------------
local GRAVITY = 1500      -- px / s^2
local EDGE = 450          -- mm of overhang still counted as standing on a platform
local DROP_VY = 160
local NEAR = 4000         -- mm: enemies this close make the hero drop through instead of running on

-- platforms (world coordinates) that contain world x
local function platformsAt(x, ext)
    local map = BM.map
    local out = {}
    if not map then return out end
    local k = math.floor(x / map.len)
    for kk = k - 1, k + 1 do
        for _, pl in ipairs(map.platforms) do
            local x0, x1 = kk * map.len + pl.x0, kk * map.len + pl.x1
            if x >= x0 - ext and x <= x1 + ext then
                out[#out + 1] = { x0 = x0, x1 = x1, level = pl.level, src = pl }
            end
        end
    end
    return out
end

local function samePlat(a, b) return a and b and a.src == b.src and a.x0 == b.x0 end

function BM.ResetHero()
    BM.jump = { y = 0, vy = 0, grounded = true }
end

-- returns the hero's height above the ground (px) and its state: "ground" | "up" | "down"
function BM.UpdateHero(b, hero, dt)
    local J = BM.jump
    if not J then BM.ResetHero(); J = BM.jump end
    if not (BM.map and hero) or not hero.alive then
        J.y, J.vy, J.grounded, J.plat, J.landOn, J.through = 0, 0, true, nil, nil, nil
        return 0, "ground"
    end
    dt = math.min(dt or 0, 0.1)
    -- where the hero wants to be: the platform of the enemy it is heading for
    local target, bd
    for _, o in ipairs(b.creatures or {}) do
        if o.alive and o.side ~= hero.side then
            local d = math.abs(o.x - hero.x)
            if not bd or d < bd then target, bd = o, d end
        end
    end
    local want = nil
    if target and type(target.mapPlat) == "table" and (target.mapY or 0) > 0 then want = target.mapPlat end
    local wantY = want and LEVEL_PX[want.level] or 0

    if J.grounded then
        -- ran off the edge of the platform
        if J.plat and (hero.x < J.plat.x0 - EDGE or hero.x > J.plat.x1 + EDGE) then
            J.grounded, J.vy, J.through = false, 0, J.plat
            J.plat = nil
        elseif want and wantY > J.y + 1 and hero.x >= want.x0 - EDGE and hero.x <= want.x1 + EDGE then
            -- jump up (a little higher than needed so the arc reads)
            J.grounded = false
            J.vy = math.sqrt(2 * GRAVITY * (wantY - J.y + 45))
            J.landOn, J.through = want, nil
        elseif J.y > 0 and bd and bd < NEAR and (not want or wantY < J.y - 1)
            and (not want or (hero.x >= want.x0 - EDGE and hero.x <= want.x1 + EDGE)) then
            -- the next enemy is right below: drop down through the platform (otherwise keep running
            -- and fall off the edge)
            J.grounded, J.vy, J.through, J.landOn = false, DROP_VY, J.plat, want
            J.plat = nil
        end
    end
    -- integrate in small steps so the arc never skips over a platform surface
    local left = J.grounded and 0 or dt
    while left > 0 and not J.grounded do
        local h = math.min(left, 1 / 60)
        left = left - h
        local prev = J.y
        J.vy = J.vy - GRAVITY * h
        J.y = J.y + J.vy * h
        if J.vy <= 0 then
            -- one-way platforms: land on the first one crossed on the way down
            local landed
            for _, pl in ipairs(platformsAt(hero.x, EDGE)) do
                local ph = LEVEL_PX[pl.level]
                if prev >= ph and J.y <= ph and not samePlat(pl, J.through) then
                    -- while dropping toward a lower target skip the platforms above it
                    if not (J.landOn and ph > LEVEL_PX[J.landOn.level]) and not (J.landOn == nil and J.through) then
                        if not landed or ph > LEVEL_PX[landed.level] then landed = pl end
                    end
                end
            end
            if landed then
                J.y, J.vy, J.grounded, J.plat = LEVEL_PX[landed.level], 0, true, landed
                J.landOn, J.through = nil, nil
            elseif J.y <= 0 then
                J.y, J.vy, J.grounded, J.plat = 0, 0, true, nil
                J.landOn, J.through = nil, nil
            end
        end
    end
    hero.mapY = J.y
    if J.grounded then return J.y, "ground" end
    return J.y, J.vy > 0 and "up" or "down"
end

---------------------------------------------------------------------------
-- skill effects
---------------------------------------------------------------------------
local effectCache = {}
function BM.EffectsFor(sid, job)
    local key = tostring(sid) .. (job and job.key or "")
    if effectCache[key] ~= nil then return effectCache[key] end
    local entry = ns.Skin and ns.Skin.SkillEntry and ns.Skin.SkillEntry(sid)
    local name = entry and entry.nameEn and entry.nameEn:lower() or ""
    local set
    for _, r in ipairs(D.EffectRules or {}) do
        if name ~= "" and name:find(r[1], 1, true) then set = { r[2], r[3], r[4] } break end
    end
    if not set then
        local cls = ns.Skin and ns.Skin.JobClass and job and ns.Skin.JobClass(job.key)
        local d = cls and D.EffectClassDefault and D.EffectClassDefault[cls]
        set = d and { d[1], d[2], d[3] } or false
    end
    effectCache[key] = set
    return set
end

local function play(fileName, x, y, size, life, toX, toY, travel)
    local id = D.EffectModels and D.EffectModels[fileName]
    if not (id and BM.fx) then return end
    BM.fxIndex = BM.fxIndex % #BM.fx + 1
    local m = BM.fx[BM.fxIndex]
    m:SetSize(size, size)
    safe(m.ClearModel, m)
    safe(m.SetModel, m, id)
    safe(m.SetPortraitZoom, m, 0)
    safe(m.SetCamDistanceScale, m, 1.6)
    m.x, m.y, m.toX, m.toY = x, y, toX, toY
    m.life, m.total, m.travel = life, life, travel
    m:ClearAllPoints()
    m:SetPoint("CENTER", BM.view, "BOTTOMLEFT", x, y)
    m:Show()
    return m
end

-- caster cast skill sid at (toX, toY); screen coordinates from the battle view
function BM.CastEffect(b, caster, sid, toX, toY, fromX, fromY)
    if not (ns.db and ns.db.settings.showEffects ~= false) then return end
    local set = BM.EffectsFor(sid, caster and caster.job)
    if not set then return end
    local missile, impact, area = set[1], set[2], set[3]
    if missile and fromX then
        local m = play(missile, fromX, fromY, 120, 0.35, toX, toY, true)
        if m then m.onArrive = impact and function() play(impact, toX, toY, 150, 0.9) end end
    elseif impact then
        play(impact, toX, toY, 150, 0.9)
    end
    if area then play(area, toX, toY - 30, 260, 1.2) end
end

function BM.UpdateEffects()
    if not BM.fx then return end
    local now = GetTime and GetTime() or 0
    local dt = BM.lastFx and math.min(0.2, now - BM.lastFx) or 0
    BM.lastFx = now
    for _, m in ipairs(BM.fx) do
        if m:IsShown() and m.life then
            m.life = m.life - dt
            if m.travel and m.toX then
                local k = 1 - math.max(0, m.life) / m.total
                m:ClearAllPoints()
                m:SetPoint("CENTER", BM.view, "BOTTOMLEFT", m.x + (m.toX - m.x) * k, m.y + (m.toY - m.y) * k)
            end
            if m.life <= 0 then
                m:Hide()
                m.life = nil
                if m.onArrive then local f = m.onArrive; m.onArrive = nil; f() end
            end
        end
    end
end
