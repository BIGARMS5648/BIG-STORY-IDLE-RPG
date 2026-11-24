-- Addon-to-addon messaging between players who have this addon installed.
-- Payloads are serialized, split into 230-byte chunks, rate limited and
-- reassembled on the other side.
--
-- API
--   ns.Comm.Register(msgType, function(sender, payload, channel) end)
--   ns.Comm.Send(msgType, payload, channel, target)   channel: "GUILD"|"PARTY"|"RAID"|"WHISPER"|"CHANNEL"
--   ns.Comm.Broadcast(msgType, payload)               -- guild + group + addon channel (per settings)
local ADDON, ns = ...
local Compat = ns.Compat
local S = ns.Serializer

local Comm = {}
ns.Comm = Comm

Comm.PREFIX = "BSIRPG1"
Comm.CHUNK = 230
Comm.handlers = {}
Comm.queue = {}
Comm.inbox = {}

local BURST, REFILL_SEC = 8, 1.1
local tokens = BURST
local lastRefill = 0
local msgCounter = 0

function Comm.Register(msgType, fn)
    Comm.handlers[msgType] = fn
end

local function now()
    return GetTime and GetTime() or os.clock()
end

local function channelIndex()
    if not GetChannelName then return nil end
    local name = ns.db and ns.db.settings.arenaChannel or "BigStoryArena"
    local id = GetChannelName(name)
    if id and id > 0 then return id end
    return nil
end

function Comm.JoinChannel()
    if not (ns.db and ns.db.settings.arenaUseChannel) then return end
    local name = ns.db.settings.arenaChannel or "BigStoryArena"
    if channelIndex() then return end
    if JoinTemporaryChannel then
        pcall(JoinTemporaryChannel, name)
    elseif JoinChannelByName then
        pcall(JoinChannelByName, name)
    end
    -- keep the addon channel out of the chat windows
    if ChatFrame_RemoveChannel and DEFAULT_CHAT_FRAME then
        pcall(ChatFrame_RemoveChannel, DEFAULT_CHAT_FRAME, name)
    end
end

local function rawSend(text, channel, target)
    if channel == "CHANNEL" then
        target = target or channelIndex()
        if not target then return false end
    end
    local ok = pcall(Compat.SendAddonMessage, Comm.PREFIX, text, channel, target)
    return ok
end

local function pump()
    local t = now()
    if t - lastRefill >= REFILL_SEC then
        local add = math.floor((t - lastRefill) / REFILL_SEC)
        tokens = math.min(BURST, tokens + add)
        lastRefill = t
    end
    while tokens > 0 and #Comm.queue > 0 do
        local m = table.remove(Comm.queue, 1)
        rawSend(m.text, m.channel, m.target)
        tokens = tokens - 1
    end
end
Comm.Pump = pump

-- header: type \t id \t part/total \t data
function Comm.Send(msgType, payload, channel, target)
    msgCounter = (msgCounter + 1) % 100000
    local id = tostring(msgCounter)
    local body = S.Escape(S.Serialize(payload))
    local sum = S.Checksum(body)
    local chunks = {}
    for i = 1, #body, Comm.CHUNK do chunks[#chunks + 1] = body:sub(i, i + Comm.CHUNK - 1) end
    if #chunks == 0 then chunks[1] = "" end
    for i, c in ipairs(chunks) do
        local header = string.format("%s\t%s\t%d/%d\t%s", msgType, id, i, #chunks, i == 1 and tostring(sum) or "")
        table.insert(Comm.queue, { text = header .. "\t" .. c, channel = channel, target = target })
    end
    pump()
end

function Comm.Broadcast(msgType, payload)
    local s = ns.db and ns.db.settings or {}
    if s.arenaUseGuild ~= false and Compat.InGuild() then Comm.Send(msgType, payload, "GUILD") end
    local grp = Compat.GroupChannel()
    if s.arenaUseParty ~= false and grp then Comm.Send(msgType, payload, grp) end
    if s.arenaUseChannel ~= false and channelIndex() then Comm.Send(msgType, payload, "CHANNEL") end
end

local function onMessage(prefix, text, channel, sender)
    if prefix ~= Comm.PREFIX then return end
    sender = sender and sender:gsub("%-.*$", "") or sender
    local me = UnitName and UnitName("player")
    if sender == me then return end
    local msgType, id, part, total, sum, data = text:match("^([^\t]+)\t([^\t]+)\t(%d+)/(%d+)\t([^\t]*)\t(.*)$")
    if not msgType then return end
    part, total = tonumber(part), tonumber(total)
    local key = sender .. ":" .. id
    local box = Comm.inbox[key]
    if not box then
        box = { parts = {}, n = 0, total = total, at = now() }
        Comm.inbox[key] = box
    end
    if part == 1 then box.sum = tonumber(sum) end
    if not box.parts[part] then
        box.parts[part] = data
        box.n = box.n + 1
    end
    if box.n >= box.total then
        Comm.inbox[key] = nil
        local body = table.concat(box.parts)
        if box.sum and S.Checksum(body) ~= box.sum then return end
        local payload = S.Deserialize(S.Unescape(body))
        local fn = Comm.handlers[msgType]
        if fn then
            local ok, err = pcall(fn, sender, payload, channel)
            if not ok then ns.Debug("comm %s: %s", msgType, tostring(err)) end
        end
    end
end
Comm.OnMessage = onMessage

-- drop half-received messages after a minute
local function sweep()
    local t = now()
    for k, box in pairs(Comm.inbox) do
        if t - box.at > 60 then Comm.inbox[k] = nil end
    end
end

ns.On("LOGIN", function()
    Compat.RegisterPrefix(Comm.PREFIX)
    ns.RegisterEvent("CHAT_MSG_ADDON", onMessage)
    if Compat.NewTicker then
        Compat.NewTicker(0.25, pump)
        Compat.NewTicker(30, sweep)
    end
    Compat.After(5, Comm.JoinChannel)
end)
