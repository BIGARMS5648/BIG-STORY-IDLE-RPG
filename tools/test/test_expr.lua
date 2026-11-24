-- Compiles every expression found in the skill data and evaluates it with a stub env.
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.load("Core/Init.lua")
H.load("Core/Util.lua")
H.load("Data/Jobs.lua")
H.load("Data/Skills.lua")
H.load("Engine/Expr.lua")
local ns = H.ns
local E = ns.Expr

local env = { calls = {} }
function env:Call(name, args)
    self.calls[name] = (self.calls[name] or 0) + 1
    if name == "CreatureStateCount" then return 3 end
    if name == "CreatureFinalStat" then return 500 end
    if name == "Min" then return math.min(args[1] or 0, args[2] or 0) end
    if name == "Max" then return math.max(args[1] or 0, args[2] or 0) end
    return 0
end
function env:Trigger(field) return 0 end

local count, errors = 0, 0
local function visit(v)
    if type(v) == "string" and E.IsExpr(v) then
        count = count + 1
        local ok, res = pcall(E.Eval, v, env)
        if not ok then
            errors = errors + 1
            print("ERR", v, res)
        end
    elseif type(v) == "table" then
        for _, x in pairs(v) do visit(x) end
    end
end
visit(ns.Data.Skills)

-- spot checks
local function check(src, expect)
    local got = E.Eval(src, env)
    print(string.format("%-60s => %s (expect %s)", src, tostring(got), tostring(expect)))
end
check("$CreatureStateCount(FiredCreature;ComboAttack) >= 5", false)
check("$CreatureStateCount(FiredCreature;ComboAttack) * 10", 30)
check("#MultByAttackSpeed(200)", 500 * 200 / 1000 + 200)
check("#FastByAttackSpeed(1000)", math.floor(1000 * 1000 / 1500))
check("#FlashSlash(3500)", 5250)
check("1 + 2 * 3 == 7 && 4 > 3", true)
check("$Trigger.Flag & DamageFlag.Critical > 0", false)
print(string.format("expressions: %d, errors: %d", count, errors))
for k, v in pairs(env.calls) do io.write(k, "=", v, " ") end
print()
