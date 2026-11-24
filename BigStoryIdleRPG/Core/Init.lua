-- 빅 스토리 키우기 (BigStoryIdleRPG)
-- Core namespace, saved variables, internal event bus and slash commands.
local ADDON, ns = ...

ns.ADDON = ADDON
ns.VERSION = "0.1.0"
ns.DB_VERSION = 1
ns.Data = ns.Data or {}
ns.L = ns.L or {}

---------------------------------------------------------------------------
-- Internal event bus (game-logic events, independent of WoW events)
---------------------------------------------------------------------------
local listeners = {}

function ns.On(event, fn, owner)
    local list = listeners[event]
    if not list then
        list = {}
        listeners[event] = list
    end
    list[#list + 1] = { fn = fn, owner = owner }
end

function ns.Off(event, owner)
    local list = listeners[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].owner == owner then table.remove(list, i) end
    end
end

function ns.Fire(event, ...)
    local list = listeners[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i].fn, ...)
        if not ok and ns.Debug then ns.Debug("event %s: %s", event, tostring(err)) end
    end
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
local PREFIX = "|cffffd100[빅스토리]|r "

function ns.Print(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
    else
        print(PREFIX .. msg)
    end
end

function ns.Debug(fmt, ...)
    if not (ns.db and ns.db.settings and ns.db.settings.debug) then return end
    ns.Print("|cff888888" .. fmt .. "|r", ...)
end

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
local DEFAULT_SETTINGS = {
    debug = false,
    scale = 1.0,
    showDamageText = true,
    showEffects = true, showProps = true,
    autoOpen = false,
    arenaChannel = "BigStoryArena",
    arenaUseGuild = true,
    arenaUseParty = true,
    arenaUseChannel = true,
    minimap = { angle = 200, hide = false },
}

local function applyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            applyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function ns.InitDB()
    BigStoryIdleDB = BigStoryIdleDB or {}
    local db = BigStoryIdleDB
    db.version = db.version or ns.DB_VERSION
    db.settings = db.settings or {}
    applyDefaults(db.settings, DEFAULT_SETTINGS)
    db.heroes = db.heroes or {}        -- [heroId] = hero save (see Systems/Hero.lua)
    db.active = db.active or {}        -- [wowCharKey] = heroId
    db.account = db.account or {}      -- account-wide progress (shared like 계정 단위 콘텐츠)
    db.arena = db.arena or {}          -- arena ladder, opponent snapshots
    ns.db = db
    ns.Fire("DB_READY", db)
end

function ns.CharKey()
    local name = UnitName and UnitName("player") or "Player"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return (name or "Player") .. "-" .. (realm or "Realm")
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
ns.slash = {}

function ns.RegisterSlash(cmd, desc, fn)
    ns.slash[cmd] = { desc = desc, fn = fn }
end

local function handleSlash(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "" then
        if ns.UI and ns.UI.Toggle then ns.UI.Toggle() end
        return
    end
    local entry = ns.slash[cmd]
    if entry then
        entry.fn(rest)
    else
        ns.Print("명령어 목록:")
        for k, v in pairs(ns.slash) do
            ns.Print("  /bsi %s - %s", k, v.desc)
        end
    end
end

if SlashCmdList then
    SLASH_BIGSTORYIDLE1 = "/bsi"
    SLASH_BIGSTORYIDLE2 = "/빅스토리"
    SlashCmdList.BIGSTORYIDLE = handleSlash
end

ns.RegisterSlash("debug", "디버그 메시지 켜기/끄기", function()
    ns.db.settings.debug = not ns.db.settings.debug
    ns.Print("디버그: %s", ns.db.settings.debug and "켜짐" or "꺼짐")
end)

---------------------------------------------------------------------------
-- WoW event frame
---------------------------------------------------------------------------
if CreateFrame then
    local f = CreateFrame("Frame")
    ns.eventFrame = f
    local wowHandlers = {}
    function ns.RegisterEvent(event, fn)
        wowHandlers[event] = wowHandlers[event] or {}
        table.insert(wowHandlers[event], fn)
        f:RegisterEvent(event)
    end
    f:SetScript("OnEvent", function(_, event, ...)
        local list = wowHandlers[event]
        if not list then return end
        for i = 1, #list do
            local ok, err = pcall(list[i], ...)
            if not ok then ns.Print("|cffff4040오류|r %s: %s", event, tostring(err)) end
        end
    end)

    ns.RegisterEvent("ADDON_LOADED", function(name)
        if name ~= ADDON then return end
        ns.InitDB()
    end)
    ns.RegisterEvent("PLAYER_LOGIN", function()
        ns.Fire("LOGIN")
    end)
    ns.RegisterEvent("PLAYER_LOGOUT", function()
        ns.Fire("LOGOUT")
    end)
else
    function ns.RegisterEvent() end
end
