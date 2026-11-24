-- Round-trips a hero profile through the chunked addon-message layer.
package.path = "tools/test/?.lua;" .. package.path
local Stub = require("wowstub")
Stub.Install()
local H = require("harness")
H.loadToc()

local ns = H.ns
ns.InitDB()
local hero = ns.Hero.New("bishop")
hero.level = 120
hero.jobStep = 4
local profile = ns.Hero.BuildProfile(hero)
local got
ns.Comm.Register("PROFILE", function(sender, payload) got = { sender = sender, p = payload } end)
GetTime = function() return 1000 + #Stub.sent * 2 end -- plenty of tokens
ns.Comm.Send("PROFILE", profile, "WHISPER", "Other")
for i = 1, 20 do ns.Comm.Pump(); GetTime = function() return 2000 + i * 5 end end
local bytes = 0
for _, m in ipairs(Stub.sent) do
    bytes = bytes + #m.msg
    assert(#m.msg <= 255, "chunk too long: " .. #m.msg)
    ns.Comm.OnMessage(m.prefix, m.msg, m.chan, "Sender-Realm")
end
assert(got, "profile not received")
assert(got.p.jobKey == "bishop" and got.p.level == 120, "payload mismatch")
local n = 0
for _ in pairs(got.p.skillSet.levels) do n = n + 1 end
print(string.format("comm ok: %d messages, %d bytes, sender %s, skill levels %d", #Stub.sent, bytes, got.sender, n))
