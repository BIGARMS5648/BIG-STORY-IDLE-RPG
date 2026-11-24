-- Compact serializer for addon-message payloads (profiles, arena results).
-- Format: n | t | f | #<number>; | s<len>:<bytes> | { key value ... }
local ADDON, ns = ...
local S = {}
ns.Serializer = S

local concat, format, tostring, tonumber, type = table.concat, string.format, tostring, tonumber, type

local function ser(v, out)
    local t = type(v)
    if v == nil then
        out[#out + 1] = "n"
    elseif t == "boolean" then
        out[#out + 1] = v and "t" or "f"
    elseif t == "number" then
        if v == math.floor(v) and v > -1e15 and v < 1e15 then
            out[#out + 1] = "#" .. format("%d", v) .. ";"
        else
            out[#out + 1] = "#" .. format("%.17g", v) .. ";"
        end
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "table" then
        out[#out + 1] = "{"
        for k, val in pairs(v) do
            if type(val) ~= "function" then
                ser(k, out)
                ser(val, out)
            end
        end
        out[#out + 1] = "}"
    else
        out[#out + 1] = "n"
    end
end

function S.Serialize(v)
    local out = {}
    ser(v, out)
    return concat(out)
end

local function de(str, pos)
    local c = str:sub(pos, pos)
    if c == "n" then return nil, pos + 1 end
    if c == "t" then return true, pos + 1 end
    if c == "f" then return false, pos + 1 end
    if c == "#" then
        local e = str:find(";", pos, true)
        if not e then error("bad number") end
        return tonumber(str:sub(pos + 1, e - 1)), e + 1
    end
    if c == "s" then
        local colon = str:find(":", pos, true)
        if not colon then error("bad string") end
        local len = tonumber(str:sub(pos + 1, colon - 1))
        return str:sub(colon + 1, colon + len), colon + len + 1
    end
    if c == "{" then
        local tbl = {}
        pos = pos + 1
        while true do
            if pos > #str then error("unterminated table") end
            if str:sub(pos, pos) == "}" then return tbl, pos + 1 end
            local k, v
            k, pos = de(str, pos)
            v, pos = de(str, pos)
            if k ~= nil then tbl[k] = v end
        end
    end
    error("bad token '" .. tostring(c) .. "' at " .. pos)
end

function S.Deserialize(str)
    local ok, v = pcall(function()
        local val = de(str, 1)
        return val
    end)
    if ok then return v end
    return nil, v
end

-- Transport escaping: addon messages must not contain NUL; '|' is escaped
-- because chat code treats it specially.
function S.Escape(str)
    return (str:gsub("\\", "\\\\"):gsub("|", "\\p"):gsub("%z", "\\0"))
end

function S.Unescape(str)
    return (str:gsub("\\(.)", function(c)
        if c == "p" then return "|" end
        if c == "0" then return "\0" end
        return c
    end))
end

-- Simple checksum (used to detect tampered or truncated payloads).
function S.Checksum(str)
    local a, b = 1, 0
    for i = 1, #str do
        a = (a + str:byte(i)) % 65521
        b = (b + a) % 65521
    end
    return b * 65536 + a
end
