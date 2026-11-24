-- Utilities: number formatting, deterministic RNG, table helpers, time.
local ADDON, ns = ...
local U = {}
ns.U = U

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

---------------------------------------------------------------------------
-- Integer helpers that mirror the client's C# integer math.
---------------------------------------------------------------------------
-- truncate toward zero (C# (int) cast / Math.Truncate)
function U.trunc(x)
    if x >= 0 then return floor(x) end
    return -floor(-x)
end

-- Math.Round (banker's rounding = MidpointRounding.ToEven, C# default)
function U.round(x)
    local f = floor(x)
    local d = x - f
    if d > 0.5 then return f + 1 end
    if d < 0.5 then return f end
    if f % 2 == 0 then return f end
    return f + 1
end

function U.clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

---------------------------------------------------------------------------
-- Korean large-number formatting (만/억/조/경/해/자/양/구/간)
---------------------------------------------------------------------------
local UNITS = { "", "만", "억", "조", "경", "해", "자", "양", "구", "간", "정", "재", "극" }

function U.FormatNumber(n, digits)
    if n == nil then return "0" end
    if n ~= n then return "NaN" end
    if n == math.huge then return "∞" end
    local neg = n < 0
    n = abs(n)
    if n < 10000 then
        local s = (n == floor(n)) and string.format("%d", n) or string.format("%.1f", n)
        return neg and ("-" .. s) or s
    end
    local idx = 1
    while n >= 10000 and idx < #UNITS do
        n = n / 10000
        idx = idx + 1
    end
    digits = digits or 2
    local s
    if n >= 1000 then s = string.format("%d", floor(n))
    elseif n >= 100 then s = string.format("%." .. max(0, digits - 2) .. "f", n)
    elseif n >= 10 then s = string.format("%." .. max(0, digits - 1) .. "f", n)
    else s = string.format("%." .. digits .. "f", n) end
    s = s:gsub("%.?0+$", "")
    return (neg and "-" or "") .. s .. UNITS[idx]
end

-- "12,345,678"
function U.Comma(n)
    local s = string.format("%d", floor(n or 0))
    local k
    repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
    return s
end

-- percent from an "M" value (1000 = 100%) => "12.3%"
function U.PctM(v, decimals)
    return string.format("%." .. (decimals or 1) .. "f%%", (v or 0) / 10)
end

function U.FormatDuration(sec)
    sec = floor(sec or 0)
    local d = floor(sec / 86400); sec = sec % 86400
    local h = floor(sec / 3600); sec = sec % 3600
    local m = floor(sec / 60); local s = sec % 60
    if d > 0 then return string.format("%d일 %d시간", d, h) end
    if h > 0 then return string.format("%d시간 %d분", h, m) end
    if m > 0 then return string.format("%d분 %d초", m, s) end
    return string.format("%d초", s)
end

---------------------------------------------------------------------------
-- Deterministic RNG (Park-Miller "minimal standard", exact in doubles).
-- Same seed => same sequence on every client, which keeps PvP replays
-- identical on both players' screens.
---------------------------------------------------------------------------
local M31 = 2147483647
local RNG = {}
RNG.__index = RNG

function U.NewRNG(seed)
    seed = floor(abs(seed or 1)) % M31
    if seed == 0 then seed = 1 end
    return setmetatable({ s = seed }, RNG)
end

function RNG:Next()                 -- integer in [1, M31-1]
    self.s = (self.s * 16807) % M31
    return self.s
end

function RNG:Float()                -- [0,1)
    return (self:Next() - 1) / (M31 - 1)
end

function RNG:Int(lo, hi)            -- inclusive
    return lo + floor(self:Float() * (hi - lo + 1))
end

-- returns true with probability ratioM/1000
function RNG:ChanceM(ratioM)
    if ratioM >= 1000 then return true end
    if ratioM <= 0 then return false end
    return self:Float() * 1000 < ratioM
end

-- pick from weights {w1, w2, ...} -> index
function RNG:Weighted(weights, total)
    if not total then
        total = 0
        for i = 1, #weights do total = total + weights[i] end
    end
    local r = self:Float() * total
    for i = 1, #weights do
        r = r - weights[i]
        if r < 0 then return i end
    end
    return #weights
end

-- string hash -> seed (djb2 on bytes, folded into M31)
function U.HashString(str)
    local h = 5381
    for i = 1, #str do
        h = (h * 33 + str:byte(i)) % M31
    end
    if h == 0 then h = 1 end
    return h
end

-- global gameplay RNG (seeded from time on login)
U.rng = U.NewRNG((time and time() or os.time()) % M31)

---------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------
function U.DeepCopy(t, seen)
    if type(t) ~= "table" then return t end
    seen = seen or {}
    if seen[t] then return seen[t] end
    local c = {}
    seen[t] = c
    for k, v in pairs(t) do c[U.DeepCopy(k, seen)] = U.DeepCopy(v, seen) end
    return c
end

function U.Merge(dst, src)
    for k, v in pairs(src) do dst[k] = v end
    return dst
end

function U.Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function U.Keys(t, sortFn)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, sortFn)
    return keys
end

function U.Split(str, sep)
    local out = {}
    for piece in string.gmatch(str, "([^" .. sep .. "]+)") do out[#out + 1] = piece end
    return out
end

---------------------------------------------------------------------------
-- Time (server time so daily/weekly resets match for everybody)
---------------------------------------------------------------------------
function U.Now()
    if GetServerTime then return GetServerTime() end
    return os.time()
end

-- Reset at 00:00 KST (UTC+9), the reset time of the original game.
U.RESET_TZ_OFFSET = 9 * 3600

function U.DayIndex(t)
    t = t or U.Now()
    return floor((t + U.RESET_TZ_OFFSET) / 86400)
end

-- weeks start Monday 00:00 KST (1970-01-01 was a Thursday)
function U.WeekIndex(t)
    t = t or U.Now()
    return floor((floor((t + U.RESET_TZ_OFFSET) / 86400) + 3) / 7)
end

function U.SecondsToNextDay(t)
    t = t or U.Now()
    return 86400 - ((t + U.RESET_TZ_OFFSET) % 86400)
end
