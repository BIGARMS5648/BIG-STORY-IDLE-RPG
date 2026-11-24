-- "던전/보스" tab: every content mode registered with ns.Content.RegisterMode (growth dungeons, quick hunt,
-- burning field, world boss, 마왕 발록, boss raids, party quests, monster park, guild raids, guild content).
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

UI.RegisterPanel("content", {
    title = "던전/보스", order = 40,
    build = function(p)
        p.list = W.ScrollList(p, 230, 240, 20, function(parent)
            local b = W.Button(parent, "", 200, 19)
            return b
        end, function(b, e)
            if e.header then
                b:SetText("|cffffd100" .. e.header .. "|r")
                b:SetEnabled(false)
                b:SetScript("OnClick", nil)
            else
                b:SetEnabled(true)
                b:SetText((p.current == e.def.key and "> " or "") .. e.def.title)
                b:SetScript("OnClick", function() p.current = e.def.key; UI.RefreshPanel() end)
            end
        end)
        p.list:SetPoint("TOPLEFT", 0, 0)

        p.title = W.Text(p, 14, W.COLORS.gold, "LEFT")
        p.title:SetPoint("TOPLEFT", 240, -2)
        p.info = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.info:SetPoint("TOPLEFT", 240, -22)
        p.info:SetWidth(690)
        p.info:SetJustifyV("TOP")

        p.selRows = {}
        for i = 1, MAX_SELECTORS do
            local r = CreateFrame("Frame", nil, p)
            r:SetSize(300, 22)
            r:SetPoint("TOPLEFT", 240 + ((i - 1) % 3) * 230, -120)
            r.label = W.Text(r, 11, W.COLORS.gray, "LEFT")
            r.label:SetPoint("LEFT", 0, 0)
            r.label:SetWidth(50)
            r.prev = W.Button(r, "<", 24, 20)
            r.prev:SetPoint("LEFT", 50, 0)
            r.value = W.Text(r, 12, W.COLORS.white, "CENTER")
            r.value:SetPoint("LEFT", r.prev, "RIGHT", 2, 0)
            r.value:SetWidth(96)
            r.next = W.Button(r, ">", 24, 20)
            r.next:SetPoint("LEFT", r.value, "RIGHT", 2, 0)
            p.selRows[i] = r
        end

        p.actions = {}
        for i = 1, MAX_ACTIONS do
            local b = W.Button(p, "", 110, 22)
            b:SetPoint("TOPLEFT", 240 + (i - 1) * 116, -148)
            p.actions[i] = b
        end

        p.result = W.Text(p, 11, W.COLORS.white, "LEFT")
        p.result:SetPoint("TOPLEFT", 240, -178)
        p.result:SetWidth(690)
        p.result:SetJustifyV("TOP")

        ns.On("CONTENT_FINISHED", function() if p:IsShown() then UI.RefreshPanel() end end)
    end,
    refresh = function(p, hero)
        if not hero.content then return end
        local modes = C.Modes()
        if not p.current and modes[1] then p.current = modes[1].key end
        -- grouped list
        local list, lastGroup = {}, nil
        for _, def in ipairs(modes) do
            if def.group ~= lastGroup then
                list[#list + 1] = { header = def.group }
                lastGroup = def.group
            end
            list[#list + 1] = { def = def }
        end
        p.list:SetData(list)

        local def = C.modes[p.current]
        if not def then return end
        local sel = modeSel(p, def, hero)
        p.title:SetText(def.title .. (C.Busy() and "  |cffff9040(진행 중)|r" or ""))
        local ok, lines = pcall(def.info, hero, sel)
        if not ok then lines = { "|cffff4040" .. tostring(lines) .. "|r" } end
        p.info:SetText(table.concat(lines or {}, "\n"))

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
