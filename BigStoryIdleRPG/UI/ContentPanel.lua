-- "던전/보스" tab: every content mode registered with ns.Content.RegisterMode (growth dungeons, quick hunt,
-- burning field, world boss, 마왕 발록, boss raids, party quests, monster park).
-- Left: mode list grouped by category. Right: info lines, stage / difficulty selectors, action buttons,
-- last result + rewards.
local ADDON, ns = ...
local W = ns.W
local U = ns.U
local UI = ns.UI
local C = ns.Content

local MAX_SELECTORS = 3
local MAX_ACTIONS = 4

local function modeSel(p, def, hero)
    p.sels = p.sels or {}
    local sel = p.sels[def.key]
    if not sel then
        sel = {}
        for _, s in ipairs(def.selectors or {}) do
            if s.options then
                sel["_" .. s.key] = 1
                sel[s.key] = s.values and s.values[1] or 1
            else
                sel[s.key] = s.default and s.default(hero) or s.min or 1
            end
        end
        p.sels[def.key] = sel
    end
    -- clamp numeric selectors to the current range
    for _, s in ipairs(def.selectors or {}) do
        if not s.options then
            local hi = s.max and s.max(hero) or sel[s.key]
            sel[s.key] = U.clamp(sel[s.key] or 1, s.min or 1, math.max(s.min or 1, hi))
        end
    end
    return sel
end

local function step(p, def, s, delta, big)
    local hero = ns.Hero.Active()
    if not hero then return end
    local sel = modeSel(p, def, hero)
    if s.options then
        local n = #s.options
        local i = ((sel["_" .. s.key] or 1) - 1 + delta) % n + 1
        sel["_" .. s.key] = i
        sel[s.key] = s.values and s.values[i] or i
        if s.values and s.values[i] == false then sel[s.key] = false end
    else
        local hi = s.max and s.max(hero) or 1
        local v = (sel[s.key] or 1) + delta * (big and 10 or 1)
        sel[s.key] = U.clamp(v, s.min or 1, math.max(s.min or 1, hi))
    end
    UI.RefreshPanel()
end

