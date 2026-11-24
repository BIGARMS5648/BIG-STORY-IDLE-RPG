-- Expression compiler for skill-table expressions such as
--   "$CreatureStateCount(FiredCreature;ComboAttack) >= 5"
--   "#MultByAttackSpeed(200)"
--   "$Trigger.Flag & DamageFlag.Critical > 0"
-- Expressions are compiled once into Lua closures: fn(env) -> number|boolean|string.
-- env must implement env:Call(name, args) and env:Trigger(field).
local ADDON, ns = ...
local E = {}
ns.Expr = E

local trunc = function(x) if x >= 0 then return math.floor(x) end return -math.floor(-x) end

---------------------------------------------------------------------------
-- Macro expansion (#Name(a;b) with {0},{1} placeholders)
---------------------------------------------------------------------------
local function splitArgs(s)
    local args, depth, start = {}, 0, 1
    for i = 1, #s do
        local c = s:sub(i, i)
        if c == "(" then depth = depth + 1
        elseif c == ")" then depth = depth - 1
        elseif (c == ";" or c == ",") and depth == 0 then
            args[#args + 1] = s:sub(start, i - 1)
            start = i + 1
        end
    end
    args[#args + 1] = s:sub(start)
    for i = 1, #args do args[i] = args[i]:match("^%s*(.-)%s*$") end
    return args
end

-- find matching ')' for '(' at position p
local function matchParen(s, p)
    local depth = 0
    for i = p, #s do
        local c = s:sub(i, i)
        if c == "(" then depth = depth + 1
        elseif c == ")" then
            depth = depth - 1
            if depth == 0 then return i end
        end
    end
    return #s + 1 -- lenient: unbalanced macro bodies exist in the client data
end

local function expandMacros(src, depth)
    depth = depth or 0
    if depth > 12 then return src end
    local macros = ns.Data and ns.Data.ExpressionMacros or {}
    local out, i = {}, 1
    while true do
        local s, e, name = src:find("#([%a_][%w_]*)%s*%(", i)
        if not s then
            out[#out + 1] = src:sub(i)
            break
        end
        out[#out + 1] = src:sub(i, s - 1)
        local close = matchParen(src, e)
        local inner = src:sub(e + 1, close - 1)
        if name == "if" then
            local args = splitArgs(inner)
            for k = 1, #args do args[k] = expandMacros(args[k], depth + 1) end
            out[#out + 1] = "$__if(" .. table.concat(args, ";") .. ")"
        else
            local body = macros[name]
            if body then
                local args = splitArgs(inner)
                body = body:gsub("{(%d+)}", function(n) return "(" .. (args[tonumber(n) + 1] or "0") .. ")" end)
                out[#out + 1] = "(" .. expandMacros(body, depth + 1) .. ")"
            else
                out[#out + 1] = "0"
            end
        end
        i = close + 1
    end
    return table.concat(out)
end
E.ExpandMacros = expandMacros

---------------------------------------------------------------------------
-- Tokenizer
---------------------------------------------------------------------------
local function tokenize(src)
    local toks, i, n = {}, 1, #src
    while i <= n do
        local c = src:sub(i, i)
        if c:match("%s") then
            i = i + 1
        elseif c:match("%d") then
            local num = src:match("^%d+%.?%d*", i)
            toks[#toks + 1] = { t = "num", v = tonumber(num) }
            i = i + #num
        elseif c == "$" then
            local name = src:match("^%$[%a_][%w_%.]*", i)
            toks[#toks + 1] = { t = "var", v = name:sub(2) }
            i = i + #name
        elseif c == "'" or c == '"' then
            local close = src:find(c, i + 1, true) or (n + 1)
            toks[#toks + 1] = { t = "str", v = src:sub(i + 1, close - 1) }
            i = close + 1
        elseif c:match("[%a_]") then
            local name = src:match("^[%a_][%w_%.]*", i)
            toks[#toks + 1] = { t = "id", v = name }
            i = i + #name
        else
            local two = src:sub(i, i + 1)
            if two == "&&" or two == "||" or two == "==" or two == "!=" or two == "<=" or two == ">=" then
                toks[#toks + 1] = { t = "op", v = two }
                i = i + 2
            elseif c:match("[%+%-%*/%%<>&|%(%);,!]") then
                toks[#toks + 1] = { t = "op", v = c }
                i = i + 1
            else
                i = i + 1 -- skip unknown char
            end
        end
    end
    toks[#toks + 1] = { t = "eof" }
    return toks
end

---------------------------------------------------------------------------
-- Enum constants
---------------------------------------------------------------------------
E.DamageFlag = { None = 0, Critical = 1, BaseAttack = 2, Dot = 4, Miss = 8, Projectile = 16 }
E.StateAttrFlag = { None = 0, Buff = 1, Debuff = 2, CC = 4 }

local function identValue(name)
    local enum, field = name:match("^(%a+)%.(%a+)$")
    if enum == "DamageFlag" then return E.DamageFlag[field] or 0 end
    if enum == "StateAttrFlag" then return E.StateAttrFlag[field] or 0 end
    local l = name:lower()
    if l == "true" then return true end
    if l == "false" then return false end
    return name -- bare identifiers (creature selectors, state names...) are strings
end

local function num(v)
    if v == true then return 1 end
    if v == false or v == nil then return 0 end
    if type(v) == "string" then return tonumber(v) or 0 end
    return v
end
local function truthy(v)
    if type(v) == "number" then return v ~= 0 end
    return v and true or false
end
E.num, E.truthy = num, truthy

-- bitwise AND on non-negative integers (no 'bit' library needed)
local function band(a, b)
    a, b = math.floor(num(a)), math.floor(num(b))
    local r, bitv = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then r = r + bitv end
        a, b, bitv = math.floor(a / 2), math.floor(b / 2), bitv * 2
    end
    return r
end

---------------------------------------------------------------------------
-- Pratt parser producing closures
---------------------------------------------------------------------------
local BIN = {
    ["||"] = 1, ["&&"] = 2, ["=="] = 3, ["!="] = 3,
    ["<"] = 4, ["<="] = 4, [">"] = 4, [">="] = 4,
    ["|"] = 5, ["&"] = 6, ["+"] = 7, ["-"] = 7, ["*"] = 8, ["/"] = 8, ["%"] = 8,
}

local function eq(a, b)
    if type(a) == "string" or type(b) == "string" then return tostring(a) == tostring(b) end
    return num(a) == num(b)
end

local function makeBin(op, l, r)
    if op == "||" then return function(env) return truthy(l(env)) or truthy(r(env)) end end
    if op == "&&" then return function(env) return truthy(l(env)) and truthy(r(env)) end end
    if op == "==" then return function(env) return eq(l(env), r(env)) end end
    if op == "!=" then return function(env) return not eq(l(env), r(env)) end end
    if op == "<" then return function(env) return num(l(env)) < num(r(env)) end end
    if op == "<=" then return function(env) return num(l(env)) <= num(r(env)) end end
    if op == ">" then return function(env) return num(l(env)) > num(r(env)) end end
    if op == ">=" then return function(env) return num(l(env)) >= num(r(env)) end end
    if op == "&" then return function(env) return band(l(env), r(env)) end end
    if op == "|" then return function(env)
        local a, b = num(l(env)), num(r(env))
        return a + b - band(a, b)
    end end
    if op == "+" then return function(env) return num(l(env)) + num(r(env)) end end
    if op == "-" then return function(env) return num(l(env)) - num(r(env)) end end
    if op == "*" then return function(env) return num(l(env)) * num(r(env)) end end
    if op == "/" then return function(env)
        local d = num(r(env))
        if d == 0 then return 0 end
        return trunc(num(l(env)) / d)
    end end
    if op == "%" then return function(env)
        local d = num(r(env))
        if d == 0 then return 0 end
        return math.fmod(num(l(env)), d)
    end end
    error("op " .. op)
end

local Parser = {}
Parser.__index = Parser

function Parser:peek() return self.toks[self.pos] end
function Parser:next()
    local t = self.toks[self.pos]
    self.pos = self.pos + 1
    return t
end
function Parser:accept(v)
    local t = self:peek()
    if t.t == "op" and t.v == v then self.pos = self.pos + 1 return true end
    return false
end

function Parser:parseArgs()
    local args = {}
    if self:accept(")") then return args end
    while true do
        args[#args + 1] = self:expr(0)
        if self:accept(";") or self:accept(",") then
            -- continue
        else
            self:accept(")")
            break
        end
        if self:peek().t == "eof" then break end
    end
    return args
end

function Parser:primary()
    local t = self:next()
    if t.t == "num" then
        local v = t.v
        return function() return v end
    elseif t.t == "str" then
        local v = t.v
        return function() return v end
    elseif t.t == "id" then
        local v = identValue(t.v)
        if self:peek().t == "op" and self:peek().v == "(" then -- unknown bare call -> 0
            self:next(); self:parseArgs()
            return function() return 0 end
        end
        return function() return v end
    elseif t.t == "var" then
        local name = t.v
        if self:accept("(") then
            local args = self:parseArgs()
            if name == "__if" then
                local c, a, b = args[1], args[2], args[3]
                return function(env)
                    if truthy(c and c(env)) then return a and a(env) or 0 end
                    return b and b(env) or 0
                end
            end
            local n = #args
            return function(env)
                local vals = {}
                for i = 1, n do vals[i] = args[i](env) end
                return env:Call(name, vals)
            end
        end
        local field = name:match("^Trigger%.(.+)$")
        if field then
            return function(env) return env:Trigger(field) end
        end
        return function(env) return env:Call(name, {}) end
    elseif t.t == "op" then
        if t.v == "(" then
            local e = self:expr(0)
            self:accept(")")
            return e
        elseif t.v == "-" then
            local e = self:unary()
            return function(env) return -num(e(env)) end
        elseif t.v == "!" then
            local e = self:unary()
            return function(env) return not truthy(e(env)) end
        end
    end
    return function() return 0 end
end

function Parser:unary()
    return self:primary()
end

function Parser:expr(minPrec)
    local left = self:unary()
    while true do
        local t = self:peek()
        if t.t ~= "op" then break end
        local prec = BIN[t.v]
        if not prec or prec <= minPrec then break end
        self:next()
        local right = self:expr(prec)
        left = makeBin(t.v, left, right)
    end
    return left
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
local cache = {}

function E.Compile(src)
    if type(src) ~= "string" then
        return function() return src end
    end
    local fn = cache[src]
    if fn then return fn end
    local expanded = expandMacros(src)
    local p = setmetatable({ toks = tokenize(expanded), pos = 1 }, Parser)
    local ok, res = pcall(function() return p:expr(0) end)
    if not ok then
        res = function() return 0 end
    end
    cache[src] = res
    return res
end

-- Is this value an expression (vs a plain literal / enum name)?
function E.IsExpr(v)
    return type(v) == "string" and (v:find("%$") or v:find("#")) ~= nil
end

function E.Eval(src, env)
    if type(src) == "number" or type(src) == "boolean" then return src end
    if not E.IsExpr(src) then return tonumber(src) or src end
    return E.Compile(src)(env)
end

function E.Num(src, env) return num(E.Eval(src, env)) end
function E.Bool(src, env) return truthy(E.Eval(src, env)) end
