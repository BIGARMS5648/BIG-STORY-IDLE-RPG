-- Headless loader: runs addon files outside WoW with minimal stubs.
-- Usage (from repo root): lua5.1 tools/test/<test>.lua
local H = {}

ROOT = ROOT or "BigStoryIdleRPG/"

-- minimal WoW stubs
time = os.time
GetServerTime = os.time
UnitName = function() return "Tester" end
GetRealmName = function() return "TestRealm" end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) print((msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))) end }

H.ns = { Data = {} }

function H.load(path)
    local f, err = loadfile(ROOT .. path)
    if not f then error(err) end
    f("BigStoryIdleRPG", H.ns)
end

-- load every file listed in the TOC up to (not including) the UI section
function H.loadToc(stopAt)
    for line in io.lines(ROOT .. "BigStoryIdleRPG.toc") do
        line = line:gsub("\r", "")
        if not line:match("^#") and line:match("%.lua$") then
            if stopAt and line:find(stopAt, 1, true) then break end
            H.load(line:gsub("\\", "/"))
        end
    end
end

return H