local function resultText(res)
    if not res then return "" end
    local color = res.ok and "|cff40ff40" or "|cffff6060"
    local lines = {}
    for i, l in ipairs(res.lines or {}) do
        lines[#lines + 1] = (i == 1) and (color .. l .. "|r") or l
    end
    local ago = res.at and (U.Now() - res.at) or 0
    return string.format("|cffffd100최근 결과|r |cff888888(%s 전)|r\n%s", U.FormatDuration(ago), table.concat(lines, "\n"))
end

local IC = "Interface\\Icons\\"
local GROWTH_SKIN = { weapon = "weapon", exp = "exp", gear = "gear", training = "heroTraining", enhance = "enhancement" }
local function modeIcon(key)
    if key == "quickHunt" then return IC .. "INV_Misc_PocketWatch_01" end
    if key == "burning" then return IC .. "Spell_Fire_Immolation" end
    if key == "worldBoss" then return IC .. "INV_Misc_Head_Dragon_01" end
    if key == "balrog" then return IC .. "Spell_Shadow_SummonInfernal" end
    if key == "monsterPark" then return IC .. "Ability_Racial_BloodRage" end
    if key == "jobAdvance" then return IC .. "Spell_Holy_SealOfWisdom" end
    if key:find("^growth_") then return IC .. "INV_Misc_Key_0" .. (({ weapon = 3, exp = 4, gear = 5, training = 6, enhance = 7 })[key:sub(8)] or 3) end
    if key:find("^raid_") then return IC .. "INV_Misc_Head_Dragon_Black" end
    if key:find("^pq_") then return IC .. "Ability_Warrior_RallyingCry" end
    return IC .. "INV_Misc_QuestionMark"
end
local function modeLook(key)
    local ok, model, name, bg
    if key == "worldBoss" then ok, model, name, bg = pcall(C.Look, "worldBoss")
    elseif key:find("^raid_") then ok, model, name, bg = pcall(C.Look, "raids", key:sub(6))
    elseif key:find("^growth_") then ok, model, name, bg = pcall(C.Look, "dungeons", GROWTH_SKIN[key:sub(8)])
    elseif key == "balrog" then ok, model, name, bg = pcall(C.Look, "balrog") end
    if ok then return model, bg end
end

local function safe(fn, ...) if fn then local ok, r = pcall(fn, ...); if ok then return r end end end

local function groups()
    local list, seen = {}, {}
    for _, def in ipairs(C.Modes()) do
        if not seen[def.group] then seen[def.group] = true; list[#list + 1] = def.group end
    end
    return list
end

UI.RegisterPanel("content", {
    title = "던전/보스", order = 40,
    build = function(p)
        p.groupNames = groups()
        p.group = 1
        p.tabs = W.Tabs(p, p.groupNames, 104, 26, function(i)
            p.group = i
            p.current = nil
            UI.RefreshPanel()
        end)
        p.tabs:SetPoint("TOPLEFT", 0, 0)

        p.cards = {}
        for i = 1, 6 do
            local c = CreateFrame("Button", nil, p, BackdropTemplateMixin and "BackdropTemplate" or nil)
            c:SetSize(318, 56)
            c:SetPoint("TOPLEFT", 0, -34 - (i - 1) * 61)
            W.Backdrop(c, { 0.1, 0.08, 0.07, 0.95 }, { 0.42, 0.33, 0.22, 1 }, 10)
            c.icon = W.Icon(c, 44)
            c.icon:SetPoint("LEFT", 6, 0)
            c.icon:EnableMouse(false)
            c.title = W.Text(c, 14, W.COLORS.white, "LEFT")
            c.title:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 10, -4)
            c.title:SetWidth(250)
            c.sub = W.Text(c, 11, W.COLORS.gray, "LEFT")
            c.sub:SetPoint("BOTTOMLEFT", c.icon, "BOTTOMRIGHT", 10, 4)
            c.sub:SetWidth(250)
            c.glow = c:CreateTexture(nil, "OVERLAY")
            c.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            c.glow:SetBlendMode("ADD")
            c.glow:SetPoint("TOPLEFT", 3, -3)
            c.glow:SetPoint("BOTTOMRIGHT", -3, 3)
            c.glow:SetAlpha(0.35)
            c:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            c:SetScript("OnClick", function(self) if self.key then p.current = self.key; UI.RefreshPanel() end end)
            p.cards[i] = c
        end
        p.pageText = W.Text(p, 11, W.COLORS.gray, "CENTER")
        p.pageText:SetPoint("TOPLEFT", 0, -404 + 14)
        p.pageText:SetWidth(318)

        -- detail card
        local box = W.InfoCard(p, 636, 372, { plain = true })
        box:SetPoint("TOPLEFT", 326, -34)
        p.box = box
        box.art = box:CreateTexture(nil, "ARTWORK")
        box.art:SetPoint("TOPLEFT", 12, -12)
        box.art:SetPoint("TOPRIGHT", -12, -12)
        box.art:SetHeight(112)
        box.art:SetTexCoord(0, 1, 0.3, 0.62)
        box.shade = box:CreateTexture(nil, "ARTWORK", nil, 1)
        box.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        box.shade:SetAllPoints(box.art)
        box.shade:SetVertexColor(0, 0, 0, 0.35)
        box.model = CreateFrame("PlayerModel", nil, box)
        box.model:SetPoint("TOPRIGHT", -20, -6)
        box.model:SetSize(170, 120)
        p.title = W.Text(box, 20, W.COLORS.gold, "LEFT")
        p.title:SetPoint("BOTTOMLEFT", box.art, "BOTTOMLEFT", 14, 12)
        p.info = W.Text(box, 12, W.COLORS.white, "LEFT")
        p.info:SetPoint("TOPLEFT", 20, -134)
        p.info:SetWidth(596)
        p.info:SetJustifyV("TOP")

        p.selRows = {}
        for i = 1, MAX_SELECTORS do
            local r = CreateFrame("Frame", nil, box, BackdropTemplateMixin and "BackdropTemplate" or nil)
            r:SetSize(194, 30)
            r:SetPoint("TOPLEFT", 18 + (i - 1) * 202, -246)
            W.Backdrop(r, { 0.03, 0.03, 0.04, 0.9 }, { 0.3, 0.3, 0.32, 1 }, 8)
            r.label = W.Text(r, 11, W.COLORS.gray, "LEFT")
            r.label:SetPoint("LEFT", 8, 0)
            r.label:SetWidth(44)
            r.prev = W.Button(r, "<", 26, 24, nil, "cyan")
            r.prev:SetPoint("LEFT", 52, 0)
            r.value = W.Text(r, 12, W.COLORS.white, "CENTER")
            r.value:SetPoint("LEFT", r.prev, "RIGHT", 2, 0)
            r.value:SetWidth(84)
            r.next = W.Button(r, ">", 26, 24, nil, "cyan")
            r.next:SetPoint("LEFT", r.value, "RIGHT", 2, 0)
            p.selRows[i] = r
        end

        p.actions = {}
        for i = 1, MAX_ACTIONS do
            local b = W.Button(box, "", 142, 34)
            b:SetPoint("TOPLEFT", 18 + (i - 1) * 150, -284)
            p.actions[i] = b
        end

        p.result = W.Text(box, 11, W.COLORS.white, "LEFT")
        p.result:SetPoint("TOPLEFT", 20, -326)
        p.result:SetWidth(596)
        p.result:SetJustifyV("TOP")

        ns.On("CONTENT_FINISHED", function() if p:IsShown() then UI.RefreshPanel() end end)
    end,
    refresh = function(p, hero)
        if not hero.content then return end
        local gname = p.groupNames[p.group]
        local list = {}
        for _, def in ipairs(C.Modes()) do if def.group == gname then list[#list + 1] = def end end
        if not (p.current and C.modes[p.current] and C.modes[p.current].group == gname) then
            p.current = list[1] and list[1].key
        end
        for i, c in ipairs(p.cards) do
            local def = list[i]
            c.key = def and def.key
            if def then
                c:Show()
                c.icon.icon:SetTexture(modeIcon(def.key))
                c.title:SetText(def.title)
                local ok, lines = pcall(def.info, hero, modeSel(p, def, hero))
                local first = ok and lines and lines[1] or ""
                c.sub:SetText((first:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
                c.glow:SetShown(def.key == p.current)
                if c.SetBackdropBorderColor then
                    if def.key == p.current then c:SetBackdropBorderColor(1, 0.82, 0.3, 1) else c:SetBackdropBorderColor(0.42, 0.33, 0.22, 1) end
                end
            else
                c:Hide()
            end
        end
        p.pageText:SetText(#list > #p.cards and string.format("외 %d개", #list - #p.cards) or "")

        local def = C.modes[p.current]
        if not def then return end
        local sel = modeSel(p, def, hero)
        p.title:SetText(def.title .. (C.Busy() and "  |cffff9040(진행 중)|r" or ""))
        local ok, lines = pcall(def.info, hero, sel)
        if not ok then lines = { "|cffff4040" .. tostring(lines) .. "|r" } end
        p.info:SetText(table.concat(lines or {}, "\n"))

        -- banner art + boss model
        if p.lookKey ~= def.key then
            p.lookKey = def.key
            local model, bg = modeLook(def.key)
            p.box.art:SetTexture(bg or "Interface\\Glues\\LoadingScreens\\LoadScreenEasternKingdom")
            local m = p.box.model
            if model then
                m:Show()
                safe(m.ClearModel, m)
                local shown = model.displayId and m.SetDisplayInfo and safe(m.SetDisplayInfo, m, model.displayId) ~= false
                if not shown and model.npcId and m.SetCreature then safe(m.SetCreature, m, model.npcId) end
                safe(m.SetFacing, m, math.rad(-30))
            else
                m:Hide()
            end
        end

        for i, r in ipairs(p.selRows) do
            local s = def.selectors and def.selectors[i]
            if s then
                r:Show()
                r.label:SetText(s.label)
                local text
                if s.options then
                    text = s.options[sel["_" .. s.key] or 1]
                else
                    text = tostring(sel[s.key])
                end
                r.value:SetText(text)
                r.prev:SetScript("OnClick", function() step(p, def, s, -1, IsShiftKeyDown and IsShiftKeyDown()) end)
                r.next:SetScript("OnClick", function() step(p, def, s, 1, IsShiftKeyDown and IsShiftKeyDown()) end)
            else
                r:Hide()
            end
        end

        for i, b in ipairs(p.actions) do
            local a = def.actions and def.actions[i]
            if a then
                b:Show()
                b:SetText(a.label)
                local enabled = not a.enabled or a.enabled(hero, sel)
                b:SetEnabled(enabled and true or false)
                b:SetScript("OnClick", function()
                    local h = ns.Hero.Active()
                    if not h then return end
                    local okCall, res, err, rewardLines = pcall(a.fn, h, modeSel(p, def, h))
                    if not okCall then
                        W.Toast("오류: " .. tostring(res), W.COLORS.red)
                    elseif not res then
                        W.Toast(err or "실행할 수 없습니다.", W.COLORS.red)
                    elseif rewardLines and #rewardLines > 0 then
                        W.Toast(table.concat(rewardLines, ", "), W.COLORS.green)
                    end
                    UI.RefreshPanel()
                end)
            else
                b:Hide()
            end
        end

        p.result:SetText(resultText(C.LastResult(hero, def.key)))
    end,
})
